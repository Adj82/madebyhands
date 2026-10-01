import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';
import 'package:madebyhands/init_dependencies.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Buyers'),
            Tab(text: 'Sellers / Creators'),
            Tab(text: 'Deletion Requests'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('support_tickets').snapshots(),
              builder: (context, ticketSnapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading users: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];
                final List<UserEntity> allUsers = docs.map<UserEntity>((doc) {
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
                }).toList();

                final buyers = allUsers.where((u) => u.role == 'buyer').toList();
                final creators = allUsers.where((u) => u.role == 'creator' || u.role == 'seller').toList();

                // Combine deletion requests from Users collection and Support Tickets collection
                final Map<String, Map<String, dynamic>> combinedDeletions = {};

                // Source 1: Users collection (isDeletionRequested == true)
                for (var doc in docs) {
                  final data = doc.data();
                  if (data['isDeletionRequested'] == true) {
                    combinedDeletions[doc.id] = {
                      'uid': doc.id,
                      'name': data['name'] as String? ?? 'User',
                      'email': data['email'] as String? ?? '',
                      'role': (data['role'] as String? ?? 'buyer').toUpperCase(),
                      'reason': data['deletionReason'] as String? ?? 'User requested account deletion',
                      'ticketId': null,
                    };
                  }
                }

                // Source 2: Support Tickets collection (Account Deletion Requests)
                if (ticketSnapshot.hasData && ticketSnapshot.data!.docs.isNotEmpty) {
                  for (var doc in ticketSnapshot.data!.docs) {
                    final data = doc.data();
                    final reqStatus = data['requestStatus'] as String? ?? 'Pending';
                    final status = data['status'] as String? ?? 'open';
                    final isDeletionTicket = data['type'] == 'account_deletion' || data['subject'] == 'Account Deletion Request';

                    if (isDeletionTicket && reqStatus == 'Pending' && status == 'open') {
                      final userId = data['userId'] as String? ?? '';
                      if (userId.isNotEmpty) {
                        combinedDeletions[userId] = {
                          'uid': userId,
                          'name': data['userName'] as String? ?? 'User',
                          'email': data['userEmail'] as String? ?? '',
                          'role': (data['userRole'] as String? ?? 'creator').toUpperCase(),
                          'reason': data['reason'] as String? ?? data['lastMessage'] as String? ?? 'User requested account deletion',
                          'ticketId': doc.id,
                        };
                      }
                    }
                  }
                }

                final deletionRequests = combinedDeletions.values.toList();

                return TabBarView(
                  children: [
                    _buildUserList(context, buyers, 'No buyers registered yet.'),
                    _buildUserList(context, creators, 'No creators registered yet.'),
                    _buildDeletionRequestsList(context, deletionRequests),
                  ],
                );
              },
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
                      ],
                      onSelected: (val) {
                        if (val == 'view') {
                          _viewProfile(context, user);
                        } else if (val == 'suspend') {
                          context.read<AdminBloc>().add(AdminSuspendUserRequested(user.uid, !isSuspended));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDeletionRequestsList(BuildContext context, List<Map<String, dynamic>> deletionRequests) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(AdminLoadDataRequested());
      },
      child: deletionRequests.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 400,
                  alignment: Alignment.center,
                  child: const Text('No pending account deletion requests.', style: TextStyle(color: AppColors.mutedText)),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: deletionRequests.length,
              itemBuilder: (context, index) {
                final user = deletionRequests[index];
                final uid = user['uid'] as String;
                final name = user['name'] as String? ?? 'User';
                final email = user['email'] as String? ?? '';
                final role = (user['role'] as String? ?? 'BUYER').toUpperCase();
                final reason = user['reason'] as String? ?? 'User requested account deletion';
                final ticketId = user['ticketId'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade200, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? name : 'User Account',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                                  ),
                                  Text(
                                    '$email · $role',
                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DELETION REQUESTED',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            'Reason: "$reason"',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  if (ticketId != null && ticketId.isNotEmpty) {
                                    final supportRepo = serviceLocator<SupportRepository>();
                                    await supportRepo.rejectAccountDeletion(
                                      ticketId: ticketId,
                                      creatorUid: uid,
                                      rejectionReason: 'Rejected by Admin',
                                    );
                                  } else {
                                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                      'isDeletionRequested': false,
                                    });
                                  }
                                  messenger.showSnackBar(SnackBar(content: Text('Cancelled deletion request for $email.')));
                                } catch (e) {
                                  try {
                                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                      'isDeletionRequested': false,
                                    });
                                    messenger.showSnackBar(SnackBar(content: Text('Cancelled deletion request for $email.')));
                                  } catch (err) {
                                    messenger.showSnackBar(SnackBar(content: Text('Error: $err')));
                                  }
                                }
                              },
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject Request'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                foregroundColor: AppColors.text,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _confirmAccountDeletion(
                                context,
                                uid: uid,
                                name: name,
                                email: email,
                                ticketId: ticketId,
                              ),
                              icon: const Icon(Icons.delete_forever, size: 16),
                              label: const Text('Approve & Delete Account'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmAccountDeletion(
    BuildContext context, {
    required String uid,
    required String name,
    required String email,
    String? ticketId,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Permanently Delete $name?'),
        content: Text(
          'Are you sure you want to permanently delete the account for $name ($email)?\n\nThis will remove their user document and creator profile from Cloud Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);

              try {
                if (ticketId != null && ticketId.isNotEmpty) {
                  try {
                    final supportRepo = serviceLocator<SupportRepository>();
                    await supportRepo.approveAccountDeletion(
                      ticketId: ticketId,
                      creatorUid: uid,
                    );
                  } catch (_) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                    await FirebaseFirestore.instance.collection('creator_profiles').doc(uid).delete();
                  }
                } else {
                  await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                  await FirebaseFirestore.instance.collection('creator_profiles').doc(uid).delete();
                }

                messenger.showSnackBar(
                  SnackBar(content: Text('Account for $email has been permanently deleted.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete account: $e')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
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
}
