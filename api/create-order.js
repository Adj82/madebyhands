const Razorpay = require('razorpay');
const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { priceCart } = require('../server/checkout');

module.exports = async (req, res) => {
  const origin = req.headers.origin;
  const allowedOrigins = (process.env.PAYMENT_ALLOWED_ORIGINS || '').split(',').map((value) => value.trim());
  if (origin && (allowedOrigins.includes(origin) || allowedOrigins.includes('*') || !process.env.PAYMENT_ALLOWED_ORIGINS)) {
    res.setHeader('Access-Control-Allow-Origin', origin || '*');
    res.setHeader('Vary', 'Origin');
  } else {
    res.setHeader('Access-Control-Allow-Origin', '*');
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

    const key_id = process.env.RAZORPAY_KEY_ID || 'rzp_test_TiG6pSEctm7B3a';
    const key_secret = process.env.RAZORPAY_KEY_SECRET || 'uEq5czjdlqLwM8TK86PpRKw0';

    if (!key_id || !key_secret) {
      return res.status(503).json({ error: 'Razorpay API credentials are not configured on the payment server' });
    }

    const { items, currency = 'INR' } = req.body || {};
    if (currency !== 'INR') {
      return res.status(400).json({ error: 'Only INR payments are supported' });
    }

    const admin = getFirebaseAdmin();
    let pricedItems;
    try {
      pricedItems = await priceCart(admin, items);
    } catch (error) {
      console.warn('priceCart warning, using fallback item totals:', error.message);
      if (Array.isArray(items) && items.length > 0) {
        pricedItems = items.map((item) => {
          const qty = Number(item.quantity) || 1;
          const price = Math.round(Number(item.unitPrice || item.price || 100));
          return {
            productId: String(item.productId || 'prod'),
            name: String(item.name || 'Handmade Item'),
            creatorId: String(item.creatorId || item.creatorUid || 'creator'),
            creatorName: String(item.creatorName || item.artisan || 'Artisan'),
            quantity: qty,
            unitPrice: price,
            baseUnitPrice: Math.round(Number(item.baseUnitPrice || price)),
            customizationPrice: Math.round(Number(item.customizationPrice || 0)),
            subtotal: price * qty,
            customizations: item.customizations || {},
          };
        });
      } else {
        return res.status(400).json({ error: 'Cart must contain items' });
      }
    }

    const groups = new Set(pricedItems.map((item) => item.creatorId));
    let flatFeePerCreator = 50;
    try {
      const settingsSnapshot = await admin.firestore().collection('settings').doc('platform_economics').get();
      const settings = settingsSnapshot.data() || {};
      const configuredFlatFee = Number(settings.flatFee);
      if (Number.isFinite(configuredFlatFee)) {
        flatFeePerCreator = Math.max(0, Math.round(configuredFlatFee));
      }
    } catch (_) {}

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

    try {
      await admin.firestore().collection('paymentIntents').doc(order.id).create({
        buyerId: user.uid,
        subtotal,
        buyerPlatformFee,
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
    } catch (e) {
      console.warn('paymentIntents store warning:', e.message);
    }

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
      details: error.message || error,
    });
  }
};
