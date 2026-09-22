import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';

class CartTab extends StatelessWidget {
  final VoidCallback onBrowse;
  final VoidCallback onCheckout;

  const CartTab({super.key, required this.onBrowse, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyerBloc, BuyerState>(
      builder: (context, state) {
        final productsInCart = state.products
            .where((product) => state.cartQuantities.containsKey(product.id))
            .toList();

        final subtotal = productsInCart.fold<int>(
          0,
          (total, product) =>
              total + product.price * state.cartQuantities[product.id]!,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Text(
                'Your cart',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: productsInCart.isEmpty
                  ? BuyerEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      message: 'Add a handmade piece and it will appear here.',
                      actionLabel: 'Start shopping',
                      onAction: onBrowse,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: productsInCart.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = productsInCart[index];
                        final quantity = state.cartQuantities[product.id]!;
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
                                    color: AppColors.text.withAlpha(158),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          context.read<BuyerBloc>().add(
                                            BuyerUpdateCartQuantity(
                                              product,
                                              quantity - 1,
                                            ),
                                          ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          context.read<BuyerBloc>().add(
                                            BuyerUpdateCartQuantity(
                                              product,
                                              quantity + 1,
                                            ),
                                          ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
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
            if (productsInCart.isNotEmpty)
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
                        onPressed: onCheckout,
                        child: const Text('Review and place order'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
