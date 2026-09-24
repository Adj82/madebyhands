import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:madebyhands/core/services/shipping_tracking_service.dart';
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
}

class CreatorRemoteDataSourceImpl implements CreatorRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  static final _imageMetadata = SettableMetadata(contentType: 'image/jpeg');

  CreatorRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

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
    try {
      if (!await image.exists()) {
        throw Exception("Source file does not exist at ${image.path}");
      }

      // Use a deterministic path based on UID
      final ref = firebaseStorage.ref().child(
        'creator_profiles/$uid/profile_image.jpg',
      );

      // Start upload
      final uploadTask = ref.putFile(image, _imageMetadata);

      // Wait for completion
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Only call getDownloadURL after success on the same reference
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } on FirebaseException catch (e) {
      // Catch specific Storage errors
      if (e.code == 'object-not-found') {
        throw Exception(
          'Firebase Storage Error: The profile image could not be found after upload. (Code: ${e.code})',
        );
      }
      throw Exception('Firebase Storage Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }

  @override
  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  }) async {
    try {
      List<String> urls = [];
      for (var i = 0; i < images.length; i++) {
        if (!await images[i].exists()) continue;

        final ref = firebaseStorage.ref().child(
          'creator_profiles/$uid/portfolio/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );

        final uploadTask = ref.putFile(images[i], _imageMetadata);

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final url = await snapshot.ref.getDownloadURL();
          urls.add(url);
        }
      }
      return urls;
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage Error: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Error uploading portfolio images: $e');
    }
  }

  @override
  Future<String> uploadVerificationFile({
    required File file,
    required String uid,
    required String fileName,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception("Source file does not exist at ${file.path}");
      }
      final ref = firebaseStorage.ref().child(
        'creator_profiles/$uid/verification/$fileName',
      );
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } catch (e) {
      throw Exception('Error uploading verification file: $e');
    }
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
    try {
      List<String> urls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < images.length; i++) {
        if (!await images[i].exists()) continue;

        final ref = firebaseStorage.ref().child(
          'products/$uid/$productName/image_${timestamp}_$i.jpg',
        );

        final uploadTask = ref.putFile(images[i], _imageMetadata);

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final url = await snapshot.ref.getDownloadURL();
          urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      throw Exception('Error uploading product images: $e');
    }
  }

  @override
  Future<List<String>> uploadCustomizationImages({
    required List<File> images,
    required String uid,
    required String productName,
    required String customizationName,
  }) async {
    try {
      List<String> urls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < images.length; i++) {
        if (!await images[i].exists()) continue;

        final ref = firebaseStorage.ref().child(
          'products/$uid/$productName/customizations/$customizationName/image_${timestamp}_$i.jpg',
        );

        final uploadTask = ref.putFile(images[i], _imageMetadata);

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final url = await snapshot.ref.getDownloadURL();
          urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      throw Exception('Error uploading customization images: $e');
    }
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

      final orders = <CreatorOrderModel>[];

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        var status = data['status'] as String? ?? 'Placed';
        final consignmentNumber = data['consignmentNumber'] as String?;
        final shippedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now();

        if (consignmentNumber != null &&
            consignmentNumber.trim().isNotEmpty &&
            ['Shipped', 'In Transit', 'Out for Delivery'].contains(status)) {
          final trackingResult = await ShippingTrackingService.fetchTrackingStatus(
            consignmentNumber: consignmentNumber,
            shippedAt: shippedAt,
            currentStatus: status,
          );

          if (trackingResult.status != status) {
            status = trackingResult.status == 'Delivered'
                ? 'Completed'
                : trackingResult.status;
            data['status'] = status;
            data['carrierName'] = trackingResult.carrierName;
            data['lastLocation'] = trackingResult.lastLocation;

            final updateMap = <String, dynamic>{
              'status': status,
              'carrierName': trackingResult.carrierName,
              'lastLocation': trackingResult.lastLocation,
              'trackingUpdatedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            if (status == 'Completed' || status == 'Delivered') {
              updateMap['deliveredAt'] = FieldValue.serverTimestamp();
            }

            await firestore.collection('orders').doc(doc.id).update(updateMap);
          }
        } else if (status == 'Delivered') {
          status = 'Completed';
          data['status'] = status;
          await firestore.collection('orders').doc(doc.id).update({
            'status': 'Completed',
            'deliveredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        orders.add(CreatorOrderModel.fromJson(data, doc.id));
      }

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw Exception(e.toString());
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
      final currentStatus = currentData['status'] as String? ?? '';

      // Requirement 2: Once marked Shipped, Creator must not manually change status
      if (['Shipped', 'In Transit', 'Out for Delivery', 'Delivered', 'Completed']
              .contains(currentStatus) &&
          status != currentStatus) {
        throw Exception(
          'Orders that are marked Shipped cannot be manually changed. Status updates are automatically tracked via external courier.',
        );
      }

      // Requirement 1: Can mark as Shipped only after entering a valid consignment number
      if (status == 'Shipped') {
        final trimmedConsignment = consignmentNumber?.trim() ?? '';
        if (trimmedConsignment.isEmpty || trimmedConsignment.length < 3) {
          throw Exception(
            'Please enter a valid consignment/reference number (at least 3 characters) to ship the order.',
          );
        }
      }

      if (status == 'Accepted') {
        await firestore.runTransaction((transaction) async {
          final txOrderSnap = await transaction.get(orderRef);
          if (!txOrderSnap.exists) {
            throw Exception('Order not found.');
          }

          final orderData = txOrderSnap.data() ?? <String, dynamic>{};
          final txStatus = orderData['status'] as String? ?? '';

          if (txStatus != 'Accepted') {
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
                  'Cannot accept order: Insufficient stock for "${item.name}". Available: $currentStock, Ordered: ${item.quantity}.',
                );
              }

              final newStock = currentStock - item.quantity;
              if (newStock < 0) {
                throw Exception(
                  'Cannot accept order: Stock for "${item.name}" cannot become negative.',
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
          if (consignmentNumber != null) {
            updateData['consignmentNumber'] = consignmentNumber.trim();
          }
          transaction.update(orderRef, updateData);
        });
      } else {
        final updateData = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (rejectionReason != null) {
          updateData['rejectionReason'] = rejectionReason;
        }
        if (consignmentNumber != null) {
          updateData['consignmentNumber'] = consignmentNumber.trim();
        }
        if (status == 'Rejected' || status == 'Cancelled') {
          updateData['payoutStatus'] = 'cancelled';
        }
        await firestore.collection('orders').doc(orderId).update(updateData);
      }
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
    this.newStock = 0,
  });
}
