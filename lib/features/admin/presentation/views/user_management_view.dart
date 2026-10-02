import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/creator_profile_review_page.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _users = FirebaseFirestore
      .instance
      .collection('users')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Buyers'),
            Tab(text: 'Creators'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _users,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Could not load users: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final users = snapshot.data!.docs.map((doc) {
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
            }).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return TabBarView(
              children: [
                _UserList(
                  users: users
                      .where((u) => !u.isCreator && !u.isAdminOrManager)
                      .toList(),
                  emptyMessage: 'No buyers registered yet.',
                ),
                _UserList(
                  users: users.where((u) => u.isCreator).toList(),
                  emptyMessage: 'No creators registered yet.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<UserEntity> users;
  final String emptyMessage;

  const _UserList({required this.users, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: users.length,
      itemBuilder: (context, index) => _UserTile(user: users[index]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isCreator = user.isCreator;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: user.isSuspended ? Colors.red.shade50 : AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () => _viewProfile(context),
        leading: CircleAvatar(
          backgroundColor: isCreator
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.outline,
          child: Icon(
            isCreator ? Icons.palette : Icons.person,
            size: 20,
            color: isCreator ? AppColors.primary : AppColors.mutedText,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name.isEmpty ? 'Unnamed user' : user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (user.isVerified)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.verified, size: 16, color: AppColors.primary),
              ),
            if (user.isSuspended)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.block, size: 16, color: Colors.red),
              ),
          ],
        ),
        subtitle: Text(
          user.isSuspended ? '${user.email}\nSuspended' : user.email,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View profile')),
            PopupMenuItem(
              value: 'suspend',
              child: Text(
                user.isSuspended ? 'Reinstate user' : 'Suspend user',
                style: TextStyle(
                  color: user.isSuspended ? Colors.green : Colors.redAccent,
                ),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _viewProfile(context);
            } else {
              _confirmSuspend(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmSuspend(BuildContext context) async {
    final adminBloc = context.read<AdminBloc>();
    final suspend = !user.isSuspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspend ? 'Suspend ${user.name}?' : 'Reinstate ${user.name}?'),
        content: Text(
          suspend
              ? 'They will be signed out of the marketplace and cannot buy or sell until reinstated.'
              : 'They will regain access to the marketplace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: suspend
                ? FilledButton.styleFrom(backgroundColor: Colors.redAccent)
                : null,
            child: Text(suspend ? 'Suspend' : 'Reinstate'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      adminBloc.add(AdminSuspendUserRequested(user.uid, suspend));
    }
  }

  Future<void> _viewProfile(BuildContext context) async {
    if (user.isCreator) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('creator_profiles')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data == null) {
          messenger.showSnackBar(
            SnackBar(content: Text('${user.name} has not set up a creator profile yet.')),
          );
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (_) => CreatorProfileReviewPage(
              profile: CreatorProfileModel.fromJson(data, doc.id),
            ),
          ),
        );
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.isEmpty ? 'Unnamed user' : user.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _detail(Icons.email_outlined, user.email.isEmpty ? 'No email' : user.email),
            _detail(Icons.phone_outlined, user.phone.isEmpty ? 'No phone number' : user.phone),
            _detail(Icons.badge_outlined, user.roleDisplay),
            _detail(
              user.isSuspended ? Icons.block : Icons.check_circle_outline,
              user.isSuspended ? 'Suspended' : 'Active',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
