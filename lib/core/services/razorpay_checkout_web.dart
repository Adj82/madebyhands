import 'dart:convert';
import 'dart:js_interop';

@JS('window.openMadeByHandsRazorpay')
external JSPromise<JSString> _openMadeByHandsRazorpay(JSString optionsJson);

Future<Map<String, dynamic>> openWebRazorpayCheckout(
  Map<String, dynamic> options,
) async {
  final result = await _openMadeByHandsRazorpay(
    jsonEncode(options).toJS,
  ).toDart;
  final decoded = jsonDecode(result.toDart);
  if (decoded is! Map) {
    throw StateError('Razorpay returned an invalid payment response.');
  }
  return Map<String, dynamic>.from(decoded);
}
