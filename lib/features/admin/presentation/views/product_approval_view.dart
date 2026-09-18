import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class ProductApprovalView extends StatelessWidget {
  const ProductApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.7,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          clipBehavior: Clip.antiAlias,
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
                    Text('Handmade Vase $index',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('by Creator $index',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    const SizedBox(height: 5),
                    const Text('₹1,200', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text('Reject'))),
                        const SizedBox(width: 5),
                        Expanded(
                            child: FilledButton(
                                onPressed: () {},
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
        );
      },
    );
  }
}
