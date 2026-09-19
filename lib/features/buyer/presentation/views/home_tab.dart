import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class HomeTab extends StatelessWidget {
  final String userName;
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onBrowseAll;

  const HomeTab({
    super.key,
    required this.userName,
    required this.userId,
    required this.onProductTap,
    required this.onBrowseAll,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.trim().isEmpty
        ? 'there'
        : userName.trim().split(' ').first;

    return BlocBuilder<BuyerBloc, BuyerState>(
      builder: (context, state) {
        final products = state.products;
        final savedProductIds = state.favoriteIds;

        return CustomScrollView(
          key: const PageStorageKey('buyer-home'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MADEBYHANDS',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hello, $firstName',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {},
                        tooltip: 'Notifications',
                        icon: const Icon(Icons.notifications_none),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stories shaped by hand',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Discover thoughtful pieces made by independent Indian artisans.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.tonal(
                                onPressed: onBrowseAll,
                                child: const Text('Explore collection'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Color(0xFFE7C889),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: 'Shop by craft'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _CategoryCard(icon: Icons.home_outlined, label: 'Decor'),
                        _CategoryCard(
                          icon: Icons.local_florist_outlined,
                          label: 'Pottery',
                        ),
                        _CategoryCard(
                          icon: Icons.diamond_outlined,
                          label: 'Jewellery',
                        ),
                        _CategoryCard(
                          icon: Icons.checkroom_outlined,
                          label: 'Textiles',
                        ),
                        _CategoryCard(
                          icon: Icons.card_giftcard_outlined,
                          label: 'Gifts',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Handpicked for you',
                    actionLabel: 'See all',
                    onAction: onBrowseAll,
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.67,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: products.length < 4 ? products.length : 4,
                  (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      isSaved: savedProductIds.contains(product.id),
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
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    margin: const EdgeInsets.only(right: 10),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFE8ECD9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
