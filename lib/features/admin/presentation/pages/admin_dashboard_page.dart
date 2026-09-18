import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Overview',
    'Creator Verifications',
    'Product Approvals',
    'User Management',
    'Moderation',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              // Simulate refresh
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing data...')));
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text('MADEBYHANDS ADMIN', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            _buildDrawerTile(0, Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
            _buildDrawerTile(1, Icons.verified_user_outlined, Icons.verified_user, 'Verifications'),
            _buildDrawerTile(2, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Products'),
            _buildDrawerTile(3, Icons.people_outline, Icons.people, 'Users'),
            _buildDrawerTile(4, Icons.gavel_outlined, Icons.gavel, 'Moderation'),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Admin Settings'),
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewView(),
          _VerificationView(),
          _ProductApprovalView(),
          _UserManagementView(),
          _ModerationView(),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(int index, IconData icon, IconData selectedIcon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppColors.primary : AppColors.mutedText),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.text,
      )),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class _OverviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: 'Total Users', value: '1,284', icon: Icons.people, color: Colors.blue),
              _StatCard(title: 'Active Creators', value: '142', icon: Icons.palette, color: AppColors.primary),
              _StatCard(title: 'Pending Approvals', value: '28', icon: Icons.hourglass_empty, color: AppColors.accent),
              _StatCard(title: 'Total Revenue', value: '₹42,500', icon: Icons.payments, color: Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.notifications_none, size: 20)),
                title: Text('New creator application from "Artisan $index"'),
                subtitle: const Text('2 hours ago'),
                trailing: TextButton(onPressed: () {}, child: const Text('Review')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 25, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Artisan Name $index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Pottery & Ceramics', style: TextStyle(color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    const Chip(label: Text('Pending'), backgroundColor: Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Bio: "Passionate ceramicist with 10 years of experience crafting handmade vases and dinnerware."', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () {}, child: const Text('View Documents')),
                    const SizedBox(width: 10),
                    FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Verify')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductApprovalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.7,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.outline,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Handmade Vase $index', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('by Creator $index', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    const SizedBox(height: 5),
                    const Text('₹1,200', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero), child: const Text('Reject'))),
                        const SizedBox(width: 5),
                        Expanded(child: FilledButton(onPressed: () {}, style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.primary), child: const Text('Approve'))),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _UserManagementView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('User $index'),
          subtitle: Text('user$index@gmail.com'),
          trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        );
      },
    );
  }
}

class _ModerationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.red),
            title: Text('Report #$index: Inappropriate content'),
            subtitle: const Text('Reported by Buyer12 on Product "Handmade Pot"'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
