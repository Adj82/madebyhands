import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/auth/data/models/user_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';

abstract interface class AdminRemoteDataSource {
  Future<List<UserModel>> getUsers(String role);
  Future<void> updateUserRole(String uid, String role);
  Future<void> toggleUserStatus(String uid, bool isActive);
  Future<Map<String, dynamic>> getPlatformSettings();
  Future<void> updatePlatformSettings(double flatFee, double percentFee);
  Future<List<Map<String, dynamic>>> getSupportTickets();
  Future<List<CreatorProfileModel>> getPendingVerifications();
  Future<void> approveCreator(String uid);
  Future<void> rejectCreator(String uid);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore firestore;

  AdminRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<UserModel>> getUsers(String role) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await firestore.collection('users').doc(uid).update({'isActive': isActive});
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getPlatformSettings() async {
    try {
      final doc = await firestore.collection('settings').doc('platform_economics').get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {'flatFee': 50.0, 'percentFee': 5.0};
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updatePlatformSettings(double flatFee, double percentFee) async {
    try {
      await firestore.collection('settings').doc('platform_economics').set({
        'flatFee': flatFee,
        'percentFee': percentFee,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    try {
      final snapshot = await firestore.collection('support_tickets').get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<CreatorProfileModel>> getPendingVerifications() async {
    try {
      final snapshot = await firestore.collection('creator_profiles').get();
      return snapshot.docs
          .map((doc) => CreatorProfileModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> approveCreator(String uid) async {
    try {
      final batch = firestore.batch();
      batch.update(firestore.collection('creator_profiles').doc(uid), {'verificationStatus': 'Verified'});
      batch.update(firestore.collection('users').doc(uid), {'isVerified': true});
      
      // Also activate products
      final products = await firestore.collection('products').where('creatorUid', isEqualTo: uid).get();
      for (var doc in products.docs) {
        batch.update(doc.reference, {'isActive': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> rejectCreator(String uid) async {
    try {
      await firestore.collection('creator_profiles').doc(uid).update({'verificationStatus': 'Rejected'});
      await firestore.collection('users').doc(uid).update({'isVerified': false});
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
