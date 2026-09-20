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
    context.read<CreatorBloc>().add(CreatorFetchPendingProducts());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      builder: (context, state) {
        List<CreatorProduct> products = [];
        bool isLoading = false;

        if (state is CreatorLoading) {
          isLoading = true;
        } else if (state is CreatorPendingProductsLoaded) {
          products = state.products;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              if (isLoading) const LinearProgressIndicator(),
              Expanded(
                child: products.isEmpty && !isLoading
                    ? const Center(child: Text('No pending product approvals'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(15),
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
      },
    );
  }
}
