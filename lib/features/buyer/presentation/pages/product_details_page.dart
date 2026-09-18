import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onAddToCart;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.isSaved,
    required this.onSave,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late bool _isSaved = widget.isSaved;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Remove from saved' : 'Save item',
            onPressed: () {
              widget.onSave();
              setState(() => _isSaved = !_isSaved);
            },
            icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
            color: _isSaved ? Colors.redAccent : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                product.icon,
                size: 112,
                color: AppColors.text.withValues(alpha: 0.62),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFE0A72F)),
              Text(
                '${product.rating}  ·  Made by ${product.artisan}',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '₹${product.price}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 22),
          const Text(
            'About this piece',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.55,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 22),
          const _DetailLine(
            icon: Icons.handyman_outlined,
            text: 'Handmade in India',
          ),
          const _DetailLine(
            icon: Icons.inventory_2_outlined,
            text: 'Plastic-conscious packaging',
          ),
          const _DetailLine(
            icon: Icons.local_shipping_outlined,
            text: 'Estimated delivery in 4–7 days',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            widget.onAddToCart();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} added to cart')),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: Text('Add to cart  ·  ₹${product.price}'),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 21, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(text),
      ],
    ),
  );
}
