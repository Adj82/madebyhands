import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class DocItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLink;
  
  const DocItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(isLink ? Icons.link : Icons.description, color: AppColors.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.open_in_new, size: 20)),
        ],
      ),
    );
  }
}
