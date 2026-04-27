enum DeviceConnectionState {
  connected,
  unconnected,
}

class DeviceConnection {
  const DeviceConnection({
    required this.state,
    required this.deviceName,
    this.batteryPercent,
    this.productAssetPath,
  });

  const DeviceConnection.connected({
    this.deviceName = 'Test Kit',
    required this.batteryPercent,
    this.productAssetPath = 'assets/figma/home-device.png',
  }) : state = DeviceConnectionState.connected;

  const DeviceConnection.unconnected({
    this.deviceName = 'Test Kit',
  })  : state = DeviceConnectionState.unconnected,
        batteryPercent = null,
        productAssetPath = null;

  final DeviceConnectionState state;
  final String deviceName;
  final int? batteryPercent;
  final String? productAssetPath;

  bool get isConnected => state == DeviceConnectionState.connected;
}
