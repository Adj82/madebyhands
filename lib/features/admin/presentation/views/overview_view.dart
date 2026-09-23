import 'package:cloud_firestore/cloud_firestore.dart';
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        double liveTotalRevenue = 0.0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            final total = (data['totalAmount'] as num?)?.toDouble() ??
                (data['total'] as num?)?.toDouble() ??
                0.0;
            final platformFee = data['platformFee'] != null
                ? (data['platformFee'] as num).toDouble()
                : (total > 999 ? (50.0 + (total * 0.05)) : 50.0);
            liveTotalRevenue += platformFee;
          }
        } else {
          liveTotalRevenue = 825.0;
        }

        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
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
                      childAspectRatio: 1.4,
                      children: [
                        AdminStatCard(title: 'Total Users', value: '${state.totalUsersCount}', icon: Icons.people, color: Colors.blue),
                        AdminStatCard(title: 'Active Creators', value: '${state.activeCreatorsCount}', icon: Icons.palette, color: AppColors.primary),
                        AdminStatCard(title: 'Pending Approvals', value: '${state.creatorProfiles.where((p) => p.verificationStatus != 'Verified').length}', icon: Icons.hourglass_empty, color: AppColors.accent),
                        AdminStatCard(title: 'Platform Revenue', value: '₹${liveTotalRevenue.toStringAsFixed(0)}', icon: Icons.payments, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => context.read<AdminCubit>().changePage(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    state.creatorProfiles.where((p) => p.verificationStatus == 'In-Process' || p.verificationStatus == 'Unverified').isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: const Text('No pending creator applications.', style: TextStyle(color: AppColors.mutedText)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.creatorProfiles.where((p) => p.verificationStatus == 'In-Process' || p.verificationStatus == 'Unverified').take(5).length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final application = state.creatorProfiles.where((p) => p.verificationStatus == 'In-Process' || p.verificationStatus == 'Unverified').toList()[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                                ),
                                title: Text('Application from "${application.name}"'),
                                subtitle: Text('Category: ${application.category}'),
                                trailing: TextButton(
                                  onPressed: () {
                                    context.read<AdminCubit>().changePage(1);
                                  },
                                  child: const Text('Review'),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
