import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin & Manager Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdminDialog(context, isSuperAdmin),
        backgroundColor: isSuperAdmin ? AppColors.primary : Colors.grey,
        icon: Icon(isSuperAdmin ? Icons.person_add : Icons.lock_outline),
        label: Text(isSuperAdmin ? 'Grant Admin / Manager Access' : 'Grant Access (Locked)'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading accounts: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          final List<UserEntity> allAdmins = docs.map<UserEntity>((doc) {
            final data = doc.data();
            return UserEntity(
              uid: doc.id,
              email: data['email'] as String? ?? '',
              name: data['name'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              role: data['role'] as String? ?? 'buyer',
              isVerified: data['isVerified'] as bool? ?? false,
              isSuspended: data['isSuspended'] as bool? ?? false,
            );
          }).where((u) => u.isAdminOrManager).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(AdminFetchAdminsRequested());
            },
            child: allAdmins.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: const Text(
                          'No administrative or manager accounts found.\nTap "Grant Access" to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: allAdmins.length,
                    itemBuilder: (context, index) {
                      final admin = allAdmins[index];
                      final isRoot = UserEntity.presetSuperAdminEmails.contains(admin.email.toLowerCase().trim());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isRoot
                                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    isRoot ? Icons.verified_user : Icons.admin_panel_settings_outlined,
                                    color: isRoot ? const Color(0xFFB8860B) : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        admin.name.isEmpty ? 'Admin Account' : admin.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        admin.email,
                                        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRoot && isSuperAdmin)
                                  PopupMenuButton<String>(
                                    tooltip: 'Manage Access',
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(
                                          children: [
                                            Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                                            SizedBox(width: 8),
                                            Text('Change Role'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'demote_buyer',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 18, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('Demote to Buyer'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'change_role') {
                                        _showChangeRoleDialog(context, admin);
                                      } else if (val == 'demote_buyer') {
                                        _changeUserRole(context, admin, 'buyer');
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRoot
                                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                        : admin.isSuperAdmin
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : Colors.teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isRoot
                                          ? const Color(0xFFDAA520)
                                          : admin.isSuperAdmin
                                              ? AppColors.primary
                                              : Colors.teal,
                                    ),
                                  ),
                                  child: Text(
                                    isRoot ? 'ROOT SUPER ADMIN' : admin.roleDisplay.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isRoot
                                          ? const Color(0xFFB8860B)
                                          : admin.isSuperAdmin
                                              ? AppColors.primary
                                              : Colors.teal.shade800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  static void _changeUserRole(BuildContext context, UserEntity targetUser, String newRole) async {
    final messenger = ScaffoldMessenger.of(context);
    final roleName = newRole == 'super_admin'
        ? 'Super Admin'
        : newRole == 'manager'
            ? 'Operational Manager'
            : newRole == 'creator'
                ? 'Creator / Seller'
                : 'Buyer';

    try {
      await FirebaseFirestore.instance.collection('users').doc(targetUser.uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        context.read<AdminBloc>().add(AdminChangeUserRoleRequested(targetUser.uid, newRole));
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Successfully updated role for ${targetUser.name} to $roleName.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  void _showChangeRoleDialog(BuildContext context, UserEntity targetUser) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Change Role for ${targetUser.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Full control over financials, payouts, and roles'),
              onTap: () {
                Navigator.pop(dialogContext);
                _changeUserRole(context, targetUser, 'super_admin');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.teal),
              title: const Text('Operational Manager', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Manages orders, verifications, products, and support'),
              onTap: () {
                Navigator.pop(dialogContext);
                _changeUserRole(context, targetUser, 'manager');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('General Buyer'),
              subtitle: const Text('Revoke administrative access'),
              onTap: () {
                Navigator.pop(dialogContext);
                _changeUserRole(context, targetUser, 'buyer');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, bool isSuperAdmin) {
    if (!isSuperAdmin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Access Restricted'),
            ],
          ),
          content: const Text(
            'Operational Managers cannot add or grant administrative credentials.\n\nOnly Super Admins have authority to manage administrative roles.',
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

    final emailController = TextEditingController();
    String selectedRole = 'manager';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Grant Admin Access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the email address of a registered user to grant administrative access.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'User Email Address',
                    hintText: 'user@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Role Designation',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text('Manager (Operational)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super Admin (Full Access)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final emailInput = emailController.text.trim().toLowerCase();
                if (emailInput.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);

                try {
                  final query = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: emailInput)
                      .get();

                  if (query.docs.isEmpty) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('No registered user account found with email "$emailInput". User must register first.')),
                    );
                    return;
                  }

                  final targetDoc = query.docs.first;
                  await targetDoc.reference.update({
                    'role': selectedRole,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    context.read<AdminBloc>().add(AdminChangeUserRoleRequested(targetDoc.id, selectedRole));
                  }

                  final roleName = selectedRole == 'super_admin' ? 'Super Admin' : 'Operational Manager';
                  messenger.showSnackBar(
                    SnackBar(content: Text('Granted $roleName access to $emailInput.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to grant administrative access: $e')),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }
}
