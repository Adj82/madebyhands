import 'package:flutter/material.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_detail_page.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_empty_state.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  final BuyerRepository repository;

  const OrderHistoryPage({
    super.key,
    required this.userId,
    required this.repository,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late final Stream<List<BuyerOrder>> _orders = widget.repository.watchOrders(
    widget.userId,
  );

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final userId = widget.userId;
    return BuyerBackground(
      child: Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: StreamBuilder<List<BuyerOrder>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return BuyerEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load orders',
                message: friendlyErrorMessage(snapshot.error!),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data!;
            if (orders.isEmpty) {
              return const BuyerEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your completed purchases will appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final showRefund =
                    order.refundStatus != null ||
                    OrderStatus.isRejectedOrCancelled(order.status);
                return Card(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          order: order,
                          orderUpdates: repository
                              .watchOrders(userId)
                              .map(
                                (orders) => orders.firstWhere(
                                  (candidate) => candidate.id == order.id,
                                  orElse: () => order,
                                ),
                              ),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: BuyerHeading(
                                  'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
                                  size: 16,
                                  color: BuyerColors.ink,
                                  weight: FontWeight.w700,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.updatedAt == null
                                ? 'Placed ${_date(order.createdAt)}'
                                : 'Placed ${_date(order.createdAt)}  ·  Updated ${_dateTime(order.updatedAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BuyerColors.muted,
                            ),
                          ),
                          if (showRefund) ...[
                            const SizedBox(height: 4),
                            Text(
                              refundStatusLabel(order.refundStatus ?? ''),
                              style: TextStyle(
                                color: order.refundStatus == 'refunded'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: BuyerColors.body,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${order.total}',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: BuyerColors.maroon,
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 22),
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
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _dateTime(DateTime date) =>
      '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    // Buyers see Placed / Confirmed / Dispatched / Delivered (or Rejected /
    // Cancelled) — the full creator/admin fulfilment pipeline stays internal.
    final bucket = OrderStatus.buyerStatus(status);
    final color = switch (bucket) {
      OrderStatus.delivered => Colors.green.shade800,
      OrderStatus.rejected || OrderStatus.cancelled => Colors.red.shade800,
      _ => BuyerColors.maroon,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        OrderStatus.buyerLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
