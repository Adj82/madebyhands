import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_cubit.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/views/cart_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/home_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/profile_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/saved_tab.dart';
import 'package:madebyhands/features/buyer/presentation/views/search_tab.dart';

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
  final Set<String> _savedProductIds = {};
  final Map<String, int> _cartQuantities = {};

  int get _cartCount =>
      _cartQuantities.values.fold(0, (total, quantity) => total + quantity);

  void _toggleSaved(Product product) {
    setState(() {
      if (!_savedProductIds.add(product.id)) {
        _savedProductIds.remove(product.id);
      }
    });
  }

  void _addToCart(Product product) {
    setState(
      () => _cartQuantities.update(
        product.id,
        (quantity) => quantity + 1,
        ifAbsent: () => 1,
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          isSaved: _savedProductIds.contains(product.id),
          onSave: () => _toggleSaved(product),
          onAddToCart: () => _addToCart(product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BuyerCubit(),
      child: BlocBuilder<BuyerCubit, int>(
        builder: (context, selectedIndex) {
          final pages = [
            HomeTab(
              userName: widget.user.name,
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
              onBrowseAll: () => context.read<BuyerCubit>().changePage(1),
            ),
            SearchTab(
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
            ),
            SavedTab(
              savedProductIds: _savedProductIds,
              onProductTap: _openProduct,
              onSave: _toggleSaved,
              onBrowse: () => context.read<BuyerCubit>().changePage(1),
            ),
            CartTab(
              quantities: _cartQuantities,
              onQuantityChanged: (product, quantity) {
                setState(() {
                  if (quantity <= 0) {
                    _cartQuantities.remove(product.id);
                  } else {
                    _cartQuantities[product.id] = quantity;
                  }
                });
              },
              onBrowse: () => context.read<BuyerCubit>().changePage(1),
            ),
            ProfileTab(user: widget.user, onLogout: widget.onLogout),
          ];

          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.read<BuyerCubit>().changePage(index),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Explore',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Saved',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: _cartCount > 0,
                    label: Text('$_cartCount'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: _cartCount > 0,
                    label: Text('$_cartCount'),
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
      ),
    );
  }
}
