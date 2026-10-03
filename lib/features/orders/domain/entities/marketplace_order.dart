// Platform fee math shared by checkout (display) and tests. The payment API
// (`server/fees.js`) applies the same rules when it snapshots fees onto
// each order; change both together.

/// Platform economics as stored in `settings/platform_economics`.
///
/// The payment API reads the same document, so the checkout total shown to a
/// buyer must be derived from this rather than from a hardcoded fee.
class PlatformFeeSettings {
  final double flatFee;
  final double percentFee;
  final double commissionThreshold;

  const PlatformFeeSettings({
    this.flatFee = 50,
    this.percentFee = 5,
    this.commissionThreshold = 999,
  });

  /// Matches `Math.round` in `api/create-order.js` so the client and the
  /// server agree on the per-creator flat fee.
  int get flatFeePerCreator => flatFee.round().clamp(0, 100000000);

  factory PlatformFeeSettings.fromMap(Map<String, dynamic>? data) {
    final settings = data ?? const <String, dynamic>{};
    return PlatformFeeSettings(
      flatFee: (settings['flatFee'] as num?)?.toDouble() ?? 50,
      percentFee: (settings['percentFee'] as num?)?.toDouble() ?? 5,
      commissionThreshold:
          (settings['commissionThreshold'] as num?)?.toDouble() ?? 999,
    );
  }
}

class PlatformFeeBreakdown {
  final int flatFee;
  final double commissionRate;
  final int commissionAmount;
  final int totalFee;
  final int creatorNetAmount;

  const PlatformFeeBreakdown({
    required this.flatFee,
    required this.commissionRate,
    required this.commissionAmount,
    required this.totalFee,
    required this.creatorNetAmount,
  });
}

class PlatformFeeCalculator {
  static PlatformFeeBreakdown calculate({
    required int subtotal,
    required double flatFee,
    required double percentFee,
    double commissionThreshold = 999,
  }) {
    final normalizedFlatFee = flatFee.round().clamp(0, 100000000);
    final appliedRate = subtotal > commissionThreshold
        ? percentFee.clamp(0, 100).toDouble()
        : 0.0;
    final commission = (subtotal * appliedRate / 100).round();
    final totalFee = normalizedFlatFee + commission;
    return PlatformFeeBreakdown(
      flatFee: normalizedFlatFee,
      commissionRate: appliedRate,
      commissionAmount: commission,
      totalFee: totalFee,
      creatorNetAmount: subtotal - commission,
    );
  }
}
