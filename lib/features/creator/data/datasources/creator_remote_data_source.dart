import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:madebyhands/features/creator/data/models/creator_order_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';

abstract interface class CreatorRemoteDataSource {
  /// Fetches the creator profile document from Firestore.
  Future<CreatorProfileModel?> getCreatorProfile(String uid);

  /// Saves or updates the creator profile document in Firestore.
  Future<void> saveCreatorProfile(CreatorProfileModel profile);

  /// Uploads a single profile image to Firebase Storage.
  Future<String> uploadProfileImage({
    required File image,
    required String uid,
  });

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
  Future<void> updateProductStatus(String productId, String status);

  /// Fetches all orders belonging to a specific creator.
  Future<List<CreatorOrderModel>> getCreatorOrders(String creatorUid);

  /// Updates the status of an order.
  Future<void> updateOrderStatus(String orderId, String status, {String? rejectionReason, String? consignmentNumber});
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
      final ref = firebaseStorage.ref().child('creator_profiles/$uid/profile_image.jpg');
      
      // Start upload
      final uploadTask = ref.putFile(
        image,
        _imageMetadata,
      );

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
        throw Exception('Firebase Storage Error: The profile image could not be found after upload. (Code: ${e.code})');
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

        final ref = firebaseStorage
            .ref()
            .child('creator_profiles/$uid/portfolio/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        
        final uploadTask = ref.putFile(
          images[i],
          _imageMetadata,
        );

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
      final ref = firebaseStorage.ref().child('creator_profiles/$uid/verification/$fileName');
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
      await firestore
          .collection('creator_profiles')
          .doc(uid)
          .update({'verificationStatus': status});

      // 2. Update users collection (Single source of truth for Role & Verification)
      await firestore
          .collection('users')
          .doc(uid)
          .update({'isVerified': isVerified});

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

        final ref = firebaseStorage
            .ref()
            .child('products/$uid/$productName/image_${timestamp}_$i.jpg');
        
        final uploadTask = ref.putFile(
          images[i],
          _imageMetadata,
        );

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
            'products/$uid/$productName/customizations/$customizationName/image_${timestamp}_$i.jpg');

        final uploadTask = ref.putFile(
          images[i],
          _imageMetadata,
        );

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
  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await firestore.collection('products').doc(productId).update({
        'status': status,
        'isActive': status == 'Approved',
      });
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
      return snapshot.docs
          .map((doc) => CreatorOrderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status, {String? rejectionReason, String? consignmentNumber}) async {
    try {
      final updateData = <String, dynamic>{'status': status};
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      if (consignmentNumber != null) {
        updateData['consignmentNumber'] = consignmentNumber;
      }
      await firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
