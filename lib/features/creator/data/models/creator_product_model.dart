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
    super.isCustomizable,
    super.customizations,
    super.editHistory,
    super.approvedBy,
    super.approvedByEmail,
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
      'isCustomizable': isCustomizable,
      'customizations': customizations.map((c) => c.toMap()).toList(),
      'createdAt': createdAt,
      'editHistory': editHistory,
      'approvedBy': approvedBy,
      'approvedByEmail': approvedByEmail,
    };
  }

  factory CreatorProductModel.fromJson(Map<String, dynamic> json, String id) {
    final customizationsRaw = json['customizations'] as List<dynamic>? ?? [];
    final customizations = customizationsRaw.map((c) => ProductCustomization(
      name: c['name'] ?? '',
      description: c['description'] ?? '',
      additionalPrice: (c['additionalPrice'] as num?)?.toDouble() ?? 0.0,
      images: List<String>.from(c['images'] ?? []),
      isMultipleSelection: c['isMultipleSelection'] ?? false,
      options: List<String>.from(c['options'] ?? []),
    )).toList();

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
      isCustomizable: json['isCustomizable'] ?? false,
      customizations: customizations,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editHistory: json['editHistory'] as Map<String, dynamic>?,
      approvedBy: json['approvedBy'] ?? '',
      approvedByEmail: json['approvedByEmail'] ?? '',
    );
  }
}
