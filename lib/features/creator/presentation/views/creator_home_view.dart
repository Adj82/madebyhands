import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/presentation/pages/public_creator_storefront_page.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_notifications_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';
import 'package:madebyhands/init_dependencies.dart';

class CreatorHomeView extends StatefulWidget {
  final CreatorProfile profile;

  const CreatorHomeView({super.key, required this.profile});

  @override
  State<CreatorHomeView> createState() => _CreatorHomeViewState();
}

class _CreatorHomeViewState extends State<CreatorHomeView> {
  final CreatorRepository _repository = serviceLocator<CreatorRepository>();
  late final Stream<List<CreatorNotification>> _notifications = _repository
      .watchNotifications(widget.profile.uid);
  late final Stream<List<CreatorOrder>> _orders = _repository.watchCreatorOrders(
    widget.profile.uid,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      builder: (context, state) {
        final profile = state.profile ?? widget.profile;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _NotificationSummary(
              notifications: _notifications,
              creatorUid: profile.uid,
            ),
            const SizedBox(height: 20),
            _StorefrontCard(profile: profile),
            const SizedBox(height: 24),
            _VerificationStatusCard(profile: profile),
            const SizedBox(height: 28),
            const Text(
              'Your performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _PerformanceSummary(orders: _orders),
          ],
        );
      },
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  final Stream<List<CreatorNotification>> notifications;
  final String creatorUid;

  const _NotificationSummary({required this.notifications, required this.creatorUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CreatorNotification>>(
      stream: notifications,
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? const <CreatorNotification>[])
            .where((n) => !n.isRead)
            .toList();
        var title = "You're all caught up!";
        var message = 'New orders and updates will show up here.';
        if (unread.isNotEmpty) {
          title = unread.length == 1 ? '1 new notification' : '${unread.length} new notifications';
          final latest = unread.first;
          message = latest.title.isNotEmpty ? '${latest.title}: ${latest.message}' : latest.message;
        }

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatorNotificationsPage(creatorUid: creatorUid)),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: unread.isNotEmpty,
                  label: Text('${unread.length}'),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StorefrontCard extends StatelessWidget {
  final CreatorProfile profile;

  const _StorefrontCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surface,
                backgroundImage: profile.profileImage.isNotEmpty
                    ? NetworkImage(profile.profileImage)
                    : null,
                child: profile.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 30, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.location.isNotEmpty)
                      Text(
                        profile.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicCreatorStorefrontPage.preview(
                  creator: PublicCreator(
                    uid: profile.uid,
                    name: profile.name,
                    businessName: profile.businessName,
                    profileImage: profile.profileImage,
                    bio: profile.bio,
                    location: profile.location,
                    socialLinks: profile.socialLinks,
                    portfolio: profile.portfolio,
                    story: profile.story,
                    isVerified: profile.isVerified,
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('View storefront'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  final CreatorProfile profile;

  const _VerificationStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String title, String subtitle) = switch (profile) {
      final p when p.isVerified => (
        Icons.verified,
        Colors.green,
        'Verified creator',
        'You can list products. Tap to view submitted documents.',
      ),
      final p when p.isUnderReview => (
        Icons.hourglass_top,
        Colors.orange,
        'Verification under review',
        'An admin is reviewing your documents. Tap to update.',
      ),
      final p when p.isVerificationRejected => (
        Icons.error_outline,
        Colors.red,
        'Verification not approved',
        p.verificationNote.isEmpty
            ? 'Tap to update your documents and resubmit.'
            : '${p.verificationNote}\nTap to resubmit.',
      ),
      _ => (
        Icons.error_outline,
        Colors.red,
        'Get verified to start selling',
        'Tap to submit your documents.',
      ),
    };
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatorVerificationPage(profile: profile)),
      ),
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  final Stream<List<CreatorOrder>> orders;

  const _PerformanceSummary({required this.orders});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CreatorOrder>>(
      stream: orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Could not load your sales right now.',
            style: TextStyle(color: AppColors.mutedText),
          );
        }
        final all = snapshot.data ?? const <CreatorOrder>[];
        final active = all.where((o) => !OrderStatus.isRejectedOrCancelled(o.status)).toList();
        final pending = active.where((o) => OrderStatus.isNew(o.status)).length;
        final inProgress = active.where((o) => OrderStatus.isInProgress(o.status)).length;
        // "Settled" means the payout has actually been released, matching
        // the definition used on the Earnings tab (see creator_earnings_view.dart).
        final settled = active.where((o) => o.countsTowardEarnings && o.isPaidOut).toList();
        final totalEarned = settled.fold<int>(0, (total, o) => total + o.creatorNetAmount);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'New orders',
              value: '$pending',
              icon: Icons.new_releases_outlined,
              color: AppColors.accent,
            ),
            _StatCard(
              title: 'In progress',
              value: '$inProgress',
              icon: Icons.precision_manufacturing_outlined,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Total orders',
              value: '${active.length}',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.primary,
            ),
            _StatCard(
              title: 'Earned (settled)',
              value: '₹$totalEarned',
              icon: Icons.payments_outlined,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
