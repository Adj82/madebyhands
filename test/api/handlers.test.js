// Handler-level tests for finalize-payment and reject-order against an
// in-memory Firestore double. Run with: npm test
const assert = require('node:assert/strict');
const path = require('node:path');
const { test, beforeEach } = require('node:test');

// ------------------------------------------------------------ fake Firestore
const INCREMENT = Symbol('increment');
const SERVER_TIME = Symbol('serverTime');
let store;
let refunds;

function applyValue(previous, value) {
  if (value && value[INCREMENT] !== undefined) return (Number(previous) || 0) + value[INCREMENT];
  if (value === SERVER_TIME) return new Date();
  return value;
}

function docRef(collection, id) {
  const key = `${collection}/${id}`;
  return {
    id,
    key,
    async get() {
      const data = store.get(key);
      return { id, ref: docRef(collection, id), exists: data !== undefined, data: () => (data ? { ...data } : undefined) };
    },
    async set(data, options = {}) { writeDoc(key, data, options.merge === true); },
    async update(data) { writeDoc(key, data, true); },
    async create(data) {
      if (store.has(key)) throw new Error('already exists');
      writeDoc(key, data, false);
    },
  };
}

function writeDoc(key, data, merge) {
  const base = merge ? { ...(store.get(key) || {}) } : {};
  for (const [field, value] of Object.entries(data)) base[field] = applyValue(base[field], value);
  store.set(key, base);
}

let autoId = 0;
const firestore = {
  collection: (name) => ({ doc: (id) => docRef(name, id || `auto${++autoId}`) }),
  async runTransaction(fn) {
    const writes = [];
    const tx = {
      get: (ref) => ref.get(),
      set: (ref, data) => writes.push(() => writeDoc(ref.key, data, false)),
      update: (ref, data) => writes.push(() => writeDoc(ref.key, data, true)),
      create: (ref, data) => writes.push(() => {
        if (store.has(ref.key)) throw new Error('already exists');
        writeDoc(ref.key, data, false);
      }),
    };
    const result = await fn(tx);
    writes.forEach((write) => write());
    return result;
  },
  batch() {
    const writes = [];
    return {
      set: (ref, data) => writes.push(() => writeDoc(ref.key, data, false)),
      commit: async () => writes.forEach((write) => write()),
    };
  },
};
const fakeAdmin = {
  firestore: Object.assign(() => firestore, {
    FieldValue: {
      serverTimestamp: () => SERVER_TIME,
      increment: (n) => ({ [INCREMENT]: n }),
    },
  }),
};

// ------------------------------------------------------- module stubbing
function stub(modulePath, exports) {
  const resolved = require.resolve(path.join(__dirname, '../../', modulePath));
  require.cache[resolved] = { id: resolved, filename: resolved, loaded: true, exports };
}

let currentUser;
stub('server/auth.js', {
  getFirebaseAdmin: () => fakeAdmin,
  requireUser: async () => currentUser,
});
const realRazorpay = require('../../server/razorpay');
stub('server/razorpay.js', {
  ...realRazorpay,
  verifyCapturedPayment: async ({ orderId, paymentId }) => ({
    order: { id: orderId, amount: store.get(`paymentIntents/${orderId}`)?.amount, currency: 'INR' },
    payment: { id: paymentId, amount: store.get(`paymentIntents/${orderId}`)?.amount, currency: 'INR', status: 'captured' },
  }),
  refundPayment: async (args) => { refunds.push(args); return { id: `rfnd_${refunds.length}` }; },
});

const finalizePayment = require('../../api/finalize-payment');
const rejectOrder = require('../../api/reject-order');

function call(handler, body) {
  return new Promise((resolve) => {
    const res = {
      statusCode: 200,
      headers: {},
      setHeader(name, value) { this.headers[name] = value; },
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      end() { resolve({ status: this.statusCode }); return this; },
    };
    handler({ method: 'POST', headers: {}, body }, res);
  });
}

beforeEach(() => {
  store = new Map();
  refunds = [];
  autoId = 0;
  currentUser = { uid: 'buyer-1', email: 'buyer@example.com' };
  process.env.RAZORPAY_KEY_ID = 'rzp_test_key';
  process.env.RAZORPAY_KEY_SECRET = 'secret';
  store.set('users/buyer-1', { name: 'Asha', role: 'buyer' });
  store.set('users/creator-1', { name: 'Clay Studio', role: 'creator' });
  store.set('products/vase', { name: 'Vase', stock: 3, price: 1200, isActive: true });
  store.set('paymentIntents/order_1', {
    buyerId: 'buyer-1',
    subtotal: 2400,
    buyerPlatformFee: 50,
    flatFeePerCreator: 50,
    platformFeeRate: 5,
    amount: 245000,
    currency: 'INR',
    status: 'pending',
    items: [{
      productId: 'vase', name: 'Vase', creatorId: 'creator-1', creatorName: 'Clay Studio',
      quantity: 2, unitPrice: 1200, baseUnitPrice: 1200, customizationPrice: 0, customizations: {},
    }],
  });
});

const address = {
  recipientName: 'Asha', phone: '9876543210', addressLine: '1 Lane', city: 'Jaipur', state: 'RJ', postalCode: '302001',
};
const finalizeBody = {
  razorpay_order_id: 'order_1', razorpay_payment_id: 'pay_1', razorpay_signature: 'x', address, buyerPhone: '9876543210',
};

test('finalize writes one paid order, decrements stock and is idempotent', async () => {
  const first = await call(finalizePayment, finalizeBody);
  assert.equal(first.status, 200);
  assert.equal(first.body.order_ids.length, 1);
  const order = store.get(`orders/${first.body.order_ids[0]}`);
  assert.equal(order.paymentStatus, 'paid');
  assert.equal(order.subtotal, 2400);
  assert.equal(order.commissionAmount, 120);
  assert.equal(order.creatorNetAmount, 2280);
  assert.equal(order.buyerPayableAmount, 2450);
  assert.equal(store.get('products/vase').stock, 1);
  assert.equal(store.get('products/vase').orderCount, 2);

  const retry = await call(finalizePayment, finalizeBody);
  assert.equal(retry.status, 200);
  assert.deepEqual(retry.body.order_ids, first.body.order_ids);
  assert.equal(store.get('products/vase').stock, 1);
  assert.equal(refunds.length, 0);
});

test('finalize refunds when stock ran out after payment', async () => {
  store.set('products/vase', { name: 'Vase', stock: 1, price: 1200, isActive: true });
  const result = await call(finalizePayment, finalizeBody);
  assert.equal(result.status, 409);
  assert.equal(result.body.refunded, true);
  assert.match(result.body.error, /sold out/);
  assert.equal(refunds.length, 1);
  assert.equal(store.get('paymentIntents/order_1').status, 'refunded');
});

test('creator rejection restores stock and refunds the buyer share', async () => {
  const placed = await call(finalizePayment, finalizeBody);
  const orderId = placed.body.order_ids[0];

  currentUser = { uid: 'someone-else' };
  const forbidden = await call(rejectOrder, { orderId, reason: 'Out of clay' });
  assert.equal(forbidden.status, 403);

  currentUser = { uid: 'creator-1' };
  const rejected = await call(rejectOrder, { orderId, reason: 'Out of clay' });
  assert.equal(rejected.status, 200);
  assert.equal(rejected.body.refunded, true);
  const order = store.get(`orders/${orderId}`);
  assert.equal(order.status, 'Rejected');
  assert.equal(order.payoutStatus, 'cancelled');
  assert.equal(order.refundStatus, 'refunded');
  assert.equal(refunds[0].amount, 245000);
  assert.equal(store.get('products/vase').stock, 3);

  const again = await call(rejectOrder, { orderId });
  assert.equal(again.status, 200);
  assert.equal(refunds.length, 1);
});

test('orders cannot be rejected after dispatch', async () => {
  const placed = await call(finalizePayment, finalizeBody);
  const orderId = placed.body.order_ids[0];
  store.set(`orders/${orderId}`, { ...store.get(`orders/${orderId}`), status: 'In-Transit' });
  currentUser = { uid: 'creator-1' };
  const result = await call(rejectOrder, { orderId });
  assert.equal(result.status, 409);
});
