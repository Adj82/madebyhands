const Razorpay = require('razorpay');
const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { priceCart } = require('../server/checkout');
const { loadPlatformEconomics } = require('../server/fees');
const { applyCors, getRazorpayCredentials, readBody } = require('../server/http');

/**
 * POST /api/create-order
 * Body: { items: [{ productId, quantity, customizations }], currency: 'INR' }
 *
 * Prices the cart on the server, creates the Razorpay order and stores the
 * priced snapshot in paymentIntents/{razorpayOrderId}. The client never sends
 * prices.
 */
module.exports = async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const credentials = getRazorpayCredentials();
    if (!credentials) {
      return res.status(503).json({ error: 'Payments are not configured on the server yet. Please try again later.' });
    }

    const { items, currency = 'INR' } = readBody(req);
    if (currency !== 'INR') {
      return res.status(400).json({ error: 'Only INR payments are supported' });
    }

    const admin = getFirebaseAdmin();
    const firestore = admin.firestore();

    let pricedItems;
    try {
      // priceCart is the only source of prices. Its errors are buyer-readable.
      pricedItems = await priceCart(admin, items);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }

    const { flatFee, percentFee } = await loadPlatformEconomics(firestore);
    const creatorCount = new Set(pricedItems.map((item) => item.creatorId)).size;
    const buyerPlatformFee = flatFee * creatorCount;
    const subtotal = pricedItems.reduce((sum, item) => sum + item.subtotal, 0);
    const amountInPaise = (subtotal + buyerPlatformFee) * 100;

    if (!Number.isSafeInteger(amountInPaise) || amountInPaise < 100 || amountInPaise > 100000000) {
      return res.status(400).json({ error: 'Order total is outside the supported payment range' });
    }

    const razorpay = new Razorpay({ key_id: credentials.keyId, key_secret: credentials.keySecret });
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt: `mbh_${Date.now()}_${user.uid.slice(0, 12)}`,
      notes: {
        buyer_id: user.uid,
        subtotal: String(subtotal),
        platform_fee: String(buyerPlatformFee),
      },
    });

    try {
      await firestore.collection('paymentIntents').doc(order.id).create({
        buyerId: user.uid,
        subtotal,
        buyerPlatformFee,
        flatFeePerCreator: flatFee,
        platformFeeRate: percentFee,
        amount: order.amount,
        currency: order.currency,
        items: pricedItems.map((item) => ({
          productId: item.productId,
          name: item.name,
          category: item.category,
          image: item.image,
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
    } catch (error) {
      // finalize-payment settles against this snapshot. Without it a capture
      // would be refunded, so fail before checkout opens instead.
      console.error('paymentIntents write failed:', error.message || error);
      return res.status(500).json({ error: 'Could not start checkout. Please try again.' });
    }

    return res.status(200).json({
      order_id: order.id,
      amount: order.amount,
      currency: order.currency,
      key_id: credentials.keyId,
      subtotal,
      platform_fee: buyerPlatformFee,
    });
  } catch (error) {
    console.error('Razorpay Create Order Error:', error.message || error);
    return res.status(500).json({ error: 'Could not start checkout. Please try again.' });
  }
};
