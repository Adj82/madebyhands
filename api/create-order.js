const Razorpay = require('razorpay');
const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { priceCart } = require('../server/checkout');

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
      return res.status(503).json({ error: 'Razorpay API credentials are not configured on the payment server' });
    }

    const { items, currency = 'INR' } = req.body || {};
    if (currency !== 'INR') {
      return res.status(400).json({ error: 'Only INR payments are supported' });
    }

    // Initialize explicitly rather than depending on requireUser having done
    // it as a side effect.
    const admin = getFirebaseAdmin();
    let pricedItems;
    try {
      pricedItems = await priceCart(admin, items);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
    const groups = new Set(pricedItems.map((item) => item.creatorId));
    const settingsSnapshot = await admin.firestore().collection('settings').doc('platform_economics').get();
    const settings = settingsSnapshot.data() || {};
    const configuredFlatFee = Number(settings.flatFee);
    const flatFeePerCreator = Number.isFinite(configuredFlatFee) ? Math.max(0, Math.round(configuredFlatFee)) : 50;
    const buyerPlatformFee = flatFeePerCreator * groups.size;
    const subtotal = pricedItems.reduce((sum, item) => sum + item.subtotal, 0);
    const amountInPaise = (subtotal + buyerPlatformFee) * 100;
    if (!Number.isSafeInteger(amountInPaise) || amountInPaise < 100 || amountInPaise > 100000000) {
      return res.status(400).json({ error: 'Order total is outside the supported payment range' });
    }

    const instance = new Razorpay({
      key_id: key_id.trim(),
      key_secret: key_secret.trim(),
    });

    const options = {
      amount: Math.round(amountInPaise),
      currency: 'INR',
      receipt: `mbh_${Date.now()}_${user.uid.slice(0, 12)}`,
      notes: {
        buyer_id: user.uid,
        subtotal: String(subtotal),
        platform_fee: String(buyerPlatformFee),
      },
    };

    const order = await instance.orders.create(options);
    const configuredRate = Number(settings.percentFee);
    const platformFeeRate = Number.isFinite(configuredRate) ? Math.min(100, Math.max(0, configuredRate)) : 5;
    await admin.firestore().collection('paymentIntents').doc(order.id).create({
      buyerId: user.uid,
      subtotal,
      buyerPlatformFee,
      platformFeeRate,
      amount: order.amount,
      currency: order.currency,
      items: pricedItems.map((item) => ({
        productId: item.productId,
        name: item.name,
        creatorId: item.creatorId,
        creatorName: item.creatorName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        baseUnitPrice: item.baseUnitPrice,
        customizationPrice: item.customizationPrice,
        customizations: item.customizations,
      })),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    return res.status(200).json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      key_id: key_id.trim(),
      subtotal,
      platform_fee: buyerPlatformFee,
    });
  } catch (error) {
    console.error('Razorpay Create Order Error:', error.message || error);
    return res.status(500).json({
      error: 'Failed to create Razorpay order',
    });
  }
};
