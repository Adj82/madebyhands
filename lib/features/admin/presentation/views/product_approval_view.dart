import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/product_review_page.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';

class ProductApprovalView extends StatefulWidget {
  const ProductApprovalView({super.key});

  @override
  State<ProductApprovalView> createState() => _ProductApprovalViewState();
}

class _ProductApprovalViewState extends State<ProductApprovalView> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _products =
      FirebaseFirestore.instance.collection('products').snapshots();

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
          stream: _products,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Could not load products: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final products = snapshot.data!.docs
                .map((doc) => CreatorProductModel.fromJson(doc.data(), doc.id))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            List<CreatorProduct> withStatus(String status) => products
                .where((p) => p.status.toLowerCase() == status)
                .toList();

            return TabBarView(
              children: [
                _ProductGrid(
                  products: withStatus('pending approval'),
                  emptyMessage: 'No products waiting for approval.',
                ),
                _ProductGrid(
                  products: withStatus('approved'),
                  emptyMessage: 'No approved products.',
                ),
                _ProductGrid(
                  products: withStatus('rejected'),
                  emptyMessage: 'No rejected products.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<CreatorProduct> products;
  final String emptyMessage;

  const _ProductGrid({required this.products, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 288,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductTile(product: products[index]),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final CreatorProduct product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isPending = product.status == 'Pending Approval';
    final isApproved = product.status == 'Approved';
    final isRejected = product.status == 'Rejected';
    return Card(
      clipBehavior: Clip.antiAlias,
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
                        cacheWidth: 480,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'by ${product.creatorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.round()} · Stock ${product.stock}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  if (!isPending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        isApproved
                            ? (product.isActive ? 'LIVE' : 'APPROVED · NOT LIVE')
                            : 'REJECTED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? Colors.green.shade700 : Colors.red,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (!isRejected)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => rejectProductWithReason(context, product),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: Colors.red,
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      if (isPending) const SizedBox(width: 4),
                      if (!isApproved)
                        Expanded(
                          child: FilledButton(
                            onPressed: () => approveProduct(context, product),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('Approve', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Approves and publishes [product], recording the reviewing admin.
void approveProduct(BuildContext context, CreatorProduct product) {
  final authState = context.read<AuthBloc>().state;
  final admin = authState is AuthSuccess ? authState.user : null;
  context.read<AdminBloc>().add(
    AdminProductReviewRequested(
      productId: product.id,
      approve: true,
      reviewerName: admin?.name ?? 'Admin',
      reviewerEmail: admin?.email ?? '',
      productName: product.name,
    ),
  );
}

/// Asks for a mandatory reason, then rejects [product]. Returns true when
/// the rejection was submitted.
Future<bool> rejectProductWithReason(BuildContext context, CreatorProduct product) async {
  final authState = context.read<AuthBloc>().state;
  final admin = authState is AuthSuccess ? authState.user : null;
  final adminBloc = context.read<AdminBloc>();
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Reject "${product.name}"'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for the creator *',
            hintText: 'e.g. Image resolution too low, inaccurate description',
          ),
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Please give a reason of at least 3 characters.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
  if (reason == null) return false;
  adminBloc.add(
    AdminProductReviewRequested(
      productId: product.id,
      approve: false,
      reviewerName: admin?.name ?? 'Admin',
      reviewerEmail: admin?.email ?? '',
      rejectionReason: reason,
      productName: product.name,
    ),
  );
  return true;
}
