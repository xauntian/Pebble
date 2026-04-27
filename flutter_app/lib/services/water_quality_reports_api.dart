import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/sf_water_test_reports.dart';
import '../models/water_test_report.dart';

class WaterQualityReportsApi {
  WaterQualityReportsApi({
    http.Client? client,
    String baseUrl = const String.fromEnvironment('PEBBLE_API_BASE_URL'),
    this.reportsPath = const String.fromEnvironment(
      'PEBBLE_WATER_REPORTS_PATH',
      defaultValue: '/water-test-reports',
    ),
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl.trim();

  static final shared = WaterQualityReportsApi();

  final http.Client _client;
  final String _baseUrl;
  final String reportsPath;

  Future<List<WaterTestReport>> fetchReports() async {
    if (_baseUrl.isEmpty) {
      return SfWaterTestReports.all;
    }

    try {
      final response =
          await _client.get(_reportsUri).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SfWaterTestReports.all;
      }

      final decoded = jsonDecode(response.body);
      final reports = _decodeReports(decoded);

      return reports.isEmpty ? SfWaterTestReports.all : reports;
    } on FormatException {
      return SfWaterTestReports.all;
    } on http.ClientException {
      return SfWaterTestReports.all;
    } on Exception {
      return SfWaterTestReports.all;
    }
  }

  Uri get _reportsUri {
    final baseUri = Uri.parse(_baseUrl);
    final normalizedPath =
        reportsPath.startsWith('/') ? reportsPath.substring(1) : reportsPath;

    return baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        ...normalizedPath.split('/').where((segment) => segment.isNotEmpty),
      ],
    );
  }

  List<WaterTestReport> _decodeReports(Object? decoded) {
    final Object? reportsJson;

    if (decoded is List<Object?>) {
      reportsJson = decoded;
    } else if (decoded is Map<String, Object?>) {
      reportsJson = decoded['reports'] ?? decoded['data'];
    } else {
      throw const FormatException('Unexpected reports response shape');
    }

    if (reportsJson is! List<Object?>) {
      throw const FormatException('Reports response is not a list');
    }

    return List<WaterTestReport>.unmodifiable(
      reportsJson.map((item) {
        if (item is! Map<String, Object?>) {
          throw const FormatException('Report item is not an object');
        }

        return WaterTestReport.fromJson(Map<String, dynamic>.from(item));
      }),
    );
  }
}
