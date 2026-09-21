import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/product_review_page.dart';

class ProductApprovalView extends StatefulWidget {
  const ProductApprovalView({super.key});

  @override
  State<ProductApprovalView> createState() => _ProductApprovalViewState();
}

class _ProductApprovalViewState extends State<ProductApprovalView> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<CreatorBloc>().add(CreatorFetchAdminAllProducts());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: BlocBuilder<CreatorBloc, CreatorState>(
          builder: (context, state) {
            List<CreatorProduct> pending = [];
            List<CreatorProduct> approved = [];
            List<CreatorProduct> rejected = [];
            bool isLoading = false;

            if (state is CreatorLoading) {
              isLoading = true;
            } else if (state is CreatorAdminAllProductsLoaded) {
              for (var p in state.products) {
                if (p.status == 'Approved') {
                  approved.add(p);
                } else if (p.status == 'Rejected') {
                  rejected.add(p);
                } else {
                  pending.add(p);
                }
              }
            }

            return TabBarView(
              children: [
                _buildProductGrid(pending, isLoading, 'No pending product approvals'),
                _buildProductGrid(approved, isLoading, 'No approved products'),
                _buildProductGrid(rejected, isLoading, 'No rejected products'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<CreatorProduct> products, bool isLoading, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          Expanded(
            child: products.isEmpty && !isLoading
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Text(emptyMessage),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductReviewPage(index: index)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: AppColors.outline,
                                  child: product.images.isNotEmpty
                                      ? Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text('by ${product.creatorName}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                                    const SizedBox(height: 5),
                                    Text('₹${product.price}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 10),
                                    if (product.status == 'Pending Approval')
                                      Row(
                                        children: [
                                          Expanded(
                                              child: OutlinedButton(
                                                  onPressed: () {
                                                    context.read<CreatorBloc>().add(CreatorUpdateProductStatus(productId: product.id, status: 'Rejected'));
                                                  },
                                                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.red),
                                                  child: const Text('Reject'))),
                                          const SizedBox(width: 5),
                                          Expanded(
                                              child: FilledButton(
                                                  onPressed: () {
                                                    context.read<CreatorBloc>().add(CreatorUpdateProductStatus(productId: product.id, status: 'Approved'));
                                                  },
                                                  style:
                                                      FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.primary),
                                                  child: const Text('Approve'))),
                                        ],
                                      )
                                    else
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: product.status == 'Approved' ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          product.status,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: product.status == 'Approved' ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
