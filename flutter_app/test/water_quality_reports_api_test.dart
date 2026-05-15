import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_quality_companion/services/pebble_bluetooth_connection_service.dart';
import 'package:water_quality_companion/services/water_quality_reports_api.dart';

void main() {
  test('generates a CCA SF water quality report from a TDS payload', () async {
    final reportsApi = WaterQualityReportsApi();
    final testedAt = DateTime(2026, 4, 28, 12, 34, 56);

    final report = await reportsApi.addGeneratedTdsReport(
      123,
      testedAt: testedAt,
      latitude: 37.7694,
      longitude: -122.4862,
    );
    final reports = await reportsApi.fetchReports();

    expect(report.tds, 123);
    expect(report.score, 85);
    expect(report.ph, 7.41);
    expect(report.temperatureCelsius, 23.6);
    expect(report.cr6MgPerL, 0.049);
    expect(report.testedAtIso8601, testedAt.toIso8601String());
    expect(report.locationId, WaterQualityReportsApi.generatedReportLocationId);
    expect(
      report.locationName,
      WaterQualityReportsApi.generatedReportLocationName,
    );
    expect(
      report.specificLocation,
      WaterQualityReportsApi.generatedReportSpecificLocation,
    );
    expect(report.regionCode, WaterQualityReportsApi.generatedReportRegionCode);
    expect(reports, contains(report));
  });

  test('routes generated reports to CCA SF regardless of submitted GPS',
      () async {
    final reportsApi = WaterQualityReportsApi();

    final oaklandReport = await reportsApi.addGeneratedTdsReport(
      144,
      testedAt: DateTime(2026, 4, 28, 14),
      latitude: 37.8044,
      longitude: -122.258,
    );
    final berkeleyReport = await reportsApi.addGeneratedTdsReport(
      144,
      testedAt: DateTime(2026, 4, 28, 15),
      latitude: 37.864,
      longitude: -122.3134,
    );
    final dalyCityReport = await reportsApi.addGeneratedTdsReport(
      144,
      testedAt: DateTime(2026, 4, 28, 16),
      latitude: 37.6993,
      longitude: -122.4842,
    );

    expect(oaklandReport.regionCode,
        WaterQualityReportsApi.generatedReportRegionCode);
    expect(berkeleyReport.regionCode,
        WaterQualityReportsApi.generatedReportRegionCode);
    expect(dalyCityReport.regionCode,
        WaterQualityReportsApi.generatedReportRegionCode);
  });

  test('derives generated water quality metrics only from TDS', () async {
    final reportsApi = WaterQualityReportsApi();
    final firstReport = await reportsApi.addGeneratedTdsReport(
      320,
      testedAt: DateTime(2026, 4, 28, 12),
      latitude: 37.7694,
      longitude: -122.4862,
    );
    final secondReport = await reportsApi.addGeneratedTdsReport(
      320,
      testedAt: DateTime(2026, 4, 28, 13),
      latitude: 37.1,
      longitude: -122.1,
    );

    expect(secondReport.score, firstReport.score);
    expect(secondReport.ph, firstReport.ph);
    expect(
      secondReport.temperatureCelsius,
      firstReport.temperatureCelsius,
    );
    expect(secondReport.cr6MgPerL, firstReport.cr6MgPerL);
    expect(secondReport.score, 60);
    expect(secondReport.ph, 7.11);
    expect(secondReport.temperatureCelsius, 25.4);
    expect(secondReport.cr6MgPerL, 0.128);
  });

  test('generates reports for quick-pick boundary TDS values', () async {
    final reportsApi = WaterQualityReportsApi();

    final lowReport = await reportsApi.addGeneratedTdsReport(
      75,
      testedAt: DateTime(2026, 4, 28, 12),
    );
    final highReport = await reportsApi.addGeneratedTdsReport(
      600,
      testedAt: DateTime(2026, 4, 28, 13),
    );

    expect(lowReport.tds, 75);
    expect(lowReport.score, 91);
    expect(highReport.tds, 600);
    expect(highReport.score, 25);
    expect((await reportsApi.fetchReports()),
        containsAll([lowReport, highReport]));
  });

  test('deduplicates repeated TDS notifications by timestamp', () async {
    final reportsApi = WaterQualityReportsApi();
    final bluetoothService = PebbleBluetoothConnectionService(
      reportsApi: reportsApi,
    );
    final generatedTdsValues = <int>[];
    final subscription = reportsApi.generatedReports.listen(
      (report) => generatedTdsValues.add(report.tds),
    );

    final repeatedPayload = utf8.encode(
      '{"tds_number":"600","tds_timestamp":"1770000000"}',
    );
    await bluetoothService.handlePayloadBytesForTesting(repeatedPayload);
    await bluetoothService.handlePayloadBytesForTesting(repeatedPayload);
    await bluetoothService.handlePayloadBytesForTesting(repeatedPayload);
    await pumpEventQueue();

    expect(generatedTdsValues, [600]);

    await bluetoothService.handlePayloadBytesForTesting(
      utf8.encode('{"tds_number":"75","tds_timestamp":"1770000001"}'),
    );
    await pumpEventQueue();

    expect(generatedTdsValues, [600, 75]);
    await subscription.cancel();
  });

  test('deletes generated and base reports from the local library', () async {
    final reportsApi = WaterQualityReportsApi();
    final generatedReport = await reportsApi.addGeneratedTdsReport(
      188,
      testedAt: DateTime(2026, 4, 28, 17),
      latitude: 37.7694,
      longitude: -122.4862,
    );

    expect(
      (await reportsApi.fetchReports())
          .any((report) => report.id == generatedReport.id),
      isTrue,
    );

    await reportsApi.deleteReport(generatedReport.id);

    expect(
      (await reportsApi.fetchReports())
          .any((report) => report.id == generatedReport.id),
      isFalse,
    );

    final baseReport = (await reportsApi.fetchReports()).first;

    await reportsApi.deleteReport(baseReport.id);

    expect(
      (await reportsApi.fetchReports())
          .any((report) => report.id == baseReport.id),
      isFalse,
    );
  });
}
