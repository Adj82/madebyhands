abstract final class OrderStatus {
  static const placed = 'placed';
  static const confirmed = 'confirmed';
  static const processing = 'processing';
  static const inTransit = 'in_transit';
  static const shipped = 'shipped';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  static const shipmentFlow = <String>[
    placed,
    confirmed,
    processing,
    inTransit,
    shipped,
    outForDelivery,
    delivered,
  ];

  static String normalize(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return switch (normalized) {
      'pending' => placed,
      'accepted' => confirmed,
      'completed' => delivered,
      'intransit' => inTransit,
      _ => normalized,
    };
  }

  static String label(String value) => switch (normalize(value)) {
    placed => 'Order placed',
    confirmed => 'Order confirmed',
    processing => 'Processing',
    inTransit => 'In transit',
    shipped => 'Shipped',
    outForDelivery => 'Out for delivery',
    delivered => 'Delivered',
    rejected => 'Rejected',
    cancelled => 'Cancelled',
    _ => value.trim().isEmpty ? 'Status unavailable' : value,
  };

  static int shipmentStep(String value) =>
      shipmentFlow.indexOf(normalize(value));

  static bool isRejectedOrCancelled(String value) {
    final status = normalize(value);
    return status == rejected || status == cancelled;
  }
}
