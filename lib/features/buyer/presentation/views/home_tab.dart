import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class HomeTab extends StatelessWidget {
  final String userName;
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onBrowseAll;
  final ValueChanged<String>? onCategoryTap;
  final SavedAddress? selectedAddress;
  final VoidCallback? onAddressTap;

  const HomeTab({
    super.key,
    required this.userName,
    required this.userId,
    required this.onProductTap,
    required this.onBrowseAll,
    this.onCategoryTap,
    this.selectedAddress,
    this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.trim().isEmpty
        ? 'Artisan'
        : userName.trim().split(' ').first;

    return BlocBuilder<BuyerBloc, BuyerState>(
      builder: (context, state) {
        final products = state.products;
        final savedProductIds = state.favoriteIds;

        return CustomScrollView(
          key: const PageStorageKey('buyer-home'),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              expandedHeight: 120.0,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MADEBYHANDS',
                              style: GoogleFonts.montserrat(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hello, $firstName',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: InkWell(
                  onTap: onAddressTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DELIVER TO',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedAddress == null
                                    ? 'Add a delivery address'
                                    : '${selectedAddress!.label} · ${selectedAddress!.formatted}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 10),
                  _buildExperienceBanner(),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Shop by craft'),
                  const SizedBox(height: 16),
                  _buildCategoryScroll(onCategoryTap),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Handpicked for you',
                    actionLabel: 'See all',
                    onAction: onBrowseAll,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.65,
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
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExperienceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1590424753858-394a12e6e4a2?q=80&w=600&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          opacity: 0.25,
          onError: (_, _) {},
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.gold, size: 32),
          const SizedBox(height: 16),
          Text(
            'Stories shaped\nby hand',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Discover thoughtful pieces made by independent artisans.',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowseAll,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(160, 48),
            ),
            child: const Text('Explore collection'),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCategoryScroll(ValueChanged<String>? onCategoryTap) {
    final categories = [
      (Icons.home_outlined, 'Home Decor'),
      (Icons.local_florist_outlined, 'Pottery'),
      (Icons.diamond_outlined, 'Jewellery'),
      (Icons.checkroom_outlined, 'Textiles'),
      (Icons.card_giftcard_outlined, 'Gifts'),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, i) {
          return _CategoryCard(
            icon: categories[i].$1,
            label: categories[i].$2,
            onTap: onCategoryTap == null
                ? null
                : () => onCategoryTap(categories[i].$2),
          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.2);
        },
      ),
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
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel!,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
    ],
  );
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CategoryCard({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    ),
  );
}
