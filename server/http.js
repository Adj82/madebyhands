/**
 * Shared request helpers for the serverless payment API.
 */

/**
 * Applies the CORS policy driven by PAYMENT_ALLOWED_ORIGINS.
 *
 * Only origins listed in the comma-separated env var are echoed back. Native
 * apps send no Origin header and are unaffected. Returns true when the request
 * was a preflight that has already been answered.
 */
function applyCors(req, res) {
  const origin = req.headers.origin;
  const allowedOrigins = (process.env.PAYMENT_ALLOWED_ORIGINS || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true;
  }
  return false;
}

/** Razorpay credentials from the environment only, trimmed. */
function getRazorpayCredentials() {
  const keyId = (process.env.RAZORPAY_KEY_ID || '').trim();
  const keySecret = (process.env.RAZORPAY_KEY_SECRET || '').trim();
  if (!keyId || !keySecret) return null;
  return { keyId, keySecret };
}

/** Parses a JSON body even when the platform did not do it for us. */
function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string' && req.body.trim()) {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

module.exports = { applyCors, getRazorpayCredentials, readBody };
