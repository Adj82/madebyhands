import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class ProductReviewPage extends StatelessWidget {
  final int index;
  const ProductReviewPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Review'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.flag_outlined, color: Colors.red)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Gallery Placeholder
            Container(
              height: 300,
              width: double.infinity,
              color: AppColors.outline,
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Handmade Ceramic Vase',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹1,200',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Chip(label: Text('Pottery'), backgroundColor: AppColors.background),
                  const SizedBox(height: 20),
                  const _InfoSection(title: 'Creator', value: 'Artisan #12 (Verified)'),
                  const _InfoSection(title: 'Stock', value: '15 Units'),
                  const _InfoSection(title: 'Dimensions', value: '12 x 8 x 8 inches'),
                  const _InfoSection(title: 'Materials', value: 'Organic Clay, Natural Glaze'),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'This beautiful vase is handcrafted using traditional techniques. Each piece is unique with its own natural variations in glaze and texture. Perfect for dry flowers or as a standalone art piece.',
                    style: TextStyle(color: AppColors.mutedText, height: 1.5),
                  ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('REJECT PRODUCT'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('APPROVE & PUBLISH'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String value;
  const _InfoSection({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
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
