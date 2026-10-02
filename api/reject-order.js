const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { applyCors, getRazorpayCredentials, readBody } = require('../server/http');
const { refundPayment } = require('../server/razorpay');

const SUPER_ADMIN_EMAILS = [
  'adhirajjain364@gmail.com',
  'mayankjaisw8673@gmail.com',
  'suhanimahajan2810@gmail.com',
  'majumdarpayal50@gmail.com',
  'reshob.rc12345@gmail.com',
];
const ADMIN_ROLES = ['admin', 'manager', 'super_admin'];
const REJECTABLE_STATUSES = ['placed', 'confirmed', 'processing'];

/** Mirrors OrderStatus.normalize() in lib/features/orders/domain/order_status.dart. */
function normalizeStatus(value) {
  const normalized = String(value || '').trim().toLowerCase().replace(/-/g, '_').replace(/\s+/g, '_');
  if (normalized === 'pending') return 'placed';
  if (normalized === 'accepted') return 'confirmed';
  if (normalized === 'completed') return 'delivered';
  if (normalized === 'intransit') return 'in_transit';
  return normalized;
}

/**
 * POST /api/reject-order
 * Body: { orderId, reason }
 *
 * Lets the order's creator (or an admin) reject an order before dispatch. The
 * order is marked Rejected, reserved stock is returned and, for paid orders,
 * the buyer's share of the payment (subtotal + flat fee) is refunded through
 * Razorpay. Calling it again on a rejected order retries a failed refund.
 */
module.exports = async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  try {
    const user = await requireUser(req, res);
    if (!user) return;

    const body = readBody(req);
    const orderId = typeof body.orderId === 'string' ? body.orderId.trim() : '';
    const reason = typeof body.reason === 'string' && body.reason.trim()
      ? body.reason.trim().slice(0, 500)
      : 'Order rejected by creator';
    if (!orderId || orderId.includes('/')) return res.status(400).json({ error: 'Order id is required' });

    const admin = getFirebaseAdmin();
    const firestore = admin.firestore();
    const { FieldValue } = admin.firestore;
    const orderRef = firestore.collection('orders').doc(orderId);

    const [orderSnapshot, userSnapshot] = await Promise.all([
      orderRef.get(),
      firestore.collection('users').doc(user.uid).get(),
    ]);
    if (!orderSnapshot.exists) return res.status(404).json({ error: 'Order not found' });
    const role = String(userSnapshot.exists ? userSnapshot.data().role || '' : '').toLowerCase();
    const isAdmin = ADMIN_ROLES.includes(role) ||
      (user.email_verified === true && SUPER_ADMIN_EMAILS.includes(String(user.email || '').toLowerCase()));
    if (orderSnapshot.data().creatorId !== user.uid && !isAdmin) {
      return res.status(403).json({ error: 'You can only reject your own orders' });
    }

    const outcome = await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(orderRef);
      const order = snapshot.data();
      const status = normalizeStatus(order.status);
      if (status === 'rejected' || status === 'cancelled') {
        return { order, alreadyRejected: true };
      }
      if (!REJECTABLE_STATUSES.includes(status)) {
        const error = new Error('Orders can only be rejected before they are dispatched');
        error.statusCode = 409;
        throw error;
      }

      const items = Array.isArray(order.items) ? order.items : [];
      const restock = new Map();
      if (order.stockReserved === true) {
        for (const item of items) {
          if (typeof item?.productId !== 'string' || !item.productId) continue;
          const quantity = Math.max(0, Math.floor(Number(item.quantity) || 0));
          restock.set(item.productId, (restock.get(item.productId) || 0) + quantity);
        }
      }
      const productSnapshots = [];
      for (const productId of restock.keys()) {
        productSnapshots.push(await transaction.get(firestore.collection('products').doc(productId)));
      }
      for (const productSnapshot of productSnapshots) {
        if (!productSnapshot.exists) continue;
        const quantity = restock.get(productSnapshot.id);
        transaction.update(productSnapshot.ref, {
          stock: FieldValue.increment(quantity),
          orderCount: FieldValue.increment(-quantity),
        });
      }

      const isPaid = order.paymentStatus === 'paid' && typeof order.paymentId === 'string' && order.paymentId;
      transaction.update(orderRef, {
        status: 'Rejected',
        rejectionReason: reason,
        payoutStatus: 'cancelled',
        stockReserved: false,
        ...(isPaid ? { refundStatus: 'processing' } : {}),
        rejectedBy: user.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { order: { ...order, refundStatus: isPaid ? 'processing' : order.refundStatus }, alreadyRejected: false };
    });

    const order = outcome.order;
    const needsRefund = order.paymentStatus === 'paid' && order.paymentId && order.refundStatus !== 'refunded';
    if (!needsRefund) return res.status(200).json({ success: true, refunded: false });

    const credentials = getRazorpayCredentials();
    const refundAmount = Math.round(Number(order.buyerPayableAmount ?? (Number(order.subtotal || 0) + Number(order.flatFee || 0)))) * 100;
    try {
      if (!credentials) throw new Error('Razorpay credentials are not configured');
      if (!Number.isSafeInteger(refundAmount) || refundAmount < 100) throw new Error('Refund amount is invalid');
      const refund = await refundPayment({
        paymentId: order.paymentId,
        amount: refundAmount,
        keyId: credentials.keyId,
        keySecret: credentials.keySecret,
        notes: { order_id: orderId, reason: 'order_rejected' },
      });
      await orderRef.update({
        refundStatus: 'refunded',
        refundId: refund.id || '',
        refundedAmount: refundAmount / 100,
        refundedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return res.status(200).json({ success: true, refunded: true });
    } catch (refundError) {
      console.error('Order rejection refund failed:', refundError.message || refundError);
      await orderRef.update({ refundStatus: 'failed', updatedAt: FieldValue.serverTimestamp() }).catch(() => {});
      return res.status(502).json({
        success: false,
        rejected: true,
        error: 'The order was rejected but the buyer refund could not be processed. An admin can retry it from the Orders panel.',
      });
    }
  } catch (error) {
    console.error('Reject order error:', error.message || error);
    if (error.statusCode === 409) return res.status(409).json({ error: error.message });
    return res.status(500).json({ error: 'Could not reject the order. Please try again.' });
  }
};
