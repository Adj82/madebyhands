const admin = require('firebase-admin');

function getFirebaseAdmin() {
  if (admin.apps.length) return admin;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) throw new Error('Firebase service account is not configured');
  const serviceAccount = JSON.parse(serviceAccountJson);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  return admin;
}

async function requireUser(req, res) {
  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Authentication required' });
    return null;
  }
  try {
    const decoded = await getFirebaseAdmin().auth().verifyIdToken(match[1]);
    return decoded;
  } catch (_) {
    res.status(401).json({ error: 'Authentication failed' });
    return null;
  }
}

module.exports = { getFirebaseAdmin, requireUser };
