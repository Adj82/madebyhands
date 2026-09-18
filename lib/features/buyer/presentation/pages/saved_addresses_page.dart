import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';

class SavedAddressesPage extends StatelessWidget {
  final String userId;
  final BuyerRepository repository;

  const SavedAddressesPage({
    super.key,
    required this.userId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      body: StreamBuilder<List<SavedAddress>>(
        stream: repository.watchAddresses(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load addresses: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No saved addresses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
                                Text(
                                  address.label,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 8),
                                  const Chip(label: Text('Default')),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showAddressForm(context, address);
                              } else if (value == 'delete') {
                                await _confirmDelete(context, address);
                              } else if (value == 'default') {
                                await repository.saveAddress(
                                  userId,
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
        onPressed: () => _showAddressForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
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
            title: const Text('Delete address?'),
            content: Text('Remove your ${address.label} address?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await repository.deleteAddress(userId, address.id);
  }

  Future<void> _showAddressForm(
    BuildContext context,
    SavedAddress? existing,
  ) async {
    final result = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressForm(address: existing),
    );
    if (result == null) return;
    try {
      await repository.saveAddress(userId, result);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save address: $error')));
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _field(_label, 'Label (Home, Work)'),
            _field(_name, 'Recipient name'),
            _field(_phone, 'Phone number', keyboardType: TextInputType.phone),
            _field(_line, 'Address line'),
            Row(
              children: [
                Expanded(child: _field(_city, 'City')),
                const SizedBox(width: 10),
                Expanded(child: _field(_state, 'State')),
              ],
            ),
            _field(
              _postalCode,
              'Postal code',
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Make this my default address'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: _submit, child: const Text('Save address')),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
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
