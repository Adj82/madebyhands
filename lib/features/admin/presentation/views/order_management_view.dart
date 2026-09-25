import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class OrderManagementView extends StatelessWidget {
  const OrderManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const TabBar(
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load orders from database',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.mutedText),
                      SizedBox(height: 12),
                      Text(
                        'No orders found in the database.',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allOrders = docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();

            allOrders.sort((a, b) {
              final tA = a['createdAt'] as Timestamp?;
              final tB = b['createdAt'] as Timestamp?;
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });

            // Filter orders across 3 segregated tabs
            final pendingOrders = allOrders.where((o) {
              final status = (o['status'] as String? ?? 'Placed').trim();
              return status == 'Placed' || status == 'Pending';
            }).toList();

            final activeOrders = allOrders.where((o) {
              final status = (o['status'] as String? ?? '').trim();
              return ['Accepted', 'Shipped', 'In-transit', 'Out for Delivery', 'Processing'].contains(status);
            }).toList();

            final completedOrders = allOrders.where((o) {
              final status = (o['status'] as String? ?? '').trim();
              return ['Delivered', 'Completed', 'Rejected', 'Cancelled'].contains(status);
            }).toList();

            return TabBarView(
              children: [
                _OrderList(orders: pendingOrders, emptyMessage: 'No pending / newly placed orders.'),
                _OrderList(orders: activeOrders, emptyMessage: 'No active / processing orders.'),
                _OrderList(orders: completedOrders, emptyMessage: 'No completed or past orders.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String emptyMessage;

  const _OrderList({
    required this.orders,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderTileCard(order: order);
      },
    );
  }
}

class _OrderTileCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderTileCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final id = (order['id'] as String? ?? 'UNKNOWN').toUpperCase();
    final displayId = id.length > 6 ? id.substring(id.length - 6) : id;
    final status = (order['status'] as String? ?? 'Placed').trim();
    final total = (order['totalAmount'] as num?)?.toDouble() ??
        (order['total'] as num?)?.toDouble() ??
        0.0;
    final sellerName = order['sellerName'] as String? ??
        order['creatorName'] as String? ??
        order['artisan'] as String? ??
        'MadeByHands artisan';
    final buyerName = order['buyerName'] as String? ?? 'Customer';
    final buyerPhone = order['buyerPhone'] as String? ?? order['phone'] as String? ?? 'N/A';
    final buyerEmail = order['buyerEmail'] as String? ?? '';
    final sellerPhone = order['sellerPhone'] as String? ?? 'N/A';
    final sellerEmail = order['sellerEmail'] as String? ?? '';
    final paymentStatus = order['paymentStatus'] as String? ?? 'skipped';
    final payoutStatus = order['payoutStatus'] as String? ?? 'pending';
    final consignmentNumber = order['consignmentNumber'] as String? ?? '';
    final rejectionReason = order['rejectionReason'] as String? ?? '';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();

    // Safely extract address (whether stored as Map or String)
    String address = 'Address unavailable';
    final rawAddress = order['shippingAddress'] ?? order['deliveryAddress'];
    if (rawAddress is Map) {
      final map = Map<String, dynamic>.from(rawAddress);
      final parts = [
        map['addressLine'],
        map['city'],
        map['state'],
        map['postalCode'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
      address = parts.isNotEmpty
          ? parts.join(', ')
          : (map['recipientName'] as String? ?? 'Address provided');
    } else if (rawAddress is String && rawAddress.trim().isNotEmpty) {
      address = rawAddress;
    }

    // Calculate platform fee and creator payout safely
    final double platformFee = order['platformFee'] != null
        ? (order['platformFee'] as num).toDouble()
        : (total > 999 ? (50.0 + (total * 0.05)) : 50.0);
    final double creatorPayout = order['payoutAmount'] != null
        ? (order['payoutAmount'] as num).toDouble()
        : (total - platformFee);

    // Safely parse items list
    final rawItems = order['items'] as List<dynamic>? ?? [];
    final items = rawItems.whereType<Map>().map((i) {
      final map = Map<String, dynamic>.from(i);
      return {
        'name': map['name'] as String? ?? 'Item',
        'quantity': (map['quantity'] as num?)?.toInt() ?? 1,
        'unitPrice': (map['unitPrice'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent, width: 0),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent, width: 0),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Row(
            children: [
              Text(
                'Order #$displayId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              _StatusBadge(status: status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              '₹${total.toStringAsFixed(0)} · $sellerName${createdAt != null ? " · ${DateFormat('dd MMM yyyy').format(createdAt)}" : ""}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
              ),
            ),
          ),
          children: [
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 12),
            _infoLine('Buyer', '$buyerName ($buyerPhone)'),
            const SizedBox(height: 4),
            _infoLine('Creator', sellerName),
            const SizedBox(height: 4),
            _infoLine('Address', address),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 12),
            ...items.map((item) {
              final name = item['name'] as String? ?? 'Item';
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
              final itemTotal = quantity * unitPrice;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $name x $quantity — ₹${itemTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 12),
            _infoLine('Platform fee', '₹${platformFee.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            _infoLine('Creator payout', '₹${creatorPayout.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            _infoLine('Payment', paymentStatus),
            const SizedBox(height: 4),
            _infoLine('Payout', payoutStatus),
            if (consignmentNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoLine('Tracking #', consignmentNumber),
            ],
            if (rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoLine('Rejection Reason', rejectionReason, isError: true),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showContactModal(
                    context,
                    title: 'Contact Buyer',
                    name: buyerName,
                    phone: buyerPhone,
                    email: buyerEmail,
                    role: 'Buyer',
                  ),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Contact Buyer'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outline),
                    foregroundColor: AppColors.text,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _showContactModal(
                    context,
                    title: 'Contact Seller',
                    name: sellerName,
                    phone: sellerPhone,
                    email: sellerEmail,
                    role: 'Creator / Seller',
                  ),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Contact Seller'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outline),
                    foregroundColor: AppColors.text,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
              ),
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

  void _showContactModal(
    BuildContext context, {
    required String title,
    required String name,
    required String phone,
    required String email,
    required String role,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(role, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ),
                  const Divider(),
                  if (phone.isNotEmpty && phone != 'N/A')
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                      title: Text(phone),
                      subtitle: const Text('Phone Number'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy Phone Number',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied $phone to clipboard')),
                          );
                        },
                      ),
                    ),
                  if (email.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                      title: Text(email),
                      subtitle: const Text('Email Address'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy Email',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied $email to clipboard')),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (phone.isNotEmpty && phone != 'N/A')
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling $name ($phone)...')),
                        );
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                if (phone.isNotEmpty && phone != 'N/A') const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$name: $phone ($email)'));
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied contact info for $name')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Contact Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Placed':
      case 'Pending':
        color = Colors.blue;
        break;
      case 'Accepted':
      case 'Processing':
        color = Colors.orange;
        break;
      case 'Shipped':
      case 'In-transit':
      case 'Out for Delivery':
        color = Colors.purple;
        break;
      case 'Delivered':
      case 'Completed':
        color = Colors.green;
        break;
      case 'Rejected':
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
