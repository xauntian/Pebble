/// Empty contract for future water point detail data.
///
/// TODO: Implement these ports when the app has a real recommendation and
/// scoring source. The Map page currently uses mock data for both values.
abstract interface class WaterPointDetailPorts {
  Future<String> getDrinkingAdvice({
    required String waterPointId,
  });

  Future<int> getWaterQualityScore({
    required String waterPointId,
  });
}
