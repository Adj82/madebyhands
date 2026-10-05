import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
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
            return const Scaffold(
              backgroundColor: Color(0xFFFAF6EE),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B261D)),
              ),
            );
          }
          return BuyerBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B261D),
                  ),
                ),
                iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
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
                    icon: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF8B261D),
                    ),
                  ),
                ],
              ),
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  for (var i = 0; i < _titles.length; i++) _view(i, profile)
                ],
              ),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF6EE),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      height: 78,
                      backgroundColor: const Color(0xFFFAF6EE),
                      indicatorColor: const Color(0xFFF2DEDD),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        return IconThemeData(
                          color: states.contains(WidgetState.selected)
                              ? const Color(0xFF8B261D)
                              : const Color(0xFF8B261D).withValues(alpha: 0.55),
                        );
                      }),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        return GoogleFonts.montserrat(
                          fontSize: 11.5,
                          fontWeight: states.contains(WidgetState.selected)
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: states.contains(WidgetState.selected)
                              ? const Color(0xFF8B261D)
                              : const Color(0xFF8B261D).withValues(alpha: 0.6),
                        );
                      }),
                    ),
                    child: NavigationBar(
                      height: 78,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _select,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2),
                          label: 'Products',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.shopping_bag_outlined),
                          selectedIcon: Icon(Icons.shopping_bag),
                          label: 'Orders',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.payments_outlined),
                          selectedIcon: Icon(Icons.payments),
                          label: 'Earnings',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      serviceLocator<CreatorRepository>()
          .watchNotifications(widget.creatorUid);

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
              builder: (_) =>
                  CreatorNotificationsPage(creatorUid: widget.creatorUid),
            ),
          ),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            backgroundColor: Colors.redAccent,
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF8B261D),
            ),
          ),
        );
      },
    );
  }
}
