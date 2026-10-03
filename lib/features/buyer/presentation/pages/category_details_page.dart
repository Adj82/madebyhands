import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/core/constants/product_categories.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

/// Buyer-facing category storefront backed only by the live product stream.
class CategoryDetailsPage extends StatefulWidget {
  final String categoryTitle;
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onOpenCart;

  const CategoryDetailsPage({
    super.key,
    required this.categoryTitle,
    required this.userId,
    required this.onProductTap,
    required this.onOpenCart,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _query = '';
  String _subcategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _key => normalizeCategory(widget.categoryTitle);

  String get _backgroundAsset {
    if (_key.contains('digital')) return 'digital.png';
    if (_key.contains('pottery')) return 'pottery.png';
    if (_key.contains('textile')) return 'textile.png';
    if (_key.contains('fashion')) return 'jewelry.png';
    if (_key.contains('home decor')) return 'homedecor.png';
    if (_key.contains('wood')) return 'wood.png';
    if (_key.contains('paper')) return 'paper.png';
    if (_key.contains('handicraft')) return 'handicraft.png';
    if (_key.contains('resin')) return 'resin.png';
    if (_key.contains('other')) return 'other.png';
    return 'painting.png';
  }

  String get _description {
    if (_key.contains('digital')) {
      return 'Discover original digital artworks, illustrations and photography.';
    }
    if (_key.contains('pottery')) {
      return 'Discover hand-shaped ceramics, clay pieces and sculpture.';
    }
    if (_key.contains('textile')) {
      return 'Discover handwoven textiles, embroidery, toys and dolls.';
    }
    if (_key.contains('fashion')) {
      return 'Discover handcrafted fashion, jewellery and wearable art.';
    }
    if (_key.contains('home decor')) {
      return 'Discover thoughtful handmade pieces for your home.';
    }
    if (_key.contains('wood')) {
      return 'Discover wood, metal, leather and natural crafts.';
    }
    if (_key.contains('paper')) {
      return 'Discover handmade paper goods, books and stationery.';
    }
    if (_key.contains('handicraft')) {
      return 'Discover unique goods made by independent artisans.';
    }
    if (_key.contains('resin')) {
      return 'Discover contemporary resin and mixed-material creations.';
    }
    if (_key.contains('other')) {
      return 'Discover experimental works by independent creators.';
    }
    return 'Discover original art made by independent artists.';
  }

  List<String> get _filters {
    if (_key.contains('digital')) {
      return const ['All', 'Digital', 'Illustration', 'Design', 'Photography'];
    }
    if (_key.contains('pottery')) {
      return const ['All', 'Pottery', 'Ceramic', 'Clay', 'Sculpture'];
    }
    if (_key.contains('textile')) {
      return const [
        'All',
        'Textile',
        'Embroidery',
        'Handloom',
        'Toys',
        'Dolls',
      ];
    }
    if (_key.contains('fashion')) {
      return const [
        'All',
        'Clothing',
        'Traditional wear',
        'Jewellery',
        'Accessories',
      ];
    }
    if (_key.contains('home decor')) {
      return const ['All', 'Wall décor', 'Homeware', 'Lighting', 'Decorative'];
    }
    if (_key.contains('wood')) {
      return const ['All', 'Wood', 'Bamboo', 'Metal', 'Leather'];
    }
    if (_key.contains('paper')) {
      return const ['All', 'Paper art', 'Journals', 'Cards', 'Books'];
    }
    if (_key.contains('handicraft')) {
      return const ['All', 'Utility', 'Decorative', 'Artisan', 'Heritage'];
    }
    if (_key.contains('resin')) {
      return const [
        'All',
        'Resin décor',
        'Jewellery',
        'Furniture',
        'Mixed media',
      ];
    }
    return const ['All', 'Painting', 'Drawing', 'Traditional', 'Fine art'];
  }

  bool _matchesSubcategory(Product product) {
    if (_subcategory == 'All') return true;
    final needle = normalizeCategory(_subcategory);
    final searchable = normalizeCategory(
      [
        product.name,
        product.description,
        product.materials,
        ...product.allCategories,
      ].join(' '),
    );
    return searchable.contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F2),
      body: BlocBuilder<BuyerBloc, BuyerState>(
        builder: (context, state) {
          final normalizedQuery = _query.trim().toLowerCase();
          final categoryProducts = state.products
              .where(
                (product) => productMatchesCategory(
                  product.allCategories,
                  widget.categoryTitle,
                ),
              )
              .where(_matchesSubcategory)
              .where(
                (product) =>
                    normalizedQuery.isEmpty ||
                    product.name.toLowerCase().contains(normalizedQuery) ||
                    product.description.toLowerCase().contains(
                      normalizedQuery,
                    ) ||
                    product.artisan.toLowerCase().contains(normalizedQuery),
              )
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHero(context, state)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${categoryProducts.length} ${categoryProducts.length == 1 ? 'item' : 'items'}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A4438),
                    ),
                  ),
                ),
              ),
              if (state.isLoadingProducts && state.products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (categoryProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyCategory(
                    category: widget.categoryTitle,
                    hasSearch:
                        normalizedQuery.isNotEmpty || _subcategory != 'All',
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _subcategory = 'All';
                      });
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid.builder(
                    itemCount: categoryProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                    itemBuilder: (context, index) {
                      final product = categoryProducts[index];
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context, BuyerState state) {
    final cartCount = state.cartQuantities.values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 350),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        0,
      ),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/category_background_images/$_backgroundAsset',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.48),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF8B261D),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: _showSearch ? 'Close search' : 'Search this category',
                onPressed: () => setState(() => _showSearch = !_showSearch),
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF8B261D),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Open cart',
                onPressed: widget.onOpenCart,
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF8B261D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            widget.categoryTitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
          if (_showSearch) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search in ${widget.categoryTitle}',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = filter == _subcategory;
                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _subcategory = filter),
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  selectedColor: const Color(0xFFFFF4F2),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF331818) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  final String category;
  final bool hasSearch;
  final VoidCallback onClear;

  const _EmptyCategory({
    required this.category,
    required this.hasSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.palette_outlined,
            size: 48,
            color: Color(0xFF8A7F73),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? 'No matching works'
                : 'No products in this category yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF331818),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try clearing the search or subcategory filter.'
                : 'New $category products will appear here after approval.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: const Color(0xFF8A7F73)),
          ),
          if (hasSearch) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    ),
  );
}
