import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_cubit.dart';
import 'package:madebyhands/features/admin/presentation/widgets/admin_stat_card.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(AdminLoadDataRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              childAspectRatio: 1.4, // Increased ratio to prevent overflow
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
            BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                final applications = state.creatorApplications;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: applications.take(5).length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.notifications_none, size: 20)),
                      title: Text('New application from "${application.name}"'),
                      subtitle: const Text('Recent'),
                      trailing: TextButton(
                        onPressed: () {
                          // Navigate to verification tab
                          context.read<AdminCubit>().changePage(1);
                        }, 
                        child: const Text('Review')
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
