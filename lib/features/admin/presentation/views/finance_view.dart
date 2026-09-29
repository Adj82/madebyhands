import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Pending Payouts'),
            Tab(text: 'Payout History'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Error loading financial data: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            double totalPlatformRevenue = 0.0;
            double totalSettledPayouts = 0.0;
            List<Map<String, dynamic>> pendingPayoutOrders = [];
            List<Map<String, dynamic>> releasedPayoutOrders = [];

            final docs = snapshot.data?.docs ?? [];
            for (var doc in docs) {
              final data = doc.data();
              final total = (data['totalAmount'] as num?)?.toDouble() ??
                  (data['total'] as num?)?.toDouble() ??
                  (data['buyerPayableAmount'] as num?)?.toDouble() ??
                  0.0;
              final platformFee = data['platformFee'] != null
                  ? (data['platformFee'] as num).toDouble()
                  : (total > 999 ? (50.0 + (total * 0.05)) : 50.0);
              final payoutAmount = data['payoutAmount'] != null
                  ? (data['payoutAmount'] as num).toDouble()
                  : (data['creatorNetAmount'] as num?)?.toDouble() ?? (total - platformFee);

              totalPlatformRevenue += platformFee;

              final payoutStatus = (data['payoutStatus'] as String? ?? 'pending').toLowerCase();
              final status = (data['status'] as String? ?? 'Placed').toLowerCase();

              final orderItem = {
                'docId': doc.id,
                'orderId': doc.id.length > 6 ? doc.id.substring(doc.id.length - 6).toUpperCase() : doc.id.toUpperCase(),
                'creatorId': data['creatorId'] as String? ?? data['sellerId'] as String? ?? '',
                'sellerName': data['sellerName'] as String? ?? data['creatorName'] as String? ?? 'Artisan',
                'payoutAmount': payoutAmount,
                'status': data['status'] ?? 'Placed',
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'releasedAt': (data['payoutReleasedAt'] as Timestamp?)?.toDate() ??
                    (data['paidAt'] as Timestamp?)?.toDate() ??
                    (data['updatedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              };

              if ((payoutStatus == 'paid' || payoutStatus == 'released') && status != 'rejected' && status != 'cancelled') {
                totalSettledPayouts += payoutAmount;
                releasedPayoutOrders.add(orderItem);
              } else if (payoutStatus == 'pending' && status != 'rejected' && status != 'cancelled') {
                pendingPayoutOrders.add(orderItem);
              }
            }

            // Sort history by released date descending
            releasedPayoutOrders.sort((a, b) {
              final tA = a['releasedAt'] as DateTime;
              final tB = b['releasedAt'] as DateTime;
              return tB.compareTo(tA);
            });

            return BlocBuilder<AdminBloc, AdminState>(
              builder: (context, adminState) {
                return TabBarView(
                  children: [
                    _buildPendingPayoutsList(
                      context,
                      adminState: adminState,
                      totalPlatformRevenue: totalPlatformRevenue,
                      pendingPayoutOrders: pendingPayoutOrders,
                    ),
                    _buildPayoutHistoryList(
                      context,
                      totalSettledPayouts: totalSettledPayouts,
                      releasedPayoutOrders: releasedPayoutOrders,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingPayoutsList(
    BuildContext context, {
    required AdminState adminState,
    required double totalPlatformRevenue,
    required List<Map<String, dynamic>> pendingPayoutOrders,
  }) {
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
            const Text('Financial Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Realized Platform Revenue', style: TextStyle(color: Colors.white70)),
                  Text(
                    '₹${totalPlatformRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SmallStat(label: 'Flat Fee', value: '₹${adminState.flatFee.toStringAsFixed(0)}'),
                      const SizedBox(width: 32),
                      SmallStat(label: 'Commission', value: '${adminState.percentFee.toStringAsFixed(0)}%'),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Creator Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingPayoutOrders.length} pending',
                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      final creatorId = payout['creatorId'] as String;
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
                                  const SizedBox(height: 6),
                                  FilledButton.icon(
                                    onPressed: () => _showPayoutReleaseModal(
                                      context,
                                      docId: docId,
                                      orderId: orderId,
                                      creatorId: creatorId,
                                      sellerName: sellerName,
                                      amount: amount,
                                    ),
                                    icon: const Icon(Icons.account_balance_wallet, size: 14),
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
  }

  Widget _buildPayoutHistoryList(
    BuildContext context, {
    required double totalSettledPayouts,
    required List<Map<String, dynamic>> releasedPayoutOrders,
  }) {
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
            const Text('Settlement History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Settled Creator Payouts', style: TextStyle(color: Colors.white70)),
                  Text(
                    '₹${totalSettledPayouts.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${releasedPayoutOrders.length} creator payout(s) completed',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text('Settled Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${releasedPayoutOrders.length} records', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            releasedPayoutOrders.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: const Text('No historical payout releases yet.', style: TextStyle(color: AppColors.mutedText)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: releasedPayoutOrders.length,
                    itemBuilder: (context, index) {
                      final payout = releasedPayoutOrders[index];
                      final orderId = payout['orderId'] as String;
                      final sellerName = payout['sellerName'] as String;
                      final amount = payout['payoutAmount'] as double;
                      final releasedAt = payout['releasedAt'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.withValues(alpha: 0.15),
                                child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Order #$orderId · Released: ${DateFormat('dd MMM yyyy, hh:mm a').format(releasedAt)}',
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
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SETTLED',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
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
  }

  void _showPayoutReleaseModal(
    BuildContext context, {
    required String docId,
    required String orderId,
    required String creatorId,
    required String sellerName,
    required double amount,
  }) async {
    String upiId = '';
    String phone = 'N/A';

    try {
      if (creatorId.isNotEmpty) {
        final profileDoc = await FirebaseFirestore.instance
            .collection('creator_profiles')
            .doc(creatorId)
            .get();
        if (profileDoc.exists && profileDoc.data() != null) {
          final pData = profileDoc.data()!;
          upiId = pData['upiId'] as String? ?? pData['payoutUpi'] as String? ?? '';
          phone = pData['phone'] as String? ?? '';
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(creatorId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final uData = userDoc.data()!;
          if (phone.isEmpty || phone == 'N/A') {
            phone = uData['phone'] as String? ?? '';
          }
        }
      }
    } catch (_) {}

    if (upiId.isEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      upiId = cleanPhone.length == 10 ? '$cleanPhone@upi' : '${sellerName.toLowerCase().replaceAll(' ', '')}@upi';
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(modalContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Release Seller Payout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.storefront, color: Colors.white),
                    ),
                    title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Order #$orderId · Creator Payout', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    trailing: Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Seller UPI ID / Payment Address:', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            upiId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.green),
                          tooltip: 'Copy UPI ID',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: upiId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied UPI ID ($upiId) to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty && phone != 'N/A') ...[
                    const SizedBox(height: 8),
                    Text('Seller Phone: $phone', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied UPI ID ($upiId)')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy UPI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(modalContext);
                      try {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(docId)
                            .update({
                              'payoutStatus': 'paid',
                              'payoutReleasedAt': FieldValue.serverTimestamp(),
                            });
                        messenger.showSnackBar(
                          SnackBar(content: Text('Payout of ₹${amount.toStringAsFixed(0)} marked as released to $sellerName.')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Could not update payout status: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm Released'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
