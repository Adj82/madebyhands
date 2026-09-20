import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

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
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 3,
        itemBuilder: (context, index) {
          final isAdmin = index == 0; // Simulate roles
          return Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.admin_panel_settings)),
              title: Text(index == 0 ? 'Adhiraj Jain (You)' : 'Admin User $index'),
              subtitle: Text(isAdmin ? 'Super Admin' : 'Manager'),
              trailing: index == 0 ? null : IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {}),
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
            const TextField(decoration: InputDecoration(labelText: 'Email Address')),
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
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Grant Access')),
        ],
      ),
    );
  }
}
