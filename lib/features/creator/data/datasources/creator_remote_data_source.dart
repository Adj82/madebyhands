import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/features/creator/data/models/creator_notification_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_order_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';

abstract interface class CreatorRemoteDataSource {
  /// Fetches the creator profile document from Firestore.
  Future<CreatorProfileModel?> getCreatorProfile(String uid);

  /// Saves or updates the creator profile document in Firestore.
  Future<void> saveCreatorProfile(CreatorProfileModel profile);

  /// Uploads a single profile image to Firebase Storage.
  Future<String> uploadProfileImage({required File image, required String uid});

  /// Uploads multiple portfolio images to Firebase Storage.
  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  });

  /// Uploads a verification document (photo or ID) to Firebase Storage.
  Future<String> uploadVerificationFile({
    required File file,
    required String uid,
    required String fileName,
  });

  /// Fetches all creator profiles from Firestore (Admin only).
  Future<List<CreatorProfileModel>> getAllCreatorProfiles();

  /// Updates the verification status of a creator and toggles their products' visibility.
  Future<void> updateVerificationStatus(String uid, String status);

  /// Adds a new product document to the Firestore 'products' collection.
  Future<void> addProduct(CreatorProductModel product);

  /// Updates an existing product document.
  Future<void> updateProduct(CreatorProductModel product);

  /// Uploads multiple product images to Firebase Storage.
  Future<List<String>> uploadProductImages({
    required List<File> images,
    required String uid,
    required String productName,
  });

  /// Uploads images for a specific product customization.
  Future<List<String>> uploadCustomizationImages({
    required List<File> images,
    required String uid,
    required String productName,
    required String customizationName,
  });

  /// Fetches products that are awaiting admin approval.
  Future<List<CreatorProductModel>> getPendingProducts();

  /// Fetches all products for admin review (Pending, Approved, Rejected).
  Future<List<CreatorProductModel>> getAdminAllProducts();

  /// Fetches all products belonging to a specific creator.
  Future<List<CreatorProductModel>> getCreatorProducts(String uid);

  /// Updates the approval status and active state of a product.
  Future<void> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
  });

  /// Fetches all orders belonging to a specific creator.
  Future<List<CreatorOrderModel>> getCreatorOrders(String creatorUid);

  /// Updates the status of an order.
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
  });

  /// Fetches in-app notifications for a specific creator.
  Future<List<CreatorNotificationModel>> getCreatorNotifications(String creatorUid);

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(String notificationId);

  /// Marks all unread notifications for a creator as read.
  Future<void> markAllNotificationsAsRead(String creatorUid);

  /// Creates a new notification document in Firestore.
  Future<void> createNotification(CreatorNotificationModel notification);

  /// Deletes specified notifications persistently from Firestore.
  Future<void> deleteNotifications(List<String> notificationIds);
}

class CreatorRemoteDataSourceImpl implements CreatorRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  static final _imageMetadata = SettableMetadata(contentType: 'image/jpeg');

  CreatorRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

  /// Universal cross-platform image uploader using putData & XFile (works on Web & Native)
  Future<String> _uploadFileSafely(File file, String path) async {
    try {
      final ref = firebaseStorage.ref().child(path);
      Uint8List bytes;
      if (kIsWeb) {
        // Use XFile to fetch blob URL on Web without calling dart:io File methods
        bytes = await XFile(file.path).readAsBytes();
      } else {
        bytes = await file.readAsBytes();
      }
      final uploadTask = ref.putData(bytes, _imageMetadata);
      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  @override
  Future<CreatorProfileModel?> getCreatorProfile(String uid) async {
    try {
      final doc = await firestore.collection('creator_profiles').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return CreatorProfileModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> saveCreatorProfile(CreatorProfileModel profile) async {
    try {
      await firestore
          .collection('creator_profiles')
          .doc(profile.uid)
          .set(profile.toJson());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> uploadProfileImage({
    required File image,
    required String uid,
  }) async {
    return _uploadFileSafely(image, 'creator_profiles/$uid/profile_image.jpg');
  }

  @override
  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  }) async {
    List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < images.length; i++) {
      final url = await _uploadFileSafely(
        images[i],
        'creator_profiles/$uid/portfolio/image_${timestamp}_$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }

  @override
  Future<String> uploadVerificationFile({
    required File file,
    required String uid,
    required String fileName,
  }) async {
    return _uploadFileSafely(file, 'creator_profiles/$uid/verification/$fileName');
  }

  @override
  Future<List<CreatorProfileModel>> getAllCreatorProfiles() async {
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
  Future<void> updateVerificationStatus(String uid, String status) async {
    try {
      final isVerified = status == 'Verified';

      // 1. Update creator_profiles collection
      await firestore.collection('creator_profiles').doc(uid).update({
        'verificationStatus': status,
      });

      // 2. Update users collection (Single source of truth for Role & Verification)
      await firestore.collection('users').doc(uid).update({
        'isVerified': isVerified,
      });

      // 3. Update products visibility (Business/Data Layer enforcement)
      final productsQuery = await firestore
          .collection('products')
          .where('creatorUid', isEqualTo: uid)
          .get();

      final batch = firestore.batch();
      for (final doc in productsQuery.docs) {
        final data = doc.data();
        final isApproved = data['status'] == 'Approved';
        // Only mark active if Creator is Verified AND Product is Approved
        batch.update(doc.reference, {'isActive': isVerified && isApproved});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> addProduct(CreatorProductModel product) async {
    try {
      await firestore.collection('products').add(product.toJson());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProduct(CreatorProductModel product) async {
    try {
      await firestore
          .collection('products')
          .doc(product.id)
          .update(product.toJson());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<String>> uploadProductImages({
    required List<File> images,
    required String uid,
    required String productName,
  }) async {
    List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < images.length; i++) {
      final url = await _uploadFileSafely(
        images[i],
        'products/$uid/$productName/image_${timestamp}_$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }

  @override
  Future<List<String>> uploadCustomizationImages({
    required List<File> images,
    required String uid,
    required String productName,
    required String customizationName,
  }) async {
    List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < images.length; i++) {
      final url = await _uploadFileSafely(
        images[i],
        'products/$uid/$productName/customizations/$customizationName/image_${timestamp}_$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }

  @override
  Future<List<CreatorProductModel>> getPendingProducts() async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('status', isEqualTo: 'Pending Approval')
          .get();
      return snapshot.docs
          .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<CreatorProductModel>> getAdminAllProducts() async {
    try {
      final snapshot = await firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<CreatorProductModel>> getCreatorProducts(String uid) async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('creatorUid', isEqualTo: uid)
          .get();
      return snapshot.docs
          .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'isActive': status == 'Approved',
      };
      if (approvedBy != null && approvedBy.isNotEmpty) {
        updateData['approvedBy'] = approvedBy;
      }
      if (approvedByEmail != null && approvedByEmail.isNotEmpty) {
        updateData['approvedByEmail'] = approvedByEmail;
      }
      if (status == 'Approved') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
      }

      await firestore.collection('products').doc(productId).update(updateData);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<CreatorOrderModel>> getCreatorOrders(String creatorUid) async {
    try {
      final snapshot = await firestore
          .collection('orders')
          .where('creatorId', isEqualTo: creatorUid)
          .get();
      final list = snapshot.docs
          .map((doc) => CreatorOrderModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static String? _getNextValidStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Placed':
        return 'Confirmed';
      case 'Accepted':
        return 'Confirmed';
      case 'Confirmed':
        return 'Processing';
      case 'Processing':
        return 'In-Transit';
      case 'In-Transit':
        return 'Shipped';
      case 'Shipped':
        return 'Out for Delivery';
      case 'Out for Delivery':
        return 'Delivered';
      default:
        return null;
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
  }) async {
    try {
      final orderRef = firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        throw Exception('Order not found.');
      }

      final currentData = orderSnap.data() ?? <String, dynamic>{};
      final currentStatus = currentData['status'] as String? ?? 'Placed';

      if (status == 'Rejected') {
        final updateData = <String, dynamic>{
          'status': 'Rejected',
          'rejectionReason': rejectionReason ?? 'Order rejected by creator',
          'payoutStatus': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await orderRef.update(updateData);
        return;
      }

      final expectedNextStatus = _getNextValidStatus(currentStatus);
      if (expectedNextStatus == null) {
        throw Exception(
          'Order is already in a final status ($currentStatus) and cannot be updated further.',
        );
      }

      if (status != expectedNextStatus) {
        throw Exception(
          'Invalid status transition from "$currentStatus" to "$status". The next valid status is "$expectedNextStatus".',
        );
      }

      if (status == 'Confirmed' || status == 'Accepted') {
        await firestore.runTransaction((transaction) async {
          final txOrderSnap = await transaction.get(orderRef);
          if (!txOrderSnap.exists) {
            throw Exception('Order not found.');
          }

          final orderData = txOrderSnap.data() ?? <String, dynamic>{};
          final txStatus = orderData['status'] as String? ?? '';

          if (txStatus != 'Confirmed' && txStatus != 'Accepted') {
            final rawItems = orderData['items'] as List<dynamic>? ?? const [];
            final itemsToUpdate = <_ItemStockUpdate>[];

            for (final rawItem in rawItems) {
              if (rawItem is! Map) continue;
              final itemMap = Map<String, dynamic>.from(rawItem);
              final productId = itemMap['productId'] as String? ?? '';
              final quantity = (itemMap['quantity'] as num?)?.round() ?? 1;
              final itemName = itemMap['name'] as String? ?? 'Product';

              if (productId.isNotEmpty) {
                final productRef =
                    firestore.collection('products').doc(productId);
                final productSnap = await transaction.get(productRef);
                itemsToUpdate.add(
                  _ItemStockUpdate(
                    ref: productRef,
                    snap: productSnap,
                    quantity: quantity,
                    name: itemName,
                  ),
                );
              }
            }

            for (final item in itemsToUpdate) {
              if (!item.snap.exists) {
                throw Exception(
                  'Product "${item.name}" no longer exists in inventory.',
                );
              }

              final productData = item.snap.data() ?? <String, dynamic>{};
              final currentStock =
                  (productData['stock'] as num?)?.toInt() ?? 0;

              if (currentStock < item.quantity) {
                throw Exception(
                  'Cannot confirm order: Insufficient stock for "${item.name}". Available: $currentStock, Ordered: ${item.quantity}.',
                );
              }

              final newStock = currentStock - item.quantity;
              if (newStock < 0) {
                throw Exception(
                  'Cannot confirm order: Stock for "${item.name}" cannot become negative.',
                );
              }

              item.newStock = newStock;
            }

            for (final item in itemsToUpdate) {
              transaction.update(item.ref, {'stock': item.newStock});
            }
          }

          final updateData = <String, dynamic>{
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (rejectionReason != null) {
            updateData['rejectionReason'] = rejectionReason;
          }
          if (consignmentNumber != null && consignmentNumber.trim().isNotEmpty) {
            updateData['consignmentNumber'] = consignmentNumber.trim();
          }
          transaction.update(orderRef, updateData);
        });
      } else {
        final updateData = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (consignmentNumber != null && consignmentNumber.trim().isNotEmpty) {
          updateData['consignmentNumber'] = consignmentNumber.trim();
        }
        if (status == 'Delivered') {
          updateData['deliveredAt'] = FieldValue.serverTimestamp();
        }
        await orderRef.update(updateData);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<CreatorNotificationModel>> getCreatorNotifications(
    String creatorUid,
  ) async {
    try {
      final snapshot = await firestore
          .collection('notifications')
          .where('creatorUid', isEqualTo: creatorUid)
          .get();

      if (snapshot.docs.isEmpty) {
        final batch = firestore.batch();
        final ref1 = firestore.collection('notifications').doc();
        batch.set(ref1, {
          'creatorUid': creatorUid,
          'title': 'Welcome to Creator Studio! 🎉',
          'message':
              'Complete your profile and submit verification to start listing your handcrafted products.',
          'type': 'announcement',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        final ref2 = firestore.collection('notifications').doc();
        batch.set(ref2, {
          'creatorUid': creatorUid,
          'title': 'Platform Announcement 📢',
          'message':
              'Ensure product listings feature accurate photos, materials, and available stock levels.',
          'type': 'announcement',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        await batch.commit();

        final freshSnapshot = await firestore
            .collection('notifications')
            .where('creatorUid', isEqualTo: creatorUid)
            .get();

        final freshList = freshSnapshot.docs
            .map((doc) => CreatorNotificationModel.fromJson(doc.data(), doc.id))
            .toList();
        freshList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return freshList;
      }

      final list = snapshot.docs
          .map((doc) => CreatorNotificationModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String creatorUid) async {
    try {
      final snapshot = await firestore
          .collection('notifications')
          .where('creatorUid', isEqualTo: creatorUid)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> createNotification(CreatorNotificationModel notification) async {
    try {
      await firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteNotifications(List<String> notificationIds) async {
    try {
      final batch = firestore.batch();
      for (final id in notificationIds) {
        final docRef = firestore.collection('notifications').doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

class _ItemStockUpdate {
  final DocumentReference<Map<String, dynamic>> ref;
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final int quantity;
  final String name;
  int newStock;

  _ItemStockUpdate({
    required this.ref,
    required this.snap,
    required this.quantity,
    required this.name,
  }) : newStock = 0;
}
