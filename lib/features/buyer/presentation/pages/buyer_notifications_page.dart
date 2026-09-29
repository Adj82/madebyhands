import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_product_notification.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';

class BuyerNotificationsPage extends StatefulWidget {
  final List<BuyerProductNotification> notifications;
  final Set<String> readNotificationIds;
  final ValueChanged<BuyerProductNotification> onNotificationTap;
  final VoidCallback onMarkAllRead;

  const BuyerNotificationsPage({
    super.key,
    required this.notifications,
    required this.readNotificationIds,
    required this.onNotificationTap,
    required this.onMarkAllRead,
  });

  @override
  State<BuyerNotificationsPage> createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
  late final Set<String> _readNotificationIds = {...widget.readNotificationIds};

  void _markAllRead() {
    setState(() {
      _readNotificationIds.addAll(
        widget.notifications.map((notification) => notification.id),
      );
    });
    widget.onMarkAllRead();
  }

  void _openNotification(BuyerProductNotification notification) {
    setState(() => _readNotificationIds.add(notification.id));
    widget.onNotificationTap(notification);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.notifications.any(
      (notification) => !_readNotificationIds.contains(notification.id),
    );
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          actions: [
            if (hasUnread)
              TextButton(
                onPressed: _markAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B261D),
                ),
                child: const Text('Mark all read'),
              ),
          ],
        ),
        body: widget.notifications.isEmpty
            ? const BuyerEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No new product alerts',
                message:
                    'When creators publish in categories you have wishlisted or purchased from, they will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: widget.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = widget.notifications[index];
                  final isRead =
                      _readNotificationIds.contains(notification.id);
                  return Material(
                    color: isRead
                        ? const Color(0xFFFAF6EE).withValues(alpha: 0.9)
                        : const Color(0xFFF2DEDD).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openNotification(notification),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF8B261D)
                                  .withValues(alpha: 0.14),
                              foregroundColor: const Color(0xFF8B261D),
                              child: Icon(
                                notification.type == BuyerNotificationType.order
                                    ? Icons.local_shipping_outlined
                                    : Icons.new_releases_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.w700
                                                : FontWeight.w900,
                                            color: const Color(0xFF8B261D),
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        const CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Color(0xFF8B261D),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    notification.message,
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(notification.publishedAt),
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF8B261D),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
