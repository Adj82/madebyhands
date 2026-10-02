import 'package:flutter/material.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:flutter/services.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

Future<SavedAddress?> showSavedAddressForm(
  BuildContext context, {
  SavedAddress? existing,
}) => showModalBottomSheet<SavedAddress>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: const Color(0xFFFAF6EE),
  builder: (_) => _AddressForm(address: existing),
);

class SavedAddressesPage extends StatefulWidget {
  final String userId;
  final BuyerRepository repository;

  const SavedAddressesPage({
    super.key,
    required this.userId,
    required this.repository,
  });

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  late final Stream<List<SavedAddress>> _addresses = widget.repository
      .watchAddresses(widget.userId);

  String get userId => widget.userId;
  BuyerRepository get repository => widget.repository;

  @override
  Widget build(BuildContext context) {
    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Saved addresses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
        ),
        body: StreamBuilder<List<SavedAddress>>(
          stream: _addresses,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load addresses: ${friendlyErrorMessage(snapshot.error!)}',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B261D)),
              );
            }
            final addresses = snapshot.data!;
            if (addresses.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 64,
                        color: Color(0xFF8B261D),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No saved addresses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B261D),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add an address for quicker checkout.',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  elevation: 1,
                  color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFF8B261D),
                      width: 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                    address.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF8B261D),
                                    ),
                                  ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    const Chip(
                                      backgroundColor: Color(0xFFF2DEDD),
                                      label: Text(
                                        'Default',
                                        style: TextStyle(
                                          color: Color(0xFF8B261D),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Color(0xFF8B261D),
                              ),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final updated = await showSavedAddressForm(
                                    context,
                                    existing: address,
                                  );
                                  if (!context.mounted) return;
                                  if (updated != null) {
                                    await _saveAddress(context, updated);
                                  }
                                } else if (value == 'delete') {
                                  await _confirmDelete(context, address);
                                } else if (value == 'default') {
                                  await _saveAddress(
                                    context,
                                    address.copyWith(isDefault: true),
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (!address.isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Make default'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          address.recipientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B261D),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address.formatted,
                          style: const TextStyle(
                            height: 1.4,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          address.phone,
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: const Color(0xFF8B261D),
          foregroundColor: Colors.white,
          onPressed: () async {
            final address = await showSavedAddressForm(context);
            if (!context.mounted) return;
            if (address != null) {
              await _saveAddress(context, address);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add address'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SavedAddress address,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFFFAF6EE),
            title: const Text(
              'Delete address?',
              style: TextStyle(color: Color(0xFF8B261D)),
            ),
            content: Text('Remove your ${address.label} address?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B261D),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await repository.deleteAddress(userId, address.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete address: ${friendlyErrorMessage(error)}')),
      );
    }
  }

  Future<void> _saveAddress(BuildContext context, SavedAddress address) async {
    try {
      await repository.saveAddress(userId, address);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Could not save address: ${friendlyErrorMessage(error)}')),
      );
    }
  }
}

class _AddressForm extends StatefulWidget {
  final SavedAddress? address;

  const _AddressForm({this.address});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(
    text: widget.address?.label ?? 'Home',
  );
  late final _name = TextEditingController(
    text: widget.address?.recipientName ?? '',
  );
  late final _phone = TextEditingController(text: widget.address?.phone ?? '');
  late final _line = TextEditingController(
    text: widget.address?.addressLine ?? '',
  );
  late final _city = TextEditingController(text: widget.address?.city ?? '');
  late final _state = TextEditingController(text: widget.address?.state ?? '');
  late final _postalCode = TextEditingController(
    text: widget.address?.postalCode ?? '',
  );
  late bool _isDefault = widget.address?.isDefault ?? false;

  @override
  void dispose() {
    for (final controller in [
      _label,
      _name,
      _phone,
      _line,
      _city,
      _state,
      _postalCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.address == null ? 'Add address' : 'Edit address',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B261D),
              ),
            ),
            const SizedBox(height: 18),
            _field(
              _label,
              'Label (Home, Work)',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                LengthLimitingTextInputFormatter(20),
              ],
            ),
            _field(
              _name,
              'Recipient name',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.-]')),
                LengthLimitingTextInputFormatter(50),
              ],
            ),
            _field(
              _phone,
              'Phone number',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.isEmpty) return 'Required';
                if (digits.length != 10) return 'Must be a 10-digit mobile number';
                return null;
              },
            ),
            _field(
              _line,
              'Address line',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,./#-]')),
                LengthLimitingTextInputFormatter(150),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _city,
                    'City',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(40),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    _state,
                    'State',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      LengthLimitingTextInputFormatter(40),
                    ],
                  ),
                ),
              ],
            ),
            _field(
              _postalCode,
              'Postal code',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.isEmpty) return 'Required';
                if (digits.length != 6) return 'Must be a 6-digit postal code';
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF8B261D),
              title: const Text(
                'Make this my default address',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B261D),
              ),
              child: const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF8B261D)),
          ),
          validator: validator ??
              (value) => value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SavedAddress(
        id: widget.address?.id ?? '',
        label: _label.text.trim(),
        recipientName: _name.text.trim(),
        phone: _phone.text.trim(),
        addressLine: _line.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postalCode: _postalCode.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }
}
