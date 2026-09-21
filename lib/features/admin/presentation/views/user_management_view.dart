import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

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

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCreator ? AppColors.primary.withAlpha(50) : AppColors.outline,
                      child: Icon(isCreator ? Icons.palette : Icons.person,
                          size: 20, color: isCreator ? AppColors.primary : AppColors.mutedText),
                    ),
                    title: Row(
                      children: [
                        Text(user.name.isEmpty ? 'Anonymous User' : user.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified, size: 14, color: AppColors.primary),
                          ),
                      ],
                    ),
                    subtitle: Text('${user.email} • ${user.role.toUpperCase()}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('View Profile')),
                        const PopupMenuItem(
                            value: 'suspend', child: Text('Suspend User', style: TextStyle(color: Colors.redAccent))),
                        const PopupMenuItem(value: 'role', child: Text('Change Role')),
                      ],
                      onSelected: (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Action "$val" will be implemented with Firebase Functions.')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
