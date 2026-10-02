import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_notifications_page.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_earnings_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_home_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_orders_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_products_view.dart';
import 'package:madebyhands/features/creator/presentation/views/creator_profile_view.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';
import 'package:madebyhands/init_dependencies.dart';

class CreatorDashboardPage extends StatefulWidget {
  final UserEntity user;

  const CreatorDashboardPage({super.key, required this.user});

  @override
  State<CreatorDashboardPage> createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends State<CreatorDashboardPage> {
  int _selectedIndex = 0;
  final Set<int> _visited = {0};

  static const List<String> _titles = [
    'Artisan Dashboard',
    'My Products',
    'Manage Orders',
    'Earnings',
    'My Profile',
  ];

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  Widget _view(int index, CreatorProfile profile) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => CreatorHomeView(profile: profile),
      1 => CreatorProductsView(profile: profile),
      2 => CreatorOrdersView(profile: profile),
      3 => CreatorEarningsView(creatorId: profile.uid),
      _ => CreatorProfileView(profile: profile, user: widget.user),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreatorBloc, CreatorState>(
      // One place surfaces the outcome of every creator write.
      listenWhen: (previous, current) =>
          previous.actionId != current.actionId &&
          current.actionStatus != CreatorActionStatus.inProgress &&
          current.action != CreatorAction.saveProfile &&
          current.action != CreatorAction.submitVerification &&
          current.action != CreatorAction.saveProduct &&
          current.action != CreatorAction.saveBankAccount,
      listener: (context, state) {
        final message = state.actionMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: state.actionStatus == CreatorActionStatus.failure
                ? Colors.red.shade700
                : null,
          ),
        );
      },
      child: BlocSelector<CreatorBloc, CreatorState, CreatorProfile?>(
        selector: (state) => state.profile,
        builder: (context, profile) {
          if (profile == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                _NotificationButton(creatorUid: profile.uid),
                IconButton(
                  tooltip: 'Help & support',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupportCenterPage(
                        user: widget.user,
                        repository: serviceLocator(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [for (var i = 0; i < _titles.length; i++) _view(i, profile)],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _select,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.mutedText,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined),
                  activeIcon: Icon(Icons.shopping_bag),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  activeIcon: Icon(Icons.payments),
                  label: 'Earnings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationButton extends StatefulWidget {
  final String creatorUid;

  const _NotificationButton({required this.creatorUid});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  late final Stream<List<CreatorNotification>> _notifications =
      serviceLocator<CreatorRepository>().watchNotifications(widget.creatorUid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CreatorNotification>>(
      stream: _notifications,
      builder: (context, snapshot) {
        final unread = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreatorNotificationsPage(creatorUid: widget.creatorUid),
            ),
          ),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
