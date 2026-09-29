import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_cubit.dart';
import 'package:madebyhands/features/admin/presentation/views/admin_settings_view.dart';
import 'package:madebyhands/features/admin/presentation/views/category_management_view.dart';
import 'package:madebyhands/features/admin/presentation/views/finance_view.dart';
import 'package:madebyhands/features/admin/presentation/views/order_management_view.dart';
import 'package:madebyhands/features/admin/presentation/views/overview_view.dart';
import 'package:madebyhands/features/admin/presentation/views/product_approval_view.dart';
import 'package:madebyhands/features/admin/presentation/views/support_tickets_view.dart';
import 'package:madebyhands/features/admin/presentation/views/verification_view.dart';
import 'package:madebyhands/features/admin/presentation/views/user_management_view.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  final UserEntity? currentUser;

  const AdminDashboardPage({super.key, this.currentUser});

  static const List<String> _titles = [
    'Overview',
    'Creator Verifications',
    'Product Approvals',
    'Categories',
    'Orders',
    'User Management',
    'Support Tickets',
    'Payouts & Finance',
    'Admin Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = currentUser ?? (authState is AuthSuccess ? authState.user : null);
    final isSuperAdmin = user?.isSuperAdmin ?? true;

    return BlocBuilder<AdminCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_titles[selectedIndex],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            actions: [
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
                        const Icon(Icons.admin_panel_settings,
                            size: 44, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('MADEBYHANDS ADMIN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSuperAdmin
                                ? const Color(0xFFFFD700).withValues(alpha: 0.25)
                                : Colors.teal.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSuperAdmin ? const Color(0xFFFFD700) : Colors.tealAccent,
                            ),
                          ),
                          child: Text(
                            isSuperAdmin ? 'SUPER ADMIN' : 'MANAGER (OPERATIONAL)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSuperAdmin ? const Color(0xFFFFD700) : Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerTile(context, 0, Icons.dashboard_outlined,
                          Icons.dashboard, 'Overview', selectedIndex),
                      _buildDrawerTile(
                          context,
                          1,
                          Icons.verified_user_outlined,
                          Icons.verified_user,
                          'Verifications',
                          selectedIndex),
                      _buildDrawerTile(
                          context,
                          2,
                          Icons.shopping_bag_outlined,
                          Icons.shopping_bag,
                          'Products',
                          selectedIndex),
                      _buildDrawerTile(context, 3, Icons.category_outlined,
                          Icons.category, 'Categories', selectedIndex),
                      _buildDrawerTile(context, 4, Icons.receipt_long_outlined,
                          Icons.receipt_long, 'Orders', selectedIndex),
                      _buildDrawerTile(context, 5, Icons.people_outline,
                          Icons.people, 'Users', selectedIndex),
                      _buildDrawerTile(
                          context,
                          6,
                          Icons.support_agent_outlined,
                          Icons.support_agent,
                          'Support',
                          selectedIndex),
                      _buildDrawerTile(
                          context,
                          7,
                          isSuperAdmin ? Icons.account_balance_wallet_outlined : Icons.lock_outlined,
                          isSuperAdmin ? Icons.account_balance_wallet : Icons.lock,
                          isSuperAdmin ? 'Payouts & Finance' : 'Payouts (Super Admin)',
                          selectedIndex,
                          isRestricted: !isSuperAdmin),
                      _buildDrawerTile(context, 8, Icons.settings_outlined,
                          Icons.settings, 'Settings', selectedIndex),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Logged in as: ${user?.name ?? "Admin"} (${user?.roleDisplay ?? "Admin"})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: const [
              OverviewView(),
              VerificationView(),
              ProductApprovalView(),
              CategoryManagementView(),
              OrderManagementView(),
              UserManagementView(),
              SupportTicketsView(),
              FinanceView(),
              AdminSettingsView(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerTile(
    BuildContext context,
    int index,
    IconData icon,
    IconData selectedIcon,
    String title,
    int selectedIndex, {
    bool isRestricted = false,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isRestricted
            ? Colors.orange.shade700
            : (isSelected ? AppColors.primary : AppColors.mutedText),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.text,
        ),
      ),
      trailing: isRestricted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text('RESTRICTED', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
            )
          : null,
      selected: isSelected,
      onTap: () {
        context.read<AdminCubit>().changePage(index);
        Navigator.pop(context);
      },
    );
  }
}
