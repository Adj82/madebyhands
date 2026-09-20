import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';

class CreatorProductModel extends CreatorProduct {
  CreatorProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.images,
    required super.category,
    required super.price,
    required super.stock,
    required super.materials,
    required super.dimensions,
    required super.weight,
    required super.shippingInfo,
    required super.creatorUid,
    required super.creatorName,
    required super.status,
    required super.isActive,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'images': images,
      'category': category,
      'price': price,
      'stock': stock,
      'materials': materials,
      'dimensions': dimensions,
      'weight': weight,
      'shippingInfo': shippingInfo,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'status': status,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CreatorProductModel.fromJson(Map<String, dynamic> json, String id) {
    return CreatorProductModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      materials: json['materials'] ?? '',
      dimensions: json['dimensions'] ?? '',
      weight: json['weight'] ?? '',
      shippingInfo: json['shippingInfo'] ?? '',
      creatorUid: json['creatorUid'] ?? '',
      creatorName: json['creatorName'] ?? '',
      status: json['status'] ?? 'Pending Approval',
      isActive: json['isActive'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CreatorProductModel.fromEntity(CreatorProduct entity) {
    return CreatorProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      images: entity.images,
      category: entity.category,
      price: entity.price,
      stock: entity.stock,
      materials: entity.materials,
      dimensions: entity.dimensions,
      weight: entity.weight,
      shippingInfo: entity.shippingInfo,
      creatorUid: entity.creatorUid,
      creatorName: entity.creatorName,
      status: entity.status,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
