import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/services/razorpay_service.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_history_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_thumbnail.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

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
  late final Stream<List<SavedAddress>> _addresses;
  final RazorpayService _razorpayService = RazorpayService();
  PlatformFeeSettings _feeSettings = const PlatformFeeSettings();

  String? _selectedAddressId;
  SavedAddress? _newAddressAwaitingSelection;

  /// True from "Pay" until the order is confirmed or checkout is abandoned.
  bool _busy = false;

  /// Address the current payment is being made for.
  SavedAddress? _paymentAddress;

  /// Set once Razorpay reports success. If confirmation then fails without a
  /// refund the buyer can retry confirmation instead of paying twice.
  RazorpayPaymentResult? _capturedPayment;

  /// What Razorpay charged, in rupees, as priced by the server.
  int? _chargedTotal;

  @override
  void initState() {
    super.initState();
    _addresses = widget.buyerRepository.watchAddresses(widget.user.uid);
    _razorpayService.init(
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
    );
    _loadFeeSettings();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  /// The admin panel can change the flat fee at any time, so the preview is
  /// read from Firestore. The server total stays authoritative either way.
  Future<void> _loadFeeSettings() async {
    try {
      final settings = await widget.buyerRepository.getPlatformFeeSettings();
      if (mounted) setState(() => _feeSettings = settings);
    } catch (_) {
      // Keep the default preview; create-order still prices the cart.
    }
  }

  ProductCustomizationSelection _selectionFor(Product product) =>
      widget.customizations[product.id] ?? const ProductCustomizationSelection();

  int get _subtotal => widget.products.fold(
    0,
    (sum, product) =>
        sum +
        _selectionFor(product).unitPriceFor(product) *
            (widget.quantities[product.id] ?? 0),
  );

  /// Distinct creators, counted the way `api/create-order.js` groups priced
  /// items, so the fee preview matches the amount Razorpay will charge.
  int get _creatorCount => widget.products
      .map((product) => product.creatorUid)
      .where((creatorUid) => creatorUid.isNotEmpty)
      .toSet()
      .length;

  int get _platformFee => _feeSettings.flatFeePerCreator * _creatorCount;

  int get _total => _subtotal + _platformFee;

  List<Map<String, dynamic>> get _cartLines => widget.products
      .map(
        (product) => <String, dynamic>{
          'productId': product.id,
          'quantity': widget.quantities[product.id] ?? 0,
          'customizations': _selectionFor(product).values,
        },
      )
      .toList();

  Map<String, String> _addressPayload(SavedAddress address) => {
    'recipientName': address.recipientName,
    'phone': address.phone,
    'addressLine': address.addressLine,
    'city': address.city,
    'state': address.state,
    'postalCode': address.postalCode,
  };

  Future<void> _pay(SavedAddress address) async {
    setState(() {
      _busy = true;
      _paymentAddress = address;
    });
    try {
      final order = await _razorpayService.createOrder(items: _cartLines);
      _chargedTotal = order.amountInRupees;
      _razorpayService.openCheckout(
        order: order,
        description: 'MadeByHands order',
        name: widget.user.name,
        phone: address.phone.isNotEmpty ? address.phone : widget.user.phone,
        email: widget.user.email,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(friendlyErrorMessage(error), isError: true);
    }
  }

  void _onPaymentSuccess(RazorpayPaymentResult payment) {
    _capturedPayment = payment;
    unawaited(_confirmOrder());
  }

  void _onPaymentFailure(String message) {
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage('Payment not completed: $message', isError: true);
  }

  Future<void> _confirmOrder() async {
    final payment = _capturedPayment;
    final address = _paymentAddress;
    if (payment == null || address == null) return;
    if (mounted) setState(() => _busy = true);
    try {
      final orderIds = await _razorpayService.finalizePaidOrder(
        payment: payment,
        buyerPhone: address.phone.isNotEmpty ? address.phone : widget.user.phone,
        address: _addressPayload(address),
      );
      _capturedPayment = null;
      widget.onOrderPlaced();
      if (!mounted) return;
      setState(() => _busy = false);
      await _showSuccessDialog(payment.paymentId ?? '', orderIds.length);
    } on PaymentConfirmationException catch (error) {
      if (error.refunded) _capturedPayment = null;
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(friendlyErrorMessage(error), isError: true);
    }
  }

  Future<void> _showSuccessDialog(String paymentId, int orderCount) {
    final navigator = Navigator.of(context);
    final user = widget.user;
    final repository = widget.buyerRepository;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Order placed', textAlign: TextAlign.center),
        content: Text(
          'Payment of ₹${_chargedTotal ?? _total} is confirmed'
          '${paymentId.isEmpty ? '' : ' (ID: $paymentId)'}. '
          '${orderCount > 1 ? 'Your items were split into $orderCount orders, one per creator.' : 'Your order is now with the creator.'} '
          'You can track it from My orders.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => OrderHistoryPage(
                    userId: user.uid,
                    repository: repository,
                  ),
                ),
              );
            },
            child: const Text('Go to my orders'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _addNewAddress() async {
    final address = await showSavedAddressForm(context);
    if (address == null || !mounted) return;
    try {
      _newAddressAwaitingSelection = address;
      await widget.buyerRepository.saveAddress(widget.user.uid, address);
    } catch (error) {
      _newAddressAwaitingSelection = null;
      if (mounted) _showMessage('Could not save address: ${friendlyErrorMessage(error)}', isError: true);
    }
  }

  SavedAddress? _resolveSelectedAddress(List<SavedAddress> addresses) {
    final awaiting = _newAddressAwaitingSelection;
    if (awaiting != null) {
      final match = addresses
          .where(
            (address) =>
                address.recipientName == awaiting.recipientName &&
                address.phone == awaiting.phone &&
                address.addressLine == awaiting.addressLine &&
                address.postalCode == awaiting.postalCode,
          )
          .firstOrNull;
      if (match != null) {
        _selectedAddressId = match.id;
        _newAddressAwaitingSelection = null;
      }
    }
    final selected = addresses
        .where((address) => address.id == _selectedAddressId)
        .firstOrNull;
    if (selected != null) return selected;
    if (addresses.isEmpty) return null;
    final fallback =
        addresses.where((address) => address.isDefault).firstOrNull ??
        addresses.first;
    _selectedAddressId = fallback.id;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving mid-payment would orphan a captured payment.
      canPop: !_busy && _capturedPayment == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showMessage(
            _capturedPayment != null
                ? 'Your payment was received. Tap "Retry order confirmation" to finish.'
                : 'Please wait while your payment is processed.',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm order')),
        body: StreamBuilder<List<SavedAddress>>(
          stream: _addresses,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load saved addresses: ${friendlyErrorMessage(snapshot.error!)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final addresses = snapshot.data!;
            final selected = _resolveSelectedAddress(addresses);
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Delivery address',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _busy || _capturedPayment != null ? null : _addNewAddress,
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
                            onPressed: _busy ? null : _addNewAddress,
                            icon: const Icon(Icons.add),
                            label: const Text('Add new address'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...addresses.map((address) {
                    final isSelected = selected?.id == address.id;
                    return Card(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        onTap: _busy || _capturedPayment != null
                            ? null
                            : () => setState(() => _selectedAddressId = address.id),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: AppColors.primary,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                address.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              const Chip(
                                label: Text('Selected'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${address.recipientName}\n${address.formatted}\n${address.phone}',
                        ),
                      ),
                    );
                  }),
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
                      'Pay by UPI, card or net banking. Card details are handled by Razorpay and never stored by MadeByHands.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order summary',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...widget.products.map((product) {
                  final customization = _selectionFor(product);
                  return Card(
                    child: ListTile(
                      key: ValueKey('checkout-product-${product.id}'),
                      onTap: () => _showProductInformation(product, customization),
                      leading: ProductThumbnail(product: product, size: 44, radius: 22),
                      title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          'By ${product.artisan}',
                          ...customization.values.entries.map(
                            (entry) => '${entry.key}: ${entry.value.join(', ')}',
                          ),
                        ].join('\n'),
                      ),
                      trailing: Text(
                        '${widget.quantities[product.id] ?? 0} × ₹${customization.unitPriceFor(product)}',
                      ),
                    ),
                  );
                }),
                const Divider(),
                _summaryRow('Items subtotal', '₹$_subtotal'),
                _summaryRow(
                  _creatorCount > 1
                      ? 'Platform fee (₹${_feeSettings.flatFeePerCreator} × $_creatorCount creators)'
                      : 'Platform fee',
                  '₹$_platformFee',
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Total payable', style: TextStyle(fontSize: 16)),
                    ),
                    Text(
                      '₹$_total',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_capturedPayment != null)
                  FilledButton.icon(
                    onPressed: _busy ? null : _confirmOrder,
                    icon: _busy ? const _ButtonSpinner() : const Icon(Icons.refresh),
                    label: const Text('Retry order confirmation'),
                  )
                else
                  FilledButton.icon(
                    onPressed: selected == null || _busy || widget.products.isEmpty
                        ? null
                        : () => _pay(selected),
                    icon: _busy ? const _ButtonSpinner() : const Icon(Icons.lock_outline),
                    label: Text('Pay securely · ₹$_total'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value),
      ],
    ),
  );

  Future<void> _showProductInformation(
    Product product,
    ProductCustomizationSelection customization,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.78,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: ProductThumbnail(product: product, radius: 20, iconSize: 72),
          ),
          const SizedBox(height: 18),
          Text(product.category.toUpperCase()),
          const SizedBox(height: 6),
          Text(product.name, style: Theme.of(sheetContext).textTheme.headlineSmall),
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
          _priceRow('Price per item', customization.unitPriceFor(product), emphasized: true),
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
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}
