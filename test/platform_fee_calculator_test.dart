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

  group('PlatformFeeSettings', () {
    test('falls back to the API defaults when the settings doc is missing', () {
      final settings = PlatformFeeSettings.fromMap(null);

      expect(settings.flatFee, 50);
      expect(settings.percentFee, 5);
      expect(settings.flatFeePerCreator, 50);
    });

    test('reads the admin-configured fee instead of assuming 50', () {
      final settings = PlatformFeeSettings.fromMap({
        'flatFee': 75.0,
        'percentFee': 8.0,
      });

      expect(settings.flatFeePerCreator, 75);
      expect(settings.percentFee, 8);
    });

    test('rounds the flat fee the way api/create-order.js does', () {
      // Math.round(74.5) === 75 in the payment API; the checkout preview must
      // agree or the buyer is quoted a different total than Razorpay charges.
      expect(
        PlatformFeeSettings.fromMap({'flatFee': 74.5}).flatFeePerCreator,
        75,
      );
      expect(
        PlatformFeeSettings.fromMap({'flatFee': 74.4}).flatFeePerCreator,
        74,
      );
    });

    test('clamps a negative configured fee to zero like the API', () {
      expect(
        PlatformFeeSettings.fromMap({'flatFee': -10.0}).flatFeePerCreator,
        0,
      );
    });
  });
}
