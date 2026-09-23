import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

void main() {
  group('PlatformFeeCalculator', () {
    test('applies only the flat fee below the commission threshold', () {
      final result = PlatformFeeCalculator.calculate(
        subtotal: 900,
        flatFee: 50,
        percentFee: 5,
      );

      expect(result.flatFee, 50);
      expect(result.commissionAmount, 0);
      expect(result.totalFee, 50);
      expect(result.creatorNetAmount, 850);
    });

    test('applies flat and percentage fees above the threshold', () {
      final result = PlatformFeeCalculator.calculate(
        subtotal: 2000,
        flatFee: 50,
        percentFee: 5,
      );

      expect(result.commissionAmount, 100);
      expect(result.totalFee, 150);
      expect(result.creatorNetAmount, 1850);
    });

    test('never creates a negative creator payout', () {
      final result = PlatformFeeCalculator.calculate(
        subtotal: 30,
        flatFee: 50,
        percentFee: 5,
      );

      expect(result.totalFee, 30);
      expect(result.creatorNetAmount, 0);
    });
  });
}
