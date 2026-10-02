import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';

/// The product's first photo, falling back to its category colour and icon
/// while loading or when the product has no usable image.
class ProductThumbnail extends StatelessWidget {
  final Product product;

  /// Square edge length. When null the thumbnail fills its parent.
  final double? size;
  final double radius;
  final double iconSize;

  const ProductThumbnail({
    super.key,
    required this.product,
    this.size,
    this.radius = 14,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: product.color,
      child: Center(
        child: Icon(
          product.icon,
          size: iconSize,
          color: AppColors.text.withValues(alpha: 0.62),
        ),
      ),
    );
    final imageUrl = product.images.isEmpty ? '' : product.images.first;
    final Widget content = imageUrl.isEmpty
        ? placeholder
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            cacheWidth: size == null ? 600 : (size! * 3).round(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
            errorBuilder: (_, _, _) => placeholder,
          );
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(child: content),
    );
    return size == null
        ? clipped
        : SizedBox.square(dimension: size, child: clipped);
  }
}
