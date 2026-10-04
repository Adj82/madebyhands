import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';

/// A heading in the Home tab's style ("Historical Art & Stories"): heavy
/// Montserrat in deep maroon. Pass a lighter [weight] and [BuyerColors.ink]
/// for names and titles inside cards.
class BuyerHeading extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final int? maxLines;
  final TextAlign? textAlign;

  const BuyerHeading(
    this.text, {
    super.key,
    this.size = 17,
    this.color = BuyerColors.maroonDeep,
    this.weight = FontWeight.w900,
    this.maxLines,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    textAlign: textAlign,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: size,
      color: color,
      fontWeight: weight,
    ),
  );
}

/// The title block at the top of a buyer tab: a heading and an optional line
/// of supporting text, left-aligned like the headings on Home.
class BuyerPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BuyerPageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      BuyerHeading(title, size: 22),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: BuyerColors.body,
          ),
        ),
      ],
    ],
  );
}
