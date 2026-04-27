import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:water_quality_companion/app/pebble_app.dart';
import 'package:water_quality_companion/theme/app_colors.dart';

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
    expect(find.text('Apr 23, 2026'), findsOneWidget);

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

  testWidgets('opens water quality details outside dropdown taps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animal Park'));
    await tester.pumpAndSettle();

    expect(find.text('Water quality'), findsNothing);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water Quality'));
    await tester.pumpAndSettle();

    expect(find.text('Water quality'), findsOneWidget);
    expect(find.text('Test history score'), findsOneWidget);
  });

  testWidgets('date picker highlights only the selected water location',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water Quality'));
    await tester.pumpAndSettle();

    Color? calendarDayColor(String dateKey, String label) {
      return tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(ValueKey('water-date-day-$dateKey')),
              matching: find.text(label),
            ),
          )
          .style
          ?.color;
    }

    final inactiveDateColor = AppColors.textPrimary.withValues(alpha: 0.24);

    expect(find.text('Apr 18, 2026'), findsOneWidget);

    await tester.tap(find.text('Apr 18, 2026'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('water-date-option-animal-park-2026-04-18')),
        findsNothing);
    expect(calendarDayColor('2026-04-18', '18'), AppColors.lime);
    for (final otherLocationDate in {
      '2026-04-16': '16',
      '2026-04-17': '17',
      '2026-04-19': '19',
      '2026-04-20': '20',
      '2026-04-21': '21',
      '2026-04-22': '22',
      '2026-04-23': '23',
    }.entries) {
      expect(
        calendarDayColor(otherLocationDate.key, otherLocationDate.value),
        inactiveDateColor,
      );
    }
    expect(find.text('Apr 18, 2026'), findsOneWidget);
    expect(find.text('Apr 22, 2026'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('water-calendar-prev-month')),
    );
    await tester.pumpAndSettle();

    expect(find.text('March 2026'), findsOneWidget);
    expect(calendarDayColor('2026-03-21', '21'), AppColors.lime);

    await tester.tap(find.byKey(const ValueKey('water-date-day-2026-03-21')));
    await tester.pumpAndSettle();

    expect(find.text('Mar 21, 2026'), findsOneWidget);
    expect(find.text('Animal Park'), findsOneWidget);

    await tester.tap(find.text('Mar 21, 2026'));
    await tester.pumpAndSettle();

    expect(calendarDayColor('2026-03-21', '21'), AppColors.lime);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animal Park'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayview Pier'));
    await tester.pumpAndSettle();

    expect(find.text('Apr 16, 2026'), findsOneWidget);
    expect(find.text('Bayview Pier'), findsOneWidget);

    await tester.tap(find.text('Apr 16, 2026'));
    await tester.pumpAndSettle();

    expect(calendarDayColor('2026-04-16', '16'), AppColors.lime);
    for (final otherLocationDate in {
      '2026-04-17': '17',
      '2026-04-18': '18',
      '2026-04-19': '19',
      '2026-04-20': '20',
      '2026-04-21': '21',
      '2026-04-22': '22',
      '2026-04-23': '23',
    }.entries) {
      expect(
        calendarDayColor(otherLocationDate.key, otherLocationDate.value),
        inactiveDateColor,
      );
    }

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SF, CA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oakland, CA'));
    await tester.pumpAndSettle();

    expect(find.text('Apr 22, 2026'), findsOneWidget);

    await tester.tap(find.text('Apr 22, 2026'));
    await tester.pumpAndSettle();
    expect(calendarDayColor('2026-04-22', '22'), AppColors.lime);
    for (final otherLocationDate in {
      '2026-04-16': '16',
      '2026-04-17': '17',
      '2026-04-18': '18',
      '2026-04-19': '19',
      '2026-04-20': '20',
      '2026-04-21': '21',
      '2026-04-23': '23',
    }.entries) {
      expect(
        calendarDayColor(otherLocationDate.key, otherLocationDate.value),
        inactiveDateColor,
      );
    }
  });

  testWidgets('toggles question answers on the ask page',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    const answer =
        'TDS means total dissolved solids. It refers to tiny substances dissolved in water, such as minerals, salts, and some metals. A TDS reading helps show how "heavy" or mineral-rich the water is.';
    const secondAnswer =
        'TDS levels tell you how much dissolved material is in the water. A low number usually means fewer dissolved solids, while a high number means more minerals, salts, or other particles. However, TDS alone cannot prove water is completely safe.';

    expect(find.text(answer), findsNothing);
    expect(find.text(secondAnswer), findsNothing);

    await tester.tap(find.text('What is TDS?'));
    await tester.pumpAndSettle();

    expect(find.text(answer), findsOneWidget);

    await tester.tap(find.text('What are TDS Levels?'));
    await tester.pumpAndSettle();

    expect(find.text(answer), findsNothing);
    expect(find.text(secondAnswer), findsOneWidget);

    await tester.tap(find.text('What are TDS Levels?'));
    await tester.pumpAndSettle();

    expect(find.text(secondAnswer), findsNothing);
  });

  testWidgets('asks a suggested AI Search question',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-search-suggestion-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-search-submit')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Water quality can be updated by testing'),
      findsOneWidget,
    );

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('ai-search-suggestion-0')), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('voice icon returns type-in AI Search to normal first',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PebbleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-search-keyboard')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ai-search-input')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai-search-voice-small')));
    await tester.pumpAndSettle();

    expect(find.text('Recording...'), findsNothing);
    expect(find.byKey(const ValueKey('ai-search-input')), findsNothing);
    expect(find.byKey(const ValueKey('ai-search-voice')), findsOneWidget);
  });
}
