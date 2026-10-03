import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_thumbnail.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isSaved;
  final VoidCallback? onTap;

  /// Hides the save button when null (e.g. a creator previewing their shop).
  final VoidCallback? onSave;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSaved,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: const Color(0xFFFFF8F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5DDD5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductThumbnail(product: product, radius: 0, iconSize: 58),
                  if (onSave != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        tooltip: isSaved ? 'Remove from saved' : 'Save item',
                        onPressed: onSave,
                        icon: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFAF6EE,
                          ).withValues(alpha: 0.92),
                          foregroundColor: isSaved
                              ? const Color(0xFF8B261D)
                              : const Color(0xFF8B261D).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: const Color(0xFF221512),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.artisan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₹ ${product.price}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF221512),
                          ),
                        ),
                      ),
                      if (product.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFFE0A72F),
                        ),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
