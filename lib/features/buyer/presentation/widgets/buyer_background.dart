import 'package:flutter/material.dart';

class BuyerBackground extends StatelessWidget {
  final Widget child;

  const BuyerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/main_page_elements/mbh_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
