import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
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
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            return TabBarView(
              children: [
                _buildUserList(context, state.buyers, 'No buyers registered yet.'),
                _buildUserList(context, state.creators, 'No creators registered yet.'),
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
          ? Center(child: Text(emptyMessage))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isCreator = user.role == 'creator';
                final isVerified = user.isVerified;
                final isSuspended = user.isSuspended;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  color: isSuspended ? Colors.red.shade50 : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCreator ? AppColors.primary.withAlpha(50) : AppColors.outline,
                      child: Icon(isCreator ? Icons.palette : Icons.person,
                          size: 20, color: isCreator ? AppColors.primary : AppColors.mutedText),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(user.name.isEmpty ? 'Anonymous User' : user.name, 
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified, size: 14, color: AppColors.primary),
                          ),
                        if (isSuspended)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.block, size: 14, color: Colors.red),
                          ),
                      ],
                    ),
                    subtitle: Text('${user.email} • ${user.role.toUpperCase()}'),
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
    if (user.role == 'creator') {
       context.read<CreatorBloc>().add(CreatorCheckProfileExists(user.uid));
       // This will navigate through the CreatorFlowWrapper if we were in that flow, 
       // but here we are in Admin flow. Let's just show a snackbar or a dialog for now 
       // as full cross-feature navigation might need more setup.
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Viewing profiles will be improved in next update.')),
       );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Buyer profile view is coming soon.')),
       );
    }
  }

  void _showChangeRoleDialog(BuildContext context, UserEntity user) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
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
              title: const Text('Creator'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'creator'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Admin'),
              onTap: () {
                adminBloc.add(AdminChangeUserRoleRequested(user.uid, 'admin'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
