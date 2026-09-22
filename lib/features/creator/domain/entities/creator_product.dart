class CreatorProduct {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final String category;
  final double price;
  final int stock;
  final String materials;
  final String dimensions;
  final String weight;
  final String shippingInfo;
  final String creatorUid;
  final String creatorName;
  final String status; // 'Pending Approval', 'Approved', 'Rejected'
  final bool isActive;
  final DateTime createdAt;
  final bool isCustomizable;
  final List<ProductCustomization> customizations;
  final Map<String, dynamic>? editHistory; // Stores previous values for comparison

  CreatorProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.category,
    required this.price,
    required this.stock,
    required this.materials,
    required this.dimensions,
    required this.weight,
    required this.shippingInfo,
    required this.creatorUid,
    required this.creatorName,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.isCustomizable = false,
    this.customizations = const [],
    this.editHistory,
  });
}

class ProductCustomization {
  final String name;
  final String description;
  final double additionalPrice;
  final List<String> images;
  final bool isMultipleSelection;
  final List<String> options;

  ProductCustomization({
    required this.name,
    required this.description,
    required this.additionalPrice,
    required this.isMultipleSelection,
    this.images = const [],
    this.options = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'additionalPrice': additionalPrice,
      'images': images,
      'isMultipleSelection': isMultipleSelection,
      'options': options,
    };
  }
}
