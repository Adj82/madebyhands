const Razorpay = require('razorpay');
const { getFirebaseAdmin, requireUser } = require('../server/auth');
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
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  let capture;
  let admin;
  let user;
  let paymentId;
  try {
    user = await requireUser(req, res);
    if (!user) return;
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keyId || !keySecret) return res.status(503).json({ error: 'Payment service is not configured' });

    const body = req.body || {};
    const orderId = body.razorpay_order_id;
    paymentId = body.razorpay_payment_id;
    const signature = body.razorpay_signature;
    capture = await verifyCapturedPayment({ orderId, paymentId, signature, buyerId: user.uid, keyId, keySecret });
    admin = getFirebaseAdmin();
    const firestore = admin.firestore();
    const intentRef = firestore.collection('paymentIntents').doc(orderId);
    const receiptRef = firestore.collection('paymentReceipts').doc(paymentId);
    const [intentSnapshot, buyerSnapshot] = await Promise.all([
      intentRef.get(),
      firestore.collection('users').doc(user.uid).get(),
    ]);
    if (!intentSnapshot.exists || !buyerSnapshot.exists) {
      throw new Error('Payment order or buyer profile was not found');
    }
    const intent = intentSnapshot.data();
    if (intent.buyerId !== user.uid || intent.amount !== capture.order.amount ||
        intent.amount !== capture.payment.amount || intent.currency !== 'INR' ||
        capture.order.currency !== 'INR' || intent.status === 'refunded') {
      throw new Error('Captured payment does not match this checkout');
    }
    const address = body.address || {};
    const requiredAddressFields = ['recipientName', 'phone', 'addressLine', 'city', 'state', 'postalCode'];
    const cleanAddress = {};
    for (const field of requiredAddressFields) {
      const value = typeof address[field] === 'string' ? address[field].trim() : '';
      if (!value || value.length > 250) throw new Error('Delivery address is incomplete');
      cleanAddress[field] = value;
    }
    if (typeof body.buyerPhone !== 'string' || body.buyerPhone.trim().length < 10) {
      throw new Error('A valid buyer phone number is required');
    }

    const grouped = new Map();
    for (const item of intent.items || []) {
      const list = grouped.get(item.creatorId) || [];
      list.push(item);
      grouped.set(item.creatorId, list);
    }
    if (!grouped.size) throw new Error('Checkout has no order items');
    const orderRefs = [...grouped.keys()].map(() => firestore.collection('orders').doc());
    const buyer = buyerSnapshot.data();
    const transactionResult = await firestore.runTransaction(async (transaction) => {
      const existingReceipt = await transaction.get(receiptRef);
      if (existingReceipt.exists) return { orderIds: existingReceipt.data().orderIds, duplicate: true };
      const currentIntent = await transaction.get(intentRef);
      if (!currentIntent.exists || currentIntent.data().buyerId !== user.uid) {
        throw new Error('Payment intent is not available');
      }

      const productRefs = [...new Map((intent.items || []).map((item) => [
        item.productId,
        firestore.collection('products').doc(item.productId),
      ])).values()];
      const productSnapshots = [];
      for (const productRef of productRefs) productSnapshots.push(await transaction.get(productRef));
      const productsById = new Map(productSnapshots.map((snapshot) => [snapshot.id, snapshot]));
      const requiredStock = new Map();
      for (const item of intent.items) {
        requiredStock.set(item.productId, (requiredStock.get(item.productId) || 0) + item.quantity);
      }
      for (const [productId, quantity] of requiredStock) {
        const snapshot = productsById.get(productId);
        if (!snapshot?.exists) throw new Error('A paid product is no longer available');
        const stock = Math.floor(Number(snapshot.data().stock) || 0);
        if (stock < quantity) throw new Error('A product sold out while payment was processing');
      }

      for (const [productId, quantity] of requiredStock) {
        const snapshot = productsById.get(productId);
        transaction.update(snapshot.ref, { stock: Math.floor(Number(snapshot.data().stock) || 0) - quantity });
      }
      const orderIds = [];
      let orderIndex = 0;
      for (const [creatorId, items] of grouped) {
        const subtotal = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
        const flatFee = Math.round(intent.buyerPlatformFee / grouped.size);
        const commissionRate = subtotal > 999 ? Math.max(0, Math.min(100, Number(intent.platformFeeRate) || 5)) : 0;
        const commissionAmount = Math.round(subtotal * commissionRate / 100);
        const orderRef = orderRefs[orderIndex++];
        orderIds.push(orderRef.id);
        transaction.set(orderRef, {
          checkoutId: orderId,
          buyerId: user.uid,
          buyerName: buyer.name || user.name || 'Buyer',
          buyerPhone: body.buyerPhone.trim(),
          creatorId,
          creatorName: items[0].creatorName,
          items: items.map((item) => ({
            productId: item.productId,
            name: item.name,
            creatorId,
            creatorName: item.creatorName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            baseUnitPrice: item.baseUnitPrice,
            customizationPrice: item.customizationPrice,
            customizations: item.customizations,
          })),
          shippingAddress: cleanAddress,
          subtotal,
          flatFee,
          commissionRate,
          commissionAmount,
          platformFee: flatFee + commissionAmount,
          creatorNetAmount: subtotal - commissionAmount,
          status: 'Placed',
          paymentStatus: 'paid',
          paymentId,
          payoutStatus: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          isSample: false,
          stockReserved: true,
        });
      }
      transaction.update(intentRef, { status: 'paid', paymentId, orderIds, paidAt: admin.firestore.FieldValue.serverTimestamp() });
      transaction.create(receiptRef, {
        buyerId: user.uid,
        orderId,
        orderIds,
        amount: capture.payment.amount,
        currency: capture.payment.currency,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { orderIds, duplicate: false };
    });

    if (!transactionResult.duplicate) try {
      const batch = firestore.batch();
      let index = 0;
      for (const [creatorId, items] of grouped) {
        const itemCount = items.reduce((count, item) => count + item.quantity, 0);
        batch.set(firestore.collection('notifications').doc(), {
          creatorUid: creatorId,
          title: 'New Incoming Order',
          message: `You received a new order for ${itemCount} item(s) from ${buyer.name || 'a buyer'}.`,
          type: 'order',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          targetId: transactionResult.orderIds[index++],
        });
      }
      batch.set(firestore.collection('notifications').doc(), {
        userId: user.uid,
        userRole: 'buyer',
        title: 'Order confirmed',
        message: 'Your payment was confirmed and your order is with the creator.',
        type: 'order',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        targetId: transactionResult.orderIds[0],
      });
      await batch.commit();
    } catch (error) {
      console.error('Creator order notification failed:', error.message || error);
    }
    return res.status(200).json({ success: true, order_ids: transactionResult.orderIds });
  } catch (error) {
    if (paymentId && capture && admin && user) {
      const receipt = await admin.firestore().collection('paymentReceipts').doc(paymentId).get().catch(() => null);
      if (receipt?.exists) return res.status(200).json({ success: true, order_ids: receipt.data().orderIds });
      try {
        const razorpay = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
        await razorpay.payments.refund(paymentId, { amount: capture.payment.amount });
        return res.status(409).json({ success: false, refunded: true, error: 'Inventory changed during checkout. The payment has been refunded.' });
      } catch (refundError) {
        console.error('Payment finalization and refund failed:', refundError.message || refundError);
      }
    }
    console.error('Razorpay Finalize Payment Error:', error.message || error);
    return res.status(500).json({ error: 'Could not confirm the paid order. Contact support before retrying.' });
  }
};
