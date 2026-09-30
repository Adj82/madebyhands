# Flutter release builds run R8 shrinking. The Razorpay SDK is reached
# reflectively and through a WebView JavascriptInterface, so R8 must not
# rename or strip it or Checkout fails to open in a release APK/AAB.
# Source: https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Keep anything exposed to the Razorpay WebView bridge.
-keepclasseswithmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}
