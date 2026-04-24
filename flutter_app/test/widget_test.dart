import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:water_quality_companion/app/pebble_app.dart';

void main() {
  testWidgets('renders the three core pages and switches between them',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    expect(find.text('My Health Test'), findsOneWidget);
    expect(find.text('Water Quality'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-map')));
    await tester.pumpAndSettle();

    expect(find.text('Search place'), findsOneWidget);
    expect(find.text('Animal Park'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    expect(find.text('Knowledge of Water'), findsOneWidget);
    expect(find.text('AI Search'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();

    expect(find.text('My Health Test'), findsOneWidget);
  });

  testWidgets('fits the navigation on a narrow phone viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-ask')), findsOneWidget);
  });
}
