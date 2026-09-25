import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  Razorpay? _razorpay;

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    } catch (e) {
      debugPrint("Razorpay Initialization Warning: $e");
    }
  }

  void openCheckout({
    required String keyId,
    required double amountInRupees,
    required String orderDescription,
    required String name,
    required String phone,
    required String email,
  }) {
    final amountInPaise = (amountInRupees * 100).round();
    // Sanitize phone number so it only contains clean 10 digits
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = digitsOnly.length >= 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : (digitsOnly.isNotEmpty ? digitsOnly : '9876543210');

    final options = {
      'key': keyId.trim(),
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name.isNotEmpty ? name : 'MADEBYHANDS',
      'description': orderDescription,
      'prefill': {
        'contact': cleanPhone,
        'email': email.isNotEmpty ? email : 'buyer@madebyhands.com',
      },
      'theme': {
        'color': '#506638'
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe']
      }
    };

    try {
      if (_razorpay == null) {
        _razorpay = Razorpay();
      }
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      rethrow;
    }
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (e) {
      debugPrint("Razorpay Dispose Warning: $e");
    }
  }
}
