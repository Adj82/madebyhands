const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { computeOrderFees, DEFAULT_PERCENT_FEE } = require('../server/fees');
const { applyCors, getRazorpayCredentials, readBody } = require('../server/http');
const { verifyCapturedPayment, refundPayment } = require('../server/razorpay');

const REQUIRED_ADDRESS_FIELDS = ['recipientName', 'phone', 'addressLine', 'city', 'state', 'postalCode'];

/** Errors whose message is safe and useful to show the buyer. */
class CheckoutError extends Error {}

function cleanAddress(address) {
  const source = address && typeof address === 'object' ? address : {};
  const cleaned = {};
  for (const field of REQUIRED_ADDRESS_FIELDS) {
    const value = typeof source[field] === 'string' ? source[field].trim() : '';
    if (!value || value.length > 250) throw new CheckoutError('Delivery address is incomplete');
    cleaned[field] = value;
  }
  return cleaned;
}

/**
 * POST /api/finalize-payment
 * Body: { razorpay_order_id, razorpay_payment_id, razorpay_signature, address, buyerPhone }
 *
 * Verifies the capture with Razorpay, then in one transaction decrements
 * stock, writes one order per creator, marks the intent paid and creates
 * paymentReceipts/{paymentId}, which is the idempotency key. Any failure after
 * the capture is verified refunds the payment and answers 409 + refunded.
 */
module.exports = async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  let capture;
  let admin;
  let paymentId;
  let orderId;
  let credentials;
  try {
    const user = await requireUser(req, res);
    if (!user) return;
    credentials = getRazorpayCredentials();
    if (!credentials) return res.status(503).json({ error: 'Payment service is not configured' });

    const body = readBody(req);
    orderId = body.razorpay_order_id;
    paymentId = body.razorpay_payment_id;
    capture = await verifyCapturedPayment({
      orderId,
      paymentId,
      signature: body.razorpay_signature,
      buyerId: user.uid,
      keyId: credentials.keyId,
      keySecret: credentials.keySecret,
    });

    admin = getFirebaseAdmin();
    const firestore = admin.firestore();
    const { FieldValue } = admin.firestore;
    const intentRef = firestore.collection('paymentIntents').doc(orderId);
    const receiptRef = firestore.collection('paymentReceipts').doc(paymentId);

    // A retry of an already-finalized payment returns the original orders.
    const existingReceipt = await receiptRef.get();
    if (existingReceipt.exists && existingReceipt.data().buyerId === user.uid) {
      return res.status(200).json({ success: true, order_ids: existingReceipt.data().orderIds || [] });
    }

    const [intentSnapshot, buyerSnapshot] = await Promise.all([
      intentRef.get(),
      firestore.collection('users').doc(user.uid).get(),
    ]);
    if (!intentSnapshot.exists) throw new Error('Payment intent was not found');
    const intent = intentSnapshot.data();
    if (intent.buyerId !== user.uid || intent.amount !== capture.order.amount ||
        intent.amount !== capture.payment.amount || intent.currency !== 'INR' ||
        intent.status === 'refunded') {
      throw new Error('Captured payment does not match this checkout');
    }

    const shippingAddress = cleanAddress(body.address);
    const buyerPhone = typeof body.buyerPhone === 'string' ? body.buyerPhone.trim() : '';
    if (buyerPhone.replace(/\D/g, '').length < 10) {
      throw new CheckoutError('A valid buyer phone number is required');
    }

    const intentItems = Array.isArray(intent.items) ? intent.items : [];
    const grouped = new Map();
    for (const item of intentItems) {
      const list = grouped.get(item.creatorId) || [];
      list.push(item);
      grouped.set(item.creatorId, list);
    }
    if (!grouped.size) throw new Error('Checkout has no order items');

    const flatFeePerCreator = Number.isFinite(Number(intent.flatFeePerCreator))
      ? Number(intent.flatFeePerCreator)
      : Math.round(Number(intent.buyerPlatformFee || 0) / grouped.size);
    const percentFee = Number.isFinite(Number(intent.platformFeeRate))
      ? Number(intent.platformFeeRate)
      : DEFAULT_PERCENT_FEE;
    const commissionThreshold = Number.isFinite(Number(intent.commissionThreshold))
      ? Number(intent.commissionThreshold)
      : undefined;
    const buyer = buyerSnapshot.exists ? buyerSnapshot.data() : {};
    const buyerName = buyer.name || user.name || 'Buyer';
    const orderRefs = [...grouped.keys()].map(() => firestore.collection('orders').doc());

    const result = await firestore.runTransaction(async (transaction) => {
      const receipt = await transaction.get(receiptRef);
      if (receipt.exists) return { orderIds: receipt.data().orderIds || [], duplicate: true };
      const currentIntent = await transaction.get(intentRef);
      if (!currentIntent.exists || currentIntent.data().buyerId !== user.uid) {
        throw new Error('Payment intent is not available');
      }
      if (currentIntent.data().status === 'paid') {
        return { orderIds: currentIntent.data().orderIds || [], duplicate: true };
      }

      const requiredStock = new Map();
      for (const item of intentItems) {
        requiredStock.set(item.productId, (requiredStock.get(item.productId) || 0) + item.quantity);
      }
      const productEntries = [];
      for (const [productId, quantity] of requiredStock) {
        const snapshot = await transaction.get(firestore.collection('products').doc(productId));
        productEntries.push({ snapshot, quantity });
      }
      for (const { snapshot, quantity } of productEntries) {
        if (!snapshot.exists) throw new CheckoutError('A product you paid for is no longer available');
        const stock = Math.floor(Number(snapshot.data().stock) || 0);
        if (stock < quantity) {
          throw new CheckoutError(`"${snapshot.data().name || 'A product'}" sold out while your payment was processing`);
        }
      }
      for (const { snapshot, quantity } of productEntries) {
        transaction.update(snapshot.ref, {
          stock: Math.floor(Number(snapshot.data().stock) || 0) - quantity,
          orderCount: FieldValue.increment(quantity),
        });
      }

      const orderIds = [];
      let orderIndex = 0;
      for (const [creatorId, items] of grouped) {
        const subtotal = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
        const fees = computeOrderFees({ subtotal, flatFee: flatFeePerCreator, percentFee, commissionThreshold });
        const orderRef = orderRefs[orderIndex++];
        orderIds.push(orderRef.id);
        transaction.set(orderRef, {
          checkoutId: orderId,
          buyerId: user.uid,
          buyerName,
          buyerEmail: user.email || buyer.email || '',
          buyerPhone,
          creatorId,
          creatorName: items[0].creatorName,
          items: items.map((item) => ({
            productId: item.productId,
            name: item.name,
            category: item.category || '',
            image: item.image || '',
            creatorId,
            creatorName: item.creatorName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            baseUnitPrice: item.baseUnitPrice,
            customizationPrice: item.customizationPrice,
            customizations: item.customizations || {},
          })),
          shippingAddress,
          subtotal,
          flatFee: fees.flatFee,
          commissionRate: fees.commissionRate,
          commissionAmount: fees.commissionAmount,
          platformFee: fees.platformFee,
          creatorNetAmount: fees.creatorNetAmount,
          buyerPayableAmount: subtotal + fees.flatFee,
          status: 'Placed',
          paymentStatus: 'paid',
          paymentId,
          payoutStatus: 'pending',
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          isSample: false,
          stockReserved: true,
        });
      }
      transaction.update(intentRef, { status: 'paid', paymentId, orderIds, paidAt: FieldValue.serverTimestamp() });
      transaction.create(receiptRef, {
        buyerId: user.uid,
        orderId,
        orderIds,
        amount: capture.payment.amount,
        currency: capture.payment.currency,
        createdAt: FieldValue.serverTimestamp(),
      });
      return { orderIds, duplicate: false };
    });

    if (!result.duplicate) {
      try {
        const batch = firestore.batch();
        let index = 0;
        for (const [creatorId, items] of grouped) {
          const itemCount = items.reduce((count, item) => count + item.quantity, 0);
          batch.set(firestore.collection('notifications').doc(), {
            creatorUid: creatorId,
            title: 'New order received',
            message: `${buyerName} ordered ${itemCount} item(s). Confirm the order to start fulfilment.`,
            type: 'order',
            createdAt: FieldValue.serverTimestamp(),
            isRead: false,
            targetId: result.orderIds[index++],
          });
        }
        await batch.commit();
      } catch (error) {
        console.error('Creator order notification failed:', error.message || error);
      }
    }
    return res.status(200).json({ success: true, order_ids: result.orderIds });
  } catch (error) {
    console.error('Razorpay Finalize Payment Error:', error.message || error);
    if (!capture || !paymentId || !credentials) {
      return res.status(400).json({ error: 'Payment could not be verified. If money was debited, contact support with your payment ID.' });
    }
    try {
      if (admin) {
        const receipt = await admin.firestore().collection('paymentReceipts').doc(paymentId).get();
        if (receipt.exists) {
          return res.status(200).json({ success: true, order_ids: receipt.data().orderIds || [] });
        }
      }
      await refundPayment({
        paymentId,
        amount: capture.payment.amount,
        keyId: credentials.keyId,
        keySecret: credentials.keySecret,
        notes: { reason: 'checkout_failed' },
      });
      if (admin) {
        await admin.firestore().collection('paymentIntents').doc(orderId).set({
          status: 'refunded',
          paymentId,
          refundReason: String(error.message || 'checkout_failed').slice(0, 300),
          refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true }).catch((intentError) => {
          console.error('Could not mark intent refunded:', intentError.message || intentError);
        });
      }
      const reason = error instanceof CheckoutError ? `${error.message}. ` : '';
      return res.status(409).json({
        success: false,
        refunded: true,
        error: `${reason}Your payment has been refunded to the original payment method.`,
      });
    } catch (refundError) {
      console.error('Payment finalization and refund failed:', refundError.message || refundError);
      return res.status(500).json({ error: `Your payment (${paymentId}) was received but the order could not be confirmed. Please contact support.` });
    }
  }
};
