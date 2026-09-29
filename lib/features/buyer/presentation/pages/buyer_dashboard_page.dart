import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_product_notification.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_cubit.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_history_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_notifications_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_account_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/checkout_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/public_creator_storefront_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/buyer/presentation/views/cart_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/home_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/profile_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/saved_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/search_tab.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/init_dependencies.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuyerDashboardPage extends StatefulWidget {
  final UserEntity user;
  final VoidCallback onLogout;

  const BuyerDashboardPage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  late final BuyerCubit _navigationCubit;
  late UserEntity _currentUser;
  SavedAddress? _selectedAddress;
  List<BuyerProductNotification> _notifications = const [];
  final Set<String> _readNotificationIds = {};
  StreamSubscription<List<SavedAddress>>? _addressSubscription;
  StreamSubscription<List<BuyerProductNotification>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _navigationCubit = BuyerCubit();
    // Initialize data streaming
    context.read<BuyerBloc>().add(BuyerWatchProducts());
    context.read<BuyerBloc>().add(BuyerWatchCreators());
    context.read<BuyerBloc>().add(BuyerWatchFavorites(_currentUser.uid));
    context.read<BuyerBloc>().add(BuyerLoadCart(_currentUser.uid));
    _restoreReadNotifications();
    final repository = context.read<BuyerBloc>().repository;
    _addressSubscription = repository.watchAddresses(_currentUser.uid).listen((
      addresses,
    ) {
      if (!mounted) return;
      final defaults = addresses.where((address) => address.isDefault);
      setState(() {
        _selectedAddress = defaults.isNotEmpty
            ? defaults.first
            : addresses.isNotEmpty
            ? addresses.first
            : null;
      });
    });
    _notificationSubscription = repository
        .watchBuyerNotifications(_currentUser.uid)
        .listen((notifications) {
          if (!mounted) return;
          setState(() {
            _notifications = notifications;
            final activeIds = notifications
                .map((notification) => notification.id)
                .toSet();
            _readNotificationIds.removeWhere(
              (notificationId) => !activeIds.contains(notificationId),
            );
          });
        }, onError: (_) {});
  }

  Future<void> _restoreReadNotifications() async {
    List<String>? stored;
    try {
      final preferences = await SharedPreferences.getInstance();
      stored = preferences.getStringList(
        'buyer_read_notifications_${_currentUser.uid}',
      );
    } catch (_) {
      return;
    }
    if (!mounted || stored == null) return;
    final restoredIds = stored;
    setState(() => _readNotificationIds.addAll(restoredIds));
  }

  Future<void> _persistReadNotifications() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        'buyer_read_notifications_${_currentUser.uid}',
        _readNotificationIds.toList(),
      );
    } catch (_) {
      // Read state still remains available for the current session.
    }
  }

  @override
  void dispose() {
    _navigationCubit.close();
    _addressSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _openProduct(Product product) {
    final buyerBloc = context.read<BuyerBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: buyerBloc,
          child: BlocBuilder<BuyerBloc, BuyerState>(
            builder: (context, state) {
              return ProductDetailsPage(
                product: product,
                isSaved: state.favoriteIds.contains(product.id),
                cartQuantity: state.cartQuantities[product.id] ?? 0,
                cartCount: state.cartQuantities.values.fold(
                  0,
                  (total, quantity) => total + quantity,
                ),
                onSave: () => buyerBloc.add(
                  BuyerToggleFavorite(
                    userId: _currentUser.uid,
                    product: product,
                  ),
                ),
                onCartQuantityChanged: (quantity) {
                  buyerBloc.add(BuyerUpdateCartQuantity(product, quantity));
                },
                customizationSelection:
                    state.cartCustomizations[product.id] ??
                    const ProductCustomizationSelection(),
                onCustomizationChanged: (selection) => buyerBloc.add(
                  BuyerUpdateProductCustomization(product, selection),
                ),
                onOpenCart: () {
                  Navigator.of(context).pop();
                  _navigationCubit.changePage(3);
                },
                onBuyNow: (selection) => _openBuyNow(
                  product,
                  state.cartQuantities[product.id] ?? 0,
                  selection,
                ),
                buyerRepository: buyerBloc.repository,
                buyerId: _currentUser.uid,
                buyerName: _currentUser.name,
                onCreatorTap: product.creatorUid.isEmpty
                    ? null
                    : () {
                        final creator = state.creators
                            .where((item) => item.uid == product.creatorUid)
                            .firstOrNull;
                        if (creator != null) _openCreator(creator);
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openCreator(PublicCreator creator) {
    final buyerBloc = context.read<BuyerBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: buyerBloc,
          child: PublicCreatorStorefrontPage(
            creator: creator,
            buyerId: _currentUser.uid,
            onProductTap: _openProduct,
          ),
        ),
      ),
    );
  }

  void _openShop() {
    _navigationCubit.changePage(1);
  }

  void _openNotifications() {
    final buyerRepository = context.read<BuyerBloc>().repository;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuyerNotificationsPage(
          notifications: _notifications,
          readNotificationIds: _readNotificationIds,
          onNotificationTap: (notification) {
            setState(() => _readNotificationIds.add(notification.id));
            _persistReadNotifications();
            if (notification.product != null) {
              _openProduct(notification.product!);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderHistoryPage(
                    userId: _currentUser.uid,
                    repository: buyerRepository,
                  ),
                ),
              );
            }
          },
          onMarkAllRead: () {
            setState(() {
              _readNotificationIds.addAll(
                _notifications.map((notification) => notification.id),
              );
            });
            _persistReadNotifications();
          },
        ),
      ),
    );
  }

  void _openCheckout() {
    final buyerBloc = context.read<BuyerBloc>();
    final state = buyerBloc.state;
    final products = state.products
        .where((product) => state.cartQuantities.containsKey(product.id))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          user: _currentUser,
          products: products,
          quantities: Map<String, int>.from(state.cartQuantities),
          customizations: Map<String, ProductCustomizationSelection>.from(
            state.cartCustomizations,
          ),
          buyerRepository: buyerBloc.repository,
          orderRepository: serviceLocator(),
          onOrderPlaced: () {
            for (final product in products) {
              buyerBloc.add(BuyerUpdateCartQuantity(product, 0));
            }
          },
        ),
      ),
    );
  }

  void _openBuyNow(
    Product product,
    int cartQuantity,
    ProductCustomizationSelection customization,
  ) {
    final buyerBloc = context.read<BuyerBloc>();
    final quantity = cartQuantity > 0 ? cartQuantity : 1;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          user: _currentUser,
          products: [product],
          quantities: {product.id: quantity},
          customizations: {product.id: customization},
          buyerRepository: buyerBloc.repository,
          orderRepository: serviceLocator(),
          onOrderPlaced: () {
            if (buyerBloc.state.cartQuantities.containsKey(product.id)) {
              buyerBloc.add(BuyerUpdateCartQuantity(product, 0));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navigationCubit,
      child: BlocBuilder<BuyerCubit, int>(
        builder: (context, selectedIndex) {
          return BlocBuilder<BuyerBloc, BuyerState>(
            builder: (context, buyerState) {
              if (buyerState.isLoadingProducts && buyerState.products.isEmpty) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (buyerState.errorMessage != null &&
                  buyerState.products.isEmpty) {
                return Scaffold(
                  body: BuyerEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Something went wrong',
                    message: buyerState.errorMessage!,
                  ),
                );
              }

              final pages = [
                HomeTab(
                  userName: _currentUser.name,
                  userId: _currentUser.uid,
                  selectedAddress: _selectedAddress,
                  onAddressTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SavedAddressesPage(
                        userId: _currentUser.uid,
                        repository: context.read<BuyerBloc>().repository,
                      ),
                    ),
                  ),
                  onProductTap: _openProduct,
                  onBrowseAll: _openShop,
                  unreadNotificationCount: _notifications
                      .where(
                        (notification) =>
                            !_readNotificationIds.contains(notification.id),
                      )
                      .length,
                  onNotificationsTap: _openNotifications,
                ),
                SafeArea(
                  child: SearchTab(
                    userId: _currentUser.uid,
                    onProductTap: _openProduct,
                    onCreatorTap: _openCreator,
                  ),
                ),
                SafeArea(
                  child: SavedTab(
                    userId: _currentUser.uid,
                    onProductTap: _openProduct,
                    onBrowse: () => _navigationCubit.changePage(1),
                  ),
                ),
                SafeArea(
                  child: CartTab(
                    onBrowse: () => _navigationCubit.changePage(1),
                    onCheckout: _openCheckout,
                  ),
                ),
                SafeArea(
                  child: ProfileTab(
                    user: _currentUser,
                    onAccount: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BuyerAccountPage(
                          user: _currentUser,
                          repository: serviceLocator(),
                          onProfileUpdated: (user) {
                            if (mounted) setState(() => _currentUser = user);
                          },
                        ),
                      ),
                    ),
                    onOrders: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryPage(
                          userId: _currentUser.uid,
                          repository: context.read<BuyerBloc>().repository,
                        ),
                      ),
                    ),
                    onAddresses: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SavedAddressesPage(
                          userId: _currentUser.uid,
                          repository: context.read<BuyerBloc>().repository,
                        ),
                      ),
                    ),
                    onSupport: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportCenterPage(
                          user: _currentUser,
                          repository: serviceLocator(),
                        ),
                      ),
                    ),
                    onLogout: widget.onLogout,
                  ),
                ),
              ];

              final safeIndex = selectedIndex.clamp(0, pages.length - 1);

              final cartCount = buyerState.cartQuantities.values.fold(
                0,
                (total, quantity) => total + quantity,
              );

              return Scaffold(
                backgroundColor: const Color(0xFFFAF6EE),
                body: IndexedStack(index: safeIndex, children: pages),
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
                                : const Color(
                                    0xFF8B261D,
                                  ).withValues(alpha: 0.55),
                          );
                        }),
                        labelTextStyle: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          return GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: states.contains(WidgetState.selected)
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: states.contains(WidgetState.selected)
                                ? const Color(0xFF8B261D)
                                : const Color(
                                    0xFF8B261D,
                                  ).withValues(alpha: 0.6),
                          );
                        }),
                      ),
                      child: NavigationBar(
                        height: 78,
                        selectedIndex: safeIndex,
                        onDestinationSelected: _navigationCubit.changePage,
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Home',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.search),
                            selectedIcon: Icon(Icons.search),
                            label: 'Shop',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.favorite_border),
                            selectedIcon: Icon(Icons.favorite),
                            label: 'Wishlist',
                          ),
                          NavigationDestination(
                            icon: Badge(
                              isLabelVisible: cartCount > 0,
                              label: Text('$cartCount'),
                              child: const Icon(Icons.shopping_bag_outlined),
                            ),
                            selectedIcon: Badge(
                              isLabelVisible: cartCount > 0,
                              label: Text('$cartCount'),
                              child: const Icon(Icons.shopping_bag),
                            ),
                            label: 'Cart',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: 'Account',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
