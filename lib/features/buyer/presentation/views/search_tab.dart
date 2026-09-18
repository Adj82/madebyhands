import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/data/mock_products.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class SearchTab extends StatefulWidget {
  final Set<String> savedProductIds;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onSave;

  const SearchTab({
    super.key,
    required this.savedProductIds,
    required this.onProductTap,
    required this.onSave,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Home Decor',
      'Pottery',
      'Jewellery',
      'Textiles',
      'Wellness',
      'Gifts',
    ];
    final products = mockProducts.where((product) {
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesCategory =
          _category == 'All' || product.category == _category;
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
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    );
                  },
                ),
              ),
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
              message: 'Try another search or category.',
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
                    isSaved: widget.savedProductIds.contains(product.id),
                    onTap: () => widget.onProductTap(product),
                    onSave: () => widget.onSave(product),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}


