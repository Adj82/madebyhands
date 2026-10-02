// Unit tests for the payment API helpers. Run with: npm test
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { test } = require('node:test');

const { priceCart } = require('../../server/checkout');
const { computeOrderFees, loadPlatformEconomics } = require('../../server/fees');
const { isValidCheckoutSignature } = require('../../server/razorpay');

function fakeAdmin(products, settings = {}) {
  const doc = (collection, id) => ({
    get: async () => {
      const data = collection === 'products' ? products[id] : settings[id];
      return { id, exists: data !== undefined, data: () => data };
    },
  });
  return {
    firestore: () => ({ collection: (name) => ({ doc: (id) => doc(name, id) }) }),
  };
}

const vase = {
  name: 'Blue Pottery Vase',
  price: 899,
  stock: 3,
  isActive: true,
  creatorUid: 'creator-1',
  creatorName: 'Jaipur Clay Studio',
  category: 'Pottery, Ceramics, Clay & Sculpture',
  isCustomizable: true,
  predefinedCustomizations: ['Name/Text'],
  customizations: [
    { name: 'Colour', options: ['Blue', 'Green'], additionalPrice: 100, isMultipleSelection: false },
    { name: 'Gift note', options: [], additionalPrice: 50 },
  ],
};

test('prices the cart from Firestore, never from the client', async () => {
  const items = await priceCart(fakeAdmin({ vase }), [
    { productId: 'vase', quantity: 2, unitPrice: 1, customizations: { Colour: ['Blue'] } },
  ]);
  assert.equal(items.length, 1);
  assert.equal(items[0].unitPrice, 999);
  assert.equal(items[0].subtotal, 1998);
  assert.equal(items[0].creatorId, 'creator-1');
});

test('accepts free-text and predefined customizations', async () => {
  const items = await priceCart(fakeAdmin({ vase }), [
    {
      productId: 'vase',
      quantity: 1,
      customizations: { 'Gift note': ['Happy birthday'], 'Name/Text': ['Asha'] },
    },
  ]);
  assert.equal(items[0].customizationPrice, 50);
  assert.deepEqual(items[0].customizations['Name/Text'], ['Asha']);
});

test('rejects unknown customization options', async () => {
  await assert.rejects(
    priceCart(fakeAdmin({ vase }), [{ productId: 'vase', quantity: 1, customizations: { Colour: ['Pink'] } }]),
    /no longer available/,
  );
});

test('rejects inactive, missing and out-of-stock products', async () => {
  await assert.rejects(priceCart(fakeAdmin({ vase: { ...vase, isActive: false } }), [{ productId: 'vase', quantity: 1 }]));
  await assert.rejects(priceCart(fakeAdmin({}), [{ productId: 'vase', quantity: 1 }]));
  await assert.rejects(priceCart(fakeAdmin({ vase }), [{ productId: 'vase', quantity: 4 }]), /Only 3/);
});

test('merges duplicate lines before checking stock', async () => {
  await assert.rejects(
    priceCart(fakeAdmin({ vase }), [
      { productId: 'vase', quantity: 2 },
      { productId: 'vase', quantity: 2 },
    ]),
    /Only 3/,
  );
});

test('fee math matches PlatformFeeCalculator', () => {
  assert.deepEqual(computeOrderFees({ subtotal: 900, flatFee: 50, percentFee: 5 }), {
    flatFee: 50, commissionRate: 0, commissionAmount: 0, platformFee: 50, creatorNetAmount: 900,
  });
  const above = computeOrderFees({ subtotal: 2000, flatFee: 50, percentFee: 5 });
  assert.equal(above.commissionAmount, 100);
  assert.equal(above.creatorNetAmount, 1900);
  assert.equal(computeOrderFees({ subtotal: 2000, flatFee: 50, percentFee: 0 }).commissionAmount, 0);
});

test('reads configured economics and honours a zero percent fee', async () => {
  const economics = await loadPlatformEconomics(
    fakeAdmin({}, { platform_economics: { flatFee: 74.5, percentFee: 0 } }).firestore(),
  );
  assert.deepEqual(economics, { flatFee: 75, percentFee: 0 });
});

test('verifies Razorpay checkout signatures in constant time', () => {
  const keySecret = 'secret';
  const signature = crypto.createHmac('sha256', keySecret).update('order_1|pay_1').digest('hex');
  assert.equal(isValidCheckoutSignature({ orderId: 'order_1', paymentId: 'pay_1', signature, keySecret }), true);
  assert.equal(isValidCheckoutSignature({ orderId: 'order_1', paymentId: 'pay_2', signature, keySecret }), false);
  assert.equal(isValidCheckoutSignature({ orderId: 'order_1', paymentId: 'pay_1', signature: 'zz', keySecret }), false);
});
