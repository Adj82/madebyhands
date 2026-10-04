import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_log_entry.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_log_repository.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/init_dependencies.dart';

/// Lists super admins and managers. Only super admins may change roles;
/// `firestore.rules` enforces the same restriction.
class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _staff = FirebaseFirestore
      .instance
      .collection('users')
      .where('role', whereIn: const ['admin', 'super_admin', 'manager'])
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select<AuthBloc, UserEntity?>((bloc) {
      final state = bloc.state;
      return state is AuthSuccess ? state.user : null;
    });
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Admins & managers')),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _showGrantDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Grant access'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _staff,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load accounts: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final admins = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return UserEntity(
              uid: doc.id,
              email: data['email'] as String? ?? '',
              name: data['name'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              role: data['role'] as String? ?? 'buyer',
            );
          }).toList();

          if (admins.isEmpty) {
            return const Center(
              child: Text(
                'No admin or manager accounts found.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final isRoot = UserEntity.presetSuperAdminEmails.contains(
                admin.email.toLowerCase().trim(),
              );
              final canManage =
                  isSuperAdmin && !isRoot && admin.uid != currentUser?.uid;
              final badgeColor = isRoot
                  ? const Color(0xFFB8860B)
                  : admin.isSuperAdmin
                  ? AppColors.primary
                  : Colors.teal.shade700;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: badgeColor.withValues(alpha: 0.12),
                    child: Icon(
                      isRoot ? Icons.verified_user : Icons.admin_panel_settings_outlined,
                      color: badgeColor,
                    ),
                  ),
                  title: Text(
                    admin.name.isEmpty ? 'Admin account' : admin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRoot ? 'ROOT SUPER ADMIN' : admin.roleDisplay.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: canManage
                      ? PopupMenuButton<String>(
                          tooltip: 'Change role',
                          onSelected: (role) => _changeRole(context, admin, role),
                          itemBuilder: (context) => [
                            if (!admin.isSuperAdmin)
                              const PopupMenuItem(
                                value: 'super_admin',
                                child: Text('Make super admin'),
                              ),
                            if (!admin.isManager)
                              const PopupMenuItem(
                                value: 'manager',
                                child: Text('Make manager'),
                              ),
                            const PopupMenuItem(
                              value: 'buyer',
                              child: Text('Revoke admin access'),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _roleName(String role) => switch (role) {
    'super_admin' => 'Super Admin',
    'manager' => 'Manager',
    _ => 'Buyer',
  };

  Future<void> _changeRole(BuildContext context, UserEntity user, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await serviceLocator<AdminLogRepository>().log(
        category: AdminLogCategory.access,
        action: 'access.role_changed',
        summary:
            'Changed the role of ${user.name.isEmpty ? user.email : '${user.name} (${user.email})'} to ${_roleName(role)}.',
        targetId: user.uid,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('${user.name.isEmpty ? user.email : user.name} is now ${_roleName(role)}.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  Future<void> _showGrantDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final emailController = TextEditingController();
    var selectedRole = 'manager';

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Grant admin access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The person must already have signed in to MadeByHands once.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'manager', child: Text('Manager (operations)')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super admin (full access)')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedRole = value);
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
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(dialogContext, (email, selectedRole));
              },
              child: const Text('Grant access'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final (email, role) = result;

    try {
      final users = FirebaseFirestore.instance.collection('users');
      final candidates = {email, email.toLowerCase()}.toList();
      final query = await users.where('email', whereIn: candidates).limit(1).get();
      if (query.docs.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('No account found for $email. Ask them to sign in first.')),
        );
        return;
      }
      await query.docs.first.reference.update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await serviceLocator<AdminLogRepository>().log(
        category: AdminLogCategory.access,
        action: 'access.granted',
        summary: 'Granted ${_roleName(role)} access to $email.',
        targetId: query.docs.first.id,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Granted ${_roleName(role)} access to $email.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }
}
