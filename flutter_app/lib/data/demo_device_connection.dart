import '../models/device_connection.dart';

class DemoDeviceConnection {
  const DemoDeviceConnection._();

  static const current = connected;

  static const connected = DeviceConnection.connected(
    deviceName: 'Test Kit',
    batteryPercent: 85,
  );

  static const waiting = DeviceConnection.unconnected(
    deviceName: 'Test Kit',
  );
}
