class SavedAddress {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  String get formatted => '$addressLine, $city, $state $postalCode';

  SavedAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) => SavedAddress(
    id: id ?? this.id,
    label: label ?? this.label,
    recipientName: recipientName ?? this.recipientName,
    phone: phone ?? this.phone,
    addressLine: addressLine ?? this.addressLine,
    city: city ?? this.city,
    state: state ?? this.state,
    postalCode: postalCode ?? this.postalCode,
    isDefault: isDefault ?? this.isDefault,
  );
}
