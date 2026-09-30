const MAX_CART_LINES = 50;

/** Returns the first argument that is a non-empty, trimmed string, else ''. */
function firstNonEmptyString(...values) {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

async function priceCart(admin, rawItems) {
  if (!Array.isArray(rawItems) || rawItems.length === 0 || rawItems.length > MAX_CART_LINES) {
    throw new Error('Cart must contain between 1 and 50 products');
  }

  const merged = new Map();
  for (const raw of rawItems) {
    const productId = typeof raw?.productId === 'string' ? raw.productId.trim() : '';
    const quantity = raw?.quantity;
    if (!productId || !Number.isSafeInteger(quantity) || quantity < 1 || quantity > 99) {
      throw new Error('Cart contains an invalid product or quantity');
    }
    const selections = raw.customizations && typeof raw.customizations === 'object' && !Array.isArray(raw.customizations)
      ? raw.customizations
      : {};
    const entry = merged.get(productId) || { productId, quantity: 0, selections: {} };
    entry.quantity += quantity;
    if (entry.quantity > 99) throw new Error('Product quantity exceeds the allowed limit');
    for (const [name, values] of Object.entries(selections)) {
      if (!Array.isArray(values) || values.some((value) => typeof value !== 'string')) {
        throw new Error('Cart contains an invalid customization');
      }
      entry.selections[name] = [...new Set(values.map((value) => value.trim()).filter(Boolean))];
    }
    merged.set(productId, entry);
  }

  const products = [];
  for (const item of merged.values()) {
    const snapshot = await admin.firestore().collection('products').doc(item.productId).get();
    if (!snapshot.exists) throw new Error('A product in the cart is no longer available');
    const product = snapshot.data() || {};
    const stock = Number.isSafeInteger(product.stock) ? product.stock : Math.floor(Number(product.stock) || 0);
    const basePrice = Math.round(Number(product.price));
    // Either spelling may be present, and an empty string must fall through
    // rather than being accepted as a creator id.
    const creatorId = firstNonEmptyString(product.creatorUid, product.creatorId);
    // The buyer catalogue reads the display name from any of these fields, so
    // requiring only creatorName here would reject products buyers can see.
    const creatorName = firstNonEmptyString(product.creatorName, product.sellerName, product.artisan);
    if (product.isActive !== true || stock < item.quantity || !Number.isSafeInteger(basePrice) || basePrice < 1 ||
        !creatorId || !creatorName) {
      throw new Error('A product is unavailable or has incomplete seller details');
    }

    const customizationOptions = Array.isArray(product.customizations) ? product.customizations : [];
    let customizationPrice = 0;
    for (const [name, values] of Object.entries(item.selections)) {
      const option = customizationOptions.find((candidate) => candidate?.name === name);
      if (!option || !Array.isArray(option.options) || values.length === 0 ||
          values.some((value) => !option.options.includes(value)) ||
          (option.isMultipleSelection !== true && values.length > 1)) {
        throw new Error('A selected customization is no longer available');
      }
      customizationPrice += Math.round(Number(option.additionalPrice) || 0);
    }
    item.product = product;
    item.creatorId = creatorId;
    item.creatorName = creatorName;
    item.name = String(product.name || 'Handmade product');
    item.baseUnitPrice = basePrice;
    item.customizationPrice = customizationPrice;
    item.unitPrice = basePrice + customizationPrice;
    item.subtotal = item.unitPrice * item.quantity;
    item.customizations = item.selections;
    delete item.selections;
    products.push(item);
  }
  return products;
}

module.exports = { priceCart };
