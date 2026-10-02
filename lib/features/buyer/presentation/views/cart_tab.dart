import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_thumbnail.dart';

class CartTab extends StatelessWidget {
  final VoidCallback onBrowse;
  final VoidCallback onCheckout;
  final ValueChanged<Product>? onProductTap;

  const CartTab({
    super.key,
    required this.onBrowse,
    required this.onCheckout,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: BlocBuilder<BuyerBloc, BuyerState>(
        buildWhen: (previous, current) =>
            previous.products != current.products ||
            previous.cartQuantities != current.cartQuantities ||
            previous.cartCustomizations != current.cartCustomizations,
        builder: (context, state) {
          final productsInCart = state.products
              .where((product) => state.cartQuantities.containsKey(product.id))
              .toList();

          final subtotal = productsInCart.fold<int>(0, (total, product) {
            final selection =
                state.cartCustomizations[product.id] ??
                const ProductCustomizationSelection();
            return total +
                selection.unitPriceFor(product) *
                    state.cartQuantities[product.id]!;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Text(
                  'Your cart',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8B261D),
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
                          final customization =
                              state.cartCustomizations[product.id] ??
                              const ProductCustomizationSelection();
                          final unitPrice = customization.unitPriceFor(product);
                          return Card(
                            elevation: 1,
                            color: const Color(0xFFFAF6EE).withValues(alpha: 0.92),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFF8B261D),
                                width: 0.8,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onProductTap == null
                                  ? null
                                  : () => onProductTap!(product),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ProductThumbnail(product: product, size: 76),
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
                                              color: Color(0xFF8B261D),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '₹$unitPrice',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2C1810),
                                            ),
                                          ),
                                          if (!customization.isEmpty) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              customization.values.entries
                                                  .map(
                                                    (entry) =>
                                                        '${entry.key}: ${entry.value.join(', ')}',
                                                  )
                                                  .join(' · '),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.mutedText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: quantity == 1 ? 'Remove from cart' : 'Decrease quantity',
                                          onPressed: () => context
                                              .read<BuyerBloc>()
                                              .add(
                                                BuyerUpdateCartQuantity(
                                                  product,
                                                  quantity - 1,
                                                ),
                                              ),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Color(0xFF8B261D),
                                          ),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF8B261D),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Increase quantity',
                                          onPressed: quantity >= product.stock
                                              ? null
                                              : () => context.read<BuyerBloc>().add(
                                                  BuyerUpdateCartQuantity(
                                                    product,
                                                    quantity + 1,
                                                  ),
                                                ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFF8B261D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                    color: Color(0xFFFAF6EE),
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
                                color: Color(0xFF8B261D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'A platform fee per creator is added at checkout.',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: onCheckout,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B261D),
                          ),
                          child: const Text('Review and place order'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
