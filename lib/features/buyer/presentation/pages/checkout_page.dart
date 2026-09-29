import 'package:flutter/material.dart';
import 'package:madebyhands/core/services/razorpay_service.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final UserEntity user;
  final List<Product> products;
  final Map<String, int> quantities;
  final Map<String, ProductCustomizationSelection> customizations;
  final BuyerRepository buyerRepository;
  final OrderRepository orderRepository;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.user,
    required this.products,
    required this.quantities,
    required this.customizations,
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
  SavedAddress? _newAddressAwaitingSelection;

  static const String _razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_ThYi51dfwooow6',
  );

  int get _subtotal => widget.products.fold(0, (sum, product) {
    final customization =
        widget.customizations[product.id] ??
        const ProductCustomizationSelection();
    return sum +
        customization.unitPriceFor(product) *
            (widget.quantities[product.id] ?? 0);
  });

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
        content: Text(
          'Payment failed: ${response.message} (Code: ${response.code})',
        ),
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
          final awaitingAddress = _newAddressAwaitingSelection;
          if (awaitingAddress != null) {
            final savedAddress = addresses.where(
              (address) =>
                  address.recipientName == awaitingAddress.recipientName &&
                  address.phone == awaitingAddress.phone &&
                  address.addressLine == awaitingAddress.addressLine &&
                  address.postalCode == awaitingAddress.postalCode,
            );
            if (savedAddress.isNotEmpty) {
              _selectedAddressId = savedAddress.first.id;
              _newAddressAwaitingSelection = null;
            }
          }
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delivery address',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isPlacing ? null : _addNewAddress,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add new'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Add a delivery address before placing your order.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _addNewAddress,
                          icon: const Icon(Icons.add),
                          label: const Text('Add new address'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...addresses.map(
                  (address) => Card(
                    color: _selectedAddressId == address.id
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      onTap: () =>
                          setState(() => _selectedAddressId = address.id),
                      leading: Icon(
                        _selectedAddressId == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_selectedAddressId == address.id)
                            const Chip(label: Text('Selected')),
                        ],
                      ),
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
                      subtitle: const Text(
                        'UPI (GPay, Paytm, PhonePe), Cards, NetBanking',
                      ),
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
                      subtitle: const Text(
                        'Instantly place order without online payment',
                      ),
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
              ...widget.products.map((product) {
                final customization =
                    widget.customizations[product.id] ??
                    const ProductCustomizationSelection();
                return Card(
                  child: ListTile(
                    key: ValueKey('checkout-product-${product.id}'),
                    onTap: () =>
                        _showProductInformation(product, customization),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: product.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(product.icon, color: AppColors.text),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        'By ${product.artisan}',
                        ...customization.values.entries.map(
                          (entry) => '${entry.key}: ${entry.value.join(', ')}',
                        ),
                        'Tap to view product information',
                      ].join('\n'),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.quantities[product.id]} × ₹${customization.unitPriceFor(product)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Order total',
                  style: TextStyle(fontSize: 16),
                ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _paymentMethod == 'razorpay'
                            ? Icons.lock_clock_outlined
                            : Icons.check_circle_outline,
                      ),
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

  Future<void> _addNewAddress() async {
    final address = await showSavedAddressForm(context);
    if (address == null) return;
    try {
      _newAddressAwaitingSelection = address;
      await widget.buyerRepository.saveAddress(widget.user.uid, address);
    } catch (error) {
      _newAddressAwaitingSelection = null;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save address: $error')));
    }
  }

  Future<void> _showProductInformation(
    Product product,
    ProductCustomizationSelection customization,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: product.color,
                        child: Icon(product.icon, size: 72),
                      ),
                    )
                  : ColoredBox(
                      color: product.color,
                      child: Icon(product.icon, size: 72),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Made by ${product.artisan}',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          Text(product.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 18),
          if (!customization.isEmpty) ...[
            const Text(
              'Your customization',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...customization.values.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('• ${entry.key}: ${entry.value.join(', ')}'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _priceRow('Base price', product.price),
          if (customization.additionalPrice > 0)
            _priceRow('Customization', customization.additionalPrice),
          const Divider(height: 24),
          _priceRow(
            'Price per item',
            customization.unitPriceFor(product),
            emphasized: true,
          ),
        ],
      ),
    ),
  );

  Widget _priceRow(String label, int amount, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              '₹$amount',
              style: TextStyle(
                fontSize: emphasized ? 18 : 14,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
                color: emphasized ? AppColors.primary : AppColors.text,
              ),
            ),
          ],
        ),
      );

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
        buyerPhone: address.phone.isNotEmpty
            ? address.phone
            : widget.user.phone,
        address: CheckoutAddress(
          recipientName: address.recipientName,
          phone: address.phone,
          addressLine: address.addressLine,
          city: address.city,
          state: address.state,
          postalCode: address.postalCode,
        ),
        items: widget.products.map((product) {
          final customization =
              widget.customizations[product.id] ??
              const ProductCustomizationSelection();
          return CheckoutOrderItem(
            productId: product.id,
            name: product.name,
            creatorId: product.creatorUid,
            creatorName: product.artisan,
            quantity: widget.quantities[product.id]!,
            unitPrice: customization.unitPriceFor(product),
            baseUnitPrice: product.price,
            customizationPrice: customization.additionalPrice,
            customizations: customization.values,
          );
        }).toList(),
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
