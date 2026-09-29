import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/public_creator_storefront_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';

class ExploreStorefrontsPage extends StatefulWidget {
  final String userId;
  final ValueChanged<Product> onProductTap;

  const ExploreStorefrontsPage({
    super.key,
    required this.userId,
    required this.onProductTap,
  });

  @override
  State<ExploreStorefrontsPage> createState() => _ExploreStorefrontsPageState();
}

class _ExploreStorefrontsPageState extends State<ExploreStorefrontsPage> {
  String _searchQuery = '';

  void _openCreatorStorefront(PublicCreator creator) {
    final buyerBloc = context.read<BuyerBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: buyerBloc,
          child: PublicCreatorStorefrontPage(
            creator: creator,
            buyerId: widget.userId,
            onProductTap: widget.onProductTap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Creator Storefronts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          centerTitle: true,
        ),
        body: BlocBuilder<BuyerBloc, BuyerState>(
          builder: (context, state) {
            final query = _searchQuery.trim().toLowerCase();

            final eligibleCreators = state.creators.where((creator) {
              final isEligible = creator.isVerified;
              if (!isEligible) return false;

              if (query.isEmpty) return true;

              return creator.displayName.toLowerCase().contains(query) ||
                  creator.name.toLowerCase().contains(query) ||
                  creator.category.toLowerCase().contains(query) ||
                  creator.location.toLowerCase().contains(query) ||
                  creator.bio.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B261D),
                      ),
                      hintText: 'Search by creator, studio or category...',
                      filled: true,
                      fillColor: const Color(0xFFFAF6EE).withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Expanded(
                  child: eligibleCreators.isEmpty
                      ? const BuyerEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No storefronts found',
                          message:
                              'Try searching for another creator or craft category.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<BuyerBloc>().add(BuyerWatchCreators());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: eligibleCreators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final creator = eligibleCreators[index];
                              return _StorefrontCard(
                                creator: creator,
                                onTap: () => _openCreatorStorefront(creator),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StorefrontCard extends StatelessWidget {
  final PublicCreator creator;
  final VoidCallback onTap;

  const _StorefrontCard({
    required this.creator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: const Color(0xFFFAF6EE).withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFF8B261D),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF2DEDD),
                    backgroundImage: creator.profileImage.isNotEmpty
                        ? NetworkImage(creator.profileImage)
                        : null,
                    child: creator.profileImage.isEmpty
                        ? const Icon(
                            Icons.storefront,
                            size: 26,
                            color: Color(0xFF8B261D),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B261D),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (creator.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF8B261D),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        if (creator.name.isNotEmpty &&
                            creator.name != creator.displayName) ...[
                          const SizedBox(height: 2),
                          Text(
                            'By ${creator.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (creator.category.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2DEDD),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  creator.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B261D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (creator.location.isNotEmpty)
                              Expanded(
                                child: Text(
                                  creator.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF8B261D),
                  ),
                ],
              ),
              if (creator.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  creator.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),
              ],
              if (creator.portfolio.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: creator.portfolio.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          creator.portfolio[index],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.outline,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
