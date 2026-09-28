import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicCreatorStorefrontPage extends StatelessWidget {
  final PublicCreator creator;
  final String buyerId;
  final ValueChanged<Product> onProductTap;

  const PublicCreatorStorefrontPage({
    super.key,
    required this.creator,
    required this.buyerId,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(creator.displayName)),
      body: BlocBuilder<BuyerBloc, BuyerState>(
        builder: (context, state) {
          final products = state.products
              .where((product) => product.creatorUid == creator.uid)
              .toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _CreatorHeader(creator: creator)),
              if (creator.portfolio.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Portfolio(images: creator.portfolio),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Storefront · ${products.length} products',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (products.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Text('No available products from this creator.'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.67,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: products.length,
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          isSaved: state.favoriteIds.contains(product.id),
                          onTap: () => onProductTap(product),
                          onSave: () => context.read<BuyerBloc>().add(
                            BuyerToggleFavorite(
                              userId: buyerId,
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
      ),
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  final PublicCreator creator;

  const _CreatorHeader({required this.creator});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: creator.profileImage.isEmpty
                  ? null
                  : NetworkImage(creator.profileImage),
              child: creator.profileImage.isEmpty
                  ? const Icon(Icons.storefront, size: 36)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          creator.displayName,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (creator.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  if (creator.category.isNotEmpty) Text(creator.category),
                  if (creator.location.isNotEmpty)
                    Text(
                      creator.location,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (creator.bio.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(creator.bio, style: const TextStyle(height: 1.5)),
        ],
        if (creator.story.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Creator story',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(creator.story, style: const TextStyle(height: 1.5)),
        ],
        if (creator.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: creator.socialLinks.map((link) {
              return ActionChip(
                avatar: const Icon(Icons.link, size: 18),
                label: const Text('Social link'),
                onPressed: () => _openLink(context, link),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );

  Future<void> _openLink(BuildContext context, String raw) async {
    final normalized = raw.startsWith('http') ? raw : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    }
  }
}

class _Portfolio extends StatelessWidget {
  final List<String> images;

  const _Portfolio({required this.images});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            images[index],
            width: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 150,
              child: ColoredBox(
                color: AppColors.surface,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
