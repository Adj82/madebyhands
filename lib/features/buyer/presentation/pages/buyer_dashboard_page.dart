import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_cubit.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_history_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/checkout_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/buyer/presentation/views/cart_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/home_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/profile_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/saved_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/search_tab.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/init_dependencies.dart';
import 'package:madebyhands/features/support/presentation/pages/support_center_page.dart';

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
  SavedAddress? _selectedAddress;
  StreamSubscription<List<SavedAddress>>? _addressSubscription;

  @override
  void initState() {
    super.initState();
    _navigationCubit = BuyerCubit();
    // Initialize data streaming
    context.read<BuyerBloc>().add(BuyerWatchProducts());
    context.read<BuyerBloc>().add(BuyerWatchFavorites(widget.user.uid));
    _addressSubscription = context
        .read<BuyerBloc>()
        .repository
        .watchAddresses(widget.user.uid)
        .listen((addresses) {
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
  }

  @override
  void dispose() {
    _navigationCubit.close();
    _addressSubscription?.cancel();
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
                onSave: () => buyerBloc.add(
                  BuyerToggleFavorite(
                    userId: widget.user.uid,
                    product: product,
                  ),
                ),
                onAddToCart: () {
                  final current = state.cartQuantities[product.id] ?? 0;
                  buyerBloc.add(BuyerUpdateCartQuantity(product, current + 1));
                },
              );
            },
          ),
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
          user: widget.user,
          products: products,
          quantities: Map<String, int>.from(state.cartQuantities),
          buyerRepository: serviceLocator(),
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
                  userName: widget.user.name,
                  userId: widget.user.uid,
                  selectedAddress: _selectedAddress,
                  onAddressTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SavedAddressesPage(
                        userId: widget.user.uid,
                        repository: serviceLocator(),
                      ),
                    ),
                  ),
                  onProductTap: _openProduct,
                  onBrowseAll: () => _navigationCubit.changePage(1),
                ),
                SearchTab(userId: widget.user.uid, onProductTap: _openProduct),
                SavedTab(
                  userId: widget.user.uid,
                  onProductTap: _openProduct,
                  onBrowse: () => _navigationCubit.changePage(1),
                ),
                CartTab(
                  onBrowse: () => _navigationCubit.changePage(1),
                  onCheckout: _openCheckout,
                ),
                ProfileTab(
                  user: widget.user,
                  onOrders: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderHistoryPage(
                        userId: widget.user.uid,
                        repository: serviceLocator(),
                      ),
                    ),
                  ),
                  onAddresses: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SavedAddressesPage(
                        userId: widget.user.uid,
                        repository: serviceLocator(),
                      ),
                    ),
                  ),
                  onSupport: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupportCenterPage(
                        user: widget.user,
                        repository: serviceLocator(),
                      ),
                    ),
                  ),
                  onLogout: widget.onLogout,
                ),
              ];

              final cartCount = buyerState.cartQuantities.values.fold(
                0,
                (total, quantity) => total + quantity,
              );

              return Scaffold(
                body: SafeArea(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _navigationCubit.changePage,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.search),
                      label: 'Shop',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Saved',
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
                      label: 'Profile',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
