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
  });
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
