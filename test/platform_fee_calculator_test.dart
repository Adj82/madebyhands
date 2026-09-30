import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

void main() {
  group('PlatformFeeCalculator', () {
    test(
      'charges the flat fee to the buyer below the commission threshold',
      () {
        final result = PlatformFeeCalculator.calculate(
          subtotal: 900,
          flatFee: 50,
          percentFee: 5,
        );

        expect(result.flatFee, 50);
        expect(result.commissionAmount, 0);
        expect(result.totalFee, 50);
        expect(result.creatorNetAmount, 900);
      },
    );

    test('applies flat and percentage fees above the threshold', () {
      final result = PlatformFeeCalculator.calculate(
        subtotal: 2000,
        flatFee: 50,
        percentFee: 5,
      );

      expect(result.commissionAmount, 100);
      expect(result.totalFee, 150);
      expect(result.creatorNetAmount, 1900);
    });

    test('does not deduct the buyer fee from the creator payout', () {
      final result = PlatformFeeCalculator.calculate(
        subtotal: 30,
        flatFee: 50,
        percentFee: 5,
      );

      expect(result.totalFee, 50);
      expect(result.creatorNetAmount, 30);
    });
  });
}
