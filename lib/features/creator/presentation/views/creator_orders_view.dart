import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:intl/intl.dart';

class CreatorOrdersView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorOrdersView({super.key, required this.profile});

  @override
  State<CreatorOrdersView> createState() => _CreatorOrdersViewState();
}

class _CreatorOrdersViewState extends State<CreatorOrdersView> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    context.read<CreatorBloc>().add(CreatorFetchOrders(widget.profile.uid));
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      _fetchOrders();
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatorBloc, CreatorState>(
      listenWhen: (previous, current) => current is CreatorFailure,
      listener: (context, state) {
        if (state is CreatorFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          _fetchOrders();
        }
      },
      buildWhen: (previous, current) =>
          current is CreatorOrdersLoaded ||
          current is CreatorLoading ||
          current is CreatorFailure,
      builder: (context, state) {
        if (state is CreatorLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CreatorOrdersLoaded) {
          final pendingOrders =
              state.orders.where((o) => o.status == 'Placed').toList();
          final activeOrders = state.orders
              .where((o) => [
                    'Accepted',
                    'Shipped',
                    'In Transit',
                    'Out for Delivery',
                    'Delivered'
                  ].contains(o.status))
              .toList();
          final completedOrders = state.orders
              .where((o) => ['Completed', 'Delivered'].contains(o.status))
              .toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Pending'),
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OrderList(
                        orders: pendingOrders,
                        emptyMessage: 'No new orders.',
                        isPending: true,
                        profile: widget.profile,
                      ),
                      _OrderList(
                        orders: activeOrders,
                        emptyMessage: 'No active orders.',
                        profile: widget.profile,
                      ),
                      _OrderList(
                        orders: completedOrders,
                        emptyMessage: 'No completed orders yet.',
                        profile: widget.profile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (state is CreatorFailure) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchOrders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _OrderList extends StatefulWidget {
  final List<CreatorOrder> orders;
  final String emptyMessage;
  final bool isPending;
  final CreatorProfile profile;

  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    this.isPending = false,
    required this.profile,
  });

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      context
          .read<CreatorBloc>()
          .add(CreatorFetchOrders(widget.profile.uid));
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: Text(
              widget.emptyMessage,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15),
        itemCount: widget.orders.length,
        itemBuilder: (context, index) {
          final order = widget.orders[index];
          return _OrderCard(
            order: order,
            isPending: widget.isPending,
            profile: widget.profile,
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CreatorOrder order;
  final bool isPending;
  final CreatorProfile profile;

  const _OrderCard({
    required this.order,
    required this.isPending,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Customer: ${order.buyerName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                  Text(
                    '₹${order.totalAmount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleAccept(BuildContext context) {
    context.read<CreatorBloc>().add(CreatorUpdateOrderStatus(
      orderId: order.id,
      status: 'Accepted',
      uid: profile.uid,
    ));
  }

  void _handleReject(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CreatorBloc>().add(CreatorUpdateOrderStatus(
                orderId: order.id,
                status: 'Rejected',
                rejectionReason: reasonController.text,
                uid: profile.uid,
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _OrderDetailSheet(order: order, profile: profile),
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
      case 'Placed': color = Colors.blue; break;
      case 'Accepted': color = Colors.orange; break;
      case 'Shipped': color = Colors.indigo; break;
      case 'In Transit': color = Colors.purple; break;
      case 'Out for Delivery': color = Colors.deepOrange; break;
      case 'Delivered': color = Colors.teal; break;
      case 'Completed': color = Colors.green; break;
      case 'Rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

class _OrderDetailSheet extends StatelessWidget {
  final CreatorOrder order;
  final CreatorProfile profile;

  const _OrderDetailSheet({required this.order, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Order ID', '#${order.id.toUpperCase()}'),
                  _infoRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)),
                  _infoRow('Status', order.status),
                  if (order.consignmentNumber != null)
                    _infoRow('Tracking ID', order.consignmentNumber!),
                  if (order.rejectionReason != null)
                    _infoRow('Rejection Reason', order.rejectionReason!, isWarning: true),
                  const Divider(height: 40),
                  const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(order.buyerName, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(order.deliveryAddress, style: const TextStyle(color: AppColors.mutedText)),
                  const Divider(height: 40),
                  const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        Text('₹${item.unitPrice * item.quantity}'),
                      ],
                    ),
                  )),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₹${order.totalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (order.status == 'Accepted')
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConsignmentDialog(context),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Mark as Shipped'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else if (['Shipped', 'In Transit', 'Out for Delivery', 'Delivered', 'Completed'].contains(order.status))
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Automatic Courier Tracking Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Subsequent statuses are automatically synced via courier ref #${order.consignmentNumber ?? "N/A"}.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConsignmentDialog(BuildContext context) {
    final consignmentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ship Order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter the consignment or reference number provided by your courier/shipping carrier.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: consignmentController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Consignment / Reference Number *',
                  hintText: 'e.g. SP123456789IN',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Consignment number is required.';
                  }
                  if (trimmed.length < 3) {
                    return 'Must be at least 3 characters long.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<CreatorBloc>().add(
                      CreatorUpdateOrderStatus(
                        orderId: order.id,
                        status: 'Shipped',
                        consignmentNumber: consignmentController.text.trim(),
                        uid: profile.uid,
                      ),
                    );
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Mark Shipped'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.mutedText))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isWarning ? Colors.red : null))),
        ],
      ),
    );
  }
}
