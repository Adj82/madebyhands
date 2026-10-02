const MAX_CART_LINES = 50;
const MAX_QUANTITY = 99;
const MAX_FREE_TEXT_LENGTH = 200;

/** Returns the first argument that is a non-empty, trimmed string, else ''. */
function firstNonEmptyString(...values) {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

/** Validates the raw cart and merges duplicate product lines. */
function normalizeCartLines(rawItems) {
  if (!Array.isArray(rawItems) || rawItems.length === 0 || rawItems.length > MAX_CART_LINES) {
    throw new Error(`Cart must contain between 1 and ${MAX_CART_LINES} products`);
  }

  const merged = new Map();
  for (const raw of rawItems) {
    const productId = typeof raw?.productId === 'string' ? raw.productId.trim() : '';
    const quantity = raw?.quantity;
    if (!productId || productId.includes('/') || !Number.isSafeInteger(quantity) ||
        quantity < 1 || quantity > MAX_QUANTITY) {
      throw new Error('Cart contains an invalid product or quantity');
    }
    const selections = raw.customizations && typeof raw.customizations === 'object' && !Array.isArray(raw.customizations)
      ? raw.customizations
      : {};
    const entry = merged.get(productId) || { productId, quantity: 0, selections: {} };
    entry.quantity += quantity;
    if (entry.quantity > MAX_QUANTITY) throw new Error('Product quantity exceeds the allowed limit');
    for (const [name, values] of Object.entries(selections)) {
      if (!Array.isArray(values) || values.some((value) => typeof value !== 'string')) {
        throw new Error('Cart contains an invalid customization');
      }
      const cleaned = [...new Set(values.map((value) => value.trim()).filter(Boolean))];
      if (cleaned.length) entry.selections[name] = cleaned;
    }
    merged.set(productId, entry);
  }
  return [...merged.values()];
}

/**
 * Prices the buyer's customization choices against the options the creator
 * defined on the product. The client never supplies prices, so anything that
 * does not match the product document is rejected.
 *
 * Three shapes are supported, mirroring the product details screen:
 * - a creator customization with a fixed option list (chips),
 * - a creator customization without options (free text, priced once),
 * - a predefined free-text field such as "Name/Text" (no extra charge).
 */
function priceCustomizations(product, selections) {
  const names = Object.keys(selections);
  if (!names.length) return 0;
  if (product.isCustomizable !== true) {
    throw new Error('A selected customization is no longer available');
  }

  const options = Array.isArray(product.customizations) ? product.customizations : [];
  const predefined = Array.isArray(product.predefinedCustomizations)
    ? product.predefinedCustomizations.filter((value) => typeof value === 'string')
    : [];

  let total = 0;
  for (const name of names) {
    const values = selections[name];
    const option = options.find((candidate) => candidate?.name === name);
    if (option) {
      const choices = Array.isArray(option.options)
        ? option.options.filter((value) => typeof value === 'string' && value.trim())
        : [];
      if (choices.length) {
        if (values.some((value) => !choices.includes(value)) ||
            (option.isMultipleSelection !== true && values.length > 1)) {
          throw new Error('A selected customization is no longer available');
        }
      } else if (values.length !== 1 || values[0].length > MAX_FREE_TEXT_LENGTH) {
        throw new Error('A customization note is too long');
      }
      total += Math.max(0, Math.round(Number(option.additionalPrice) || 0));
      continue;
    }
    if (predefined.includes(name)) {
      if (values.length !== 1 || values[0].length > MAX_FREE_TEXT_LENGTH) {
        throw new Error('A customization note is too long');
      }
      continue;
    }
    throw new Error('A selected customization is no longer available');
  }
  return total;
}

/**
 * Re-reads every product in the cart and returns server-side priced lines.
 * Throws a buyer-readable Error when anything is unavailable.
 */
async function priceCart(admin, rawItems) {
  const lines = normalizeCartLines(rawItems);
  const firestore = admin.firestore();
  const snapshots = await Promise.all(
    lines.map((line) => firestore.collection('products').doc(line.productId).get()),
  );

  return lines.map((item, index) => {
    const snapshot = snapshots[index];
    if (!snapshot.exists) throw new Error('A product in the cart is no longer available');
    const product = snapshot.data() || {};
    const stock = Number.isSafeInteger(product.stock) ? product.stock : Math.floor(Number(product.stock) || 0);
    const basePrice = Math.round(Number(product.price));
    // Either spelling may be present, and an empty string must fall through
    // rather than being accepted as a creator id.
    const creatorId = firstNonEmptyString(product.creatorUid, product.creatorId);
    const creatorName = firstNonEmptyString(product.creatorName, product.sellerName, product.artisan);
    const productName = String(product.name || 'Handmade product');
    if (product.isActive !== true || !Number.isSafeInteger(basePrice) || basePrice < 1 ||
        !creatorId || !creatorName) {
      throw new Error(`"${productName}" is no longer available`);
    }
    if (stock < item.quantity) {
      throw new Error(stock > 0
        ? `Only ${stock} unit(s) of "${productName}" are available`
        : `"${productName}" is out of stock`);
    }

    const customizationPrice = priceCustomizations(product, item.selections);
    const unitPrice = basePrice + customizationPrice;
    return {
      productId: item.productId,
      name: productName,
      category: typeof product.category === 'string' ? product.category : '',
      image: Array.isArray(product.images) && typeof product.images[0] === 'string' ? product.images[0] : '',
      creatorId,
      creatorName,
      quantity: item.quantity,
      baseUnitPrice: basePrice,
      customizationPrice,
      unitPrice,
      subtotal: unitPrice * item.quantity,
      customizations: item.selections,
    };
  });
}

module.exports = { priceCart, priceCustomizations, normalizeCartLines };
