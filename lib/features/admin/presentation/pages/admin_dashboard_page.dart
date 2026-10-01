import 'package:cloud_firestore/cloud_firestore.dart';
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
    'User Management & Deletions',
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
              _buildAdminNotificationBell(context),
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
                          Icons.people, 'Users & Deletions', selectedIndex),
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

  Widget _buildAdminNotificationBell(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
      builder: (context, snapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('support_tickets')
              .snapshots(),
          builder: (context, ticketSnapshot) {
            int unreadCount = 0;
            final List<Map<String, dynamic>> adminNotifications = [];
            final Set<String> addedTicketIds = {};

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data();
                final type = data['type'] as String? ?? 'general';
                final isRead = data['isRead'] as bool? ?? false;

                if (type == 'admin' || type == 'general' || data['category'] == 'deletion_request') {
                  adminNotifications.add({'id': doc.id, ...data});
                  if (data['ticketId'] != null) addedTicketIds.add(data['ticketId'] as String);
                  if (!isRead) unreadCount++;
                }
              }
            }

            // Stream deletion support tickets directly so deletion requests NEVER miss!
            if (ticketSnapshot.hasData && ticketSnapshot.data!.docs.isNotEmpty) {
              for (var doc in ticketSnapshot.data!.docs) {
                final data = doc.data();
                final requestStatus = data['requestStatus'] as String? ?? 'Pending';
                final status = data['status'] as String? ?? 'open';
                final isDeletionTicket = data['type'] == 'account_deletion' ||
                    data['subject'] == 'Account Deletion Request';

                if (isDeletionTicket && requestStatus == 'Pending' && status == 'open' && !addedTicketIds.contains(doc.id)) {
                  adminNotifications.add({
                    'id': doc.id,
                    'type': 'admin',
                    'category': 'deletion_request',
                    'title': 'Account Deletion Request ⚠️',
                    'message': '${data['userName'] ?? "User"} requested account deletion. Reason: "${data['reason'] ?? data['lastMessage'] ?? "N/A"}"',
                    'targetId': data['userId'],
                    'ticketId': doc.id,
                    'isRead': false,
                  });
                  unreadCount++;
                }
              }
            }

            return IconButton(
              tooltip: 'Admin Notifications',
              onPressed: () => _showAdminNotificationsModal(context, adminNotifications),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_outlined),
              ),
            );
          },
        );
      },
    );
  }

  void _showAdminNotificationsModal(
    BuildContext context,
    List<Map<String, dynamic>> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Admin Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Text('No system notifications at the moment.', style: TextStyle(color: AppColors.mutedText)),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final id = item['id'] as String;
                        final title = item['title'] as String? ?? 'System Alert';
                        final message = item['message'] as String? ?? '';
                        final category = item['category'] as String? ?? 'general';
                        final isRead = item['isRead'] as bool? ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isRead ? AppColors.surface : Colors.red.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: category == 'deletion_request' ? Colors.red : AppColors.primary,
                              child: Icon(
                                category == 'deletion_request' ? Icons.warning_amber_rounded : Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            trailing: category == 'deletion_request'
                                ? FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                    onPressed: () {
                                      Navigator.pop(modalContext);
                                      context.read<AdminCubit>().changePage(5); // Users & Deletions tab
                                    },
                                    child: const Text('Review', style: TextStyle(fontSize: 11)),
                                  )
                                : IconButton(
                                    icon: Icon(isRead ? Icons.check_circle : Icons.circle_outlined, size: 20, color: isRead ? Colors.green : Colors.grey),
                                    onPressed: () {
                                      try {
                                        FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': !isRead});
                                      } catch (_) {}
                                    },
                                  ),
                            onTap: () {
                              try {
                                FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': true});
                              } catch (_) {}
                              Navigator.pop(modalContext);
                              if (category == 'deletion_request') {
                                context.read<AdminCubit>().changePage(5);
                              } else if (category == 'verification') {
                                context.read<AdminCubit>().changePage(1);
                              } else if (category == 'product') {
                                context.read<AdminCubit>().changePage(2);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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
