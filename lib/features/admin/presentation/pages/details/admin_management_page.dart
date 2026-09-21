import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';

class AdminManagementPage extends StatelessWidget {
  const AdminManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdminDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text('Add New Admin'),
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
                    padding: const EdgeInsets.all(15),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              backgroundColor: AppColors.outline, child: Icon(Icons.admin_panel_settings)),
                          title: Text(admin.name.isEmpty ? 'Admin Account' : admin.name),
                          subtitle: Text(admin.email),
                          trailing: admin.email == 'adhirajjain364@gmail.com'
                              ? const Chip(label: Text('Root'), backgroundColor: AppColors.background)
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Permission required to revoke admin access.')),
                                    );
                                  }),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note: New admins must be registered users first.', 
                style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
            const SizedBox(height: 10),
            const TextField(decoration: InputDecoration(labelText: 'User Email Address')),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Admin Role'),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Manager')),
                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
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
                  const SnackBar(content: Text('Firebase Cloud Function will update role to "admin".')),
                );
                Navigator.pop(context);
              },
              child: const Text('Grant Access')),
        ],
      ),
    );
  }
}
