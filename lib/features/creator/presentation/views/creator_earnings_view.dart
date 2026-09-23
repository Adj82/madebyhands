import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';

class CreatorEarningsView extends StatelessWidget {
  final String creatorId;
  final OrderRepository repository;

  const CreatorEarningsView({
    super.key,
    required this.creatorId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceOrder>>(
      stream: repository.watchCreatorOrders(creatorId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load earnings: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!
            .where((order) => order.payoutStatus != 'cancelled')
            .toList();
        final pending = orders
            .where((order) => order.payoutStatus == 'pending')
            .fold<int>(0, (sum, order) => sum + order.creatorNetAmount);
        final paid = orders
            .where((order) => order.payoutStatus == 'paid')
            .fold<int>(0, (sum, order) => sum + order.creatorNetAmount);
        final available = orders
            .where(
              (order) =>
                  order.payoutStatus == 'pending' &&
                  order.status == 'Completed',
            )
            .fold<int>(0, (sum, order) => sum + order.creatorNetAmount);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your Earnings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '₹$available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(label: 'Pending', value: pending),
                      ),
                      Expanded(
                        child: _Metric(label: 'Paid', value: paid),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Order earnings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('No earnings yet'),
                  subtitle: Text('Placed orders will appear here.'),
                ),
              )
            else
              ...orders.map(
                (order) => Card(
                  child: ListTile(
                    title: Text('Order #${_shortId(order.id)}'),
                    subtitle: Text(
                      '${order.status} • ${order.payoutStatus.toUpperCase()}',
                    ),
                    trailing: Text(
                      '₹${order.creatorNetAmount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _shortId(String id) => id.length > 6
      ? id.substring(id.length - 6).toUpperCase()
      : id.toUpperCase();
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Text(
        '₹$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
