import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class CreatorDashboardPage extends StatelessWidget {
  final CreatorProfile profile;

  const CreatorDashboardPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: _CreatorDrawer(profile: profile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(profile: profile),
            const SizedBox(height: 30),
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _QuickActionsGrid(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final CreatorProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.surface,
            backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
            child: profile.profileImage.isEmpty ? const Icon(Icons.person, size: 35, color: AppColors.primary) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(profile.category, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: Colors.white)),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_box_outlined, 'Add Product'),
      (Icons.inventory_2_outlined, 'Listings'),
      (Icons.shopping_bag_outlined, 'Orders'),
      (Icons.payments_outlined, 'Earnings'),
      (Icons.collections_outlined, 'Portfolio'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _DashboardCard(
          icon: actions[index].$1,
          label: actions[index].$2,
          onTap: () {},
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _CreatorDrawer extends StatelessWidget {
  final CreatorProfile profile;
  const _CreatorDrawer({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(profile.name),
            accountEmail: Text(profile.category),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
              child: profile.profileImage.isEmpty ? const Icon(Icons.person) : null,
            ),
          ),
          _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.person_outline, 'Creator Profile', () {}),
          _buildDrawerItem(Icons.inventory_2_outlined, 'Products/Listings', () {}),
          _buildDrawerItem(Icons.add_circle_outline, 'Add Product', () {}),
          _buildDrawerItem(Icons.shopping_bag_outlined, 'Orders', () {}),
          _buildDrawerItem(Icons.payments_outlined, 'Sales/Earnings', () {}),
          _buildDrawerItem(Icons.collections_outlined, 'Portfolio', () {}),
          const Divider(),
          _buildDrawerItem(Icons.settings_outlined, 'Settings', () {}),
          const Spacer(),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          }, color: Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
