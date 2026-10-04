import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';

/// The backdrop shared by every buyer screen. It also applies [BuyerTheme],
/// so anything built underneath — including dialogs and bottom sheets opened
/// from it — picks up the buyer fonts, buttons, fields and cards.
class BuyerBackground extends StatelessWidget {
  final Widget child;

  const BuyerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: BuyerTheme.data,
      child: ColoredBox(color: BuyerColors.paper, child: child),
    );
  }
}
