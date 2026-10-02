import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_cubit.dart';
import 'package:madebyhands/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _users = FirebaseFirestore
      .instance
      .collection('users')
      .snapshots();
  final Stream<QuerySnapshot<Map<String, dynamic>>> _orders = FirebaseFirestore
      .instance
      .collection('orders')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _users,
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data?.docs ?? const [];
        final creatorCount = users.where((doc) {
          final role = (doc.data()['role'] as String? ?? '').toLowerCase();
          return role == 'creator' || role == 'seller';
        }).length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _orders,
          builder: (context, ordersSnapshot) {
            var revenue = 0;
            var paidOrders = 0;
            for (final doc in ordersSnapshot.data?.docs ?? const []) {
              final data = doc.data();
              final paymentStatus = (data['paymentStatus'] as String? ?? 'paid').toLowerCase();
              if (paymentStatus != 'paid' || data['isSample'] == true) {
                continue;
              }
              if (OrderStatus.isRejectedOrCancelled(data['status'] as String? ?? '')) {
                continue;
              }
              paidOrders++;
              revenue += (data['platformFee'] as num?)?.round() ?? 0;
            }

            return BlocBuilder<AdminBloc, AdminState>(
              buildWhen: (previous, current) =>
                  previous.creatorProfiles != current.creatorProfiles,
              builder: (context, state) {
                final pending = state.pendingVerifications;
                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<AdminBloc>().add(AdminLoadDataRequested()),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Platform status',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.25,
                        children: [
                          AdminStatCard(
                            title: 'Total users',
                            value: '${users.length}',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          AdminStatCard(
                            title: 'Creators',
                            value: '$creatorCount',
                            icon: Icons.palette,
                            color: AppColors.primary,
                          ),
                          AdminStatCard(
                            title: 'Pending verifications',
                            value: '${pending.length}',
                            icon: Icons.hourglass_empty,
                            color: AppColors.accent,
                          ),
                          AdminStatCard(
                            title: 'Platform revenue ($paidOrders orders)',
                            value: '₹$revenue',
                            icon: Icons.payments,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Awaiting verification',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<AdminCubit>().changePage(1),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (pending.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Text(
                            'No creator applications waiting.',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                        )
                      else
                        for (final application in pending.take(5))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                            ),
                            title: Text(
                              application.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              application.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: TextButton(
                              onPressed: () => context.read<AdminCubit>().changePage(1),
                              child: const Text('Review'),
                            ),
                          ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
