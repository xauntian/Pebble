// ignore_for_file: non_constant_identifier_names

class AppSnapshot {
  const AppSnapshot({
    required this.averageTestScore,
    required this.monthlyGoal,
    required this.battery_number,
    required this.deviceConnected,
    required this.testLife,
    required this.waterQualityScore,
    required this.chartValues,
    required this.locationName,
    required this.locationShort,
    required this.lastCheckedLabel,
  });

  const AppSnapshot.demo()
      : averageTestScore = 75,
        monthlyGoal = 100,
        battery_number = '85',
        deviceConnected = true,
        testLife = 89,
        waterQualityScore = 66,
        chartValues = const [41, 55, 44, 65, 62, 33, 41, 55, 49],
        locationName = 'Animal Park',
        locationShort = 'SF, CA',
        lastCheckedLabel = 'Jun 10, 2024';

  final int averageTestScore;
  final int monthlyGoal;
  final String battery_number;
  final bool deviceConnected;
  final int testLife;
  final int waterQualityScore;
  final List<double> chartValues;
  final String locationName;
  final String locationShort;
  final String lastCheckedLabel;
}
