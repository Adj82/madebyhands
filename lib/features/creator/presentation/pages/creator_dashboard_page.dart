import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/pages/add_product_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_listings_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';

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
            _VerificationBlock(profile: profile),
            const SizedBox(height: 30),
            const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _QuickActionsGrid(profile: profile),
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
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5)),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (profile.verificationStatus == 'Verified')
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                  ],
                ),
                Text(profile.category,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBlock extends StatelessWidget {
  final CreatorProfile profile;
  const _VerificationBlock({required this.profile});

  @override
  Widget build(BuildContext context) {
    final status = profile.verificationStatus;
    if (status == 'Verified') {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: Colors.green),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Your account is officially verified!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreatorVerificationPage(profile: profile)),
                );
              },
              child: const Text('Edit Info', style: TextStyle(decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
    }

    final isInProcess = status == 'In-Process';

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInProcess ? const Color(0xFFFFF3E0) : const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isInProcess ? Colors.orange : Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isInProcess ? Icons.hourglass_top : Icons.error_outline, color: isInProcess ? Colors.orange : Colors.red),
              const SizedBox(width: 10),
              Text(
                isInProcess ? 'Verification In-Process' : 'Get verified to start selling',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isInProcess
                ? 'Your verification documents are currently being reviewed by our admin team. Duplicate requests are blocked.'
                : 'Please submit your official verification details to enable product listings and public storefront visibility.',
            style: const TextStyle(fontSize: 13),
          ),
          if (!isInProcess) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreatorVerificationPage(profile: profile)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Get Started'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final CreatorProfile profile;
  const _QuickActionsGrid({required this.profile});

  void _handleProductAction(BuildContext context, String actionName) {
    if (profile.verificationStatus != 'Verified') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verification Required'),
          content: Text(
            profile.verificationStatus == 'In-Process'
                ? 'Your profile verification is currently In-Process. You will be able to add or publish products once approved by our admin team.'
                : 'You must have verification status "Verified" to add or publish products. Please complete verification first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            if (profile.verificationStatus != 'In-Process')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreatorVerificationPage(profile: profile)),
                  );
                },
                child: const Text('Get Verified'),
              ),
          ],
        ),
      );
      return;
    }

    if (actionName == 'Add Product') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddProductPage(profile: profile)),
      );
    } else if (actionName == 'Listings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatorListingsPage(profile: profile)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionName feature coming soon for verified creators!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_box_outlined, 'Add Product', true),
      (Icons.inventory_2_outlined, 'Listings', true),
      (Icons.shopping_bag_outlined, 'Orders', false),
      (Icons.payments_outlined, 'Earnings', false),
      (Icons.collections_outlined, 'Portfolio', false),
      (Icons.settings_outlined, 'Settings', false),
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
        final act = actions[index];
        return _DashboardCard(
          icon: act.$1,
          label: act.$2,
          onTap: () {
            if (act.$3) {
              _handleProductAction(context, act.$2);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${act.$2} feature coming soon!')),
              );
            }
          },
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

  void _handleProductAction(BuildContext context, String actionName) {
    Navigator.pop(context);
    if (profile.verificationStatus != 'Verified') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verification Required'),
          content: Text(
            profile.verificationStatus == 'In-Process'
                ? 'Your profile verification is currently In-Process. You will be able to add or publish products once approved by our admin team.'
                : 'You must have verification status "Verified" to add or publish products. Please complete verification first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (actionName == 'Add Product') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddProductPage(profile: profile)),
      );
    } else if (actionName == 'Listings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatorListingsPage(profile: profile)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionName feature coming soon for verified creators!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Row(
              children: [
                Text(profile.name),
                if (profile.verificationStatus == 'Verified')
                  const Padding(
                    padding: EdgeInsets.only(left: 6.0),
                    child: Icon(Icons.verified, color: Colors.white, size: 16),
                  ),
              ],
            ),
            accountEmail: Text(profile.category),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profile.profileImage.isNotEmpty ? NetworkImage(profile.profileImage) : null,
              child: profile.profileImage.isEmpty ? const Icon(Icons.person) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Creator Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products/Listings'),
            onTap: () => _handleProductAction(context, 'Listings'),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Product'),
            onTap: () => _handleProductAction(context, 'Add Product'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Orders'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Sales/Earnings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.collections_outlined),
            title: const Text('Portfolio'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
