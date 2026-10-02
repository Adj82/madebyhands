/**
 * Platform economics shared by the payment endpoints.
 *
 * Mirrors PlatformFeeCalculator in
 * lib/features/orders/domain/entities/marketplace_order.dart — change both
 * together. All amounts are integer rupees.
 */

const DEFAULT_FLAT_FEE = 50;
const DEFAULT_PERCENT_FEE = 5;
const COMMISSION_THRESHOLD = 999;

/** Reads settings/platform_economics, falling back to the defaults. */
async function loadPlatformEconomics(firestore) {
  let flatFee = DEFAULT_FLAT_FEE;
  let percentFee = DEFAULT_PERCENT_FEE;
  try {
    const snapshot = await firestore.collection('settings').doc('platform_economics').get();
    const settings = snapshot.data() || {};
    const configuredFlat = Number(settings.flatFee);
    if (settings.flatFee !== undefined && settings.flatFee !== null && Number.isFinite(configuredFlat)) {
      flatFee = Math.max(0, Math.round(configuredFlat));
    }
    const configuredRate = Number(settings.percentFee);
    if (settings.percentFee !== undefined && settings.percentFee !== null && Number.isFinite(configuredRate)) {
      percentFee = Math.min(100, Math.max(0, configuredRate));
    }
  } catch (error) {
    console.warn('Platform economics lookup failed, using defaults:', error.message || error);
  }
  return { flatFee, percentFee };
}

/**
 * The buyer pays subtotal + flatFee. The percentage commission applies only
 * above the threshold and is deducted from the creator's subtotal.
 */
function computeOrderFees({ subtotal, flatFee, percentFee }) {
  const normalizedFlat = Math.max(0, Math.round(Number(flatFee) || 0));
  const rate = Number.isFinite(Number(percentFee)) ? Math.min(100, Math.max(0, Number(percentFee))) : DEFAULT_PERCENT_FEE;
  const commissionRate = subtotal > COMMISSION_THRESHOLD ? rate : 0;
  const commissionAmount = Math.round((subtotal * commissionRate) / 100);
  return {
    flatFee: normalizedFlat,
    commissionRate,
    commissionAmount,
    platformFee: normalizedFlat + commissionAmount,
    creatorNetAmount: subtotal - commissionAmount,
  };
}

module.exports = {
  DEFAULT_FLAT_FEE,
  DEFAULT_PERCENT_FEE,
  COMMISSION_THRESHOLD,
  loadPlatformEconomics,
  computeOrderFees,
};
