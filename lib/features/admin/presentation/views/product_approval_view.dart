import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/product_review_page.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class ProductApprovalView extends StatelessWidget {
  const ProductApprovalView({super.key});

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
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading products: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final docs = snapshot.data?.docs ?? [];
            final allProducts = docs.map((doc) {
              return CreatorProductModel.fromJson(doc.data(), doc.id);
            }).toList();

            final pending = allProducts
                .where((p) => p.status == 'Pending Approval' || p.status == 'pending')
                .toList();
            final approved = allProducts
                .where((p) => p.status == 'Approved' || p.status == 'approved')
                .toList();
            final rejected = allProducts
                .where((p) => p.status == 'Rejected' || p.status == 'rejected')
                .toList();

            return TabBarView(
              children: [
                _buildProductGrid(context, pending, 'No pending product approvals.'),
                _buildProductGrid(context, approved, 'No approved products.'),
                _buildProductGrid(context, rejected, 'No rejected products.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<CreatorProduct> products, String emptyMessage) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final adminName = currentUser?.name ?? 'Admin';
    final adminEmail = currentUser?.email ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CreatorBloc>().add(CreatorFetchAdminAllProducts());
      },
      child: products.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 400,
                  alignment: Alignment.center,
                  child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductReviewPage(product: product)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.outline,
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                                  )
                                : const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'by ${product.creatorName}',
                                style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text('₹${product.price}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                              if (product.approvedBy.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Approved by: ${product.approvedBy}',
                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (product.rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Reason: ${product.rejectionReason}',
                                  style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (product.status == 'Pending Approval' || product.status == 'pending')
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showRejectionDialog(context, product, adminName, adminEmail),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          foregroundColor: Colors.red,
                                          minimumSize: const Size(0, 32),
                                        ),
                                        child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () {
                                          context.read<CreatorBloc>().add(CreatorUpdateProductStatus(
                                                productId: product.id,
                                                status: 'Approved',
                                                approvedBy: adminName,
                                                approvedByEmail: adminEmail,
                                              ));
                                        },
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: AppColors.primary,
                                          minimumSize: const Size(0, 32),
                                        ),
                                        child: const Text('Approve', style: TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: product.status == 'Approved' || product.status == 'approved'
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.status.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: product.status == 'Approved' || product.status == 'approved'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showRejectionDialog(
    BuildContext context,
    CreatorProduct product,
    String adminName,
    String adminEmail,
  ) {
    final reasonController = TextEditingController();
    final creatorBloc = context.read<CreatorBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reject "${product.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this product. The seller will see this feedback.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'e.g. Image resolution too low, inaccurate description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(dialogContext);
              creatorBloc.add(CreatorUpdateProductStatus(
                productId: product.id,
                status: 'Rejected',
                approvedBy: adminName,
                approvedByEmail: adminEmail,
                rejectionReason: reason,
              ));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rejected "${product.name}" with reason.')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }
}
