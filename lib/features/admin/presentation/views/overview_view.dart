import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/widgets/admin_stat_card.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3, // Adjusted for better fit on various screens
            children: const [
              AdminStatCard(title: 'Total Users', value: '1,284', icon: Icons.people, color: Colors.blue),
              AdminStatCard(title: 'Active Creators', value: '142', icon: Icons.palette, color: AppColors.primary),
              AdminStatCard(title: 'Pending Approvals', value: '28', icon: Icons.hourglass_empty, color: AppColors.accent),
              AdminStatCard(title: 'Total Revenue', value: '₹42,500', icon: Icons.payments, color: Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.notifications_none, size: 20)),
                title: Text('New creator application from "Artisan $index"'),
                subtitle: const Text('2 hours ago'),
                trailing: TextButton(onPressed: () {}, child: const Text('Review')),
              );
            },
          ),
        ],
      ),
    );
  }
}
