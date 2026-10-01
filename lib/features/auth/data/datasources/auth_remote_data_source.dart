import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:madebyhands/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel?> signInWithGoogle();
  Future<UserModel> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String role,
  });
  Future<UserModel?> getCurrentUserData();
  Future<UserModel> updateProfile({
    required String uid,
    required String name,
    required String phone,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> requestAccountDeletion(UserModel user);
  Future<void> deleteAccount(String uid);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      debugPrint("Starting Google Sign-In flow...");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In: User cancelled the flow.");
        return null;
      }

      debugPrint("Google Sign-In: Fetching authentication details...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception(
          'Both idToken and accessToken are null. Check your Google Cloud Console configuration.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("Firebase: Signing in with Google credentials...");
      final UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      // Admin emails list
      const adminEmails = [
        'adhirajjain364@gmail.com',
        'mayankjaisw8673@gmail.com',
        'suhanimahajan2810@gmail.com',
        'majumdarpayal50@gmail.com',
        'reshob.rc12345@gmail.com',
      ];
      final String userEmail = user.email ?? '';

      // Check if user exists in Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userDoc.exists && userData != null) {
        return UserModel.fromJson(userData);
      } else if (adminEmails.contains(userEmail)) {
        // Automatically create admin profile if it's a preset admin email
        return await signUpWithRole(
          uid: user.uid,
          email: userEmail,
          name: user.displayName ?? 'Admin',
          phone: '',
          role: 'admin',
        );
      } else {
        // Return partial user for role selection
        return UserModel(
          uid: user.uid,
          email: userEmail,
          name: user.displayName ?? '',
          role: '', // Triggers Role Selection UI
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'A Firebase authentication error occurred.');
    } catch (e, stackTrace) {
      debugPrint("Google Sign-In Detailed Error: $e");
      debugPrint("Stacktrace: $stackTrace");
      throw Exception('Google sign-in error: $e');
    }
  }

  @override
  Future<UserModel> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final reference = firestore.collection('users').doc(uid);
      final existing = await reference.get();
      if (existing.exists && existing.data() != null) {
        await reference.update({'name': name, 'email': email, 'phone': phone});
        return UserModel.fromJson({
          ...existing.data()!,
          'name': name,
          'email': email,
          'phone': phone,
        });
      }
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        isVerified: false,
      );
      await reference.set(userModel.toJson());
      return userModel;
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'A Firestore error occurred while creating user.',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred during role assignment.');
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userDoc.exists && userData != null) {
        return UserModel.fromJson(userData);
      }

      // If user is authenticated in Firebase but no profile in Firestore,
      // trigger role selection by returning a UserModel with empty role.
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: '',
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    final reference = firestore.collection('users').doc(uid);
    await reference.update({'name': name.trim(), 'phone': phone.trim()});
    if (firebaseAuth.currentUser?.uid == uid) {
      await firebaseAuth.currentUser?.updateDisplayName(name.trim());
    }
    final snapshot = await reference.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('User profile not found.');
    }
    return UserModel.fromJson(snapshot.data()!);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      firebaseAuth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> requestAccountDeletion(UserModel user) async {
    final ticket = firestore.collection('support_tickets').doc();
    final firstMessage = ticket.collection('messages').doc();
    final notificationRef = firestore.collection('notifications').doc();
    final userRef = firestore.collection('users').doc(user.uid);

    final batch = firestore.batch();

    // 1. Mark deletion requested on user document
    batch.update(userRef, {
      'isDeletionRequested': true,
      'deletionRequestedAt': FieldValue.serverTimestamp(),
    });

    // 2. Write support ticket
    batch.set(ticket, {
      'userId': user.uid,
      'userName': user.name,
      'userEmail': user.email,
      'userRole': user.role,
      'subject': 'Account deletion request',
      'category': 'Account',
      'status': 'Open',
      'lastMessage': 'Please permanently delete my MADEBYHANDS account.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(firstMessage, {
      'senderId': user.uid,
      'senderRole': user.role,
      'message': 'Please permanently delete my MADEBYHANDS account.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Write admin notification
    batch.set(notificationRef, {
      'type': 'admin',
      'category': 'deletion_request',
      'title': 'Account Deletion Request ⚠️',
      'message':
          '${user.name.isNotEmpty ? user.name : "A user"} (${user.email}) requested permanent account deletion.',
      'targetId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  @override
  Future<void> deleteAccount(String uid) async {
    final currentUser = firebaseAuth.currentUser;

    try {
      // 1. Fetch user role safely
      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      try {
        userDoc = await firestore.collection('users').doc(uid).get();
      } catch (_) {}

      final role = userDoc?.data()?['role'] as String? ?? '';

      // 2. Safely clean up Firestore subcollections & documents
      if (role == 'creator') {
        try {
          await firestore.collection('creator_profiles').doc(uid).delete();
        } catch (_) {}
        try {
          await firestore.collection('creator_bank_accounts').doc(uid).delete();
        } catch (_) {}
        try {
          final products = await firestore
              .collection('products')
              .where('creatorUid', isEqualTo: uid)
              .get();
          for (final doc in products.docs) {
            try {
              await doc.reference.delete();
            } catch (_) {}
          }
        } catch (_) {}
        try {
          final notifications = await firestore
              .collection('notifications')
              .where('creatorUid', isEqualTo: uid)
              .get();
          for (final doc in notifications.docs) {
            try {
              await doc.reference.delete();
            } catch (_) {}
          }
        } catch (_) {}

        try {
          final storage = FirebaseStorage.instance;
          final result = await storage.ref('creator_profiles/$uid').listAll();
          for (final item in result.items) {
            try {
              await item.delete();
            } catch (_) {}
          }
        } catch (_) {}
      } else if (role == 'buyer') {
        try {
          final favs = await firestore
              .collection('users')
              .doc(uid)
              .collection('favorites')
              .get();
          for (final doc in favs.docs) {
            try {
              await doc.reference.delete();
            } catch (_) {}
          }
        } catch (_) {}
        try {
          final addrs = await firestore
              .collection('users')
              .doc(uid)
              .collection('addresses')
              .get();
          for (final doc in addrs.docs) {
            try {
              await doc.reference.delete();
            } catch (_) {}
          }
        } catch (_) {}
      }

      // 3. Delete main user document
      try {
        await firestore.collection('users').doc(uid).delete();
      } catch (_) {}

      // 4. Delete Firebase Auth User
      if (currentUser != null && currentUser.uid == uid) {
        await currentUser.delete();
      }

      // 5. Sign out Google
      try {
        await googleSignIn.signOut();
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security reasons, please sign out and sign in again before deleting your account.',
        );
      }
      throw Exception(
        e.message ?? 'An error occurred while deleting your account.',
      );
    } catch (e) {
      if (firebaseAuth.currentUser == null) {
        return;
      }
      throw Exception('An error occurred while deleting your account: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error signing out.');
    }
  }
}
