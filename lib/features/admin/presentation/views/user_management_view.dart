import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Buyers'),
            Tab(text: 'Sellers / Creators'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading users: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final docs = snapshot.data?.docs ?? [];
            final allUsers = docs.map((doc) {
              final data = doc.data();
              return UserEntity(
                uid: doc.id,
                email: data['email'] as String? ?? '',
                name: data['name'] as String? ?? '',
                phone: data['phone'] as String? ?? '',
                role: data['role'] as String? ?? 'buyer',
                isVerified: data['isVerified'] as bool? ?? false,
                isSuspended: data['isSuspended'] as bool? ?? false,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList();

            final buyers = allUsers.where((u) => u.role == 'buyer').toList();
            final creators = allUsers.where((u) => u.role == 'creator' || u.role == 'seller').toList();

            return TabBarView(
              children: [
                _buildUserList(context, buyers, 'No buyers registered yet.'),
                _buildUserList(context, creators, 'No creators registered yet.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<UserEntity> users, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(AdminLoadDataRequested());
      },
      child: users.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 400,
                  alignment: Alignment.center,
                  child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isCreator = user.role == 'creator' || user.role == 'seller';
                final isVerified = user.isVerified;
                final isSuspended = user.isSuspended;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isSuspended ? Colors.red.shade50 : AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: isCreator ? AppColors.primary.withValues(alpha: 0.15) : AppColors.outline,
                      child: Icon(isCreator ? Icons.palette : Icons.person,
                          size: 20, color: isCreator ? AppColors.primary : AppColors.mutedText),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(user.name.isEmpty ? 'Anonymous User' : user.name, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ),
                        if (isSuspended)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.block, size: 16, color: Colors.red),
                          ),
                      ],
                    ),
                    subtitle: Text('${user.email}\nRole: ${user.roleDisplay.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('View Profile')),
                        PopupMenuItem(
                            value: 'suspend', 
                            child: Text(isSuspended ? 'Unsuspend User' : 'Suspend User', 
                                style: TextStyle(color: isSuspended ? Colors.green : Colors.redAccent))),
                        const PopupMenuItem(value: 'role', child: Text('Change Role')),
                      ],
                      onSelected: (val) {
                        if (val == 'view') {
                          _viewProfile(context, user);
                        } else if (val == 'suspend') {
                          context.read<AdminBloc>().add(AdminSuspendUserRequested(user.uid, !isSuspended));
                        } else if (val == 'role') {
                          _showChangeRoleDialog(context, user);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewProfile(BuildContext context, UserEntity user) {
    if (user.role == 'creator' || user.role == 'seller') {
       context.read<CreatorBloc>().add(CreatorCheckProfileExists(user.uid));
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Creator profile details for ${user.name}')),
       );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Buyer account details for ${user.name}')),
       );
    }
  }

  void _showChangeRoleDialog(BuildContext context, UserEntity user) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? true;

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
            'Operational Managers cannot modify user roles or grant administrative access.\n\nOnly Super Admins have permission to manage and reassign user roles.',
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

    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Buyer'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'buyer'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Creator / Seller'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'creator'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Operational Manager'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'manager'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Super Admin'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'super_admin'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
