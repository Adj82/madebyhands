import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String artisan;
  final String category;
  final String description;
  final int price;
  final double rating;
  final Color color;
  final IconData icon;
  final String creatorUid;
  final List<String> images;
  final int stock;
  final bool isAvailable;
  final String materials;
  final String dimensions;
  final String shippingInfo;
  final bool isCustomizable;
  final List<String> predefinedCustomizations;
  final List<BuyerProductCustomization> customizations;

  /// Up to two marketplace categories (see kProductCategories). Older
  /// listings only carry [category].
  final List<String> categories;

  /// Popularity signals maintained by the payment API (orders) and by
  /// shoppers' wishlist toggles.
  final int orderCount;
  final int wishlistCount;

  const Product({
    required this.id,
    required this.name,
    required this.artisan,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.color,
    required this.icon,
    this.creatorUid = '',
    this.images = const [],
    this.stock = 999,
    this.isAvailable = true,
    this.materials = '',
    this.dimensions = '',
    this.shippingInfo = '',
    this.isCustomizable = false,
    this.predefinedCustomizations = const [],
    this.customizations = const [],
    this.categories = const [],
    this.orderCount = 0,
    this.wishlistCount = 0,
  });

  /// Categories to match filters against, falling back to [category].
  List<String> get allCategories => categories.isNotEmpty
      ? categories
      : category.trim().isEmpty
      ? const []
      : [category];

  /// Orders weigh more than wishlist saves when ranking the home feed.
  int get popularityScore => orderCount * 3 + wishlistCount;

  /// Display string for the category line on cards and details.
  String get categoryLabel => allCategories.join(' · ');
}

class BuyerProductCustomization {
  final String name;
  final String description;
  final int additionalPrice;
  final List<String> images;
  final bool isMultipleSelection;
  final List<String> options;

  const BuyerProductCustomization({
    required this.name,
    required this.description,
    required this.additionalPrice,
    this.images = const [],
    this.isMultipleSelection = false,
    this.options = const [],
  });
}

class ProductCustomizationSelection {
  final Map<String, List<String>> values;
  final int additionalPrice;

  const ProductCustomizationSelection({
    this.values = const {},
    this.additionalPrice = 0,
  });

  bool get isEmpty => values.values.every((choices) => choices.isEmpty);

  int unitPriceFor(Product product) => product.price + additionalPrice;
}
