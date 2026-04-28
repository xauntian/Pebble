import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
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
  final List<WaterTestReport> _generatedReports = <WaterTestReport>[];
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
  }

  Future<List<WaterTestReport>> fetchReports() async {
    final baseReports = await _fetchBaseReports();
    _latestBaseReports = baseReports;

    return _mergeGeneratedReports(baseReports);
  }

  Future<WaterTestReport> addGeneratedTdsReport(
    int tds, {
    DateTime? testedAt,
    double? latitude,
    double? longitude,
  }) async {
    final gps = latitude != null && longitude != null
        ? _GpsSnapshot(latitude: latitude, longitude: longitude)
        : await _currentGpsSnapshot();
    final report = _generatedReportFromTds(
      tds: tds,
      testedAt: testedAt ?? DateTime.now(),
      gps: gps,
    );

    _generatedReports
      ..removeWhere((existingReport) => existingReport.id == report.id)
      ..add(report);

    final reports = _mergeGeneratedReports(
      _latestBaseReports ?? SfWaterTestReports.all,
    );
    if (!_reportsChangedController.isClosed) {
      _reportsChangedController.add(reports);
    }
    if (!_generatedReportController.isClosed) {
      _generatedReportController.add(report);
    }

    return report;
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

  List<WaterTestReport> _mergeGeneratedReports(
    List<WaterTestReport> baseReports,
  ) {
    if (_generatedReports.isEmpty) {
      return List<WaterTestReport>.unmodifiable(baseReports);
    }

    final generatedIds = _generatedReports.map((report) => report.id).toSet();
    return List<WaterTestReport>.unmodifiable([
      ...baseReports.where((report) => !generatedIds.contains(report.id)),
      ..._generatedReports,
    ]);
  }

  Future<_GpsSnapshot> _currentGpsSnapshot() async {
    try {
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
        onTimeout: () => LocationPermission.denied,
      );

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 8),
          onTimeout: () => LocationPermission.denied,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return _GpsSnapshot.fallback();
      }

      final lastKnownPosition = await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        ).timeout(const Duration(seconds: 7));

        return _GpsSnapshot.fromPosition(currentPosition);
      } catch (_) {
        if (lastKnownPosition != null) {
          return _GpsSnapshot.fromPosition(lastKnownPosition);
        }
      }
    } catch (_) {
      return _GpsSnapshot.fallback();
    }

    return _GpsSnapshot.fallback();
  }

  WaterTestReport _generatedReportFromTds({
    required int tds,
    required DateTime testedAt,
    required _GpsSnapshot gps,
  }) {
    final tdsValue = tds.clamp(0, 2000).toInt();
    final latitude = _round(gps.latitude, 6);
    final longitude = _round(gps.longitude, 6);
    final locationId = 'current-gps-${_coordinateSlug(latitude, longitude)}';
    final coordinateLabel =
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    final locationName = gps.isFallback ? 'CCA' : 'Current GPS';
    final specificLocation = gps.isFallback ? 'CCA' : coordinateLabel;
    final regionCode = gps.isFallback ? 'SF, CA' : 'GPS';
    final derivedMetrics = _WaterMetricsFromTds(tdsValue);

    return WaterTestReport(
      id: 'gps-${testedAt.microsecondsSinceEpoch}-$tdsValue',
      locationId: locationId,
      locationName: locationName,
      specificLocation: specificLocation,
      regionCode: regionCode,
      latitude: latitude,
      longitude: longitude,
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

  String _coordinateSlug(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}-${longitude.toStringAsFixed(4)}'
        .replaceAll('-', 'm')
        .replaceAll('.', 'p');
  }

  double _round(double value, int fractionDigits) {
    final factor = math.pow(10, fractionDigits).toDouble();
    return (value * factor).round() / factor;
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

class _GpsSnapshot {
  const _GpsSnapshot({
    required this.latitude,
    required this.longitude,
    this.isFallback = false,
  });

  factory _GpsSnapshot.fromPosition(Position position) {
    return _GpsSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  factory _GpsSnapshot.fallback() {
    return const _GpsSnapshot(
      latitude: 37.7749,
      longitude: -122.4194,
      isFallback: true,
    );
  }

  final double latitude;
  final double longitude;
  final bool isFallback;
}
