import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/features/creator/data/models/creator_bank_account_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_notification_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_order_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

/// Private verification documents, stored in `creator_verifications/{uid}`.
class VerificationDocumentsModel {
  final String businessName;
  final String address;
  final String latestPhoto;
  final String idCard;

  const VerificationDocumentsModel({
    required this.businessName,
    required this.address,
    required this.latestPhoto,
    required this.idCard,
  });
}

abstract interface class CreatorRemoteDataSource {
  Future<CreatorProfileModel?> getCreatorProfile(String uid);

  /// Creates or updates the public, creator-editable profile fields.
  Future<void> saveCreatorProfile(CreatorProfileModel profile);

  Future<String> uploadProfileImage({required File image, required String uid});

  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  });

  Future<String> uploadVerificationFile({
    required File file,
    required String uid,
    required String fileName,
  });

  Future<VerificationDocumentsModel?> getVerificationDocuments(String uid);

  /// Stores the documents privately, marks the profile 'In-Process' and
  /// alerts the admins.
  Future<void> submitVerification({
    required String uid,
    required String creatorName,
    required VerificationDocumentsModel documents,
  });

  Future<List<CreatorProfileModel>> getAllCreatorProfiles();

  Future<void> updateVerificationStatus(String uid, String status);

  Future<void> addProduct(CreatorProductModel product);
  Future<void> updateProduct(CreatorProductModel product);
  Future<void> deleteProduct(String productId);
  Future<void> setProductPublished(String productId, bool published);
  Future<void> updateStock(String productId, int stock);
  Future<CreatorProductModel?> getProduct(String productId);

  Future<List<CreatorProductModel>> getPendingProducts();
  Future<List<CreatorProductModel>> getAdminAllProducts();
  Future<List<CreatorProductModel>> getCreatorProducts(String uid);

  Future<void> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
    String? rejectionReason,
  });

  Future<List<String>> uploadProductImages({
    required List<File> images,
    required String uid,
    required String folder,
  });

  Future<List<String>> uploadCustomizationImages({
    required List<File> images,
    required String uid,
    required String productName,
    required String customizationName,
  });

  Stream<List<CreatorProductModel>> watchCreatorProducts(String uid);
  Stream<List<CreatorOrderModel>> watchCreatorOrders(String uid);

  Future<List<CreatorOrderModel>> getCreatorOrders(String creatorUid);

  /// Moves an order forward in fulfilment. Rejections go through the API.
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
    String? carrierName,
  });

  Stream<List<CreatorNotificationModel>> watchNotifications(String uid);
  Future<List<CreatorNotificationModel>> getCreatorNotifications(
    String creatorUid,
  );
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String uid);
  Future<void> deleteNotifications(List<String> notificationIds);

  Future<CreatorBankAccountModel?> getCreatorBankAccount(String uid);
  Future<void> saveCreatorBankAccount(CreatorBankAccountModel bankDetail);
}

class CreatorRemoteDataSourceImpl implements CreatorRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  static final _imageMetadata = SettableMetadata(contentType: 'image/jpeg');

  CreatorRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

  CollectionReference<Map<String, dynamic>> get _profiles =>
      firestore.collection('creator_profiles');
  CollectionReference<Map<String, dynamic>> get _products =>
      firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      firestore.collection('notifications');

  /// Uploads [file] to [path] and returns its download URL. Works on web
  /// (where `File` wraps a blob URL) and on mobile.
  Future<String> _upload(File file, String path) async {
    final bytes = kIsWeb
        ? await XFile(file.path).readAsBytes()
        : await file.readAsBytes();
    final snapshot = await firebaseStorage
        .ref()
        .child(path)
        .putData(bytes, _imageMetadata);
    return snapshot.ref.getDownloadURL();
  }

  /// Storage path segment derived from user input.
  static String _segment(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) return 'item';
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  @override
  Future<CreatorProfileModel?> getCreatorProfile(String uid) async {
    final doc = await _profiles.doc(uid).get();
    final data = doc.data();
    return data == null ? null : CreatorProfileModel.fromJson(data, doc.id);
  }

  @override
  Future<void> saveCreatorProfile(CreatorProfileModel profile) async {
    final ref = _profiles.doc(profile.uid);
    final exists = (await ref.get()).exists;
    await ref.set({
      ...profile.toJson(),
      if (!exists) 'verificationStatus': 'Unverified',
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String> uploadProfileImage({
    required File image,
    required String uid,
  }) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(image, 'creator_profiles/$uid/profile_$stamp.jpg');
  }

  @override
  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return [
      for (var i = 0; i < images.length; i++)
        await _upload(
          images[i],
          'creator_profiles/$uid/portfolio/image_${stamp}_$i.jpg',
        ),
    ];
  }

  @override
  Future<String> uploadVerificationFile({
    required File file,
    required String uid,
    required String fileName,
  }) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(
      file,
      'creator_profiles/$uid/verification/${stamp}_$fileName',
    );
  }

  @override
  Future<VerificationDocumentsModel?> getVerificationDocuments(
    String uid,
  ) async {
    final doc =
        await firestore.collection('creator_verifications').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return VerificationDocumentsModel(
      businessName: data['businessName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latestPhoto: data['latestPhoto'] as String? ?? '',
      idCard: data['idCard'] as String? ?? '',
    );
  }

  @override
  Future<void> submitVerification({
    required String uid,
    required String creatorName,
    required VerificationDocumentsModel documents,
  }) async {
    final batch = firestore.batch();
    batch.set(firestore.collection('creator_verifications').doc(uid), {
      'uid': uid,
      'businessName': documents.businessName,
      'address': documents.address,
      'latestPhoto': documents.latestPhoto,
      'idCard': documents.idCard,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_profiles.doc(uid), {
      'verificationStatus': 'In-Process',
      'businessName': documents.businessName,
      'verificationNote': FieldValue.delete(),
      'address': FieldValue.delete(),
      'latestPhoto': FieldValue.delete(),
      'idCard': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_notifications.doc(), {
      'type': 'admin',
      'category': 'creator_verification',
      'title': 'New creator verification request',
      'message':
          '${creatorName.isEmpty ? 'A creator' : creatorName} submitted verification documents.',
      'targetId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    await batch.commit();
  }

  @override
  Future<List<CreatorProfileModel>> getAllCreatorProfiles() async {
    final snapshot = await _profiles.get();
    return snapshot.docs
        .map((doc) => CreatorProfileModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateVerificationStatus(String uid, String status) async {
    final isVerified = status == 'Verified';
    await _profiles.doc(uid).update({'verificationStatus': status});
    await firestore.collection('users').doc(uid).update({
      'isVerified': isVerified,
    });
  }

  @override
  Future<void> addProduct(CreatorProductModel product) async {
    await _products.add({
      ...product.toJson(),
      'orderCount': 0,
      'wishlistCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProduct(CreatorProductModel product) async {
    final data = product.toJson()
      ..remove('createdAt')
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(product.id).update(data);
  }

  @override
  Future<void> deleteProduct(String productId) =>
      _products.doc(productId).delete();

  @override
  Future<void> setProductPublished(String productId, bool published) =>
      _products.doc(productId).update({
        'isActive': published,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> updateStock(String productId, int stock) =>
      _products.doc(productId).update({
        'stock': stock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<CreatorProductModel?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    final data = doc.data();
    return data == null ? null : CreatorProductModel.fromJson(data, doc.id);
  }

  @override
  Future<List<CreatorProductModel>> getPendingProducts() async {
    final snapshot = await _products
        .where('status', isEqualTo: 'Pending Approval')
        .get();
    return snapshot.docs
        .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<CreatorProductModel>> getAdminAllProducts() async {
    final snapshot = await _products.get();
    return snapshot.docs
        .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<CreatorProductModel>> getCreatorProducts(String uid) async {
    final snapshot =
        await _products.where('creatorUid', isEqualTo: uid).get();
    return snapshot.docs
        .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
    String? rejectionReason,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'isActive': status == 'Approved',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (approvedBy != null && approvedBy.isNotEmpty) {
      updateData['approvedBy'] = approvedBy;
    }
    if (approvedByEmail != null && approvedByEmail.isNotEmpty) {
      updateData['approvedByEmail'] = approvedByEmail;
    }
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      updateData['rejectionReason'] = rejectionReason;
    }
    if (status == 'Approved') {
      updateData['approvedAt'] = FieldValue.serverTimestamp();
    }
    await _products.doc(productId).update(updateData);
  }

  @override
  Future<List<String>> uploadProductImages({
    required List<File> images,
    required String uid,
    required String folder,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'products/$uid/${_segment(folder)}';
    return [
      for (var i = 0; i < images.length; i++)
        await _upload(images[i], '$path/image_${stamp}_$i.jpg'),
    ];
  }

  @override
  Future<List<String>> uploadCustomizationImages({
    required List<File> images,
    required String uid,
    required String productName,
    required String customizationName,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'products/$uid/${_segment(productName)}/customizations/${_segment(customizationName)}';
    return [
      for (var i = 0; i < images.length; i++)
        await _upload(images[i], '$path/image_${stamp}_$i.jpg'),
    ];
  }

  @override
  Stream<List<CreatorProductModel>> watchCreatorProducts(String uid) =>
      _products.where('creatorUid', isEqualTo: uid).snapshots().map((snapshot) {
        final products = snapshot.docs
            .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
            .toList();
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return products;
      });

  @override
  Stream<List<CreatorOrderModel>> watchCreatorOrders(String uid) => firestore
      .collection('orders')
      .where('creatorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => CreatorOrderModel.fromJson(doc.data(), doc.id))
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });

  @override
  Future<List<CreatorOrderModel>> getCreatorOrders(String creatorUid) async {
    final snapshot = await firestore
        .collection('orders')
        .where('creatorId', isEqualTo: creatorUid)
        .get();
    return snapshot.docs
        .map((doc) => CreatorOrderModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
    String? carrierName,
  }) {
    final stored = OrderStatus.storedValue(status);
    return firestore.collection('orders').doc(orderId).update({
      'status': stored,
      'updatedAt': FieldValue.serverTimestamp(),
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
        'rejectionReason': rejectionReason.trim(),
      if (consignmentNumber != null && consignmentNumber.trim().isNotEmpty)
        'consignmentNumber': consignmentNumber.trim(),
      if (carrierName != null && carrierName.trim().isNotEmpty)
        'carrierName': carrierName.trim(),
      if (OrderStatus.isDelivered(stored))
        'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CreatorNotificationModel>> watchNotifications(String uid) =>
      _notifications.where('creatorUid', isEqualTo: uid).snapshots().map((
        snapshot,
      ) {
        final notifications = snapshot.docs
            .map((doc) => CreatorNotificationModel.fromJson(doc.data(), doc.id))
            .toList();
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      });

  @override
  Future<List<CreatorNotificationModel>> getCreatorNotifications(
    String creatorUid,
  ) async {
    final snapshot = await _notifications
        .where('creatorUid', isEqualTo: creatorUid)
        .get();
    final notifications = snapshot.docs
        .map((doc) => CreatorNotificationModel.fromJson(doc.data(), doc.id))
        .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) =>
      _notifications.doc(notificationId).update({'isRead': true});

  @override
  Future<void> markAllNotificationsAsRead(String uid) async {
    final snapshot = await _notifications
        .where('creatorUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotifications(List<String> notificationIds) async {
    final batch = firestore.batch();
    for (final id in notificationIds) {
      batch.delete(_notifications.doc(id));
    }
    await batch.commit();
  }

  @override
  Future<CreatorBankAccountModel?> getCreatorBankAccount(String uid) async {
    final doc =
        await firestore.collection('creator_bank_accounts').doc(uid).get();
    final data = doc.data();
    return data == null ? null : CreatorBankAccountModel.fromJson(data, uid);
  }

  @override
  Future<void> saveCreatorBankAccount(
    CreatorBankAccountModel bankDetail,
  ) async {
    final ref =
        firestore.collection('creator_bank_accounts').doc(bankDetail.uid);
    final exists = (await ref.get()).exists;
    await ref.set({
      ...bankDetail.toJson(),
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
