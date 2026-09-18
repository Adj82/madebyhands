import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';

const mockProducts = <Product>[
  Product(
    id: 'woven-basket',
    name: 'Handwoven Storage Basket',
    artisan: 'Asha Weaves',
    category: 'Home Decor',
    description:
        'A sturdy, naturally dyed basket woven by hand. Every piece has small variations that make it one of a kind.',
    price: 1299,
    rating: 4.8,
    color: Color(0xFFD8BE8B),
    icon: Icons.shopping_basket_outlined,
  ),
  Product(
    id: 'blue-pottery',
    name: 'Blue Pottery Vase',
    artisan: 'Jaipur Clay Studio',
    category: 'Pottery',
    description:
        'A hand-painted ceramic vase inspired by traditional Jaipur blue pottery patterns.',
    price: 899,
    rating: 4.7,
    color: Color(0xFFAFC9D6),
    icon: Icons.local_florist_outlined,
  ),
  Product(
    id: 'silver-earrings',
    name: 'Hammered Silver Earrings',
    artisan: 'Tara Jewellery',
    category: 'Jewellery',
    description:
        'Lightweight statement earrings shaped and textured by hand for an organic finish.',
    price: 749,
    rating: 4.9,
    color: Color(0xFFD8D6D1),
    icon: Icons.diamond_outlined,
  ),
  Product(
    id: 'block-print-tote',
    name: 'Block Print Tote Bag',
    artisan: 'Rang Collective',
    category: 'Textiles',
    description:
        'A roomy cotton tote printed in small batches with hand-carved wooden blocks.',
    price: 599,
    rating: 4.6,
    color: Color(0xFFE8AA91),
    icon: Icons.shopping_bag_outlined,
  ),
  Product(
    id: 'soy-candle',
    name: 'Terracotta Soy Candle',
    artisan: 'Mitti & Light',
    category: 'Wellness',
    description:
        'A calm sandalwood soy candle poured into a reusable, hand-thrown terracotta cup.',
    price: 449,
    rating: 4.8,
    color: Color(0xFFD9A179),
    icon: Icons.light_mode_outlined,
  ),
  Product(
    id: 'wooden-toy',
    name: 'Wooden Pull-Along Elephant',
    artisan: 'Little Karigar',
    category: 'Gifts',
    description:
        'A cheerful wooden toy finished with child-safe, water-based colours by local craftspeople.',
    price: 699,
    rating: 4.7,
    color: Color(0xFFB8C99D),
    icon: Icons.toys_outlined,
  ),
];
