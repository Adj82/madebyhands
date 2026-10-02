const { getFirebaseAdmin, requireUser } = require('../server/auth');
const { applyCors, readBody } = require('../server/http');

const SUPER_ADMIN_EMAILS = [
  'adhirajjain364@gmail.com',
  'mayankjaisw8673@gmail.com',
  'suhanimahajan2810@gmail.com',
  'majumdarpayal50@gmail.com',
  'reshob.rc12345@gmail.com',
];
const ADMIN_ROLES = ['admin', 'manager', 'super_admin'];

/**
 * POST /api/suspend-user
 * Body: { uid, suspend: boolean }
 *
 * Suspending a user must actually stop them from using the platform, not
 * just hide the UI behind a blocking screen. This disables their Firebase
 * Auth account (so sign-in fails immediately with auth/user-disabled) and
 * revokes any already-issued ID tokens (so an app session open at the time
 * of suspension cannot keep calling this API or Firestore either), then
 * records the state on their profile for the UI to read.
 *
 * This is deliberately a different code path from account deletion
 * (auth_remote_data_source.dart's deleteAccount): suspension disables the
 * existing account and keeps its data so it can be reinstated, while
 * deletion permanently removes the Auth user and Firestore data outright.
 */
module.exports = async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  try {
    const caller = await requireUser(req, res);
    if (!caller) return;

    const body = readBody(req);
    const targetUid = typeof body.uid === 'string' ? body.uid.trim() : '';
    const suspend = body.suspend === true;
    if (!targetUid) return res.status(400).json({ error: 'uid is required' });

    const admin = getFirebaseAdmin();
    const firestore = admin.firestore();
    const { FieldValue } = admin.firestore;

    const [callerSnapshot, targetSnapshot] = await Promise.all([
      firestore.collection('users').doc(caller.uid).get(),
      firestore.collection('users').doc(targetUid).get(),
    ]);

    const callerRole = String(callerSnapshot.exists ? callerSnapshot.data().role || '' : '').toLowerCase();
    const isAdmin = ADMIN_ROLES.includes(callerRole) ||
      (caller.email_verified === true && SUPER_ADMIN_EMAILS.includes(String(caller.email || '').toLowerCase()));
    if (!isAdmin) return res.status(403).json({ error: 'Only admins can suspend or reinstate users' });

    if (!targetSnapshot.exists) return res.status(404).json({ error: 'User not found' });
    if (targetUid === caller.uid) return res.status(400).json({ error: 'You cannot suspend your own account' });

    const targetRole = String(targetSnapshot.data().role || '').toLowerCase();
    const targetEmail = String(targetSnapshot.data().email || '').toLowerCase();
    const targetIsAdmin = ADMIN_ROLES.includes(targetRole) || SUPER_ADMIN_EMAILS.includes(targetEmail);
    if (suspend && targetIsAdmin) {
      return res.status(400).json({ error: 'Admins and managers cannot be suspended here' });
    }

    await admin.auth().updateUser(targetUid, { disabled: suspend });
    if (suspend) {
      // Invalidate any ID token already in the suspended user's hands so an
      // open app session is cut off immediately, not just future sign-ins.
      await admin.auth().revokeRefreshTokens(targetUid);
    }

    await firestore.collection('users').doc(targetUid).update({
      isSuspended: suspend,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Suspend user error:', error.message || error);
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({ error: 'User not found' });
    }
    return res.status(500).json({ error: 'Could not update this user. Please try again.' });
  }
};
