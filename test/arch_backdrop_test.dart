import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/arch_backdrop.dart';

void main() {
  for (final size in const [
    Size(320, 560),
    Size(360, 780),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets(
      'fills ${size.width.toInt()}x${size.height.toInt()} without errors',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: ArchBackdrop(),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ArchBackdrop)), size);
      },
    );
  }
}
