import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_detail_page.dart';

class OrderHistoryPage extends StatelessWidget {
  final String userId;
  final BuyerRepository repository;

  const OrderHistoryPage({
    super.key,
    required this.userId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: StreamBuilder<List<BuyerOrder>>(
        stream: repository.watchOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _OrderMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load orders',
              message: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const _OrderMessage(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your completed purchases will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(order: order),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _StatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _date(order.createdAt),
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                        const Divider(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                              ),
                            ),
                            Text(
                              '₹${order.total}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
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

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFDDE5CA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _OrderMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _OrderMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    ),
  );
}
