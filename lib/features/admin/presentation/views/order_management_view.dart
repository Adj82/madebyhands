import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/services/payment_api.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';
import 'package:madebyhands/init_dependencies.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderManagementView extends StatefulWidget {
  const OrderManagementView({super.key});

  @override
  State<OrderManagementView> createState() => _OrderManagementViewState();
}

class _OrderManagementViewState extends State<OrderManagementView> {
  final Stream<QuerySnapshot<Map<String, dynamic>>> _orders = FirebaseFirestore
      .instance
      .collection('orders')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'New'),
            Tab(text: 'In progress'),
            Tab(text: 'Delivered'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load orders: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final orders = snapshot.data!.docs
                .map((doc) => _AdminOrder.fromDocument(doc))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: [
                _OrderList(
                  orders: orders.where((o) => OrderStatus.isNew(o.status)).toList(),
                  emptyMessage: 'No new orders.',
                ),
                _OrderList(
                  orders: orders
                      .where((o) => OrderStatus.isInProgress(o.status))
                      .toList(),
                  emptyMessage: 'No orders in progress.',
                ),
                _OrderList(
                  orders: orders
                      .where((o) => OrderStatus.isDelivered(o.status))
                      .toList(),
                  emptyMessage: 'No delivered orders yet.',
                ),
                _OrderList(
                  orders: orders
                      .where((o) => OrderStatus.isRejectedOrCancelled(o.status))
                      .toList(),
                  emptyMessage: 'No rejected orders.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminOrder {
  final String id;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  _AdminOrder(this.id, this.data, this.createdAt);

  factory _AdminOrder.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _AdminOrder(
      doc.id,
      data,
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
    );
  }

  String get status => data['status'] as String? ?? 'Placed';
  String get shortId => id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();
  int get subtotal =>
      (data['subtotal'] as num?)?.round() ??
      (data['totalAmount'] as num?)?.round() ??
      (data['total'] as num?)?.round() ??
      0;
  int get flatFee => (data['flatFee'] as num?)?.round() ?? 0;
  int get buyerTotal => (data['buyerPayableAmount'] as num?)?.round() ?? subtotal + flatFee;
  int get platformFee => (data['platformFee'] as num?)?.round() ?? flatFee;
  int get creatorNet => (data['creatorNetAmount'] as num?)?.round() ?? subtotal;
  String get paymentStatus => data['paymentStatus'] as String? ?? 'unknown';
  String get payoutStatus => data['payoutStatus'] as String? ?? 'pending';
  String? get refundStatus => data['refundStatus'] as String?;
  String get creatorId => data['creatorId'] as String? ?? '';
  String get creatorName => data['creatorName'] as String? ?? 'Creator';
  String get buyerId => data['buyerId'] as String? ?? '';
  String get buyerName => data['buyerName'] as String? ?? 'Buyer';
  String get buyerPhone => data['buyerPhone'] as String? ?? '';
  String get buyerEmail => data['buyerEmail'] as String? ?? '';
  bool get isPaid => paymentStatus == 'paid';

  String get address {
    final raw = data['shippingAddress'] ?? data['deliveryAddress'];
    if (raw is Map) {
      return [
        raw['recipientName'],
        raw['addressLine'],
        raw['city'],
        raw['state'],
        raw['postalCode'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    }
    return raw is String && raw.trim().isNotEmpty ? raw : 'Address unavailable';
  }

  List<Map<String, dynamic>> get items => (data['items'] as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class _OrderList extends StatelessWidget {
  final List<_AdminOrder> orders;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: orders.length,
      itemBuilder: (context, index) => _OrderTile(order: orders[index]),
    );
  }
}

class _OrderTile extends StatefulWidget {
  final _AdminOrder order;

  const _OrderTile({required this.order});

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _working = false;

  _AdminOrder get order => widget.order;

  Future<void> _rejectOrRetryRefund({required bool isRetry}) async {
    String reason = order.data['rejectionReason'] as String? ?? 'Rejected by admin';
    if (!isRetry) {
      final entered = await _askReason();
      if (entered == null || !mounted) return;
      reason = entered;
    }
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await serviceLocator<OrderActionsApi>().rejectOrder(
        orderId: order.id,
        reason: reason,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.warning ??
                (result.refunded
                    ? 'Order rejected and buyer refunded.'
                    : 'Order rejected.'),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reject order #${order.shortId}?'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Reason (shown to the buyer)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().isEmpty ? 'Rejected by admin' : controller.text.trim(),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reject & refund'),
          ),
        ],
      ),
    );
  }

  /// Looks up [uid]'s current phone/email from their `users` profile (the
  /// email they actually signed in with) and merges it with whatever was
  /// snapshotted onto the order itself, preferring the live profile value
  /// when present — covers older orders saved before a field existed, or
  /// a buyer/creator who added their email after placing the order.
  Future<void> _contactUser({
    required String title,
    required String uid,
    required String fallbackName,
    required String fallbackPhone,
    required String fallbackEmail,
  }) async {
    String phone = fallbackPhone;
    String email = fallbackEmail;
    String name = fallbackName;
    if (uid.isNotEmpty) {
      try {
        final user = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = user.data();
        if (data != null) {
          final liveName = data['name'] as String?;
          final livePhone = data['phone'] as String?;
          final liveEmail = data['email'] as String?;
          if ((liveName ?? '').trim().isNotEmpty) name = liveName!;
          if ((livePhone ?? '').trim().isNotEmpty) phone = livePhone!;
          if ((liveEmail ?? '').trim().isNotEmpty) email = liveEmail!;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    _showContactSheet(title: title, name: name, phone: phone, email: email);
  }

  Future<void> _contactSeller() => _contactUser(
        title: 'Contact creator',
        uid: order.creatorId,
        fallbackName: order.creatorName,
        fallbackPhone: '',
        fallbackEmail: '',
      );

  Future<void> _contactBuyer() => _contactUser(
        title: 'Contact buyer',
        uid: order.buyerId,
        fallbackName: order.buyerName,
        fallbackPhone: order.buyerPhone,
        fallbackEmail: order.buyerEmail,
      );

  void _showContactSheet({
    required String title,
    required String name,
    required String phone,
    required String email,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    Future<void> launch(Uri uri) async {
      if (!await launchUrl(uri)) {
        messenger.showSnackBar(const SnackBar(content: Text('Could not open that app.')));
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
              title: Text(phone.isEmpty ? 'Phone not available' : phone),
              trailing: phone.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Copy phone number',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        messenger.showSnackBar(const SnackBar(content: Text('Phone number copied.')));
                      },
                    ),
              onTap: phone.isEmpty ? null : () => launch(Uri(scheme: 'tel', path: phone)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text(email.isEmpty ? 'Email not available' : email),
              trailing: email.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Copy email',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        messenger.showSnackBar(const SnackBar(content: Text('Email copied.')));
                      },
                    ),
              onTap: email.isEmpty
                  ? null
                  : () => launch(
                      Uri(
                        scheme: 'mailto',
                        path: email,
                        query: 'subject=MadeByHands order ${order.shortId}',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refund = order.refundStatus;
    final canReject = order.isPaid && OrderStatus.canReject(order.status);
    final needsRefundRetry =
        order.isPaid &&
        OrderStatus.isRejectedOrCancelled(order.status) &&
        (refund == 'failed' || refund == 'processing');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Order #${order.shortId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _StatusBadge(status: order.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '₹${order.buyerTotal} · ${order.creatorName} · ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoLine('Buyer', order.buyerName),
          if (order.buyerPhone.isNotEmpty) _infoLine('Buyer phone', order.buyerPhone),
          if (order.buyerEmail.isNotEmpty) _infoLine('Buyer email', order.buyerEmail),
          _infoLine('Deliver to', order.address),
          _infoLine('Creator', order.creatorName),
          const SizedBox(height: 12),
          const Text(
            'Items',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '• ${item['name'] ?? 'Item'} × ${(item['quantity'] as num?)?.round() ?? 1}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '₹${((item['unitPrice'] as num?)?.round() ?? 0) * ((item['quantity'] as num?)?.round() ?? 1)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          _infoLine('Items subtotal', '₹${order.subtotal}'),
          _infoLine('Buyer paid', '₹${order.buyerTotal}'),
          _infoLine('Platform fee', '₹${order.platformFee}'),
          _infoLine('Creator payout', '₹${order.creatorNet}'),
          _infoLine('Payment', order.paymentStatus.toUpperCase()),
          _infoLine('Payout', order.payoutStatus.toUpperCase()),
          if (refund != null) _infoLine('Refund', refund.toUpperCase(), isError: refund == 'failed'),
          if ((order.data['carrierName'] as String?)?.isNotEmpty == true)
            _infoLine('Carrier', order.data['carrierName'] as String),
          if ((order.data['consignmentNumber'] as String?)?.isNotEmpty == true)
            _infoLine('Consignment #', order.data['consignmentNumber'] as String),
          if ((order.data['rejectionReason'] as String?)?.isNotEmpty == true)
            _infoLine('Rejection reason', order.data['rejectionReason'] as String, isError: true),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _contactBuyer,
                icon: const Icon(Icons.person, size: 18),
                label: const Text('Buyer'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
              OutlinedButton.icon(
                onPressed: _contactSeller,
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Creator'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
              if (canReject)
                FilledButton.icon(
                  onPressed: _working ? null : () => _rejectOrRetryRefund(isRetry: false),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject & refund'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(0, 40),
                  ),
                ),
              if (needsRefundRetry)
                FilledButton.icon(
                  onPressed: _working ? null : () => _rejectOrRetryRefund(isRetry: true),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Retry refund'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isError ? Colors.redAccent : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = OrderStatus.normalize(status);
    final color = switch (normalized) {
      OrderStatus.placed => Colors.blue,
      OrderStatus.confirmed || OrderStatus.processing => Colors.orange,
      OrderStatus.inTransit || OrderStatus.shipped || OrderStatus.outForDelivery => Colors.purple,
      OrderStatus.delivered => Colors.green,
      OrderStatus.rejected || OrderStatus.cancelled => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        OrderStatus.shortLabel(status).toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
