import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:madebyhands/core/services/payment_api.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
// dart.library.js_interop is true for both dart2js and Wasm builds, while
// dart.library.html is false under Wasm — which would silently select the
// stub and make web checkout throw UnsupportedError.
import 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart';

/// Payment ids returned by Razorpay Checkout after a successful payment.
class RazorpayPaymentResult {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  const RazorpayPaymentResult({this.paymentId, this.orderId, this.signature});
}

/// Thrown when the payment API could not turn a captured payment into orders.
class PaymentConfirmationException implements Exception {
  final String message;

  /// True when the server already refunded the payment, so retrying the
  /// confirmation is pointless and the buyer can simply try again.
  final bool refunded;

  const PaymentConfirmationException(this.message, {this.refunded = false});

  @override
  String toString() => message;
}

/// Server order created by `/api/create-order`.
class RazorpayCheckoutOrder {
  final String orderId;
  final int amountInPaise;
  final String keyId;

  const RazorpayCheckoutOrder({
    required this.orderId,
    required this.amountInPaise,
    required this.keyId,
  });

  int get amountInRupees => (amountInPaise / 100).round();
}

class RazorpayService {
  final Dio _dio;
  Razorpay? _razorpay;
  ValueChanged<RazorpayPaymentResult>? _onSuccess;
  ValueChanged<String>? _onFailure;

  RazorpayService({Dio? dio}) : _dio = dio ?? PaymentApi.createClient();

  /// Registers the callbacks for the native SDK and the web bridge.
  void init({
    required ValueChanged<RazorpayPaymentResult> onSuccess,
    required ValueChanged<String> onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
  }

  /// The native SDK is created on first use so screens that never pay (and
  /// widget tests) do not touch the platform channel.
  Razorpay _nativeCheckout() {
    final existing = _razorpay;
    if (existing != null) return existing;
    final razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      _onSuccess?.call(
        RazorpayPaymentResult(
          paymentId: r.paymentId,
          orderId: r.orderId,
          signature: r.signature,
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      final message = r.message?.trim();
      _onFailure?.call(
        message == null || message.isEmpty
            ? 'Payment was not completed.'
            : message,
      );
    });
    return _razorpay = razorpay;
  }

  /// Creates the Razorpay order through the trusted server endpoint.
  /// Only product ids, quantities and customization choices are sent.
  Future<RazorpayCheckoutOrder> createOrder({
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) throw StateError('The cart is empty.');
    final idToken = await PaymentApi.idToken();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/create-order',
        data: {'items': items, 'currency': 'INR'},
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      final data = response.data;
      final orderId = data?['order_id'] as String?;
      final amount = (data?['amount'] as num?)?.round();
      final keyId = (data?['key_id'] as String?)?.trim();
      if (orderId == null || orderId.isEmpty || amount == null || keyId == null || keyId.isEmpty) {
        throw StateError('The payment server returned an incomplete order.');
      }
      return RazorpayCheckoutOrder(
        orderId: orderId,
        amountInPaise: amount,
        keyId: keyId,
      );
    } on DioException catch (error) {
      throw StateError(
        PaymentApi.errorMessage(
          error,
          fallback: 'Could not start checkout. Please try again.',
        ),
      );
    }
  }

  /// Opens Razorpay Standard Checkout for a server-created order.
  void openCheckout({
    required RazorpayCheckoutOrder order,
    required String description,
    required String name,
    required String phone,
    required String email,
  }) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final prefill = <String, String>{
      if (digitsOnly.length >= 10) 'contact': digitsOnly.substring(digitsOnly.length - 10),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (name.trim().isNotEmpty) 'name': name.trim(),
    };
    final options = <String, dynamic>{
      'key': order.keyId,
      'order_id': order.orderId,
      'amount': order.amountInPaise,
      'currency': 'INR',
      'name': 'MadeByHands',
      'description': description,
      if (prefill.isNotEmpty) 'prefill': prefill,
      'theme': {'color': '#6B7E43'},
    };

    if (kIsWeb) {
      openWebRazorpayCheckout(options).then(
        (response) => _onSuccess?.call(
          RazorpayPaymentResult(
            paymentId: response['razorpay_payment_id'] as String?,
            orderId: response['razorpay_order_id'] as String?,
            signature: response['razorpay_signature'] as String?,
          ),
        ),
        onError: (Object error) => _onFailure?.call(
          error.toString().replaceFirst(RegExp(r'^(Error|Exception):\s*'), ''),
        ),
      );
      return;
    }
    _nativeCheckout().open(options);
  }

  /// Turns a captured payment into orders. Idempotent on the server, so a
  /// network timeout is retried once with the same payment details.
  Future<List<String>> finalizePaidOrder({
    required RazorpayPaymentResult payment,
    required String buyerPhone,
    required Map<String, String> address,
  }) async {
    final paymentId = payment.paymentId;
    final orderId = payment.orderId;
    final signature = payment.signature;
    if (paymentId == null || orderId == null || signature == null) {
      throw const PaymentConfirmationException(
        'Payment confirmation details are missing. If money was debited, contact support.',
      );
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final idToken = await PaymentApi.idToken(forceRefresh: attempt > 0);
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/finalize-payment',
          data: {
            'razorpay_order_id': orderId,
            'razorpay_payment_id': paymentId,
            'razorpay_signature': signature,
            'buyerPhone': buyerPhone,
            'address': address,
          },
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        );
        final ids = response.data?['order_ids'];
        if (response.data?['success'] != true || ids is! List) {
          throw const PaymentConfirmationException(
            'Payment was received, but the order could not be confirmed yet.',
          );
        }
        return ids.map((id) => id.toString()).toList();
      } on DioException catch (error) {
        final body = error.response?.data;
        if (body is Map && body['refunded'] == true) {
          throw PaymentConfirmationException(
            PaymentApi.errorMessage(
              error,
              fallback: 'Your payment has been refunded.',
            ),
            refunded: true,
          );
        }
        if (attempt == 0 && PaymentApi.isNetworkFailure(error)) continue;
        throw PaymentConfirmationException(
          PaymentApi.errorMessage(
            error,
            fallback: 'Order confirmation failed. Retry confirmation or contact support.',
          ),
        );
      }
    }
    throw const PaymentConfirmationException(
      'Order confirmation could not be reached. Retry confirmation in a moment.',
    );
  }

  void dispose() {
    _onSuccess = null;
    _onFailure = null;
    _razorpay?.clear();
    _razorpay = null;
  }
}
