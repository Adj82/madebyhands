import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/product_review_page.dart';

class ProductApprovalView extends StatelessWidget {
  const ProductApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final products = state.productApprovals;
        return GridView.builder(
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
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
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
                                        context.read<AdminBloc>().add(AdminRejectProductRequested(product.id));
                                      },
                                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                      child: const Text('Reject'))),
                              const SizedBox(width: 5),
                              Expanded(
                                  child: FilledButton(
                                      onPressed: () {
                                        context.read<AdminBloc>().add(AdminApproveProductRequested(product.id));
                                      },
                                      style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero, backgroundColor: AppColors.primary),
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
        );
      },
    );
  }
}
