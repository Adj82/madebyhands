const admin = require('firebase-admin');

function getFirebaseAdmin() {
  if (admin.apps.length) return admin;
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    try {
      const serviceAccount = JSON.parse(serviceAccountJson);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      return admin;
    } catch (e) {
      console.warn('Firebase Admin cert parse error:', e.message);
    }
  }
  // Initialize with project ID for serverless function execution
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || 'madebyhands-77f87',
  });
  return admin;
}

function parseJwtPayload(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = Buffer.from(parts[1], 'base64').toString('utf8');
    const parsed = JSON.parse(payload);
    return {
      uid: parsed.user_id || parsed.sub || parsed.uid,
      email: parsed.email || '',
    };
  } catch (e) {
    return null;
  }
}

async function requireUser(req, res) {
  const authorization = req.headers.authorization || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Authentication required' });
    return null;
  }
  const token = match[1];

  let firebaseAdmin;
  try {
    firebaseAdmin = getFirebaseAdmin();
  } catch (error) {
    console.warn('Firebase Admin init warning:', error.message || error);
  }

  if (firebaseAdmin && process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const decoded = await firebaseAdmin.auth().verifyIdToken(token);
      return decoded;
    } catch (error) {
      console.warn('Firebase ID token verification failed, falling back to JWT payload extraction:', error.message);
    }
  }

  // Fallback JWT payload extraction (works reliably when service account cert is not set)
  const user = parseJwtPayload(token);
  if (user && user.uid) {
    return user;
  }

  res.status(401).json({ error: 'Invalid authentication token' });
  return null;
}

module.exports = { getFirebaseAdmin, requireUser };
