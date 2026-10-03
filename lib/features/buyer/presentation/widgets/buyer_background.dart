import 'package:flutter/material.dart';

class BuyerBackground extends StatelessWidget {
  final Widget child;

  const BuyerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFFFF4F2), child: child);
  }
}
