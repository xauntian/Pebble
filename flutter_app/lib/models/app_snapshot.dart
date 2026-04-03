class AppSnapshot {
  const AppSnapshot({
    required this.averageTestScore,
    required this.monthlyGoal,
    required this.batteryLevel,
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
        batteryLevel = 85,
        testLife = 89,
        waterQualityScore = 66,
        chartValues = const [41, 55, 44, 65, 62, 33, 41, 55, 49],
        locationName = 'Animal Park',
        locationShort = 'SF, CA',
        lastCheckedLabel = 'Jun 10, 2024';

  final int averageTestScore;
  final int monthlyGoal;
  final int batteryLevel;
  final int testLife;
  final int waterQualityScore;
  final List<double> chartValues;
  final String locationName;
  final String locationShort;
  final String lastCheckedLabel;
}
