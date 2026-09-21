import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/add_product_page.dart';

enum ProductSortCriteria { name, price, date }

class CreatorListingsPage extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorListingsPage({super.key, required this.profile});

  @override
  State<CreatorListingsPage> createState() => _CreatorListingsPageState();
}

class _CreatorListingsPageState extends State<CreatorListingsPage> {
  ProductSortCriteria _currentCriteria = ProductSortCriteria.date;
  bool _isAscending = false; // Default: Newest first for date

  @override
  void initState() {
    super.initState();
    context.read<CreatorBloc>().add(CreatorFetchCreatorProducts(widget.profile.uid));
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _sortTile(String title, ProductSortCriteria criteria, StateSetter setSheetState) {
    final isSelected = _currentCriteria == criteria;
    
    return ListTile(
      tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.text,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected 
          ? Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          if (_currentCriteria == criteria) {
            _isAscending = !_isAscending;
          } else {
            _currentCriteria = criteria;
            // Default sensible orders for new selection
            _isAscending = criteria != ProductSortCriteria.date; 
          }
        });
        setSheetState(() {}); // Refresh bottom sheet UI
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: BlocBuilder<CreatorBloc, CreatorState>(
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
                        _ProductList(profile: widget.profile, products: approvedProducts, emptyMessage: 'No approved products yet.'),
                        _ProductList(profile: widget.profile, products: pendingProducts, emptyMessage: 'No pending products.'),
                        _ProductList(profile: widget.profile, products: rejectedProducts, emptyMessage: 'No rejected products.'),
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
                        .add(CreatorFetchCreatorProducts(widget.profile.uid)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final CreatorProfile profile;
  final List<CreatorProduct> products;
  final String emptyMessage;

  const _ProductList({required this.profile, required this.products, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: AppColors.outline, child: const Icon(Icons.image_not_supported)))
                  : Container(width: 60, height: 60, color: AppColors.outline, child: const Icon(Icons.image)),
            ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${product.price} • Stock: ${product.stock}'),
                Text('Category: ${product.category}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.status == 'Approved') 
                   IconButton(
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
                   ),
                const SizedBox(width: 5),
                product.status == 'Approved' 
                    ? const Icon(Icons.verified, color: Colors.green)
                    : Text(product.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}
