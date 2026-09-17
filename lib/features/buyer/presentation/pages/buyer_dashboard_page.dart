import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/data/mock_products.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';

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
  int _selectedIndex = 0;
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
    final pages = [
      _HomeTab(
        userName: widget.user.name,
        savedProductIds: _savedProductIds,
        onProductTap: _openProduct,
        onSave: _toggleSaved,
        onBrowseAll: () => setState(() => _selectedIndex = 1),
      ),
      _SearchTab(
        savedProductIds: _savedProductIds,
        onProductTap: _openProduct,
        onSave: _toggleSaved,
      ),
      _SavedTab(
        savedProductIds: _savedProductIds,
        onProductTap: _openProduct,
        onSave: _toggleSaved,
        onBrowse: () => setState(() => _selectedIndex = 1),
      ),
      _CartTab(
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
        onBrowse: () => setState(() => _selectedIndex = 1),
      ),
      _ProfileTab(user: widget.user, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final Set<String> savedProductIds;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onSave;
  final VoidCallback onBrowseAll;

  const _HomeTab({
    required this.userName,
    required this.savedProductIds,
    required this.onProductTap,
    required this.onSave,
    required this.onBrowseAll,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.trim().isEmpty
        ? 'there'
        : userName.trim().split(' ').first;
    return CustomScrollView(
      key: const PageStorageKey('buyer-home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MADEBYHANDS',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello, $firstName',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stories shaped by hand',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Discover thoughtful pieces made by independent Indian artisans.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.tonal(
                            onPressed: onBrowseAll,
                            child: const Text('Explore collection'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Color(0xFFE7C889),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _SectionTitle(title: 'Shop by craft'),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CategoryCard(icon: Icons.home_outlined, label: 'Decor'),
                    _CategoryCard(
                      icon: Icons.local_florist_outlined,
                      label: 'Pottery',
                    ),
                    _CategoryCard(
                      icon: Icons.diamond_outlined,
                      label: 'Jewellery',
                    ),
                    _CategoryCard(
                      icon: Icons.checkroom_outlined,
                      label: 'Textiles',
                    ),
                    _CategoryCard(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Gifts',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _SectionTitle(
                title: 'Handpicked for you',
                actionLabel: 'See all',
                onAction: onBrowseAll,
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.67,
            ),
            delegate: SliverChildBuilderDelegate(childCount: 4, (
              context,
              index,
            ) {
              final product = mockProducts[index];
              return ProductCard(
                product: product,
                isSaved: savedProductIds.contains(product.id),
                onTap: () => onProductTap(product),
                onSave: () => onSave(product),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SearchTab extends StatefulWidget {
  final Set<String> savedProductIds;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onSave;

  const _SearchTab({
    required this.savedProductIds,
    required this.onProductTap,
    required this.onSave,
  });

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Home Decor',
      'Pottery',
      'Jewellery',
      'Textiles',
      'Wellness',
      'Gifts',
    ];
    final products = mockProducts.where((product) {
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.artisan.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();

    return CustomScrollView(
      key: const PageStorageKey('buyer-search'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverList.list(
            children: [
              Text(
                'Explore handmade',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find a piece with a story behind it.',
                style: TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products, crafts or artisans',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${products.length} pieces',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: Icons.search_off,
              title: 'No pieces found',
              message: 'Try another search or category.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.67,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: products.length,
                (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    isSaved: widget.savedProductIds.contains(product.id),
                    onTap: () => widget.onProductTap(product),
                    onSave: () => widget.onSave(product),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SavedTab extends StatelessWidget {
  final Set<String> savedProductIds;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onSave;
  final VoidCallback onBrowse;

  const _SavedTab({
    required this.savedProductIds,
    required this.onProductTap,
    required this.onSave,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final products = mockProducts
        .where((product) => savedProductIds.contains(product.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Text(
            'Saved pieces',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? _EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Nothing saved yet',
                  message: 'Tap the heart on a product to keep it here.',
                  actionLabel: 'Browse products',
                  onAction: onBrowse,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.67,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      isSaved: true,
                      onTap: () => onProductTap(product),
                      onSave: () => onSave(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CartTab extends StatelessWidget {
  final Map<String, int> quantities;
  final void Function(Product, int) onQuantityChanged;
  final VoidCallback onBrowse;

  const _CartTab({
    required this.quantities,
    required this.onQuantityChanged,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final products = mockProducts
        .where((product) => quantities.containsKey(product.id))
        .toList();
    final subtotal = products.fold<int>(
      0,
      (total, product) => total + product.price * quantities[product.id]!,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Text(
            'Your cart',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? _EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  message: 'Add a handmade piece and it will appear here.',
                  actionLabel: 'Start shopping',
                  onAction: onBrowse,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final quantity = quantities[product.id]!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: product.color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                product.icon,
                                color: AppColors.text.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '₹${product.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      onQuantityChanged(product, quantity - 1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      onQuantityChanged(product, quantity + 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (products.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Text(
                        '₹$subtotal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment integration will be added with the team.',
                        ),
                      ),
                    ),
                    child: const Text('Proceed to checkout'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onLogout;

  const _ProfileTab({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? 'B'
        : user.name.trim()[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Your profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFDDE5CA),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'Buyer' : user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'My orders',
          subtitle: 'Track, return or buy again',
        ),
        const _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'Saved addresses',
          subtitle: 'Manage delivery locations',
        ),
        const _ProfileTile(
          icon: Icons.support_agent_outlined,
          title: 'Help & support',
          subtitle: 'FAQs and contact options',
        ),
        const _ProfileTile(
          icon: Icons.info_outline,
          title: 'About MadeByHands',
          subtitle: 'Our mission and artisan community',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final shouldLogout =
                await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                      'You can sign back in with your Google account.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (shouldLogout) onLogout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    margin: const EdgeInsets.only(right: 10),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFE8ECD9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 68, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title screen is coming next.'))),
    ),
  );
}
