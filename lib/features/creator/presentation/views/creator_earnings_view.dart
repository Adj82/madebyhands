import 'package:flutter/material.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';
import 'package:madebyhands/init_dependencies.dart';

/// Creator payouts derived from the fee snapshot stored on each order.
class CreatorEarningsView extends StatefulWidget {
  final String creatorId;

  const CreatorEarningsView({super.key, required this.creatorId});

  @override
  State<CreatorEarningsView> createState() => _CreatorEarningsViewState();
}

class _CreatorEarningsViewState extends State<CreatorEarningsView> {
  late final Stream<List<CreatorOrder>> _orders = serviceLocator<CreatorRepository>()
      .watchCreatorOrders(widget.creatorId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CreatorOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load earnings: ${friendlyErrorMessage(snapshot.error!)}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Same rules as Admin Finance: real paid orders, not rejected or cancelled.
        final orders = snapshot.data!
            .where(
              (order) =>
                  order.countsTowardEarnings &&
                  !OrderStatus.isRejectedOrCancelled(order.status),
            )
            .toList();
        bool isPaidOut(CreatorOrder order) => order.isPaidOut;
        int sum(Iterable<CreatorOrder> list) =>
            list.fold<int>(0, (total, order) => total + order.creatorNetAmount);

        final paid = sum(orders.where(isPaidOut));
        final available = sum(
          orders.where((order) => !isPaidOut(order) && OrderStatus.isDelivered(order.status)),
        );
        final upcoming = sum(
          orders.where((order) => !isPaidOut(order) && !OrderStatus.isDelivered(order.status)),
        );

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                    'Ready for payout',
                    style: TextStyle(color: Colors.white70),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹$available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _Metric(label: 'Awaiting delivery', value: upcoming)),
                      Expanded(child: _Metric(label: 'Paid to you', value: paid)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Earnings are released by MadeByHands after delivery, to the bank details in your profile. '
              'Orders above ₹999 carry the platform commission.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
            const SizedBox(height: 24),
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
                  subtitle: Text('Paid orders will appear here.'),
                ),
              )
            else
              for (final order in orders)
                Card(
                  child: ListTile(
                    title: Text('Order #${order.shortId}'),
                    subtitle: Text(
                      '${OrderStatus.label(order.status)} · '
                      '${isPaidOut(order) ? 'Paid out' : 'Payout pending'}'
                      '${order.totalAmount > order.creatorNetAmount ? ' · Commission ₹${order.totalAmount - order.creatorNetAmount}' : ''}',
                    ),
                    trailing: Text(
                      '₹${order.creatorNetAmount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
