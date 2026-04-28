import 'package:flutter_test/flutter_test.dart';
import 'package:water_quality_companion/services/water_quality_reports_api.dart';

void main() {
  test('generates a GPS water quality report from a TDS payload', () async {
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
    expect(report.locationName, 'Current GPS');
    expect(report.specificLocation, '37.76940, -122.48620');
    expect(reports, contains(report));
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
}
