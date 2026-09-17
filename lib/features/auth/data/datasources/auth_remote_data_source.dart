import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      // Admin emails list - add your admin emails here
      const adminEmails = [
        'admin@madebyhands.com',
        'adj@madebyhands.com',
      ];
      final String userEmail = user.email ?? '';

      // Check if user exists in Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!);
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
    } catch (e) {
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
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!);
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
