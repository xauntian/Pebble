import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:water_quality_companion/app/pebble_app.dart';

void main() {
  testWidgets('renders the three core pages and switches between them',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    expect(find.text('My Health Test'), findsOneWidget);
    expect(find.text('Water Quality'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-map')));
    await tester.pumpAndSettle();

    expect(find.text('Search place'), findsOneWidget);
    expect(find.text('Animal Park'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    expect(find.text('Knowledge of Water'), findsOneWidget);
    expect(find.text('AI Search'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();

    expect(find.text('My Health Test'), findsOneWidget);
  });
}
