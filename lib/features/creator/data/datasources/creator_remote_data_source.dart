import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';

abstract interface class CreatorRemoteDataSource {
  Future<CreatorProfileModel?> getCreatorProfile(String uid);
  Future<void> saveCreatorProfile(CreatorProfileModel profile);
  Future<String> uploadProfileImage({
    required File image,
    required String uid,
  });
  Future<List<String>> uploadPortfolioImages({
    required List<File> images,
    required String uid,
  });
}

class CreatorRemoteDataSourceImpl implements CreatorRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

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
      final ref = firebaseStorage.ref().child('creator_profiles/$uid/profile_image.jpg');
      
      // Upload the file
      final uploadTask = await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception("Upload failed with state: ${uploadTask.state}");
      }
    } on FirebaseException catch (e) {
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
        
        final uploadTask = await ref.putFile(
          images[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );

        if (uploadTask.state == TaskState.success) {
          final url = await ref.getDownloadURL();
          urls.add(url);
        }
      }
      return urls;
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage Error: ${e.message}');
    } catch (e) {
      throw Exception('Error uploading portfolio images: $e');
    }
  }
}
