import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorNotificationsPage extends StatefulWidget {
  final CreatorProfile profile;

  const CreatorNotificationsPage(this.profile, {super.key});

  @override
  State<CreatorNotificationsPage> createState() =>
      _CreatorNotificationsPageState();
}

class _CreatorNotificationsPageState extends State<CreatorNotificationsPage> {
  bool _isRefreshing = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String initialId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(initialId);
    });
  }

  void _confirmDeleteSelected(List<CreatorNotification> allNotifications) {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} notification(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              final idsToDelete = _selectedIds.toList();
              _exitSelectionMode();
              context.read<CreatorBloc>().add(
                    CreatorDeleteNotifications(
                      notificationIds: idsToDelete,
                      uid: widget.profile.uid,
                    ),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _selectAll(List<CreatorNotification> notifications) {
    setState(() {
      if (_selectedIds.length == notifications.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(notifications.map((n) => n.id));
      }
    });
  }

  void _showNotificationDetailDialog(CreatorNotification notification) {
    if (!notification.isRead) {
      context.read<CreatorBloc>().add(
            CreatorMarkNotificationAsRead(
              notificationId: notification.id,
              uid: widget.profile.uid,
            ),
          );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _NotificationDetailDialog(
        notification: notification,
        profile: widget.profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      buildWhen: (previous, current) =>
          current is CreatorNotificationsLoaded ||
          current is CreatorLoading ||
          current is CreatorFailure,
      builder: (context, state) {
        final notifications = state is CreatorNotificationsLoaded
            ? state.notifications
            : <CreatorNotification>[];

        return Scaffold(
          appBar: AppBar(
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                    tooltip: 'Exit selection mode',
                  )
                : null,
            title: Text(
              _isSelectionMode
                  ? '${_selectedIds.length} Selected'
                  : 'Notifications',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: !_isSelectionMode,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        _selectedIds.length == notifications.length
                            ? Icons.deselect
                            : Icons.select_all,
                      ),
                      tooltip: _selectedIds.length == notifications.length
                          ? 'Deselect all'
                          : 'Select all',
                      onPressed: () => _selectAll(notifications),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete selected',
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () => _confirmDeleteSelected(notifications),
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                    IconButton(
                      tooltip: 'Mark all as read',
                      icon: const Icon(Icons.done_all),
                      onPressed: _markAllAsRead,
                    ),
                    const SizedBox(width: 8),
                  ],
          ),
          body: _buildBody(state, notifications),
        );
      },
    );
  }

  Widget _buildBody(CreatorState state, List<CreatorNotification> notifications) {
    if (state is CreatorLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CreatorNotificationsLoaded) {
      if (notifications.isEmpty) {
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Updates about your orders, products, and account will appear here.',
                    style: TextStyle(color: AppColors.mutedText),
                    textAlign: TextAlign.center,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final isSelected = _selectedIds.contains(notification.id);

            return _NotificationTile(
              notification: notification,
              isSelectionMode: _isSelectionMode,
              isSelected: isSelected,
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(notification.id);
                } else {
                  _showNotificationDetailDialog(notification);
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _enterSelectionMode(notification.id);
                } else {
                  _toggleSelection(notification.id);
                }
              },
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
  }
}

class _NotificationTile extends StatelessWidget {
  final CreatorNotification notification;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'verification':
        return Icons.verified_outlined;
      case 'product':
        return Icons.inventory_2_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'order':
        return AppColors.primary;
      case 'verification':
        return Colors.green;
      case 'product':
        return Colors.orange;
      case 'announcement':
        return Colors.purple;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.12)
          : (isUnread ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isUnread
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.outline.withValues(alpha: 0.5)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.mutedText,
                    size: 22,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getIconColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isUnread && !isSelectionMode)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd MMM').format(notification.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailDialog extends StatelessWidget {
  final CreatorNotification notification;
  final CreatorProfile profile;

  const _NotificationDetailDialog({
    required this.notification,
    required this.profile,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'verification':
        return Icons.verified_outlined;
      case 'product':
        return Icons.inventory_2_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'order':
        return AppColors.primary;
      case 'verification':
        return Colors.green;
      case 'product':
        return Colors.orange;
      case 'announcement':
        return Colors.purple;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIconColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), color: _getIconColor(), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notification.message,
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(notification.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notification.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
