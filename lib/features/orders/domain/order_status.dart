/// Order status helpers.
///
/// Status strings are mixed-case in Firestore: the API writes 'Placed', older
/// records use 'Accepted', 'pending' or 'Completed'. Always compare through
/// [normalize] instead of raw string equality.
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

  /// Buyer-facing bucket only — never a real stored order status. Covers
  /// every granular creator step from `inTransit` onward, once a carrier and
  /// consignment number exist.
  static const dispatched = 'dispatched';

  static const shipmentFlow = <String>[
    placed,
    confirmed,
    processing,
    inTransit,
    shipped,
    outForDelivery,
    delivered,
  ];

  /// The exact strings creators write to Firestore. `firestore.rules` only
  /// accepts these values from a creator.
  static const _storedValues = <String, String>{
    placed: 'Placed',
    confirmed: 'Confirmed',
    processing: 'Processing',
    inTransit: 'In-Transit',
    shipped: 'Shipped',
    outForDelivery: 'Out for Delivery',
    delivered: 'Delivered',
    rejected: 'Rejected',
    cancelled: 'Cancelled',
  };

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
    dispatched => 'Dispatched',
    _ => value.trim().isEmpty ? 'Status unavailable' : value,
  };

  /// Short label for badges, e.g. 'In transit'.
  static String shortLabel(String value) => switch (normalize(value)) {
    placed => 'New',
    confirmed => 'Confirmed',
    _ => label(value),
  };

  /// The Firestore value for a normalized status.
  static String storedValue(String status) =>
      _storedValues[normalize(status)] ?? status;

  static int shipmentStep(String value) =>
      shipmentFlow.indexOf(normalize(value));

  /// The next fulfilment step, or null when the order is finished.
  static String? next(String value) {
    final step = shipmentStep(value);
    if (step < 0 || step >= shipmentFlow.length - 1) return null;
    return shipmentFlow[step + 1];
  }

  static bool isRejectedOrCancelled(String value) {
    final status = normalize(value);
    return status == rejected || status == cancelled;
  }

  static bool isNew(String value) => normalize(value) == placed;

  static bool isDelivered(String value) => normalize(value) == delivered;

  /// Accepted by the creator and not yet delivered.
  static bool isInProgress(String value) {
    final step = shipmentStep(value);
    return step > 0 && step < shipmentFlow.length - 1;
  }

  /// Before dispatch, i.e. still rejectable with a refund.
  static bool canReject(String value) {
    final status = normalize(value);
    return status == placed || status == confirmed || status == processing;
  }

  /// Buyer-facing status bucket. Creators and admins still track the full
  /// granular pipeline (placed → confirmed → processing → in_transit →
  /// shipped → out_for_delivery → delivered) to manage fulfilment, but
  /// buyers see a simpler 4-step journey: "Placed" → "Confirmed" (accepted,
  /// tracking not yet available) → "Dispatched" (carrier handed off, track
  /// with the provided details) → "Delivered". Rejected and cancelled
  /// orders stay their own distinct, clearly-flagged state.
  static String buyerStatus(String value) {
    final normalized = normalize(value);
    if (normalized == delivered) return delivered;
    if (isRejectedOrCancelled(normalized)) return normalized;
    if (normalized == placed) return placed;
    final step = shipmentStep(normalized);
    if (step >= shipmentFlow.indexOf(inTransit)) return dispatched;
    return confirmed;
  }

  /// The label a buyer sees for [value] — see [buyerStatus].
  static String buyerLabel(String value) => label(buyerStatus(value));
}
