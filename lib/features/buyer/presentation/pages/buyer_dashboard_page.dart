import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_cubit.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_history_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/buyer/presentation/views/cart_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/home_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/profile_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/saved_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/search_tab.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';

class BuyerDashboardPage extends StatefulWidget {
  final UserEntity user;
  final BuyerRepository repository;
  final VoidCallback onLogout;

  const BuyerDashboardPage({
    super.key,
    required this.user,
    required this.repository,
    required this.onLogout,
  });

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  final Set<String> _savedProductIds = {};
  final Map<String, int> _cartQuantities = {};
  List<Product> _products = const [];
  bool _isLoadingProducts = true;
  Object? _productError;
  StreamSubscription<List<Product>>? _productSubscription;
  StreamSubscription<Set<String>>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    _productSubscription = widget.repository.watchProducts().listen(
      (products) {
        if (!mounted) return;
        setState(() {
          _products = products;
          _isLoadingProducts = false;
          _productError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isLoadingProducts = false;
          _productError = error;
        });
      },
    );
    _favoriteSubscription = widget.repository
        .watchFavoriteProductIds(widget.user.uid)
        .listen(
          (ids) {
            if (!mounted) return;
            setState(() {
              _savedProductIds
                ..clear()
                ..addAll(ids);
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load saved products.')),
            );
          },
        );
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleSaved(Product product) async {
    final wasSaved = _savedProductIds.contains(product.id);
    setState(() {
      if (wasSaved) {
        _savedProductIds.remove(product.id);
      } else {
        _savedProductIds.add(product.id);
      }
    });

    try {
      await widget.repository.setFavorite(
        userId: widget.user.uid,
        productId: product.id,
        isFavorite: !wasSaved,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedProductIds.add(product.id);
        } else {
          _savedProductIds.remove(product.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update saved products.')),
      );
    }
  }

  void _changeQuantity(Product product, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartQuantities.remove(product.id);
      } else {
        _cartQuantities[product.id] = quantity;
      }
    });
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          isSaved: _savedProductIds.contains(product.id),
          onSave: () => _toggleSaved(product),
          onAddToCart: () {
            final current = _cartQuantities[product.id] ?? 0;
            _changeQuantity(product, current + 1);
          },
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderHistoryPage(
          userId: widget.user.uid,
          repository: widget.repository,
        ),
      ),
    );
  }

  void _openAddresses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedAddressesPage(
          userId: widget.user.uid,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BuyerCubit(),
      child: BlocBuilder<BuyerCubit, int>(
        builder: (context, selectedIndex) {
          final pages = [
            HomeTab(
              userName: widget.user.name,
              products: _products,
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
              onBrowseAll: () => context.read<BuyerCubit>().changePage(1),
            ),
            SearchTab(
              products: _products,
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
            ),
            SavedTab(
              products: _products,
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
              onBrowse: () => context.read<BuyerCubit>().changePage(1),
            ),
            CartTab(
              products: _products,
              quantities: _cartQuantities,
              onQuantityChanged: _changeQuantity,
              onBrowse: () => context.read<BuyerCubit>().changePage(1),
            ),
            ProfileTab(
              user: widget.user,
              onOrders: _openOrders,
              onAddresses: _openAddresses,
              onLogout: widget.onLogout,
            ),
          ];

          Widget body;
          if (_isLoadingProducts) {
            body = const Center(child: CircularProgressIndicator());
          } else if (_productError != null) {
            body = BuyerEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load products',
              message: _productError.toString(),
            );
          } else {
            body = IndexedStack(index: selectedIndex, children: pages);
          }

          return Scaffold(
            body: SafeArea(child: body),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: context.read<BuyerCubit>().changePage,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(icon: Icon(Icons.search), label: 'Shop'),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Saved',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
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
