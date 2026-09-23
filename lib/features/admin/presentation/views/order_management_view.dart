import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class OrderManagementView extends StatelessWidget {
  const OrderManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> orders = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          orders = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          orders.sort((a, b) {
            final tA = a['createdAt'] as Timestamp?;
            final tB = b['createdAt'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });
        } else {
          // Fallback mock orders matching the required structure if Firestore has no orders yet
          orders = [
            {
              'id': '9I9HP7',
              'status': 'Placed',
              'totalAmount': 3500,
              'buyerName': 'Mayank Jaiswal',
              'buyerPhone': '8707469955',
              'buyerEmail': 'mayank.jaiswal@gmail.com',
              'sellerName': 'MadeByHands artisan',
              'sellerPhone': '9876543210',
              'sellerEmail': 'artisan@madebyhands.com',
              'deliveryAddress': 'abcd, xyz, odisha, 751024',
              'items': [
                {'name': 'painting', 'quantity': 1, 'unitPrice': 3500}
              ],
              'platformFee': 225.0,
              'payoutAmount': 3275.0,
              'paymentStatus': 'skipped',
              'payoutStatus': 'pending',
              'createdAt': Timestamp.now(),
            },
            {
              'id': 'KJ5BPF',
              'status': 'Accepted',
              'totalAmount': 5000,
              'buyerName': 'Suhani Mahajan',
              'buyerPhone': '9812345678',
              'buyerEmail': 'suhani@example.com',
              'sellerName': 'MadeByHands artisan',
              'sellerPhone': '9876543210',
              'sellerEmail': 'artisan@madebyhands.com',
              'deliveryAddress': '21 Craft Lane, Jaipur, Rajasthan 302001',
              'items': [
                {'name': 'Ceramic Pottery Set', 'quantity': 1, 'unitPrice': 5000}
              ],
              'platformFee': 300.0,
              'payoutAmount': 4700.0,
              'paymentStatus': 'paid',
              'payoutStatus': 'pending',
              'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
            },
            {
              'id': 'IJDRO4',
              'status': 'Placed',
              'totalAmount': 5000,
              'buyerName': 'Adhiraj Jain',
              'buyerPhone': '9765432109',
              'buyerEmail': 'adhiraj@example.com',
              'sellerName': 'MadeByHands artisan',
              'sellerPhone': '9876543210',
              'sellerEmail': 'artisan@madebyhands.com',
              'deliveryAddress': '56 Art Street, New Delhi 110001',
              'items': [
                {'name': 'Handmade Silk Tapestry', 'quantity': 1, 'unitPrice': 5000}
              ],
              'platformFee': 300.0,
              'payoutAmount': 4700.0,
              'paymentStatus': 'paid',
              'payoutStatus': 'pending',
              'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
            },
          ];
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream updates automatically
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderTileCard(order: order);
            },
          ),
        );
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
    final status = order['status'] as String? ?? 'Placed';
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
    final address = order['deliveryAddress'] as String? ??
        order['shippingAddress'] as String? ??
        'Address unavailable';
    final paymentStatus = order['paymentStatus'] as String? ?? 'skipped';
    final payoutStatus = order['payoutStatus'] as String? ?? 'pending';
    final consignmentNumber = order['consignmentNumber'] as String? ?? '';
    final rejectionReason = order['rejectionReason'] as String? ?? '';

    // Calculate platform fee and creator payout
    final double platformFee = order['platformFee'] != null
        ? (order['platformFee'] as num).toDouble()
        : (total > 999 ? (50.0 + (total * 0.05)) : 50.0);
    final double creatorPayout = order['payoutAmount'] != null
        ? (order['payoutAmount'] as num).toDouble()
        : (total - platformFee);

    // Items list
    final rawItems = order['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((i) {
      if (i is Map) {
        return {
          'name': i['name'] as String? ?? 'Item',
          'quantity': (i['quantity'] as num?)?.toInt() ?? 1,
          'unitPrice': (i['unitPrice'] as num?)?.toDouble() ?? (i['price'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {'name': 'Item', 'quantity': 1, 'unitPrice': 0.0};
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
          title: Text(
            'Order #$displayId',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '$status · ₹${total.toStringAsFixed(0)} · $sellerName',
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
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${item['name']} ${item['quantity']} × 1 — ₹${((item['unitPrice'] as double) * (item['quantity'] as int)).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                )),
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
