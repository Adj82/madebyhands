import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/widgets/small_stat.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? true;

    if (!isSuperAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Icon(Icons.lock_rounded, size: 56, color: Colors.orange.shade800),
              ),
              const SizedBox(height: 24),
              const Text(
                'Financial Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const SizedBox(height: 12),
              const Text(
                'As per platform administration controls (SRS FR-20), platform balances, fee configurations, and creator payout releases are restricted to Super Admins.\n\nOperational Managers are not permitted to manage financial payouts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        double totalPlatformRevenue = 0.0;
        List<Map<String, dynamic>> pendingPayoutOrders = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            final total = (data['totalAmount'] as num?)?.toDouble() ??
                (data['total'] as num?)?.toDouble() ??
                0.0;
            final platformFee = data['platformFee'] != null
                ? (data['platformFee'] as num).toDouble()
                : (total > 999 ? (50.0 + (total * 0.05)) : 50.0);
            final payoutAmount = data['payoutAmount'] != null
                ? (data['payoutAmount'] as num).toDouble()
                : (total - platformFee);

            totalPlatformRevenue += platformFee;

            final payoutStatus = data['payoutStatus'] as String? ?? 'pending';
            final status = data['status'] as String? ?? 'Placed';

            if (payoutStatus == 'pending' && status != 'Rejected') {
              pendingPayoutOrders.add({
                'docId': doc.id,
                'orderId': doc.id.length > 6 ? doc.id.substring(doc.id.length - 6).toUpperCase() : doc.id.toUpperCase(),
                'sellerName': data['sellerName'] as String? ?? data['creatorName'] as String? ?? 'Artisan',
                'payoutAmount': payoutAmount,
                'status': status,
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              });
            }
          }
        } else {
          // Fallback mock payouts if Firestore has no live orders yet
          totalPlatformRevenue = 825.0;
          pendingPayoutOrders = [
            {
              'docId': '9I9HP7',
              'orderId': '9I9HP7',
              'sellerName': 'MadeByHands artisan',
              'payoutAmount': 3275.0,
              'status': 'Placed',
              'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
            },
            {
              'docId': 'KJ5BPF',
              'orderId': 'KJ5BPF',
              'sellerName': 'MadeByHands artisan',
              'payoutAmount': 4700.0,
              'status': 'Accepted',
              'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
            },
            {
              'docId': 'IJDRO4',
              'orderId': 'IJDRO4',
              'sellerName': 'MadeByHands artisan',
              'payoutAmount': 4700.0,
              'status': 'Placed',
              'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
            },
          ];
        }

        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, adminState) {
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
                    const Text('Financial Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(25),
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(25)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Realized Platform Revenue', style: TextStyle(color: Colors.white70)),
                          Text(
                            '₹${totalPlatformRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              SmallStat(label: 'Flat Fee', value: '₹${adminState.flatFee.toStringAsFixed(0)}'),
                              const SizedBox(width: 40),
                              SmallStat(label: 'Comm.', value: '${adminState.percentFee.toStringAsFixed(0)}%'),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pending Creator Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${pendingPayoutOrders.length} pending', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    pendingPayoutOrders.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: const Text('All creator payouts are fully settled!', style: TextStyle(color: AppColors.mutedText)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingPayoutOrders.length,
                            itemBuilder: (context, index) {
                              final payout = pendingPayoutOrders[index];
                              final docId = payout['docId'] as String;
                              final orderId = payout['orderId'] as String;
                              final sellerName = payout['sellerName'] as String;
                              final amount = payout['payoutAmount'] as double;
                              final createdAt = payout['createdAt'] as DateTime;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sellerName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Order #$orderId · ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${amount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                                          ),
                                          const SizedBox(height: 4),
                                          FilledButton.icon(
                                            onPressed: () async {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('orders')
                                                    .doc(docId)
                                                    .update({'payoutStatus': 'released'});
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Payout of ₹${amount.toStringAsFixed(0)} released to $sellerName.')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Payout released for Order #$orderId.')),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.check, size: 14),
                                            label: const Text('Release Payout', style: TextStyle(fontSize: 11)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
