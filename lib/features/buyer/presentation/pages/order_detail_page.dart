import 'package:flutter/material.dart';
import 'package:madebyhands/core/constants/couriers.dart';
import 'package:madebyhands/core/services/invoice_pdf_service.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';
import 'package:url_launcher/url_launcher.dart';

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
            'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          actions: [
            IconButton(
              tooltip: 'Download invoice',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _downloadInvoice(context, order),
            ),
          ],
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

/// Builds the buyer-copy invoice PDF for [order] and hands it to the
/// platform's share/download sheet.
Future<void> _downloadInvoice(BuildContext context, BuyerOrder order) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final data = InvoiceData.buyerCopy(
      orderId: order.id,
      invoiceDate: order.createdAt,
      billToName: order.buyerName,
      billToAddressLines: order.deliveryAddress
          .split(',')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
      items: order.items
          .map(
            (item) => InvoiceLineItem(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ),
          )
          .toList(),
      subtotal: order.subtotal > 0
          ? order.subtotal
          : order.items.fold<int>(0, (total, item) => total + item.total),
      buyerTotalPaid: order.total,
    );
    await InvoicePdfService.downloadOrShare(data);
  } catch (error) {
    logInvoiceError(error);
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not generate the invoice. Please try again.')),
      );
    }
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
                        // Buyers only ever see Confirmed/Delivered (or
                        // Rejected/Cancelled, unchanged) — not the full
                        // creator/admin fulfilment pipeline.
                        OrderStatus.buyerLabel(order.status),
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
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 44,
                  child: item.image.isEmpty
                      ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF8B261D))
                      : Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          cacheWidth: 132,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF8B261D),
                          ),
                        ),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B261D),
                ),
              ),
              subtitle: Text(
                [
                  'Quantity: ${item.quantity}  ·  ₹${item.unitPrice} each',
                  for (final entry in item.customizations.entries)
                    '${entry.key}: ${entry.value.join(', ')}',
                ].join('\n'),
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
            child: Column(
              children: [
                if (order.subtotal > 0 && order.platformFee > 0) ...[
                  _AmountRow(label: 'Items', amount: order.subtotal),
                  const SizedBox(height: 6),
                  _AmountRow(label: 'Platform fee', amount: order.platformFee),
                  const Divider(height: 20),
                ],
                Row(
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

  // Buyers only track two milestones — Confirmed, then Delivered. The full
  // placed→confirmed→processing→in_transit→shipped→out_for_delivery
  // pipeline stays internal to creator fulfilment and admin tracking; it
  // never surfaces here.
  static const _buyerFlow = [OrderStatus.confirmed, OrderStatus.delivered];

  @override
  Widget build(BuildContext context) {
    final currentStep = OrderStatus.buyerStatus(currentStatus) ==
            OrderStatus.delivered
        ? 1
        : 0;
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
              'Order progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B261D),
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _buyerFlow.length; index++)
              _TimelineStep(
                label: OrderStatus.label(_buyerFlow[index]),
                isComplete: index < currentStep,
                isCurrent: index == currentStep,
                showConnector: index < _buyerFlow.length - 1,
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
            if (_trackingUri(order) != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final opened = await launchUrl(
                    _trackingUri(order)!,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the tracking page.')),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Track shipment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B261D),
                  side: const BorderSide(color: Color(0xFF8B261D)),
                ),
              ),
            ],
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

  static Uri? _trackingUri(BuyerOrder order) {
    final explicit = order.trackingUrl?.trim() ?? '';
    final parsed = explicit.isEmpty ? null : Uri.tryParse(explicit);
    if (parsed != null && parsed.hasScheme) return parsed;
    return courierTrackingUri(order.carrierName, order.consignmentNumber);
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final int amount;

  const _AmountRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.mutedText))),
      Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
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
                    if (order.refundStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        refundStatusLabel(order.refundStatus!),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
