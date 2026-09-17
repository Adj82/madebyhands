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
  });
}
