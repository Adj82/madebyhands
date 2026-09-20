import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
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
    context.read<CreatorBloc>().add(CreatorFetchPendingProducts());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      buildWhen: (previous, current) {
        // Only rebuild if the state is specifically about products, loading, or failures.
        // This prevents the view from being reset by creator profile fetches.
        return current is CreatorPendingProductsLoaded ||
            current is CreatorFailure ||
            current is CreatorLoading;
      },
      builder: (context, state) {
        // If we have products already and a new loading state comes (from another tab),
        // we keep showing the products instead of a spinner.
        if (state is CreatorLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CreatorPendingProductsLoaded) {
          final products = state.products;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CreatorBloc>().add(CreatorFetchPendingProducts());
            },
            child: products.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 500,
                      child: Center(
                        child: Text('No pending product approvals.',
                            style: TextStyle(color: AppColors.mutedText)),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductReviewCard(product: product);
                    },
                  ),
          );
        }

        if (state is CreatorFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text('Error: ${state.message}'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      context.read<CreatorBloc>().add(CreatorFetchPendingProducts()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show a spinner for CreatorInitial or states intended for other views
        // if we haven't loaded products yet.
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ProductReviewCard extends StatelessWidget {
  final CreatorProduct product;
  const _ProductReviewCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showProductDetails(context),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.images.isNotEmpty)
                    Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                  else
                    Container(color: AppColors.outline, child: const Icon(Icons.image, color: Colors.grey)),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Text('${product.images.length} Photos', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('by ${product.creatorName}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText), maxLines: 1),
                const SizedBox(height: 4),
                Text('₹${product.price}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(context, 'Rejected'),
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: Colors.red), foregroundColor: Colors.red),
                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _handleAction(context, 'Approved'),
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.primary),
                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String status) {
    context.read<CreatorBloc>().add(CreatorUpdateProductStatus(productId: product.id, status: status));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product $status')));
  }

  void _showProductDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.85,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product Details Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(product.images[i], width: 250, fit: BoxFit.cover)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(label: 'Name', value: product.name),
              _DetailRow(label: 'Description', value: product.description),
              _DetailRow(label: 'Category', value: product.category),
              _DetailRow(label: 'Price', value: '₹${product.price}'),
              _DetailRow(label: 'Stock', value: '${product.stock} units'),
              _DetailRow(label: 'Materials', value: product.materials),
              _DetailRow(label: 'Dimensions', value: product.dimensions),
              _DetailRow(label: 'Weight', value: product.weight),
              _DetailRow(label: 'Shipping', value: product.shippingInfo),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
