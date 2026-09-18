import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:madebyhands/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel?> signInWithGoogle();
  Future<UserModel> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String role,
  });
  Future<UserModel?> getCurrentUserData();
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
        throw Exception('Both idToken and accessToken are null. Check your Google Cloud Console configuration.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("Firebase: Signing in with Google credentials...");
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      // Admin emails list
      const adminEmails = [
        'admin@madebyhands.com',
        'adj@madebyhands.com',
        'adhirajjain@madebyhands.com',
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
    required String role,
  }) async {
    try {
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: role,
        isVerified: false,
      );
      await firestore.collection('users').doc(uid).set(userModel.toJson());
      return userModel;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'A Firestore error occurred while creating user.');
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
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error signing out.');
    }
  }
}
