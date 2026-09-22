import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_earnings_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_home_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_orders_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_products_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_profile_view.dart';
import 'package:madebyhands/init_dependencies.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

class CreatorDashboardPage extends StatefulWidget {
  final CreatorProfile profile;

  const CreatorDashboardPage({super.key, required this.profile});

  @override
  State<CreatorDashboardPage> createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends State<CreatorDashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      CreatorHomeView(profile: widget.profile),
      CreatorProductsView(profile: widget.profile),
      CreatorOrdersView(profile: widget.profile),
      CreatorEarningsView(
        creatorId: widget.profile.uid,
        repository: serviceLocator(),
      ),
      CreatorProfileView(profile: widget.profile),
    ];
  }

  static const List<String> _titles = [
    'Artisan Dashboard',
    'My Products',
    'Manage Orders',
    'Earnings',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SupportCenterPage(
                  user: UserEntity(
                    uid: widget.profile.uid,
                    email: '',
                    name: widget.profile.name,
                    role: 'creator',
                  ),
                  repository: serviceLocator(),
                ),
              ),
            ),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _views),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedText,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
