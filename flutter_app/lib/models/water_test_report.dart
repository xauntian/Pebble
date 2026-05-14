class WaterTestReport {
  const WaterTestReport({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.specificLocation,
    this.regionCode = 'SF, CA',
    required this.latitude,
    required this.longitude,
    required this.testedAtIso8601,
    required this.testedAtLabel,
    required this.score,
    required this.tds,
    required this.ph,
    required this.temperatureCelsius,
    required this.cr6MgPerL,
  });

  factory WaterTestReport.fromJson(Map<String, dynamic> json) {
    final testedAtIso8601 = _stringValue(
      json,
      const ['testedAtIso8601', 'tested_at_iso8601', 'testedAt', 'tested_at'],
    );
    final testedAt = DateTime.parse(testedAtIso8601);

    return WaterTestReport(
      id: _stringValue(json, const ['id']),
      locationId: _stringValue(json, const ['locationId', 'location_id']),
      locationName: _stringValue(json, const ['locationName', 'location_name']),
      specificLocation: _stringValue(
        json,
        const ['specificLocation', 'specific_location'],
      ),
      regionCode: _stringValue(
        json,
        const ['regionCode', 'region_code'],
        fallback: 'SF, CA',
      ),
      latitude: _doubleValue(json, const ['latitude', 'lat']),
      longitude: _doubleValue(json, const ['longitude', 'lng', 'lon']),
      testedAtIso8601: testedAtIso8601,
      testedAtLabel: _stringValue(
        json,
        const ['testedAtLabel', 'tested_at_label'],
        fallback: _formatDateLabel(testedAt),
      ),
      score: _intValue(json, const ['score']),
      tds: _intValue(json, const ['tds', 'tdsPpm', 'tds_ppm']),
      ph: _doubleValue(json, const ['ph', 'pH']),
      temperatureCelsius: _doubleValue(
        json,
        const [
          'temperatureCelsius',
          'temperature_celsius',
          'temperatureC',
          'temperature_c',
        ],
      ),
      cr6MgPerL: _doubleValue(
        json,
        const ['cr6MgPerL', 'cr6_mg_per_l', 'cr6', 'chromium6MgPerL'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'locationName': locationName,
      'specificLocation': specificLocation,
      'regionCode': regionCode,
      'latitude': latitude,
      'longitude': longitude,
      'testedAtIso8601': testedAtIso8601,
      'testedAtLabel': testedAtLabel,
      'score': score,
      'tds': tds,
      'ph': ph,
      'temperatureCelsius': temperatureCelsius,
      'cr6MgPerL': cr6MgPerL,
    };
  }

  final String id;
  final String locationId;
  final String locationName;
  final String specificLocation;
  final String regionCode;
  final double latitude;
  final double longitude;
  final String testedAtIso8601;
  final String testedAtLabel;
  final int score;
  final int tds;
  final double ph;
  final double temperatureCelsius;
  final double cr6MgPerL;

  DateTime get testedAt => DateTime.parse(testedAtIso8601);

  static String _stringValue(
    Map<String, dynamic> json,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }

    if (fallback != null) {
      return fallback;
    }

    throw FormatException('Missing string field: ${keys.first}');
  }

  static int _intValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) {
          return parsed.round();
        }
      }
    }

    throw FormatException('Missing numeric field: ${keys.first}');
  }

  static double _doubleValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    throw FormatException('Missing numeric field: ${keys.first}');
  }

  static String _formatDateLabel(DateTime date) {
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
