// Bridge between the Flutter web build and Razorpay Standard Checkout.
// Called from lib/core/services/razorpay_checkout_web.dart.
window.openMadeByHandsRazorpay = function (optionsJson) {
  return new Promise(function (resolve, reject) {
    if (typeof window.Razorpay !== 'function') {
      reject(new Error('Razorpay Checkout did not load. Reload the page and try again.'));
      return;
    }

    var options;
    try {
      options = JSON.parse(optionsJson);
    } catch (_) {
      reject(new Error('Payment options are invalid.'));
      return;
    }

    var settled = false;
    var lastFailure = null;

    options.handler = function (response) {
      if (settled) return;
      settled = true;
      resolve(JSON.stringify(response));
    };
    options.modal = {
      // The buyer can retry inside the modal after a failed attempt, so a
      // failure only ends checkout once the modal is closed.
      ondismiss: function () {
        if (settled) return;
        settled = true;
        reject(new Error(lastFailure || 'Payment checkout was closed.'));
      },
    };

    var checkout = new window.Razorpay(options);
    checkout.on('payment.failed', function (response) {
      lastFailure = (response && response.error && response.error.description) || 'Payment failed.';
    });
    checkout.open();
  });
};
