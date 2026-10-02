const crypto = require('crypto');
const https = require('https');

const RAZORPAY_ID_PATTERN = /^[A-Za-z0-9_]{5,64}$/;

function razorpayRequest(method, path, { keyId, keySecret, body } = {}) {
  return new Promise((resolve, reject) => {
    const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
    const payload = body ? JSON.stringify(body) : null;
    const request = https.request({
      hostname: 'api.razorpay.com',
      path,
      method,
      headers: {
        Authorization: `Basic ${auth}`,
        ...(payload ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}),
      },
    }, (response) => {
      let data = '';
      response.setEncoding('utf8');
      response.on('data', (chunk) => {
        data += chunk;
        if (data.length > 1024 * 1024) response.destroy(new Error('Payment response too large'));
      });
      response.on('end', () => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return reject(new Error(`Razorpay ${method} ${path.split('?')[0]} failed with HTTP ${response.statusCode}`));
        }
        try { resolve(JSON.parse(data)); } catch (_) { reject(new Error('Invalid Razorpay response')); }
      });
    });
    request.setTimeout(10000, () => request.destroy(new Error('Razorpay request timed out')));
    request.on('error', reject);
    if (payload) request.write(payload);
    request.end();
  });
}

/** Constant-time check of the checkout signature Razorpay returned to the client. */
function isValidCheckoutSignature({ orderId, paymentId, signature, keySecret }) {
  if (typeof signature !== 'string' || !/^[a-f0-9]{64}$/i.test(signature)) return false;
  const expected = crypto.createHmac('sha256', keySecret).update(`${orderId}|${paymentId}`).digest();
  const supplied = Buffer.from(signature, 'hex');
  return supplied.length === expected.length && crypto.timingSafeEqual(expected, supplied);
}

/**
 * Verifies the signature, then confirms with Razorpay's API that the payment
 * belongs to this buyer's order, matches its amount and is captured. A payment
 * that is only authorized (manual-capture accounts) is captured here.
 */
async function verifyCapturedPayment({ orderId, paymentId, signature, buyerId, keyId, keySecret }) {
  if (![orderId, paymentId].every((value) => typeof value === 'string' && RAZORPAY_ID_PATTERN.test(value))) {
    throw new Error('Invalid payment verification details');
  }
  if (!isValidCheckoutSignature({ orderId, paymentId, signature, keySecret })) {
    throw new Error('Payment signature is invalid');
  }
  const credentials = { keyId, keySecret };
  const [order, fetchedPayment] = await Promise.all([
    razorpayRequest('GET', `/v1/orders/${encodeURIComponent(orderId)}`, credentials),
    razorpayRequest('GET', `/v1/payments/${encodeURIComponent(paymentId)}`, credentials),
  ]);
  if (order.id !== orderId || order.notes?.buyer_id !== buyerId || order.currency !== 'INR' ||
      fetchedPayment.order_id !== orderId || fetchedPayment.currency !== 'INR' ||
      fetchedPayment.amount !== order.amount) {
    throw new Error('Payment does not belong to this buyer and order');
  }

  let payment = fetchedPayment;
  if (payment.status === 'authorized') {
    payment = await razorpayRequest('POST', `/v1/payments/${encodeURIComponent(paymentId)}/capture`, {
      ...credentials,
      body: { amount: order.amount, currency: 'INR' },
    });
  }
  if (payment.status !== 'captured') {
    throw new Error('Payment is not captured');
  }
  return { order, payment };
}

/** Full refund of a captured payment. */
function refundPayment({ paymentId, amount, keyId, keySecret, notes }) {
  return razorpayRequest('POST', `/v1/payments/${encodeURIComponent(paymentId)}/refund`, {
    keyId,
    keySecret,
    body: { amount, notes: notes || {} },
  });
}

module.exports = { verifyCapturedPayment, refundPayment, isValidCheckoutSignature, RAZORPAY_ID_PATTERN };
