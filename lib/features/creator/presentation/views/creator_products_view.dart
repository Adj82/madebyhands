import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/add_product_page.dart';

enum ProductSortCriteria { name, price, date }

class CreatorProductsView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorProductsView({super.key, required this.profile});

  @override
  State<CreatorProductsView> createState() => _CreatorProductsViewState();
}

class _CreatorProductsViewState extends State<CreatorProductsView> {
  ProductSortCriteria _currentCriteria = ProductSortCriteria.date;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    context
        .read<CreatorBloc>()
        .add(CreatorFetchCreatorProducts(widget.profile.uid));
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sort By',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _sortTile('Name', ProductSortCriteria.name, setSheetState),
                  _sortTile('Price', ProductSortCriteria.price, setSheetState),
                  _sortTile('Date Added', ProductSortCriteria.date, setSheetState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortTile(
      String title, ProductSortCriteria criteria, StateSetter setSheetState) {
    final isSelected = _currentCriteria == criteria;

    return ListTile(
      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.text,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          if (_currentCriteria == criteria) {
            _isAscending = !_isAscending;
          } else {
            _currentCriteria = criteria;
            _isAscending = criteria != ProductSortCriteria.date;
          }
        });
        setSheetState(() {});
      },
    );
  }

  List<CreatorProduct> _sortProducts(List<CreatorProduct> products) {
    final sorted = List<CreatorProduct>.from(products);
    switch (_currentCriteria) {
      case ProductSortCriteria.name:
        sorted.sort((a, b) => _isAscending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSortCriteria.price:
        sorted.sort((a, b) => _isAscending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case ProductSortCriteria.date:
        sorted.sort((a, b) => _isAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  void _addProduct() {
    if (widget.profile.verificationStatus != 'Verified') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verification Required'),
          content: const Text(
              'You must be a verified creator to add products. Please check your verification status in the dashboard.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddProductPage(profile: widget.profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Your Inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showSortOptions,
                  icon: const Icon(Icons.sort),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CreatorBloc, CreatorState>(
              buildWhen: (previous, current) {
                return current is CreatorMyProductsLoaded ||
                    current is CreatorLoading ||
                    current is CreatorFailure;
              },
              builder: (context, state) {
                if (state is CreatorLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CreatorMyProductsLoaded) {
                  final sortedProducts = _sortProducts(state.products);
                  final approvedProducts = sortedProducts
                      .where((p) => p.status == 'Approved')
                      .toList();
                  final pendingProducts = sortedProducts
                      .where((p) => p.status == 'Pending Approval')
                      .toList();
                  final rejectedProducts = sortedProducts
                      .where((p) => p.status == 'Rejected')
                      .toList();

                  return DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: AppColors.primary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: 'Approved'),
                            Tab(text: 'Pending'),
                            Tab(text: 'Rejected'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _ProductList(
                                  profile: widget.profile,
                                  products: approvedProducts,
                                  emptyMessage: 'No approved products yet.'),
                              _ProductList(
                                  profile: widget.profile,
                                  products: pendingProducts,
                                  emptyMessage: 'No pending products.'),
                              _ProductList(
                                  profile: widget.profile,
                                  products: rejectedProducts,
                                  emptyMessage: 'No rejected products.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CreatorFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context
                              .read<CreatorBloc>()
                              .add(CreatorFetchCreatorProducts(
                                  widget.profile.uid)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final CreatorProfile profile;
  final List<CreatorProduct> products;
  final String emptyMessage;

  const _ProductList(
      {required this.profile, required this.products, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AppColors.mutedText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first,
                      width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) =>
                          Container(
                              width: 60,
                              height: 60,
                              color: AppColors.outline,
                              child: const Icon(Icons.image_not_supported)))
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.outline,
                      child: const Icon(Icons.image)),
            ),
            title: Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('₹${product.price} • Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text('Category: ${product.category}',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ],
            ),
            trailing: product.status == 'Approved'
                ? IconButton(
                    icon: const Icon(Icons.edit_note, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductPage(
                            profile: profile,
                            initialProduct: product,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.status == 'Rejected' ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.status == 'Pending Approval' ? 'Pending' : 'Rejected',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.status == 'Rejected' ? Colors.red : Colors.orange.shade800,
                      ),
                    ),
                  ),
            onTap: () {
              // Open product details (Admin review page can be reused or dedicated view)
            },
          ),
        );
      },
    );
  }
}
