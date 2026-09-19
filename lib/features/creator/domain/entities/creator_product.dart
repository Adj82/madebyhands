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
  });
}
