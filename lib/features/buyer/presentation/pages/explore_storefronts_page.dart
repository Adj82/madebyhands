import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/public_creator_storefront_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

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
        appBar: AppBar(title: const Text('Creator Storefronts')),
        body: BlocBuilder<BuyerBloc, BuyerState>(
          buildWhen: (previous, current) =>
              previous.creators != current.creators,
          builder: (context, state) {
            final query = _searchQuery.trim().toLowerCase();

            final eligibleCreators = state.creators.where((creator) {
              final isEligible = creator.isVerified;
              if (!isEligible) return false;

              if (query.isEmpty) return true;

              return creator.displayName.toLowerCase().contains(query) ||
                  creator.name.toLowerCase().contains(query) ||
                  creator.location.toLowerCase().contains(query) ||
                  creator.bio.toLowerCase().contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Search by creator, studio or location...',
                    ),
                  ),
                ),
                Expanded(
                  child: eligibleCreators.isEmpty
                      ? const BuyerEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No storefronts found',
                          message:
                              'Try searching for another creator or location.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<BuyerBloc>().add(BuyerWatchCreators());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            itemCount: eligibleCreators.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
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

  const _StorefrontCard({required this.creator, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: BuyerColors.blush,
                    backgroundImage: creator.profileImage.isNotEmpty
                        ? NetworkImage(creator.profileImage)
                        : null,
                    child: creator.profileImage.isEmpty
                        ? const Icon(Icons.storefront, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: BuyerHeading(
                                creator.displayName,
                                size: 16,
                                color: BuyerColors.ink,
                                weight: FontWeight.w700,
                                maxLines: 1,
                              ),
                            ),
                            if (creator.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified, size: 16),
                            ],
                          ],
                        ),
                        if (creator.name.isNotEmpty &&
                            creator.name != creator.displayName) ...[
                          const SizedBox(height: 2),
                          Text(
                            'By ${creator.name}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: BuyerColors.body,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (creator.location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 13),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  creator.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BuyerColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (creator.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  creator.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: BuyerColors.body,
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
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          creator.portfolio[index],
                          width: 64,
                          height: 64,
                          cacheWidth: 192,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 64,
                            height: 64,
                            color: BuyerColors.sand,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 18,
                              color: BuyerColors.muted,
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
