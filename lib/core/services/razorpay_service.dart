import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_checkout_stub.dart'
    if (dart.library.html) 'razorpay_checkout_web.dart';

class RazorpayService {
  Razorpay? _razorpay;
  late Function(String?, String?, String?) _onWebPaymentSuccess;
  late Function(String) _onWebPaymentFailure;
  RazorpayService({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions);

  final Dio _dio;
  static const String _apiBaseUrl = String.fromEnvironment(
    'PAYMENT_API_BASE_URL',
  );
  static final BaseOptions _defaultOptions = BaseOptions(
    baseUrl: _apiBaseUrl.isNotEmpty
        ? _apiBaseUrl
        : (kIsWeb ? Uri.base.origin : ''),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  );

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
    required Function(String?, String?, String?) onWebPaymentSuccess,
    required Function(String) onWebPaymentFailure,
  }) {
    _onWebPaymentSuccess = onWebPaymentSuccess;
    _onWebPaymentFailure = onWebPaymentFailure;
    if (kIsWeb) return;
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    } catch (e) {
      debugPrint("Razorpay Initialization Warning: $e");
    }
  }

  /// Create the Razorpay order through the trusted server endpoint.
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String idToken,
    String currency = 'INR',
  }) async {
    if (items.isEmpty) throw StateError('The cart is empty.');

    if (_dio.options.baseUrl.isEmpty) {
      throw StateError('Configure PAYMENT_API_BASE_URL for this platform.');
    }
    final response = await _dio.post(
      '/api/create-order',
      data: {'items': items, 'currency': currency},
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw StateError('Payment server did not create an order.');
    }
    return Map<String, dynamic>.from(response.data);
  }

  /// Step 2: Open Standard Razorpay Checkout Modal with generated order_id
  void openCheckout({
    required String orderId,
    required double amountInRupees,
    required String orderDescription,
    required String name,
    required String phone,
    required String email,
    String? keyId,
  }) {
    final activeKey = keyId?.trim() ?? '';
    if (activeKey.isEmpty) {
      throw StateError('Payment server did not return a public key.');
    }
    final amountInPaise = (amountInRupees * 100).round();
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = digitsOnly.length >= 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : (digitsOnly.isNotEmpty ? digitsOnly : '9876543210');

    final options = {
      'key': activeKey,
      'order_id': orderId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name.isNotEmpty ? name : 'MADEBYHANDS',
      'description': orderDescription,
      'prefill': {
        'contact': cleanPhone,
        'email': email.isNotEmpty ? email : 'buyer@madebyhands.com',
      },
      'theme': {'color': '#506638'},
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe'],
      },
    };

    try {
      if (kIsWeb) {
        openWebRazorpayCheckout(options)
            .then((response) {
              _onWebPaymentSuccess(
                response['razorpay_payment_id'] as String?,
                response['razorpay_order_id'] as String?,
                response['razorpay_signature'] as String?,
              );
            })
            .catchError((Object error) {
              _onWebPaymentFailure(error.toString());
            });
        return;
      }
      _razorpay ??= Razorpay();
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      rethrow;
    }
  }

  /// Step 3: Verify HMAC-SHA256 Payment Signature
  Future<bool> verifyPaymentSignature({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String idToken,
  }) async {
    if (razorpayOrderId.isEmpty ||
        razorpayPaymentId.isEmpty ||
        razorpaySignature.isEmpty) {
      return false;
    }

    if (_dio.options.baseUrl.isEmpty) return false;
    try {
      final response = await _dio.post(
        '/api/verify-payment',
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['success'] == true;
      }
    } catch (error) {
      debugPrint('Payment verification failed: $error');
      return false;
    }
    return false;
  }

  Future<List<String>> finalizePaidOrder({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String idToken,
    required String buyerPhone,
    required Map<String, String> address,
    required List<Map<String, dynamic>> items,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.post(
          '/api/finalize-payment',
          data: {
            'razorpay_order_id': razorpayOrderId,
            'razorpay_payment_id': razorpayPaymentId,
            'razorpay_signature': razorpaySignature,
            'buyerPhone': buyerPhone,
            'address': address,
            'items': items,
          },
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        );
        if (response.statusCode != 200 || response.data?['success'] != true) {
          throw StateError(
            'Payment was received, but order confirmation failed. Check your order history or contact support before retrying.',
          );
        }
        return List<String>.from(response.data['order_ids'] as List);
      } on DioException catch (error) {
        final responseData = error.response?.data;
        final message = responseData is Map
            ? responseData['error']?.toString()
            : null;
        if (responseData is Map && responseData['refunded'] == true) {
          throw StateError(
            message ??
                'Inventory changed during checkout; Razorpay has refunded the payment.',
          );
        }
        final canRetry =
            attempt == 0 &&
            (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.connectionError);
        if (!canRetry) {
          throw StateError(
            message ??
                'Order confirmation failed. Check your order history or contact support before retrying.',
          );
        }
      }
    }
    throw StateError(
      'Order confirmation could not be reached. Check your order history before retrying.',
    );
  }

  void dispose() {
    if (kIsWeb) return;
    try {
      _razorpay?.clear();
    } catch (e) {
      debugPrint("Razorpay Dispose Warning: $e");
    }
  }
}
