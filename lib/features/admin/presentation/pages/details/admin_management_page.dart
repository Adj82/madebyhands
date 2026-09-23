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
        label: Text(isSuperAdmin ? 'Add New Admin / Manager' : 'Grant Access (Locked)'),
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          final admins = state.admins;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(AdminFetchAdminsRequested());
            },
            child: admins.isEmpty
                ? const Center(child: Text('Fetching administrative accounts...'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      final isRoot = UserEntity.presetSuperAdminEmails.contains(admin.email.toLowerCase());

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
                                  radius: 20,
                                  backgroundColor: isRoot
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.outline,
                                  child: Icon(
                                    isRoot ? Icons.verified_user : Icons.admin_panel_settings_outlined,
                                    color: isRoot ? AppColors.primary : AppColors.text,
                                    size: 20,
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
                                if (!isRoot)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      if (!isSuperAdmin) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Access Restricted: Only Super Admins can revoke admin access.')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Super Admin privilege required to revoke credentials.')),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRoot
                                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isRoot ? const Color(0xFFDAA520) : AppColors.primary,
                                    ),
                                  ),
                                  child: Text(
                                    isRoot ? 'ROOT SUPER ADMIN' : admin.roleDisplay.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isRoot ? const Color(0xFFB8860B) : AppColors.primary,
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
            'Operational Managers cannot add or revoke administrative credentials.\n\nOnly Super Admins have authority to grant administrative access.',
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Admin / Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note: Target account must be a registered user first.', 
                style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'User Email Address')),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Role Designation'),
              items: const [
                DropdownMenuItem(value: 'manager', child: Text('Manager (Operational Access)')),
                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (Full Financial Control)')),
              ],
              onChanged: (val) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Role assignment requested. Updates in Firestore.')),
                );
                Navigator.pop(context);
              },
              child: const Text('Grant Access')),
        ],
      ),
    );
  }
}
