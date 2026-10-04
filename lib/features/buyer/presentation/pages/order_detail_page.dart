import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/core/constants/couriers.dart';
import 'package:madebyhands/core/services/invoice_pdf_service.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';
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
        appBar: AppBar(
          title: Text(
            'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
          ),
          actions: [
            IconButton(
              tooltip: 'Download invoice',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => _downloadInvoice(context, order),
            ),
            const SizedBox(width: 4),
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
        const SnackBar(
          content: Text('Could not generate the invoice. Please try again.'),
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (updateError != null) ...[
          Text(updateError!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 10),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isStopped
                        ? Colors.red.withValues(alpha: 0.12)
                        : BuyerColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isStopped
                        ? Icons.cancel_outlined
                        : normalizedStatus == OrderStatus.delivered
                        ? Icons.check_circle_outline
                        : Icons.local_shipping_outlined,
                    size: 22,
                    color: isStopped ? Colors.red : BuyerColors.maroon,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Buyers see Placed / Confirmed / Dispatched /
                      // Delivered (or Rejected / Cancelled) — not the full
                      // creator/admin fulfilment pipeline.
                      BuyerHeading(
                        OrderStatus.buyerLabel(order.status),
                        size: 18,
                        color: isStopped ? Colors.red : BuyerColors.maroonDeep,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.updatedAt == null
                            ? 'Placed on ${_date(order.createdAt)}'
                            : 'Last updated ${_dateTime(order.updatedAt!)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: BuyerColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (isStopped)
          _StoppedOrderCard(order: order)
        else
          _ShipmentTimeline(currentStatus: normalizedStatus),
        if (hasTracking) ...[
          const SizedBox(height: 14),
          _TrackingCard(order: order),
        ],
        const SizedBox(height: 22),
        const BuyerHeading('Items'),
        const SizedBox(height: 10),
        for (final item in order.items)
          _OrderItemCard(order: order, item: item),
        const SizedBox(height: 12),
        const BuyerHeading('Delivery address'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(
                      height: 1.45,
                      color: BuyerColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const BuyerHeading('Payment summary'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                if (order.subtotal > 0 && order.platformFee > 0) ...[
                  _AmountRow(label: 'Items', amount: order.subtotal),
                  const SizedBox(height: 8),
                  _AmountRow(label: 'Platform fee', amount: order.platformFee),
                  const Divider(height: 22),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text(
                        'Order total',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '₹${order.total}',
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: BuyerColors.maroon,
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

/// One purchased item. Tapping it opens the full item and order info.
class _OrderItemCard extends StatelessWidget {
  final BuyerOrder order;
  final BuyerOrderItem item;

  const _OrderItemCard({required this.order, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => _showItemSheet(context, order, item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemImage(url: item.image, size: 52, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BuyerHeading(
                        item.name,
                        size: 14.5,
                        color: BuyerColors.ink,
                        weight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          'Quantity: ${item.quantity}  ·  ₹${item.unitPrice} each',
                          for (final entry in item.customizations.entries)
                            '${entry.key}: ${entry.value.join(', ')}',
                        ].join('\n'),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: BuyerColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.total}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: BuyerColors.maroon,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: BuyerColors.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  final String url;
  final double? size;
  final double radius;

  const _ItemImage({required this.url, required this.radius, this.size});

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: BuyerColors.sand,
      child: Center(child: Icon(Icons.inventory_2_outlined)),
    );
    final image = url.isEmpty
        ? placeholder
        : Image.network(
            url,
            fit: BoxFit.cover,
            cacheWidth: size == null ? 900 : (size! * 3).round(),
            errorBuilder: (_, _, _) => placeholder,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: size == null
          ? AspectRatio(aspectRatio: 4 / 3, child: image)
          : SizedBox.square(dimension: size, child: image),
    );
  }
}

Future<void> _showItemSheet(
  BuildContext context,
  BuyerOrder order,
  BuyerOrderItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (_) => _ItemInfoSheet(order: order, item: item),
  );
}

class _ItemInfoSheet extends StatelessWidget {
  final BuyerOrder order;
  final BuyerOrderItem item;

  const _ItemInfoSheet({required this.order, required this.item});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final hasBreakdown = item.baseUnitPrice > 0 && item.customizationPrice > 0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ItemImage(url: item.image, radius: 20),
            const SizedBox(height: 16),
            BuyerHeading(item.name, size: 20),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Column(
                  children: [
                    _SheetLine(label: 'Quantity', value: '${item.quantity}'),
                    if (hasBreakdown) ...[
                      _SheetLine(
                        label: 'Base price',
                        value: '₹${item.baseUnitPrice}',
                      ),
                      _SheetLine(
                        label: 'Customisation',
                        value: '₹${item.customizationPrice}',
                      ),
                    ],
                    _SheetLine(
                      label: 'Price each',
                      value: '₹${item.unitPrice}',
                    ),
                    _SheetLine(
                      label: 'Item total',
                      value: '₹${item.total}',
                      emphasised: true,
                    ),
                  ],
                ),
              ),
            ),
            if (item.customizations.isNotEmpty) ...[
              const SizedBox(height: 18),
              const BuyerHeading('Your customisation'),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Column(
                    children: [
                      for (final entry in item.customizations.entries)
                        _SheetLine(
                          label: entry.key,
                          value: entry.value.join(', '),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const BuyerHeading('Order info'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Column(
                  children: [
                    _SheetLine(label: 'Order', value: '#$shortId'),
                    _SheetLine(
                      label: 'Placed on',
                      value: _OrderDetailBody._date(order.createdAt),
                    ),
                    _SheetLine(
                      label: 'Status',
                      value: OrderStatus.buyerLabel(order.status),
                    ),
                    _SheetLine(
                      label: 'Deliver to',
                      value: order.deliveryAddress,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasised;

  const _SheetLine({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: const TextStyle(color: BuyerColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              height: 1.4,
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
              color: emphasised ? BuyerColors.maroon : BuyerColors.ink,
              fontSize: emphasised ? 15.5 : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShipmentTimeline extends StatelessWidget {
  final String currentStatus;

  const _ShipmentTimeline({required this.currentStatus});

  // Buyers track a simplified 4-step journey. The full
  // placed→confirmed→processing→in_transit→shipped→out_for_delivery
  // pipeline stays internal to creator fulfilment and admin tracking; it
  // never surfaces here.
  static const _buyerFlow = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.dispatched,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = _buyerFlow.indexOf(
      OrderStatus.buyerStatus(currentStatus),
    );
    final bucket = OrderStatus.buyerStatus(currentStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BuyerHeading('Order progress'),
            const SizedBox(height: 14),
            for (var index = 0; index < _buyerFlow.length; index++)
              _TimelineStep(
                label: OrderStatus.label(_buyerFlow[index]),
                isComplete: index < currentStep,
                isCurrent: index == currentStep,
                showConnector: index < _buyerFlow.length - 1,
              ),
            if (bucket == OrderStatus.confirmed) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BuyerColors.blush.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      size: 18,
                      color: BuyerColors.maroon,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your order has been confirmed by the creator. '
                        'Tracking details will be available soon once it ships.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: BuyerColors.maroonDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (bucket == OrderStatus.dispatched) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BuyerColors.blush.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: BuyerColors.maroon,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your order is on its way! You can track it with the '
                        'details provided below.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: BuyerColors.maroonDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  color: active ? BuyerColors.maroon : BuyerColors.goldSoft,
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isComplete ? BuyerColors.maroon : BuyerColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              // Room for the connector down to the next step; the last
              // step ends flush so the card has no trailing gap.
              padding: EdgeInsets.only(top: 1, bottom: showConnector ? 18 : 0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent
                      ? BuyerColors.maroon
                      : active
                      ? BuyerColors.ink
                      : BuyerColors.muted,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pin_drop_outlined, size: 20),
                SizedBox(width: 8),
                Expanded(child: BuyerHeading('Tracking details')),
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
                      const SnackBar(
                        content: Text('Could not open the tracking page.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Track shipment'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
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
      Expanded(
        child: Text(label, style: const TextStyle(color: BuyerColors.body)),
      ),
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
          child: Text(label, style: const TextStyle(color: BuyerColors.muted)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: BuyerColors.ink,
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuyerHeading(
                  OrderStatus.normalize(order.status) == OrderStatus.rejected
                      ? 'Order rejected by the creator'
                      : OrderStatus.label(order.status),
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(height: 6),
                Text(
                  order.rejectionReason?.trim().isNotEmpty == true
                      ? (OrderStatus.normalize(order.status) ==
                                OrderStatus.rejected
                            ? 'Reason: ${order.rejectionReason}'
                            : order.rejectionReason!)
                      : 'Please contact support if you need more information.',
                ),
                const SizedBox(height: 8),
                Text(
                  refundStatusLabel(order.refundStatus ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
