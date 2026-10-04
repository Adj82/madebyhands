import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

class BuyerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BuyerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: BuyerColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: BuyerColors.gold, width: 1.1),
            ),
            child: Icon(icon, size: 42, color: BuyerColors.maroon),
          ),
          const SizedBox(height: 18),
          BuyerHeading(title, size: 20, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BuyerColors.body, height: 1.45),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}
