import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/constants/couriers.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';
import 'package:madebyhands/init_dependencies.dart';

class CreatorOrdersView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorOrdersView({super.key, required this.profile});

  @override
  State<CreatorOrdersView> createState() => _CreatorOrdersViewState();
}

class _CreatorOrdersViewState extends State<CreatorOrdersView> {
  late final Stream<List<CreatorOrder>> _orders = serviceLocator<CreatorRepository>()
      .watchCreatorOrders(widget.profile.uid);

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
                'Could not load orders: ${friendlyErrorMessage(snapshot.error!)}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        final newOrders = orders.where((o) => OrderStatus.isNew(o.status)).toList();
        final active = orders.where((o) => OrderStatus.isInProgress(o.status)).toList();
        final closed = orders
            .where(
              (o) =>
                  OrderStatus.isDelivered(o.status) ||
                  OrderStatus.isRejectedOrCancelled(o.status),
            )
            .toList();

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'New (${newOrders.length})'),
                  Tab(text: 'Active (${active.length})'),
                  Tab(text: 'Closed (${closed.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OrderList(orders: newOrders, emptyMessage: 'No new orders.'),
                    _OrderList(orders: active, emptyMessage: 'No orders in progress.'),
                    _OrderList(orders: closed, emptyMessage: 'No completed orders yet.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<CreatorOrder> orders;
  final String emptyMessage;

  const _OrderList({required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.mutedText)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

/// Confirms with the creator, then rejects through the payment API which
/// refunds the buyer.
Future<bool> _rejectOrder(BuildContext context, CreatorOrder order) async {
  final bloc = context.read<CreatorBloc>();
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Reject order #${order.shortId}?'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The buyer is refunded in full and the items go back into stock.',
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Reason for the buyer *'),
              validator: (value) =>
                  (value?.trim().length ?? 0) < 3 ? 'Please give a short reason.' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject & refund'),
        ),
      ],
    ),
  );
  if (reason == null) return false;
  bloc.add(CreatorRejectOrder(orderId: order.id, reason: reason));
  return true;
}

class _OrderCard extends StatelessWidget {
  final CreatorOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isNew = OrderStatus.isNew(order.status);
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          builder: (_) => _OrderDetailSheet(order: order),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.shortId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Customer: ${order.buyerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              if ((order.rejectionReason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Rejected: ${order.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (isNew) ...[
                const SizedBox(height: 16),
                BlocSelector<CreatorBloc, CreatorState, bool>(
                  selector: (state) =>
                      state.isRunning(CreatorAction.rejectOrder) ||
                      state.isRunning(CreatorAction.updateOrder),
                  builder: (context, busy) => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : () => _rejectOrder(context, order),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: busy
                              ? null
                              : () => context.read<CreatorBloc>().add(
                                  CreatorUpdateOrderStatus(
                                    orderId: order.id,
                                    status: OrderStatus.confirmed,
                                  ),
                                ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (OrderStatus.normalize(status)) {
      OrderStatus.placed => Colors.blue,
      OrderStatus.confirmed => Colors.orange,
      OrderStatus.processing => Colors.amber.shade800,
      OrderStatus.inTransit => Colors.purple,
      OrderStatus.shipped => Colors.indigo,
      OrderStatus.outForDelivery => Colors.deepOrange,
      OrderStatus.delivered => Colors.green,
      OrderStatus.rejected || OrderStatus.cancelled => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        OrderStatus.shortLabel(status),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final CreatorOrder order;

  const _OrderDetailSheet({required this.order});

  void _advance(BuildContext context, String nextStatus) {
    if (nextStatus == OrderStatus.inTransit) {
      _showDispatchDialog(context);
      return;
    }
    context.read<CreatorBloc>().add(
      CreatorUpdateOrderStatus(orderId: order.id, status: nextStatus),
    );
    Navigator.pop(context);
  }

  Future<void> _showDispatchDialog(BuildContext context) async {
    final bloc = context.read<CreatorBloc>();
    final navigator = Navigator.of(context);
    final consignment = TextEditingController(text: order.consignmentNumber ?? '');
    final confirm = TextEditingController(text: order.consignmentNumber ?? '');
    String? courier = kCourierOptions.contains(order.carrierName) ? order.carrierName : null;
    final formKey = GlobalKey<FormState>();
    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
      LengthLimitingTextInputFormatter(30),
    ];

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Dispatch details'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The buyer gets these details and a tracking link.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: courier,
                decoration: const InputDecoration(labelText: 'Courier partner *'),
                items: [
                  for (final option in kCourierOptions)
                    DropdownMenuItem(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => courier = value,
                validator: (value) => value == null ? 'Select a courier.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: consignment,
                inputFormatters: formatters,
                decoration: const InputDecoration(
                  labelText: 'Consignment number *',
                  hintText: 'e.g. SP123456789IN',
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Consignment number is required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                inputFormatters: formatters,
                decoration: const InputDecoration(labelText: 'Confirm consignment number *'),
                validator: (value) => value?.trim() != consignment.text.trim()
                    ? 'Consignment numbers do not match.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Mark in transit'),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    bloc.add(
      CreatorUpdateOrderStatus(
        orderId: order.id,
        status: OrderStatus.inTransit,
        consignmentNumber: consignment.text.trim(),
        carrierName: courier,
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final next = OrderStatus.next(order.status);
    final canAdvance =
        !OrderStatus.isNew(order.status) &&
        !OrderStatus.isRejectedOrCancelled(order.status);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Order details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _infoRow('Order', '#${order.shortId}'),
                  _infoRow('Placed', DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)),
                  _infoRow('Status', OrderStatus.label(order.status)),
                  if ((order.carrierName ?? '').isNotEmpty) _infoRow('Carrier', order.carrierName!),
                  if ((order.consignmentNumber ?? '').isNotEmpty)
                    _infoRow('Consignment #', order.consignmentNumber!),
                  if ((order.rejectionReason ?? '').trim().isNotEmpty)
                    _infoRow('Rejection reason', order.rejectionReason!, isWarning: true),
                  if (order.refundStatus != null)
                    _infoRow(
                      'Refund',
                      switch (order.refundStatus) {
                        'refunded' => 'Refunded to buyer',
                        'failed' => 'Refund pending — our team will retry',
                        _ => 'Processing',
                      },
                      isWarning: order.refundStatus == 'failed',
                    ),
                  const Divider(height: 32),
                  const Text('Ship to', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(order.buyerName, style: const TextStyle(fontSize: 16)),
                  if (order.buyerPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(order.buyerPhone),
                  ],
                  const SizedBox(height: 4),
                  Text(order.deliveryAddress, style: const TextStyle(color: AppColors.mutedText)),
                  const Divider(height: 32),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  'Qty ${item.quantity} × ₹${item.unitPrice}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                ),
                                for (final entry in item.customizations.entries)
                                  Text(
                                    '${entry.key}: ${entry.value.join(', ')}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₹${item.total}'),
                        ],
                      ),
                    ),
                  const Divider(height: 32),
                  _amountRow('Items total', order.totalAmount),
                  if (order.totalAmount > order.creatorNetAmount)
                    _amountRow('Commission', -(order.totalAmount - order.creatorNetAmount)),
                  _amountRow('Your earnings', order.creatorNetAmount, emphasize: true),
                ],
              ),
            ),
            BlocSelector<CreatorBloc, CreatorState, bool>(
              selector: (state) =>
                  state.isRunning(CreatorAction.updateOrder) ||
                  state.isRunning(CreatorAction.rejectOrder),
              builder: (context, busy) {
                if (OrderStatus.isNew(order.status)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    final navigator = Navigator.of(context);
                                    if (await _rejectOrder(context, order)) navigator.pop();
                                  },
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: busy ? null : () => _advance(context, OrderStatus.confirmed),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (next != null && canAdvance) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : () => _advance(context, next),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text('Mark as ${OrderStatus.label(next).toLowerCase()}'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.mutedText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int amount, {bool emphasize = false}) {
    final style = TextStyle(
      fontSize: emphasize ? 17 : 14,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: emphasize ? AppColors.primary : null,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(amount < 0 ? '−₹${-amount}' : '₹$amount', style: style),
        ],
      ),
    );
  }
}
