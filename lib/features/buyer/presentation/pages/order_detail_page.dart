import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

class OrderDetailPage extends StatelessWidget {
  final BuyerOrder order;
  final Stream<BuyerOrder>? orderUpdates;

  const OrderDetailPage({super.key, required this.order, this.orderUpdates});

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Order #${order.id}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
        ),
        body: orderUpdates == null
            ? _OrderDetailBody(order: order)
            : StreamBuilder<BuyerOrder>(
                stream: orderUpdates,
                initialData: order,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _OrderDetailBody(
                      order: order,
                      updateError: 'Live updates are temporarily unavailable.',
                    );
                  }
                  return _OrderDetailBody(order: snapshot.data ?? order);
                },
              ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final BuyerOrder order;
  final String? updateError;

  const _OrderDetailBody({required this.order, this.updateError});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = OrderStatus.normalize(order.status);
    final isStopped = OrderStatus.isRejectedOrCancelled(normalizedStatus);
    final hasTracking = [
      order.consignmentNumber,
      order.carrierName,
      order.trackingUrl,
      order.lastLocation,
    ].any((value) => value != null && value.trim().isNotEmpty);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (updateError != null) ...[
          Text(updateError!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 10),
        ],
        Card(
          elevation: 1,
          color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isStopped
                      ? Colors.red.withValues(alpha: 0.12)
                      : const Color(0xFFF2DEDD),
                  child: Icon(
                    isStopped
                        ? Icons.cancel_outlined
                        : normalizedStatus == OrderStatus.delivered
                        ? Icons.check_circle_outline
                        : Icons.local_shipping_outlined,
                    color: isStopped ? Colors.red : const Color(0xFF8B261D),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        OrderStatus.label(order.status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B261D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.updatedAt == null
                            ? 'Placed on ${_date(order.createdAt)}'
                            : 'Last updated ${_dateTime(order.updatedAt!)}',
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isStopped)
          _StoppedOrderCard(order: order)
        else
          _ShipmentTimeline(currentStatus: normalizedStatus),
        if (hasTracking) ...[
          const SizedBox(height: 18),
          _TrackingCard(order: order),
        ],
        const SizedBox(height: 22),
        const Text(
          'Items',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B261D),
          ),
        ),
        const SizedBox(height: 10),
        ...order.items.map(
          (item) => Card(
            elevation: 1,
            color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF8B261D).withValues(alpha: 0.3),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF8B261D),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B261D),
                ),
              ),
              subtitle: Text(
                'Quantity: ${item.quantity}  ·  ₹${item.unitPrice} each',
              ),
              trailing: Text(
                '₹${item.total}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B261D),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Delivery address',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B261D),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF8B261D).withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF8B261D),
            ),
            title: Text(
              order.deliveryAddress,
              style: const TextStyle(height: 1.4, color: AppColors.text),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 1,
          color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Order total',
                    style: TextStyle(fontSize: 17, color: Color(0xFF2C1810)),
                  ),
                ),
                Text(
                  '₹${order.total}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B261D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _dateTime(DateTime date) =>
      '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _ShipmentTimeline extends StatelessWidget {
  final String currentStatus;

  const _ShipmentTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentStep = OrderStatus.shipmentStep(currentStatus);
    return Card(
      elevation: 1,
      color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipment progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B261D),
              ),
            ),
            const SizedBox(height: 16),
            for (
              var index = 0;
              index < OrderStatus.shipmentFlow.length;
              index++
            )
              _TimelineStep(
                label: OrderStatus.label(OrderStatus.shipmentFlow[index]),
                isComplete: index < currentStep,
                isCurrent: index == currentStep,
                showConnector: index < OrderStatus.shipmentFlow.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isComplete;
  final bool isCurrent;
  final bool showConnector;

  const _TimelineStep({
    required this.label,
    required this.isComplete,
    required this.isCurrent,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    final active = isComplete || isCurrent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  isComplete
                      ? Icons.check_circle
                      : isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: active ? const Color(0xFF8B261D) : AppColors.outline,
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isComplete
                          ? const Color(0xFF8B261D)
                          : AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: active ? const Color(0xFF8B261D) : AppColors.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final BuyerOrder order;

  const _TrackingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF8B261D), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pin_drop_outlined, color: Color(0xFF8B261D)),
                SizedBox(width: 10),
                Text(
                  'Tracking details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B261D),
                  ),
                ),
              ],
            ),
            if (_hasValue(order.carrierName))
              _TrackingRow(label: 'Carrier', value: order.carrierName!),
            if (_hasValue(order.consignmentNumber))
              _TrackingRow(
                label: 'Consignment number',
                value: order.consignmentNumber!,
              ),
            if (_hasValue(order.lastLocation))
              _TrackingRow(label: 'Last location', value: order.lastLocation!),
            if (_hasValue(order.trackingUrl))
              _TrackingRow(label: 'Tracking link', value: order.trackingUrl!),
            if (order.trackingUpdatedAt != null)
              _TrackingRow(
                label: 'Tracking updated',
                value: _OrderDetailBody._dateTime(order.trackingUpdatedAt!),
              ),
          ],
        ),
      ),
    );
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class _TrackingRow extends StatelessWidget {
  final String label;
  final String value;

  const _TrackingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B261D),
                ),
              ),
            ),
          ],
        ),
      );
}

class _StoppedOrderCard extends StatelessWidget {
  final BuyerOrder order;

  const _StoppedOrderCard({required this.order});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.red, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      OrderStatus.label(order.status),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.rejectionReason?.trim().isNotEmpty == true
                          ? order.rejectionReason!
                          : 'Please contact support if you need more information.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
