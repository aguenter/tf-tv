import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/app/shared/constants.dart';
import 'package:tv/session/view/t7_end_view.dart';

void main() {
  group('T7 – Abschluss', () {
    testWidgets('zeigt Danke-Screen mit App-Name (T7-T3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const T7EndView(),
        ),
      );

      expect(find.text('THANKS!'), findsOneWidget);
      expect(find.text(AppConstants.appName.toUpperCase()), findsOneWidget);

      final thanks = tester.widget<Text>(find.text('THANKS!'));
      expect(thanks.style?.fontSize, greaterThan(40));
    });
  });
}
