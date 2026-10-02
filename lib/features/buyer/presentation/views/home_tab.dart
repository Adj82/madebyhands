import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/core/constants/product_categories.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeTab extends StatefulWidget {
  final String userName;
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onBrowseAll;
  final ValueChanged<String>? onCategoryTap;
  final SavedAddress? selectedAddress;
  final VoidCallback? onAddressTap;
  final int unreadNotificationCount;
  final VoidCallback onNotificationsTap;

  const HomeTab({
    super.key,
    required this.userName,
    required this.userId,
    required this.onProductTap,
    required this.onBrowseAll,
    this.onCategoryTap,
    this.selectedAddress,
    this.onAddressTap,
    required this.unreadNotificationCount,
    required this.onNotificationsTap,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final PageController _storyPageController;

  final List<Map<String, String>> _stories = [
    {
      'title': 'The Story of Madhubani Art',
      'image':
          'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=800&auto=format&fit=crop',
      'asset': 'assets/main_page_elements/painting_main.png',
      'category': kProductCategories[0],
    },
    {
      'title': 'The Heritage of Phulkari',
      'image':
          'https://images.unsplash.com/photo-1606744888344-493238951221?q=80&w=800&auto=format&fit=crop',
      'asset': 'assets/main_page_elements/textile_main.png',
      'category': kProductCategories[3],
    },
    {
      'title': 'Royal Terracotta & Pottery',
      'image':
          'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?q=80&w=800&auto=format&fit=crop',
      'asset': 'assets/main_page_elements/pottery_main.png',
      'category': kProductCategories[2],
    },
    {
      'title': 'Handcrafted Cultural Heritage',
      'image':
          'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=800&auto=format&fit=crop',
      'asset': 'assets/main_page_elements/handicraft_main.png',
      'category': kProductCategories[8],
    },
  ];

  /// Artwork for each entry of [kProductCategories], in the same order.
  static const _categoryArt = <String>[
    'painting_main.png',
    'digital_main.png',
    'pottery_main.png',
    'textile_main.png',
    'fashion_main.png',
    'homedec_main.png',
    'wood_main.png',
    'paper_main.png',
    'handicraft_main.png',
    'resin_main.png',
    'other_main.png',
  ];

  @override
  void initState() {
    super.initState();
    _storyPageController = PageController();
  }

  @override
  void dispose() {
    _storyPageController.dispose();
    super.dispose();
  }

  void _openSearch() {
    widget.onBrowseAll();
  }

  void _openCategory(String category) {
    final onCategoryTap = widget.onCategoryTap;
    onCategoryTap == null ? _openSearch() : onCategoryTap(category);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.userName.trim().isEmpty
        ? 'there'
        : widget.userName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      body: Stack(
        children: [
          // Background frame overlay
          Positioned.fill(
            child: Image.asset(
              'assets/main_page_elements/main_page_background.png',
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          // Scrollable body sitting on top of background
          SafeArea(
            child: SingleChildScrollView(
              key: const PageStorageKey('buyer-home-scroll'),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 26.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderWithBrandingAndTopRightIcons(),
                  const SizedBox(height: 6),
                  _buildGreetingAndAddress(firstName),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                  const SizedBox(height: 18),
                  _buildHistoricalArtSection(),
                  const SizedBox(height: 22),
                  _PopularPicks(
                    userId: widget.userId,
                    onProductTap: widget.onProductTap,
                    onSeeAll: widget.onBrowseAll,
                  ),
                  const SizedBox(height: 18),
                  _buildCategoryDivider(),
                  const SizedBox(height: 14),
                  _buildCategoriesGrid(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithBrandingAndTopRightIcons() {
    return SizedBox(
      width: double.infinity,
      height: 132,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Image.asset(
                'assets/main_page_elements/mbh_logo.png',
                height: 76,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.palette,
                  size: 48,
                  color: Color(0xFF8B261D),
                ),
              ),
              const SizedBox(height: 2),
              Image.asset(
                'assets/main_page_elements/madebyhands_text.png',
                height: 45,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'MADE BY HANDS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: const Color(0xFF8B261D),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 80,
            right: 0,
            child: IconButton(
              tooltip: 'Open notifications',
              onPressed: widget.onNotificationsTap,
              icon: Badge(
                isLabelVisible: widget.unreadNotificationCount > 0,
                label: Text('${widget.unreadNotificationCount}'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF8B261D),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingAndAddress(String firstName) {
    final addressText = widget.selectedAddress == null
        ? 'Add a delivery address'
        : 'Deliver to: ${widget.selectedAddress!.formatted}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/main_page_elements/flower_left.png',
          height: 68,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(width: 20),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello, $firstName',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF331818),
                ),
              ),
              const SizedBox(height: 3),
              InkWell(
                onTap: widget.onAddressTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF8B261D),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          addressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A4438),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 15,
                        color: Color(0xFF8B261D),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/main_page_elements/flower_right.png',
          height: 68,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(width: 20),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      onTap: _openSearch,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFC49A6C), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF8B261D), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search handmade art, crafts and more...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF8A7F73),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalArtSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historical Art & Stories',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B1D1D),
              ),
            ),
            InkWell(
              onTap: widget.onBrowseAll,
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B261D),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF8B261D),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _storyPageController,
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];
              return GestureDetector(
                onTap: () => _openCategory(story['category']!),
                child: _buildStoryCard(story),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SmoothPageIndicator(
            controller: _storyPageController,
            count: _stories.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: Color(0xFF8B261D),
              dotColor: Color(0xFFE2D0B5),
              dotHeight: 7,
              dotWidth: 7,
              expansionFactor: 2.5,
              spacing: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryImage(String? url, String? assetPath) {
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (assetPath != null && assetPath.isNotEmpty) {
            return Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholderImage(),
            );
          }
          return _buildPlaceholderImage();
        },
      );
    } else if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFEAD9C6),
      child: const Center(
        child: Icon(Icons.palette, size: 48, color: Color(0xFF8B261D)),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, String> story) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Artwork Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildStoryImage(story['image'], story['asset']),
            ),
          ),
          // Block border overlay frame
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/main_page_elements/block_border.png',
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Bottom Title Banner
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF8).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFC49A6C), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      story['title']!,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF331818),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B261D),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF8B261D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDivider() {
    return Image.asset(
      'assets/main_page_elements/category.png',
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (_, _, _) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(
          '— CATEGORIES —',
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFF6B1D1D),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final count = kProductCategories.length;
    final rowsCount = (count / 2).ceil();

    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        final firstIndex = rowIndex * 2;
        final secondIndex = firstIndex + 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(child: _buildCategoryCard(firstIndex)),
              const SizedBox(width: 10),
              Expanded(
                child: secondIndex < count
                    ? _buildCategoryCard(secondIndex)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryCard(int index) {
    final name = kProductCategories[index];
    return GestureDetector(
      onTap: () => _openCategory(name),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/main_page_elements/${_categoryArt[index]}',
              semanticLabel: name,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFF5EFE3),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B1D1D),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// FR-08 home feed: the most wished-for and most ordered products, with
/// items from categories the buyer has saved ranked first.
class _PopularPicks extends StatelessWidget {
  final String userId;
  final ValueChanged<Product> onProductTap;
  final VoidCallback onSeeAll;

  const _PopularPicks({
    required this.userId,
    required this.onProductTap,
    required this.onSeeAll,
  });

  static List<Product> rank(List<Product> products, Set<String> favoriteIds) {
    final favoriteCategories = <String>{
      for (final product in products)
        if (favoriteIds.contains(product.id))
          ...product.allCategories.map(normalizeCategory),
    };
    bool matchesTaste(Product product) =>
        product.allCategories.any((c) => favoriteCategories.contains(normalizeCategory(c)));

    final candidates = products
        .where((product) => product.isAvailable && product.stock > 0)
        .toList()
      ..sort((a, b) {
        final taste = (matchesTaste(b) ? 1 : 0) - (matchesTaste(a) ? 1 : 0);
        if (taste != 0) return taste;
        return b.popularityScore.compareTo(a.popularityScore);
      });
    return candidates.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyerBloc, BuyerState>(
      buildWhen: (previous, current) =>
          previous.products != current.products ||
          previous.favoriteIds != current.favoriteIds,
      builder: (context, state) {
        final picks = rank(state.products, state.favoriteIds);
        if (picks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Popular picks',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B1D1D),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'Shop all',
                    style: TextStyle(color: Color(0xFF8B261D), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: picks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = picks[index];
                  return SizedBox(
                    width: 170,
                    child: ProductCard(
                      product: product,
                      isSaved: state.favoriteIds.contains(product.id),
                      onTap: () => onProductTap(product),
                      onSave: () => context.read<BuyerBloc>().add(
                        BuyerToggleFavorite(userId: userId, product: product),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
