window.openMadeByHandsRazorpay = function (optionsJson) {
  return new Promise(function (resolve, reject) {
    if (typeof window.Razorpay !== 'function') {
      reject(new Error('Razorpay Checkout did not load. Reload the page and try again.'));
      return;
    }

    let options;
    try {
      options = JSON.parse(optionsJson);
    } catch (_) {
      reject(new Error('Payment options are invalid.'));
      return;
    }

    options.handler = function (response) {
      resolve(JSON.stringify(response));
    };
    options.modal = {
      ondismiss: function () {
        reject(new Error('Payment checkout was closed.'));
      },
    };

    const checkout = new window.Razorpay(options);
    checkout.on('payment.failed', function (response) {
      reject(new Error(response?.error?.description || 'Payment failed.'));
    });
    checkout.open();
  });
};
