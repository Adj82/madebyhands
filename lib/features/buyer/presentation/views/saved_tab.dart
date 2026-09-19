import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class SavedTab extends StatelessWidget {
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onBrowse;

  const SavedTab({
    super.key,
    required this.userId,
    required this.onProductTap,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyerBloc, BuyerState>(
      builder: (context, state) {
        final products = state.products
            .where((product) => state.favoriteIds.contains(product.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Text(
                'Saved pieces',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? BuyerEmptyState(
                      icon: Icons.favorite_border,
                      title: 'Nothing saved yet',
                      message: 'Tap the heart on a product to keep it here.',
                      actionLabel: 'Browse products',
                      onAction: onBrowse,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.67,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          isSaved: true,
                          onTap: () => onProductTap(product),
                          onSave: () => context.read<BuyerBloc>().add(
                                BuyerToggleFavorite(
                                  userId: userId,
                                  product: product,
                                ),
                              ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
