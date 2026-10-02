const admin = require('firebase-admin');

/**
 * Normalizes the service account's private key.
 *
 * Pasting the JSON into a hosting dashboard often leaves the PEM newlines
 * double-escaped, which JSON.parse turns into a literal backslash-n rather
 * than a line break. admin.credential.cert() then rejects the key.
 */
function normalizePrivateKey(serviceAccount) {
  const key = serviceAccount.private_key;
  if (typeof key === 'string' && !key.includes('\n') && key.includes('\\n')) {
    return { ...serviceAccount, private_key: key.replace(/\\n/g, '\n') };
  }
  return serviceAccount;
}

/**
 * Returns an initialized Firebase Admin app, or throws.
 *
 * This must never fall back to an unauthenticated app: requireUser relies on
 * it to verify ID tokens, and every caller writes orders and payment records
 * through the Admin SDK, which bypasses firestore.rules.
 */
function getFirebaseAdmin() {
  if (admin.apps.length) return admin;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set on the payment server');
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (error) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON (check for a truncated or re-wrapped paste)');
  }

  try {
    admin.initializeApp({ credential: admin.credential.cert(normalizePrivateKey(serviceAccount)) });
  } catch (error) {
    throw new Error(`Firebase service account was rejected: ${error.message}`);
  }

  return admin;
}

/**
 * Resolves the authenticated caller, or responds and returns null.
 *
 * The returned uid decides whose cart is priced and whose orders are written,
 * so it may only ever come from a verified ID token.
 */
async function requireUser(req, res) {
  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Authentication required' });
    return null;
  }

  let firebaseAdmin;
  try {
    firebaseAdmin = getFirebaseAdmin();
  } catch (error) {
    console.error('Firebase Admin configuration error:', error.message || error);
    res.status(503).json({ error: 'Firebase authentication is not configured on the payment server' });
    return null;
  }

  try {
    return await firebaseAdmin.auth().verifyIdToken(match[1]);
  } catch (error) {
    console.error('Firebase ID token verification failed:', error.message || error);
    res.status(401).json({
      error: 'Your session could not be verified. Sign out, sign in again and retry.',
    });
    return null;
  }
}

module.exports = { getFirebaseAdmin, requireUser };
