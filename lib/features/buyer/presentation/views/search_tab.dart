import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class SearchTab extends StatefulWidget {
  final String userId;
  final ValueChanged<Product> onProductTap;

  const SearchTab({
    super.key,
    required this.userId,
    required this.onProductTap,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _query = '';
  final Set<String> _selectedCategories = {};

  bool _matchesCategory(Product product) {
    if (_selectedCategories.isEmpty) return true;
    final productCategory = _normalizeCategory(product.category);
    return _selectedCategories.any((category) {
      final acceptedNames =
          _legacyCategoryAliases[category] ?? const <String>[];
      return productCategory == _normalizeCategory(category) ||
          acceptedNames.contains(productCategory);
    });
  }

  Future<void> _openCategoryFilter() async {
    final draftSelection = Set<String>.from(_selectedCategories);
    final selection = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select one or more categories',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close filters',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: buyerProductCategories.length,
                  itemBuilder: (context, index) {
                    final category = buyerProductCategories[index];
                    return CheckboxListTile(
                      value: draftSelection.contains(category),
                      title: Text(category),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      onChanged: (selected) {
                        setModalState(() {
                          selected == true
                              ? draftSelection.add(category)
                              : draftSelection.remove(category);
                        });
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setModalState(draftSelection.clear),
                      child: const Text('Clear all'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          Set<String>.from(draftSelection),
                        ),
                        child: Text(
                          draftSelection.isEmpty
                              ? 'Show all products'
                              : 'Apply (${draftSelection.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() {
        _selectedCategories
          ..clear()
          ..addAll(selection);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyerBloc, BuyerState>(
      builder: (context, state) {
        final products = state.products.where((product) {
          final normalizedQuery = _query.trim().toLowerCase();
          final matchesCategory = _matchesCategory(product);
          final matchesQuery =
              normalizedQuery.isEmpty ||
              product.name.toLowerCase().contains(normalizedQuery) ||
              product.artisan.toLowerCase().contains(normalizedQuery) ||
              product.category.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        }).toList();

        return CustomScrollView(
          key: const PageStorageKey('buyer-search'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Explore handmade',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Find a piece with a story behind it.',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search products, crafts or artisans',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openCategoryFilter,
                        icon: const Icon(Icons.tune),
                        label: Text(
                          _selectedCategories.isEmpty
                              ? 'Filter'
                              : 'Filter (${_selectedCategories.length})',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      if (_selectedCategories.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => setState(_selectedCategories.clear),
                          child: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                  if (_selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _selectedCategories.elementAt(index);
                          return InputChip(
                            label: Text(category),
                            onDeleted: () => setState(
                              () => _selectedCategories.remove(category),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    '${products.length} pieces',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: BuyerEmptyState(
                  icon: Icons.search_off,
                  title: 'No pieces found',
                  message: 'Try another search or change your filters.',
                ),
              )
            else
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
                    childCount: products.length,
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isSaved: state.favoriteIds.contains(product.id),
                        onTap: () => widget.onProductTap(product),
                        onSave: () => context.read<BuyerBloc>().add(
                          BuyerToggleFavorite(
                            userId: widget.userId,
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

const buyerProductCategories = <String>[
  'Paintings & Fine Art',
  'Drawings & Illustrations',
  'Digital Art & Design',
  'Pottery, Ceramics & Clay',
  'Sculptures & Figurines',
  'Textile & Fiber Art',
  'Fashion & Wearables',
  'Jewellery & Accessories',
  'Home Décor & Living',
  'Wood, Bamboo & Natural Crafts',
  'Paper, Books & Stationery',
  'Traditional & Folk Art',
  'Handicrafts & Artisan Goods',
  'Toys, Dolls & Collectibles',
  'Resin & Mixed-Material Art',
  'Photography & Prints',
  'Gifts & Personalized Creations',
  'Other Creative Works',
];

String _normalizeCategory(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('é', 'e')
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

final Map<String, List<String>> _legacyCategoryAliases =
    {
      'Paintings & Fine Art': ['painting', 'paintings', 'fine art'],
      'Drawings & Illustrations': [
        'drawing',
        'drawings',
        'illustration',
        'illustrations',
      ],
      'Digital Art & Design': ['digital art', 'digital design'],
      'Pottery, Ceramics & Clay': ['pottery', 'ceramics', 'ceramic', 'clay'],
      'Sculptures & Figurines': [
        'sculpture',
        'sculptures',
        'figurine',
        'figurines',
      ],
      'Textile & Fiber Art': ['textile', 'textiles', 'fiber art', 'fibre art'],
      'Fashion & Wearables': ['fashion', 'wearables', 'clothing'],
      'Jewellery & Accessories': ['jewellery', 'jewelry', 'accessories'],
      'Home Décor & Living': ['home decor', 'decor', 'home and living'],
      'Wood, Bamboo & Natural Crafts': [
        'wood',
        'wooden',
        'bamboo',
        'natural crafts',
      ],
      'Paper, Books & Stationery': ['paper', 'books', 'stationery'],
      'Traditional & Folk Art': ['traditional art', 'folk art'],
      'Handicrafts & Artisan Goods': [
        'handicrafts',
        'artisan goods',
        'handmade',
      ],
      'Toys, Dolls & Collectibles': ['toys', 'toy', 'dolls', 'collectibles'],
      'Resin & Mixed-Material Art': [
        'resin',
        'mixed material art',
        'mixed media',
      ],
      'Photography & Prints': ['photography', 'prints'],
      'Gifts & Personalized Creations': ['gifts', 'gift', 'personalized'],
      'Other Creative Works': ['other', 'wellness'],
    }.map(
      (category, aliases) => MapEntry(
        category,
        aliases.map(_normalizeCategory).toList(growable: false),
      ),
    );
