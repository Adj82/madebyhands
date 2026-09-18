import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';

void main() {
  runApp(const BuyerPreviewApp());
}

class BuyerPreviewApp extends StatelessWidget {
  const BuyerPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MadeByHands Buyer Preview',
      theme: AppTheme.lightThemeMode,
      home: BuyerDashboardPage(
        user: UserEntity(
          uid: 'buyer-preview',
          email: 'suhani@buyer.preview',
          name: 'Suhani',
          role: 'buyer',
        ),
        onLogout: () {},
      ),
    );
  }
}
