import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';
import 'package:madebyhands/init_dependencies.dart';

class OrderManagementView extends StatelessWidget {
  const OrderManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = serviceLocator<OrderRepository>();
    return StreamBuilder<List<MarketplaceOrder>>(
      stream: repository.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load orders: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        return Column(
          children: [
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => _seed(context, repository),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Create sample orders (debug only)'),
                ),
              ),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('No orders found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            title: Text(
                              'Order #${_shortId(order.id)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${order.status} • ₹${order.subtotal} • ${order.creatorName}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buyer: ${order.buyerName} (${order.buyerPhone})',
                                    ),
                                    Text('Creator: ${order.creatorName}'),
                                    Text('Address: ${order.deliveryAddress}'),
                                    const Divider(),
                                    ...order.items.map(
                                      (item) => Text(
                                        '• ${item.name} × ${item.quantity} — ₹${item.total}',
                                      ),
                                    ),
                                    const Divider(),
                                    Text('Platform fee: ₹${order.platformFee}'),
                                    Text(
                                      'Creator payout: ₹${order.creatorNetAmount}',
                                    ),
                                    Text('Payment: ${order.paymentStatus}'),
                                    Text('Payout: ${order.payoutStatus}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _seed(BuildContext context, OrderRepository repository) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create sample orders?'),
        content: const Text(
          'This writes clearly marked sample orders for registered creators. Existing sample IDs will not be duplicated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final count = await repository.seedSampleOrders();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count sample orders created.')));
    }
  }

  static String _shortId(String id) => id.length > 6
      ? id.substring(id.length - 6).toUpperCase()
      : id.toUpperCase();
}
