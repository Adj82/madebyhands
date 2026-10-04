import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/services/razorpay_service.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_history_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/saved_addresses_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_thumbnail.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

class CheckoutPage extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      BuyerBackground(child: _CheckoutBody(page: this));
}

/// Holds the page state below [BuyerBackground], so dialogs and sheets opened
/// from the state's own context inherit the buyer theme.
class _CheckoutBody extends StatefulWidget {
  final CheckoutPage page;

  const _CheckoutBody({required this.page});

  @override
  State<_CheckoutBody> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<_CheckoutBody> {
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
    _addresses = widget.page.buyerRepository.watchAddresses(
      widget.page.user.uid,
    );
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
      final settings = await widget.page.buyerRepository
          .getPlatformFeeSettings();
      if (mounted) setState(() => _feeSettings = settings);
    } catch (_) {
      // Keep the default preview; create-order still prices the cart.
    }
  }

  ProductCustomizationSelection _selectionFor(Product product) =>
      widget.page.customizations[product.id] ??
      const ProductCustomizationSelection();

  int get _subtotal => widget.page.products.fold(
    0,
    (sum, product) =>
        sum +
        _selectionFor(product).unitPriceFor(product) *
            (widget.page.quantities[product.id] ?? 0),
  );

  /// Distinct creators, counted the way `api/create-order.js` groups priced
  /// items, so the fee preview matches the amount Razorpay will charge.
  int get _creatorCount => widget.page.products
      .map((product) => product.creatorUid)
      .where((creatorUid) => creatorUid.isNotEmpty)
      .toSet()
      .length;

  int get _platformFee => _feeSettings.flatFeePerCreator * _creatorCount;

  int get _total => _subtotal + _platformFee;

  List<Map<String, dynamic>> get _cartLines => widget.page.products
      .map(
        (product) => <String, dynamic>{
          'productId': product.id,
          'quantity': widget.page.quantities[product.id] ?? 0,
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
        name: widget.page.user.name,
        phone: address.phone.isNotEmpty
            ? address.phone
            : widget.page.user.phone,
        email: widget.page.user.email,
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
        buyerPhone: address.phone.isNotEmpty
            ? address.phone
            : widget.page.user.phone,
        address: _addressPayload(address),
      );
      _capturedPayment = null;
      widget.page.onOrderPlaced();
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
    final user = widget.page.user;
    final repository = widget.page.buyerRepository;
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
      await widget.page.buyerRepository.saveAddress(
        widget.page.user.uid,
        address,
      );
    } catch (error) {
      _newAddressAwaitingSelection = null;
      if (mounted) {
        _showMessage(
          'Could not save address: ${friendlyErrorMessage(error)}',
          isError: true,
        );
      }
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
            final locked = _busy || _capturedPayment != null;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Row(
                  children: [
                    const Expanded(child: BuyerHeading('Delivery address')),
                    TextButton.icon(
                      onPressed: locked ? null : _addNewAddress,
                      icon: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 18,
                      ),
                      label: const Text('Add new'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (addresses.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Add a delivery address before paying.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: BuyerColors.body),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _addNewAddress,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add new address'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final address in addresses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddressOption(
                        address: address,
                        isSelected: selected?.id == address.id,
                        onTap: locked
                            ? null
                            : () => setState(
                                () => _selectedAddressId = address.id,
                              ),
                      ),
                    ),
                const SizedBox(height: 14),
                const BuyerHeading('Secure payment'),
                const SizedBox(height: 10),
                const Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Icon(Icons.lock_outline),
                    title: Text('Razorpay Checkout'),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text(
                        'Pay by UPI, card or net banking. Card details are handled by Razorpay and never stored by MadeByHands.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const BuyerHeading('Order summary'),
                const SizedBox(height: 10),
                for (final product in widget.page.products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _summaryItem(product),
                  ),
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      children: [
                        _summaryRow('Items subtotal', '₹$_subtotal'),
                        _summaryRow(
                          _creatorCount > 1
                              ? 'Platform fee (₹${_feeSettings.flatFeePerCreator} × $_creatorCount creators)'
                              : 'Platform fee',
                          '₹$_platformFee',
                        ),
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Text(
                                'Total payable',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '₹$_total',
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
                const SizedBox(height: 20),
                if (_capturedPayment != null)
                  FilledButton.icon(
                    onPressed: _busy ? null : _confirmOrder,
                    icon: _busy
                        ? const _ButtonSpinner()
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry order confirmation'),
                  )
                else
                  FilledButton.icon(
                    onPressed:
                        selected == null ||
                            _busy ||
                            widget.page.products.isEmpty
                        ? null
                        : () => _pay(selected),
                    icon: _busy
                        ? const _ButtonSpinner()
                        : const Icon(Icons.lock_outline, size: 18),
                    label: Text('Pay securely · ₹$_total'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryItem(Product product) {
    final customization = _selectionFor(product);
    return Card(
      child: ListTile(
        key: ValueKey('checkout-product-${product.id}'),
        onTap: () => _showProductInformation(product, customization),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ProductThumbnail(product: product, size: 48, radius: 12),
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
          '${widget.page.quantities[product.id] ?? 0} × ₹${customization.unitPriceFor(product)}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: BuyerColors.maroon,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: BuyerColors.body)),
        ),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
            child: ProductThumbnail(product: product, radius: 16, iconSize: 72),
          ),
          const SizedBox(height: 16),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: BuyerColors.maroon,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          BuyerHeading(
            product.name,
            size: 22,
            color: BuyerColors.ink,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 6),
          Text(
            'Made by ${product.artisan}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: BuyerColors.body,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.description,
            style: const TextStyle(height: 1.5, color: BuyerColors.body),
          ),
          const SizedBox(height: 18),
          if (!customization.isEmpty) ...[
            const BuyerHeading('Your customization', size: 15),
            const SizedBox(height: 8),
            ...customization.values.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${entry.key}: ${entry.value.join(', ')}',
                  style: const TextStyle(color: BuyerColors.body),
                ),
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
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                  color: emphasized ? BuyerColors.ink : BuyerColors.body,
                ),
              ),
            ),
            Text(
              '₹$amount',
              style: TextStyle(
                fontSize: emphasized ? 18 : 14,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                color: emphasized ? BuyerColors.maroon : BuyerColors.ink,
              ),
            ),
          ],
        ),
      );
}

/// One selectable delivery address on the checkout page.
class _AddressOption extends StatelessWidget {
  final SavedAddress address;
  final bool isSelected;
  final VoidCallback? onTap;

  const _AddressOption({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: isSelected ? BuyerColors.blush : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected ? BuyerColors.maroon : BuyerColors.line,
        width: 1.5,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BuyerHeading(
                          address.label,
                          size: 15,
                          color: BuyerColors.ink,
                          weight: FontWeight.w700,
                          maxLines: 1,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: BuyerColors.maroon,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Selected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.recipientName}\n${address.formatted}\n${address.phone}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: BuyerColors.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
