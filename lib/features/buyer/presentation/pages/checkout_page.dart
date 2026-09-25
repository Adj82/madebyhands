import 'package:flutter/material.dart';
import 'package:madebyhands/core/services/razorpay_service.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final UserEntity user;
  final List<Product> products;
  final Map<String, int> quantities;
  final BuyerRepository buyerRepository;
  final OrderRepository orderRepository;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.user,
    required this.products,
    required this.quantities,
    required this.buyerRepository,
    required this.orderRepository,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedAddressId;
  bool _isPlacing = false;
  String _paymentMethod = 'razorpay'; // 'razorpay' or 'skip'
  late RazorpayService _razorpayService;
  SavedAddress? _pendingAddress;

  static const String _razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_TeNxd2gWeMmJRp',
  );

  int get _subtotal => widget.products.fold(
        0,
        (sum, product) =>
            sum + product.price * (widget.quantities[product.id] ?? 0),
      );

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_pendingAddress != null) {
      _executeOrderPlacement(
        _pendingAddress!,
        paymentStatus: 'paid',
        paymentId: response.paymentId,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPlacing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message} (Code: ${response.code})'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected wallet: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm order')),
      body: StreamBuilder<List<SavedAddress>>(
        stream: widget.buyerRepository.watchAddresses(widget.user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data!;
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            final defaults = addresses.where((address) => address.isDefault);
            _selectedAddressId =
                (defaults.isNotEmpty ? defaults.first : addresses.first).id;
          }
          final selected = addresses
              .where((address) => address.id == _selectedAddressId)
              .firstOrNull;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            children: [
              const Text(
                'Delivery address',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Add a saved address from your profile before placing an order.',
                    ),
                  ),
                )
              else
                ...addresses.map(
                  (address) => Card(
                    child: ListTile(
                      onTap: () =>
                          setState(() => _selectedAddressId = address.id),
                      leading: Icon(
                        _selectedAddressId == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                      ),
                      title: Text(address.label),
                      subtitle: Text(
                        '${address.recipientName}\n${address.formatted}\n${address.phone}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'razorpay',
                      groupValue: _paymentMethod,
                      activeColor: AppColors.primary,
                      title: const Row(
                        children: [
                          Icon(Icons.payment, color: AppColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Razorpay Online Gateway',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text('UPI (GPay, Paytm, PhonePe), Cards, NetBanking'),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'skip',
                      groupValue: _paymentMethod,
                      activeColor: AppColors.primary,
                      title: const Row(
                        children: [
                          Icon(Icons.money_off, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Test Mode / Skip Payment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text('Instantly place order without online payment'),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order summary',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...widget.products.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text('By ${product.artisan}'),
                  trailing: Text(
                    '${widget.quantities[product.id]} × ₹${product.price}',
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order total', style: TextStyle(fontSize: 16)),
                trailing: Text(
                  '₹$_subtotal',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: selected == null || _isPlacing
                    ? null
                    : () => _initiateCheckout(selected),
                icon: _isPlacing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_paymentMethod == 'razorpay' ? Icons.lock_clock_outlined : Icons.check_circle_outline),
                label: Text(
                  _paymentMethod == 'razorpay'
                      ? 'Pay with Razorpay  ·  ₹$_subtotal'
                      : 'Place order (Test Mode)',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _initiateCheckout(SavedAddress address) {
    _pendingAddress = address;
    if (_paymentMethod == 'razorpay') {
      setState(() => _isPlacing = true);
      try {
        _razorpayService.openCheckout(
          keyId: _razorpayKeyId,
          amountInRupees: _subtotal.toDouble(),
          orderDescription: 'MADEBYHANDS Order Payment',
          name: widget.user.name,
          phone: address.phone.isNotEmpty ? address.phone : widget.user.phone,
          email: widget.user.email,
        );
      } catch (e) {
        setState(() => _isPlacing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Razorpay checkout: $e')),
        );
      }
    } else {
      _executeOrderPlacement(address, paymentStatus: 'skipped');
    }
  }

  Future<void> _executeOrderPlacement(
    SavedAddress address, {
    required String paymentStatus,
    String? paymentId,
  }) async {
    setState(() => _isPlacing = true);
    try {
      await widget.orderRepository.placeOrders(
        buyerId: widget.user.uid,
        buyerName: widget.user.name,
        buyerPhone: address.phone.isNotEmpty ? address.phone : widget.user.phone,
        address: CheckoutAddress(
          recipientName: address.recipientName,
          phone: address.phone,
          addressLine: address.addressLine,
          city: address.city,
          state: address.state,
          postalCode: address.postalCode,
        ),
        items: widget.products
            .map(
              (product) => CheckoutOrderItem(
                productId: product.id,
                name: product.name,
                creatorId: product.creatorUid,
                creatorName: product.artisan,
                quantity: widget.quantities[product.id]!,
                unitPrice: product.price,
              ),
            )
            .toList(),
      );
      widget.onOrderPlaced();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Order Placed Successfully'),
            ],
          ),
          content: Text(
            paymentStatus == 'paid'
                ? 'Payment of ₹$_subtotal confirmed via Razorpay (Payment ID: ${paymentId ?? "N/A"}). Your order is now being processed by the creator.'
                : 'Your order is now placed in test mode and visible to the creator and admin.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('View My Orders'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}
