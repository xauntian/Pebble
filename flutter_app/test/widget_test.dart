import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:water_quality_companion/app/pebble_app.dart';
import 'package:water_quality_companion/services/ask_ai_responder.dart';
import 'package:water_quality_companion/services/water_quality_reports_api.dart';
import 'package:water_quality_companion/theme/app_colors.dart';

Future<void> _pumpPebbleApp(WidgetTester tester) {
  return tester.pumpWidget(
    const PebbleApp(askAiResponder: LocalAskAiResponder()),
  );
}

void main() {
  testWidgets('renders the three core pages and switches between them',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('My Health Test'), findsOneWidget);
    expect(find.text('Water Quality'), findsOneWidget);
    expect(find.text('Unconnected'), findsOneWidget);
    expect(find.text('Test Kit'), findsNothing);
    expect(
      find.byKey(const ValueKey('device-unconnected-image')),
      findsOneWidget,
    );
    expect(find.text('85%'), findsNothing);
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

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-ask')), findsOneWidget);
  });

  testWidgets('map search fuzzy searches all drinking points',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-map')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search place'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('map-search-input')), 'civc');
    await tester.pumpAndSettle();

    expect(find.text('Civic Center Plaza'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);

    await tester.tap(
      find.byKey(
          const ValueKey('map-search-result-civic-center-plaza-fountain')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Possible public drinking fountain'),
      findsWidgets,
    );

    await tester.enterText(
        find.byKey(const ValueKey('map-search-input')), 'anml');
    await tester.pumpAndSettle();

    expect(find.text('Animal Park'), findsOneWidget);
  });

  testWidgets('opens water quality details outside dropdown taps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daly City, CA'));
    await tester.pumpAndSettle();

    expect(find.text('Water quality'), findsNothing);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water Quality'));
    await tester.pumpAndSettle();

    expect(find.text('Water quality'), findsOneWidget);
    expect(find.text('Test history score'), findsOneWidget);
  });

  testWidgets('date picker highlights all water record dates',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water Quality'));
    await tester.pumpAndSettle();
    await _selectSfAnimalPark(tester);

    expect(
      (tester.getTopLeft(find.text('Animal Park')).dy -
              tester.getTopLeft(find.text('SF, CA')).dy)
          .abs(),
      lessThan(2),
    );
    expect(
      tester.getTopLeft(find.text('SF, CA')).dx -
          tester.getTopRight(find.text('Animal Park')).dx,
      lessThan(64),
    );

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
        AppColors.lime,
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
        AppColors.lime,
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
        AppColors.lime,
      );
    }
  });

  testWidgets('selects and deletes same-day water test times',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Water Quality'));
    await tester.pumpAndSettle();
    await _selectSfAnimalPark(tester);

    expect(find.text('12:20:20'), findsOneWidget);

    await tester.tap(find.text('12:20:20'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:24:00  89/100'));
    await tester.pumpAndSettle();

    expect(find.text('10:24:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('water-delete-report')));
    await tester.pumpAndSettle();

    expect(find.text('10:24:00'), findsNothing);
    expect(find.text('12:20:20'), findsOneWidget);
  });

  testWidgets('toggles question answers on the ask page',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
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

    await _pumpPebbleApp(tester);
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

    await _pumpPebbleApp(tester);
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

  testWidgets('voice AI Search shows API integration waiting result',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-ask')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ai-search-voice')));
    await tester.pumpAndSettle();

    expect(find.text('Recording...'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai-search-voice')));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for API integration.'), findsOneWidget);
    expect(find.text('Voice search'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ai-search-answer-panel')))
          .width,
      greaterThan(300),
    );
  });

  testWidgets('dismisses a new test notice when tapping outside the card',
      (WidgetTester tester) async {
    WaterQualityReportsApi.shared.clearGeneratedReportsForTesting();
    addTearDown(WaterQualityReportsApi.shared.clearGeneratedReportsForTesting);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await WaterQualityReportsApi.shared.addGeneratedTdsReport(
      144,
      testedAt: DateTime(2026, 4, 28, 13, 24, 36),
      latitude: 37.7694,
      longitude: -122.4862,
    );
    await tester.pump();

    expect(find.text('You have a new test result'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('You have a new test result'), findsNothing);
    expect(find.text('Water quality'), findsNothing);
  });

  testWidgets('shows a new test notice and opens that water detail',
      (WidgetTester tester) async {
    WaterQualityReportsApi.shared.clearGeneratedReportsForTesting();
    addTearDown(WaterQualityReportsApi.shared.clearGeneratedReportsForTesting);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPebbleApp(tester);
    await tester.pumpAndSettle();

    await WaterQualityReportsApi.shared.addGeneratedTdsReport(
      144,
      testedAt: DateTime(2026, 4, 28, 13, 24, 36),
      latitude: 37.7694,
      longitude: -122.4862,
    );
    await tester.pump();

    expect(find.text('You have a new test result'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Water quality'), findsOneWidget);
    expect(find.text('13:24:36'), findsOneWidget);
    expect(find.text('Current GPS'), findsOneWidget);
  });
}

Future<void> _selectSfAnimalPark(WidgetTester tester) async {
  await tester.tap(find.text('Daly City, CA'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('SF, CA').last);
  await tester.pumpAndSettle();
}
