import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/constants/product_categories.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/explore_storefronts_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

class SearchTab extends StatefulWidget {
  final String userId;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<PublicCreator>? onCreatorTap;

  /// Set by other tabs (e.g. a category tile on Home) to open the shop
  /// filtered to one category. The tab clears it once applied.
  final ValueNotifier<String?>? categoryRequest;

  const SearchTab({
    super.key,
    required this.userId,
    required this.onProductTap,
    this.onCreatorTap,
    this.categoryRequest,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _query = '';
  final Set<String> _selectedCategories = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.categoryRequest?.addListener(_applyCategoryRequest);
    _applyCategoryRequest();
  }

  @override
  void didUpdateWidget(SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryRequest != widget.categoryRequest) {
      oldWidget.categoryRequest?.removeListener(_applyCategoryRequest);
      widget.categoryRequest?.addListener(_applyCategoryRequest);
    }
  }

  @override
  void dispose() {
    widget.categoryRequest?.removeListener(_applyCategoryRequest);
    _searchController.dispose();
    super.dispose();
  }

  void _applyCategoryRequest() {
    final request = widget.categoryRequest;
    final category = request?.value;
    if (request == null || category == null) return;
    request.value = null;
    void apply() {
      _searchController.clear();
      _query = '';
      _selectedCategories
        ..clear()
        ..add(category);
    }

    // The notifier may fire during the first build; defer setState then.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(apply);
      });
    } else if (mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  bool _matchesCategory(Product product) {
    if (_selectedCategories.isEmpty) return true;
    return _selectedCategories.any(
      (category) => productMatchesCategory(product.allCategories, category),
    );
  }

  Future<void> _openCategoryFilter() async {
    final state = context.read<BuyerBloc>().state;
    final categories = [
      ...(state.categories.isEmpty ? kProductCategories : state.categories),
    ];
    final draftSelection = Set<String>.from(_selectedCategories);
    final selection = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFAF6EE),
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
                              color: Color(0xFF8B261D),
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
                      icon: const Icon(Icons.close, color: Color(0xFF8B261D)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CheckboxListTile(
                      value: draftSelection.contains(category),
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF8B261D),
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
                  color: Color(0xFFFAF6EE),
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setModalState(draftSelection.clear),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B261D),
                      ),
                      child: const Text('Clear all'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          Set<String>.from(draftSelection),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B261D),
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
    return BuyerBackground(
      child: BlocBuilder<BuyerBloc, BuyerState>(
        buildWhen: (previous, current) =>
            previous.products != current.products ||
            previous.creators != current.creators ||
            previous.favoriteIds != current.favoriteIds,
        builder: (context, state) {
          final products = state.products.where((product) {
            final normalizedQuery = _query.trim().toLowerCase();
            final matchesCategory = _matchesCategory(product);
            final matchesQuery =
                normalizedQuery.isEmpty ||
                product.name.toLowerCase().contains(normalizedQuery) ||
                product.artisan.toLowerCase().contains(normalizedQuery) ||
                product.categoryLabel.toLowerCase().contains(normalizedQuery);
            return matchesCategory && matchesQuery;
          }).toList();
          final normalizedQuery = _query.trim().toLowerCase();
          final creators = normalizedQuery.isEmpty
              ? <PublicCreator>[]
              : state.creators.where((creator) {
                  if (!creator.isVerified) return false;
                  return creator.displayName.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      creator.name.toLowerCase().contains(normalizedQuery) ||
                      creator.location.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      creator.bio.toLowerCase().contains(normalizedQuery);
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF8B261D),
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find a piece with a story behind it.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF8B261D),
                        ),
                        hintText: 'Search products, crafts or artisans',
                        filled: true,
                        fillColor: const Color(
                          0xFFFAF6EE,
                        ).withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openCategoryFilter,
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF8B261D),
                          ),
                          label: Text(
                            _selectedCategories.isEmpty
                                ? 'Filter'
                                : 'Filter (${_selectedCategories.length})',
                            style: const TextStyle(
                              color: Color(0xFF8B261D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B261D)),
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        if (_selectedCategories.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () =>
                                setState(_selectedCategories.clear),
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Color(0xFF8B261D)),
                            ),
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
                            final category = _selectedCategories.elementAt(
                              index,
                            );
                            return InputChip(
                              backgroundColor: const Color(0xFFF2DEDD),
                              label: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8B261D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onDeleted: () => setState(
                                () => _selectedCategories.remove(category),
                              ),
                              deleteIconColor: const Color(0xFF8B261D),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_query.trim().isEmpty)
                      Card(
                        elevation: 1,
                        color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFF8B261D),
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B261D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: const Text(
                            'Explore Storefronts by Creators',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF8B261D),
                            ),
                          ),
                          subtitle: const Text(
                            'Discover verified artisans & full studio collections',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF8B261D),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExploreStorefrontsPage(
                                  userId: widget.userId,
                                  onProductTap: widget.onProductTap,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_query.trim().isEmpty) const SizedBox(height: 20),
                    if (creators.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Creators',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B261D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...creators.map(
                        (creator) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: creator.profileImage.isNotEmpty
                                  ? NetworkImage(creator.profileImage)
                                  : null,
                              child: creator.profileImage.isEmpty
                                  ? const Icon(Icons.storefront)
                                  : null,
                            ),
                            title: Text(
                              creator.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              creator.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: widget.onCreatorTap == null
                                ? null
                                : () => widget.onCreatorTap!(creator),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '${products.length} pieces',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (products.isEmpty && creators.isEmpty)
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
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
      ),
    );
  }
}
