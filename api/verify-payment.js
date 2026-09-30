const { requireUser } = require('../server/auth');
const { verifyCapturedPayment } = require('../server/razorpay');

module.exports = async (req, res) => {
  const origin = req.headers.origin;
  const allowedOrigins = (process.env.PAYMENT_ALLOWED_ORIGINS || '').split(',').map((value) => value.trim());
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const key_id = process.env.RAZORPAY_KEY_ID;
    const key_secret = process.env.RAZORPAY_KEY_SECRET;

    if (!key_id || !key_secret) {
      return res.status(401).json({ error: 'Razorpay secret key not configured' });
    }

    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body || {};

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        error: 'Missing required fields: razorpay_order_id, razorpay_payment_id, and razorpay_signature are required.',
      });
    }

    const result = await verifyCapturedPayment({
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
      signature: razorpay_signature,
      buyerId: user.uid,
      keyId: key_id.trim(),
      keySecret: key_secret.trim(),
    });
    return res.status(200).json({
      success: true,
      order_id: result.order.id,
      payment_id: result.payment.id,
      amount: result.payment.amount,
    });
  } catch (error) {
    console.error('Razorpay Verify Payment Error:', error.message || error);
    return res.status(500).json({
      error: 'Failed to verify payment signature',
    });
  }
};
