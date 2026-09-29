import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_notifications_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';

class CreatorHomeView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorHomeView({super.key, required this.profile});

  @override
  State<CreatorHomeView> createState() => _CreatorHomeViewState();
}

class _CreatorHomeViewState extends State<CreatorHomeView> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    context
        .read<CreatorBloc>()
        .add(CreatorFetchNotifications(widget.profile.uid));
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final bloc = context.read<CreatorBloc>();
      bloc.add(CreatorCheckProfileExists(widget.profile.uid));
      bloc.add(CreatorFetchOrders(widget.profile.uid));
      bloc.add(CreatorFetchCreatorProducts(widget.profile.uid));
      bloc.add(CreatorFetchNotifications(widget.profile.uid));
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationSection(),
            const SizedBox(height: 20),
            _buildStorefrontProminent(context),
            const SizedBox(height: 30),
            _buildVerificationStatus(context),
            const SizedBox(height: 30),
            const Text(
              'Recent Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildPerformanceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return BlocBuilder<CreatorBloc, CreatorState>(
      buildWhen: (previous, current) => current is CreatorNotificationsLoaded,
      builder: (context, state) {
        String title = "You're all caught up!";
        String message = 'Check back later for new orders and updates.';
        int unreadCount = 0;

        if (state is CreatorNotificationsLoaded) {
          final unreadNotifications =
              state.notifications.where((n) => !n.isRead).toList();
          unreadCount = unreadNotifications.length;

          if (unreadCount > 0) {
            title = unreadCount == 1
                ? '1 new notification'
                : '$unreadCount new notifications';
            final latest = unreadNotifications.first;
            message = latest.title.isNotEmpty
                ? '${latest.title}: ${latest.message}'
                : latest.message;
          }
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorNotificationsPage(widget.profile),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.mutedText,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStorefrontProminent(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.storefront,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surface,
                      backgroundImage: widget.profile.profileImage.isNotEmpty
                          ? NetworkImage(widget.profile.profileImage)
                          : null,
                      child: widget.profile.profileImage.isEmpty
                          ? const Icon(Icons.person,
                              size: 30, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.profile.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Storefront'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(BuildContext context) {
    final status = widget.profile.verificationStatus;
    final isVerified = status == 'Verified';
    final isInProcess = status == 'In-Process';

    return InkWell(
      onTap: () {
        if (!isVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CreatorVerificationPage(profile: widget.profile)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              isVerified
                  ? Icons.verified
                  : (isInProcess ? Icons.hourglass_top : Icons.error_outline),
              color: isVerified
                  ? Colors.green
                  : (isInProcess ? Colors.orange : Colors.red),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Officially Verified' : 'Verification Status',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isVerified
                        ? 'Your products are live for buyers.'
                        : (isInProcess
                            ? 'Under review by admin.'
                            : 'Required to start selling.'),
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            if (!isVerified && !isInProcess)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('creatorId', isEqualTo: widget.profile.uid)
          .snapshots(),
      builder: (context, snapshot) {
        double totalSales = 0.0;
        int activeOrdersCount = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            final status = (data['status'] as String? ?? '').trim();
            final netAmount = (data['creatorNetAmount'] as num?)?.toDouble() ??
                (data['subtotal'] as num?)?.toDouble() ??
                0.0;

            if (status != 'Rejected' && status != 'Cancelled') {
              totalSales += netAmount;
            }

            if (['Placed', 'Pending', 'Accepted', 'Confirmed', 'Processing', 'Shipped', 'In-transit', 'Out for Delivery'].contains(status)) {
              activeOrdersCount++;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Sales',
                value: '₹${totalSales.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _SummaryCard(
                label: 'Active Orders',
                value: '$activeOrdersCount',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
