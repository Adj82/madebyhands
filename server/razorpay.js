const crypto = require('crypto');
const https = require('https');

function getResource(path, keyId, keySecret) {
  return new Promise((resolve, reject) => {
    const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
    const request = https.request({
      hostname: 'api.razorpay.com',
      path,
      method: 'GET',
      headers: { Authorization: `Basic ${auth}` },
    }, (response) => {
      let body = '';
      response.setEncoding('utf8');
      response.on('data', (chunk) => {
        body += chunk;
        if (body.length > 1024 * 1024) response.destroy(new Error('Payment response too large'));
      });
      response.on('end', () => {
        if (response.statusCode !== 200) return reject(new Error('Razorpay resource lookup failed'));
        try { resolve(JSON.parse(body)); } catch (_) { reject(new Error('Invalid Razorpay response')); }
      });
    });
    request.setTimeout(10000, () => request.destroy(new Error('Razorpay lookup timed out')));
    request.on('error', reject);
    request.end();
  });
}

async function verifyCapturedPayment({ orderId, paymentId, signature, buyerId, keyId, keySecret }) {
  if (![orderId, paymentId].every((value) => typeof value === 'string' && /^\w{5,64}$/.test(value)) ||
      typeof signature !== 'string' || !/^[a-f0-9]{64}$/i.test(signature)) {
    throw new Error('Invalid payment verification details');
  }
  const expected = crypto.createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest();
  const supplied = Buffer.from(signature, 'hex');
  if (supplied.length !== expected.length || !crypto.timingSafeEqual(expected, supplied)) {
    throw new Error('Payment signature is invalid');
  }
  const [order, payment] = await Promise.all([
    getResource(`/v1/orders/${encodeURIComponent(orderId)}`, keyId, keySecret),
    getResource(`/v1/payments/${encodeURIComponent(paymentId)}`, keyId, keySecret),
  ]);
  if (order.id !== orderId || order.notes?.buyer_id !== buyerId ||
      payment.order_id !== orderId || payment.status !== 'captured' ||
      payment.amount !== order.amount || payment.currency !== 'INR' || order.currency !== 'INR') {
    throw new Error('Payment is not captured for this buyer and order');
  }
  return { order, payment };
}

module.exports = { verifyCapturedPayment };
