import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/auth/data/models/user_model.dart';

abstract interface class AdminRemoteDataSource {
  Future<List<UserModel>> getUsers(String role);
  Future<void> updateUserRole(String uid, String role);
  Future<void> toggleUserStatus(String uid, bool isActive);
  Future<Map<String, dynamic>> getPlatformSettings();
  Future<void> updatePlatformSettings(double flatFee, double percentFee);
  Future<List<Map<String, dynamic>>> getSupportTickets();
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
}
