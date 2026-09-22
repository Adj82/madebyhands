import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class ProductReviewPage extends StatelessWidget {
  final CreatorProduct product;
  const ProductReviewPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Review', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _EditableText(
                          label: 'Product Name',
                          value: product.name,
                          previousValue: product.editHistory?['previousName'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _EditableText(
                        label: 'Price',
                        value: '₹${product.price}',
                        previousValue: product.editHistory != null ? '₹${product.editHistory!['previousPrice']}' : null,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Chip(label: Text(product.category), backgroundColor: AppColors.background),
                  if (product.editHistory?['previousCategory'] != null && product.editHistory?['previousCategory'] != product.category)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Changed from: ${product.editHistory!['previousCategory']}', style: const TextStyle(color: Colors.orange, fontSize: 10)),
                    ),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'Creator', 
                    value: product.creatorName,
                  ),
                  _InfoSection(
                    title: 'Stock', 
                    value: '${product.stock} Units',
                    previousValue: product.editHistory != null ? '${product.editHistory!['previousStock']} Units' : null,
                  ),
                  _InfoSection(title: 'Dimensions', value: product.dimensions),
                  _InfoSection(title: 'Materials', value: product.materials),
                  
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  _EditableText(
                    label: 'Description',
                    value: product.description,
                    previousValue: product.editHistory?['previousDescription'],
                    style: const TextStyle(color: AppColors.mutedText, height: 1.5),
                  ),

                  if (product.isCustomizable) ...[
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('Customizations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 15),
                    ...product.customizations.map((c) => _buildCustomizationCard(c)),
                  ],

                  const SizedBox(height: 40),
                  const Divider(),
                  const Text('Admin Quality Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  const _CheckItem(label: 'Images are clear and relevant'),
                  const _CheckItem(label: 'Price falls within category norms'),
                  const _CheckItem(label: 'Description is accurate and non-promotional'),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildImageGallery() {
    return Container(
      height: 300,
      width: double.infinity,
      color: AppColors.outline,
      child: product.images.isNotEmpty
          ? PageView.builder(
              itemCount: product.images.length,
              itemBuilder: (context, i) => Image.network(product.images[i], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
            )
          : const Icon(Icons.image, size: 100, color: Colors.grey),
    );
  }

  Widget _buildCustomizationCard(ProductCustomization c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Text('+ ₹${c.additionalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 5),
          Text(c.description, style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
          const SizedBox(height: 12),
          Text('Selection Type: ${c.isMultipleSelection ? "Multiple" : "Single"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Options:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: c.options.map((opt) => Chip(
              label: Text(opt, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          if (c.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(c.images[i], width: 60, height: 60, fit: BoxFit.cover)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<CreatorBloc>().add(CreatorUpdateProductStatus(productId: product.id, status: 'Rejected'));
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                child: const Text('REJECT PRODUCT'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  context.read<CreatorBloc>().add(CreatorUpdateProductStatus(productId: product.id, status: 'Approved'));
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: AppColors.primary),
                child: const Text('APPROVE & PUBLISH'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String value;
  final String? previousValue;
  const _InfoSection({required this.title, required this.value, this.previousValue});

  @override
  Widget build(BuildContext context) {
    final hasChanged = previousValue != null && previousValue != value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 100, child: Text(title, style: const TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w600))),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'N/A', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasChanged ? Colors.orange.shade800 : null,
                  )
                ),
              ),
            ],
          ),
          if (hasChanged)
            Padding(
              padding: const EdgeInsets.only(left: 100, top: 2),
              child: Text('Previous: $previousValue', style: const TextStyle(color: Colors.grey, fontSize: 10, decoration: TextDecoration.lineThrough)),
            ),
        ],
      ),
    );
  }
}

class _EditableText extends StatelessWidget {
  final String label;
  final String value;
  final String? previousValue;
  final TextStyle? style;

  const _EditableText({required this.label, required this.value, this.previousValue, this.style});

  @override
  Widget build(BuildContext context) {
    final hasChanged = previousValue != null && previousValue != value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: style?.copyWith(
            color: hasChanged ? Colors.orange.shade800 : style?.color,
          ) ?? style,
        ),
        if (hasChanged)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Previous $label: $previousValue',
              style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.lineThrough),
            ),
          ),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  const _CheckItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
