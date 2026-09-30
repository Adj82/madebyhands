import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:madebyhands/core/services/razorpay_service.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final UserEntity user;
  final List<Product> products;
  final Map<String, int> quantities;
  final Map<String, ProductCustomizationSelection> customizations;
  final BuyerRepository buyerRepository;
  final VoidCallback onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.user,
    required this.products,
    required this.quantities,
    this.customizations = const {},
    required this.buyerRepository,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedAddressId;
  bool _isPlacing = false;
  bool _handlingPaymentCallback = false;
  late RazorpayService _razorpayService;
  PlatformFeeSettings _feeSettings = const PlatformFeeSettings();
  SavedAddress? _pendingAddress;
  String? _pendingRazorpayOrderId;
  SavedAddress? _newAddressAwaitingSelection;

  int get _subtotal => widget.products.fold(
    0,
    (sum, product) =>
        sum +
        (widget.customizations[product.id] ??
                    const ProductCustomizationSelection())
                .unitPriceFor(product) *
            (widget.quantities[product.id] ?? 0),
  );

  /// Distinct creators, counted the way `api/create-order.js` groups priced
  /// items so the fee preview matches the amount Razorpay will charge.
  int get _creatorCount => widget.products
      .map((product) => product.creatorUid)
      .where((creatorUid) => creatorUid.isNotEmpty)
      .toSet()
      .length;

  int get _platformFee => _feeSettings.flatFeePerCreator * _creatorCount;

  int get _total => _subtotal + _platformFee;

  /// What Razorpay actually captured, in rupees. Only set once the server has
  /// priced the cart, so the confirmation never quotes a client-side estimate.
  int? _chargedTotal;

  @override
  void initState() {
    super.initState();
    _loadFeeSettings();
    _razorpayService = RazorpayService();
    _razorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
      onWebPaymentSuccess: _handleWebPaymentSuccess,
      onWebPaymentFailure: _handleWebPaymentFailure,
    );
  }

  /// The admin panel can change the flat fee at any time, so the preview is
  /// read from Firestore rather than assumed. The default stays in place if
  /// the read fails; the server total is authoritative either way.
  Future<void> _loadFeeSettings() async {
    try {
      final settings = await widget.buyerRepository.getPlatformFeeSettings();
      if (!mounted) return;
      setState(() => _feeSettings = settings);
    } catch (_) {
      // Keep the default preview; create-order still prices the cart.
    }
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _confirmPayment(response.paymentId, response.orderId, response.signature);
  }

  void _handleWebPaymentSuccess(
    String? paymentId,
    String? orderId,
    String? signature,
  ) {
    _confirmPayment(paymentId, orderId, signature);
  }

  void _confirmPayment(
    String? paymentId,
    String? responseOrderId,
    String? signature,
  ) async {
    if (_handlingPaymentCallback) return;
    _handlingPaymentCallback = true;
    final orderId = responseOrderId ?? _pendingRazorpayOrderId ?? '';

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (idToken == null) {
      _handlingPaymentCallback = false;
      if (!mounted) return;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment may have completed. Sign in again and contact support before retrying.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final address = _pendingAddress;
    if (address == null) {
      _handlingPaymentCallback = false;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout address was lost. Please retry.'),
        ),
      );
      return;
    }
    _executeOrderPlacement(
      address,
      paymentId: paymentId,
      paymentSignature: signature,
      razorpayOrderId: orderId,
      idToken: idToken,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _handlingPaymentCallback = false;
    setState(() => _isPlacing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment cancelled or failed: ${response.message} (Code: ${response.code})',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet selected: ${response.walletName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: StreamBuilder<List<SavedAddress>>(
        stream: widget.buyerRepository.watchAddresses(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load saved addresses: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data!;
          final awaitingAddress = _newAddressAwaitingSelection;
          if (awaitingAddress != null) {
            final matches = addresses.where(
              (address) =>
                  address.recipientName == awaitingAddress.recipientName &&
                  address.phone == awaitingAddress.phone &&
                  address.addressLine == awaitingAddress.addressLine &&
                  address.postalCode == awaitingAddress.postalCode,
            );
            if (matches.isNotEmpty) {
              _selectedAddressId = matches.first.id;
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
                      'Delivery Address',
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
                        const Text('Add a delivery address before paying.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isPlacing ? null : _addNewAddress,
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
                          Expanded(child: Text(address.label)),
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
                'Secure payment',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: AppColors.primary),
                  title: Text('Razorpay Checkout'),
                  subtitle: Text(
                    'Pay by UPI, card, or net banking. Card details are handled by Razorpay.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Summary',
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
                    leading: CircleAvatar(
                      backgroundColor: product.color,
                      child: Icon(product.icon, color: AppColors.text),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      [
                        'By ${product.artisan}',
                        ...customization.values.entries.map(
                          (entry) => '${entry.key}: ${entry.value.join(', ')}',
                        ),
                        'Tap to view product information',
                      ].join('\n'),
                    ),
                    trailing: Text(
                      '${widget.quantities[product.id]} × ₹${customization.unitPriceFor(product)}',
                    ),
                  ),
                );
              }),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Items subtotal'),
                trailing: Text('₹$_subtotal'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Platform fee'),
                trailing: Text('₹$_platformFee'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Total payable',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Text(
                  '₹$_total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    selected == null || _isPlacing || _handlingPaymentCallback
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
                    : const Icon(Icons.lock_outline),
                label: Text('Pay with Razorpay  ·  ₹$_total'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _initiateCheckout(SavedAddress address) async {
    _pendingAddress = address;
    setState(() => _isPlacing = true);
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw StateError('Please sign in again before paying.');
      }
      // Step 1: Create Order via Backend Endpoint or REST API
      final orderData = await _razorpayService.createOrder(
        items: widget.products.map((product) {
          final customization =
              widget.customizations[product.id] ??
              const ProductCustomizationSelection();
          return {
            'productId': product.id,
            'quantity': widget.quantities[product.id] ?? 0,
            'customizations': customization.values,
          };
        }).toList(),
        idToken: idToken,
      );
      _pendingRazorpayOrderId = orderData['order_id'] as String?;

      if (_pendingRazorpayOrderId == null || _pendingRazorpayOrderId!.isEmpty) {
        throw Exception('Failed to obtain order_id from Razorpay');
      }

      // The server re-prices the cart, so trust its total over the preview.
      final serverAmount = orderData['amount'] as num?;
      if (serverAmount != null) {
        _chargedTotal = (serverAmount / 100).round();
      }

      // Step 2: Open Standard Razorpay Checkout Modal
      _razorpayService.openCheckout(
        orderId: _pendingRazorpayOrderId ?? '',
        keyId: orderData['key_id'] as String?,
        amountInRupees: (orderData['amount'] as num).toDouble() / 100,
        orderDescription: 'MADEBYHANDS Order Payment',
        name: widget.user.name,
        phone: address.phone.isNotEmpty ? address.phone : widget.user.phone,
        email: widget.user.email,
      );
    } catch (e) {
      if (!mounted) return;
      _handlingPaymentCallback = false;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not initiate Razorpay checkout: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _addNewAddress() async {
    final address = await showSavedAddressForm(context);
    if (address == null || !mounted) return;
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
          Text(product.category.toUpperCase()),
          const SizedBox(height: 6),
          Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Made by ${product.artisan}'),
          const SizedBox(height: 14),
          Text(product.description),
          const SizedBox(height: 18),
          if (!customization.isEmpty) ...[
            const Text('Your customization'),
            const SizedBox(height: 8),
            ...customization.values.entries.map(
              (entry) => Text('${entry.key}: ${entry.value.join(', ')}'),
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

  void _handleWebPaymentFailure(String error) {
    if (!mounted) return;
    setState(() => _isPlacing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment cancelled or failed: $error')),
    );
  }

  Future<void> _executeOrderPlacement(
    SavedAddress address, {
    String? paymentId,
    String? paymentSignature,
    String? razorpayOrderId,
    String? idToken,
  }) async {
    setState(() => _isPlacing = true);
    try {
      if (paymentId == null ||
          paymentSignature == null ||
          razorpayOrderId == null ||
          idToken == null) {
        throw StateError('Payment confirmation details are missing.');
      }
      await _razorpayService.finalizePaidOrder(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: paymentSignature,
        idToken: idToken,
        buyerPhone: address.phone.isNotEmpty
            ? address.phone
            : widget.user.phone,
        address: {
          'recipientName': address.recipientName,
          'phone': address.phone,
          'addressLine': address.addressLine,
          'city': address.city,
          'state': address.state,
          'postalCode': address.postalCode,
        },
        items: widget.products.map((product) {
          final customization =
              widget.customizations[product.id] ??
              const ProductCustomizationSelection();
          return {
            'productId': product.id,
            'quantity': widget.quantities[product.id] ?? 0,
            'customizations': customization.values,
          };
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
            'Payment of ₹${_chargedTotal ?? _total} confirmed by Razorpay (Payment ID: $paymentId). Your order is now with the creator.',
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
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Order confirmation failed. Check My Orders or contact support before trying again.',
            ),
          ),
        );
      }
    } finally {
      _handlingPaymentCallback = false;
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}
