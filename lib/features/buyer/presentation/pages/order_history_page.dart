import 'package:flutter/material.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_detail_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'My orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
        ),
        body: StreamBuilder<List<BuyerOrder>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _OrderMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load orders',
                message: friendlyErrorMessage(snapshot.error!),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B261D)),
              );
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
                  elevation: 1,
                  color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFF8B261D),
                      width: 0.8,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B261D),
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
                          if (order.refundStatus != null ||
                              OrderStatus.isRejectedOrCancelled(order.status)) ...[
                            const SizedBox(height: 3),
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
                          if (order.updatedAt != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Updated ${_dateTime(order.updatedAt!)}',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const Divider(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${order.total}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8B261D),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF8B261D),
                              ),
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
    // Buyers only ever see Confirmed / Delivered / Rejected / Cancelled —
    // the full creator/admin fulfilment pipeline stays internal.
    final bucket = OrderStatus.buyerStatus(status);
    final color = switch (bucket) {
      OrderStatus.delivered => Colors.green.shade800,
      OrderStatus.rejected || OrderStatus.cancelled => Colors.red.shade800,
      _ => const Color(0xFF8B261D),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        OrderStatus.buyerLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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
              Icon(icon, size: 64, color: const Color(0xFF8B261D)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B261D),
                ),
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
