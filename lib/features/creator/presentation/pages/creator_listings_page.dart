import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorListingsPage extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorListingsPage({super.key, required this.profile});

  @override
  State<CreatorListingsPage> createState() => _CreatorListingsPageState();
}

class _CreatorListingsPageState extends State<CreatorListingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CreatorBloc>().add(CreatorFetchCreatorProducts(widget.profile.uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
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
            final approvedProducts = state.products
                .where((p) => p.status == 'Approved')
                .toList();
            final pendingProducts = state.products
                .where((p) => p.status == 'Pending Approval')
                .toList();
            final rejectedProducts = state.products
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
                        _ProductList(products: approvedProducts, emptyMessage: 'No approved products yet.'),
                        _ProductList(products: pendingProducts, emptyMessage: 'No pending products.'),
                        _ProductList(products: rejectedProducts, emptyMessage: 'No rejected products.'),
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
  final List<CreatorProduct> products;
  final String emptyMessage;

  const _ProductList({required this.products, required this.emptyMessage});

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
                  ? Image.network(product.images.first, width: 60, height: 60, fit: BoxFit.cover)
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
            trailing: product.status == 'Approved' 
                ? const Icon(Icons.verified, color: Colors.green)
                : Text(product.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
        );
      },
    );
  }
}
