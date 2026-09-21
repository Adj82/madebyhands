import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // In real MVP, fetch users here
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 20,
        itemBuilder: (context, index) {
          final isCreator = index % 3 == 0;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCreator ? AppColors.primary.withAlpha(50) : AppColors.outline,
                child: Icon(isCreator ? Icons.palette : Icons.person,
                    size: 20, color: isCreator ? AppColors.primary : AppColors.mutedText),
              ),
              title: Text('User $index', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('user$index@gmail.com • ${isCreator ? 'Creator' : 'Buyer'}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Profile')),
                  const PopupMenuItem(
                      value: 'suspend', child: Text('Suspend User', style: TextStyle(color: Colors.redAccent))),
                  const PopupMenuItem(value: 'role', child: Text('Change Role')),
                ],
                onSelected: (val) {},
              ),
            ),
          );
        },
      ),
    );
  }
}
