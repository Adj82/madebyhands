import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';

class CreatorNotificationsPage extends StatefulWidget {
  final CreatorProfile profile;

  const CreatorNotificationsPage(this.profile, {super.key});

  @override
  State<CreatorNotificationsPage> createState() =>
      _CreatorNotificationsPageState();
}

class _CreatorNotificationsPageState extends State<CreatorNotificationsPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() {
    context
        .read<CreatorBloc>()
        .add(CreatorFetchNotifications(widget.profile.uid));
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      _fetchNotifications();
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _markAllAsRead() {
    context
        .read<CreatorBloc>()
        .add(CreatorMarkAllNotificationsAsRead(widget.profile.uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: BlocBuilder<CreatorBloc, CreatorState>(
        buildWhen: (previous, current) =>
            current is CreatorNotificationsLoaded ||
            current is CreatorLoading ||
            current is CreatorFailure,
        builder: (context, state) {
          if (state is CreatorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CreatorNotificationsLoaded) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.mutedText,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    profile: widget.profile,
                  );
                },
              ),
            );
          }

          if (state is CreatorFailure) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final CreatorNotification notification;
  final CreatorProfile profile;

  const _NotificationCard({
    required this.notification,
    required this.profile,
  });

  void _onNotificationTap(BuildContext context) {
    if (!notification.isRead) {
      context.read<CreatorBloc>().add(
            CreatorMarkNotificationAsRead(
              notificationId: notification.id,
              uid: profile.uid,
            ),
          );
    }

    if (notification.type == 'verification') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatorVerificationPage(profile: profile),
        ),
      );
    } else if (notification.type == 'order') {
      context.read<CreatorBloc>().add(CreatorFetchOrders(profile.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening order notifications... Navigate to Manage Orders tab.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'order':
        return Icons.shopping_bag;
      case 'verification':
        return Icons.verified;
      case 'product':
        return Icons.inventory_2;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'order':
        return Colors.green;
      case 'verification':
        return AppColors.primary;
      case 'product':
        return Colors.orange;
      case 'announcement':
        return Colors.blue;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), color: _getIconColor(), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
