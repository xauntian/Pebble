import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  static const generatedReportLocationId = 'cca-sf';
  static const generatedReportLocationName = 'CCA';
  static const generatedReportSpecificLocation = 'CCA, SF';
  static const generatedReportRegionCode = 'CCA, SF';
  static const generatedReportLatitude = 37.7749;
  static const generatedReportLongitude = -122.4194;

  final http.Client _client;
  final String _baseUrl;
  final String reportsPath;
  final List<WaterTestReport> _generatedReports = <WaterTestReport>[];
  final Set<String> _deletedReportIds = <String>{};
  final StreamController<List<WaterTestReport>> _reportsChangedController =
      StreamController<List<WaterTestReport>>.broadcast();
  final StreamController<WaterTestReport> _generatedReportController =
      StreamController<WaterTestReport>.broadcast();
  List<WaterTestReport>? _latestBaseReports;

  Stream<List<WaterTestReport>> get reportsChanged =>
      _reportsChangedController.stream;

  Stream<WaterTestReport> get generatedReports =>
      _generatedReportController.stream;

  void clearGeneratedReportsForTesting() {
    _generatedReports.clear();
    _deletedReportIds.clear();
  }

  Future<List<WaterTestReport>> fetchReports() async {
    final baseReports = await _fetchBaseReports();
    _latestBaseReports = baseReports;

    return _mergeReports(baseReports);
  }

  Future<WaterTestReport> addGeneratedTdsReport(
    int tds, {
    DateTime? testedAt,
    double? latitude,
    double? longitude,
  }) async {
    final baseReports = _latestBaseReports ?? SfWaterTestReports.all;
    final report = _generatedReportFromTds(
      tds: tds,
      testedAt: testedAt ?? DateTime.now(),
    );

    await _pushGeneratedReport(report);

    _generatedReports
      ..removeWhere((existingReport) => existingReport.id == report.id)
      ..add(report);
    _deletedReportIds.remove(report.id);

    final reports = _mergeReports(baseReports);
    _emitReportsChanged(reports);
    if (!_generatedReportController.isClosed) {
      _generatedReportController.add(report);
    }

    return report;
  }

  Future<List<WaterTestReport>> deleteReport(String reportId) async {
    await _deleteRemoteReport(reportId);

    final baseReports = _latestBaseReports ?? await _fetchBaseReports();
    _latestBaseReports = baseReports;
    _generatedReports.removeWhere((report) => report.id == reportId);
    _deletedReportIds.add(reportId);

    final reports = _mergeReports(baseReports);
    _emitReportsChanged(reports);

    return reports;
  }

  Future<List<WaterTestReport>> _fetchBaseReports() async {
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

  List<WaterTestReport> _mergeReports(
    List<WaterTestReport> baseReports,
  ) {
    if (_generatedReports.isEmpty && _deletedReportIds.isEmpty) {
      return List<WaterTestReport>.unmodifiable(baseReports);
    }

    final generatedIds = _generatedReports.map((report) => report.id).toSet();
    return List<WaterTestReport>.unmodifiable([
      ...baseReports.where(
        (report) =>
            !generatedIds.contains(report.id) &&
            !_deletedReportIds.contains(report.id),
      ),
      ..._generatedReports.where(
        (report) => !_deletedReportIds.contains(report.id),
      ),
    ]);
  }

  void _emitReportsChanged(List<WaterTestReport> reports) {
    if (!_reportsChangedController.isClosed) {
      _reportsChangedController.add(reports);
    }
  }

  Future<void> _pushGeneratedReport(WaterTestReport report) async {
    if (_baseUrl.isEmpty) {
      return;
    }

    try {
      await _client
          .post(
            _reportsUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(report.toJson()),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Keep the result in the local in-memory library when the remote API
      // is unavailable.
    }
  }

  Future<void> _deleteRemoteReport(String reportId) async {
    if (_baseUrl.isEmpty) {
      return;
    }

    try {
      await _client
          .delete(_reportUri(reportId))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Local deletion state keeps the UI correct even without a remote API.
    }
  }

  WaterTestReport _generatedReportFromTds({
    required int tds,
    required DateTime testedAt,
  }) {
    final tdsValue = tds.clamp(0, 2000).toInt();
    final derivedMetrics = _WaterMetricsFromTds(tdsValue);

    return WaterTestReport(
      id: 'cca-sf-${testedAt.microsecondsSinceEpoch}-$tdsValue',
      locationId: generatedReportLocationId,
      locationName: generatedReportLocationName,
      specificLocation: generatedReportSpecificLocation,
      regionCode: generatedReportRegionCode,
      latitude: generatedReportLatitude,
      longitude: generatedReportLongitude,
      testedAtIso8601: testedAt.toIso8601String(),
      testedAtLabel: _formatDateLabel(testedAt),
      score: derivedMetrics.score,
      tds: tdsValue,
      ph: derivedMetrics.ph,
      temperatureCelsius: derivedMetrics.temperatureCelsius,
      cr6MgPerL: derivedMetrics.cr6MgPerL,
    );
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

  Uri _reportUri(String reportId) {
    final reportsUri = _reportsUri;

    return reportsUri.replace(
      pathSegments: [
        ...reportsUri.pathSegments.where((segment) => segment.isNotEmpty),
        reportId,
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

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _WaterMetricsFromTds {
  _WaterMetricsFromTds(int tds)
      : score = _scoreFromTds(tds),
        ph = _round((7.6 - tds / 650).clamp(6.0, 7.8).toDouble(), 2),
        temperatureCelsius = _round(
          (22.5 + tds.clamp(0, 500) / 500 * 4.5).toDouble(),
          1,
        ),
        cr6MgPerL = _round((tds / 2500).clamp(0.01, 0.5).toDouble(), 3);

  final int score;
  final double ph;
  final double temperatureCelsius;
  final double cr6MgPerL;

  static int _scoreFromTds(int tds) {
    return (100 - (tds / 8).round()).clamp(0, 100).toInt();
  }

  static double _round(double value, int fractionDigits) {
    final factor = math.pow(10, fractionDigits).toDouble();
    return (value * factor).round() / factor;
  }
}
