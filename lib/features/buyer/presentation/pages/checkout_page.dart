import 'package:flutter/material.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';

class CheckoutPage extends StatefulWidget {
  final UserEntity user;
  final List<Product> products;
  final Map<String, int> quantities;
  final BuyerRepository buyerRepository;
  final OrderRepository orderRepository;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.user,
    required this.products,
    required this.quantities,
    required this.buyerRepository,
    required this.orderRepository,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedAddressId;
  bool _isPlacing = false;

  int get _subtotal => widget.products.fold(
    0,
    (sum, product) =>
        sum + product.price * (widget.quantities[product.id] ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm order')),
      body: StreamBuilder<List<SavedAddress>>(
        stream: widget.buyerRepository.watchAddresses(widget.user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data!;
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            final defaults = addresses.where((address) => address.isDefault);
            _selectedAddressId =
                (defaults.isNotEmpty ? defaults.first : addresses.first).id;
          }
          final selected = addresses
              .where((address) => address.id == _selectedAddressId)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Delivery address',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Add a saved address from your profile before placing an order.',
                    ),
                  ),
                )
              else
                ...addresses.map(
                  (address) => Card(
                    child: ListTile(
                      onTap: () =>
                          setState(() => _selectedAddressId = address.id),
                      leading: Icon(
                        _selectedAddressId == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(address.label),
                      subtitle: Text(
                        '${address.recipientName}\n${address.formatted}\n${address.phone}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Order summary',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...widget.products.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text('By ${product.artisan}'),
                  trailing: Text(
                    '${widget.quantities[product.id]} × ₹${product.price}',
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order total'),
                trailing: Text(
                  '₹$_subtotal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Payment skipped for MVP'),
                  subtitle: Text(
                    'The order will be placed directly. No payment will be collected.',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: selected == null || _isPlacing
                    ? null
                    : () => _placeOrder(selected),
                icon: _isPlacing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Place order'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder(SavedAddress address) async {
    setState(() => _isPlacing = true);
    try {
      await widget.orderRepository.placeOrders(
        buyerId: widget.user.uid,
        buyerName: widget.user.name,
        buyerPhone: widget.user.phone,
        address: CheckoutAddress(
          recipientName: address.recipientName,
          phone: address.phone,
          addressLine: address.addressLine,
          city: address.city,
          state: address.state,
          postalCode: address.postalCode,
        ),
        items: widget.products
            .map(
              (product) => CheckoutOrderItem(
                productId: product.id,
                name: product.name,
                creatorId: product.creatorUid,
                creatorName: product.artisan,
                quantity: widget.quantities[product.id]!,
                unitPrice: product.price,
              ),
            )
            .toList(),
      );
      widget.onOrderPlaced();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order placed'),
          content: const Text(
            'Your order is now visible to the creator and admin.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}
