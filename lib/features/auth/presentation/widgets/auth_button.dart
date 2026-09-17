import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(395, 55),
        backgroundColor: const Color.fromRGBO(107, 142, 35, 1), // Sage Green
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
    );
  }
}
