import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';

import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';

class CartTab extends StatelessWidget {
  final List<Product> products;
  final Map<String, int> quantities;
  final void Function(Product, int) onQuantityChanged;
  final VoidCallback onBrowse;

  const CartTab({
    super.key,
    required this.products,
    required this.quantities,
    required this.onQuantityChanged,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final products = this.products
        .where((product) => quantities.containsKey(product.id))
        .toList();
    final subtotal = products.fold<int>(
      0,
      (total, product) => total + product.price * quantities[product.id]!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Text(
            'Your cart',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? BuyerEmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  message: 'Add a handmade piece and it will appear here.',
                  actionLabel: 'Start shopping',
                  onAction: onBrowse,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final quantity = quantities[product.id]!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: product.color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                product.icon,
                                color: AppColors.text.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '₹${product.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      onQuantityChanged(product, quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      onQuantityChanged(product, quantity + 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (products.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Text(
                        '₹$subtotal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment integration will be added with the team.',
                        ),
                      ),
                    ),
                    child: const Text('Proceed to checkout'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
