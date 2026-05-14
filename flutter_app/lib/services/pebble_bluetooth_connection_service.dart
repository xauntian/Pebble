import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device_connection.dart';
import 'water_quality_reports_api.dart';

class PebbleBluetoothConnectionService {
  PebbleBluetoothConnectionService({
    List<String>? deviceNameKeywords,
    WaterQualityReportsApi? reportsApi,
  })  : deviceNameKeywords = deviceNameKeywords ?? _defaultDeviceNameKeywords,
        _reportsApi = reportsApi ?? WaterQualityReportsApi.shared;

  static final shared = PebbleBluetoothConnectionService();
  static final pebbleServiceUuid = Guid(
    '7b7d0001-4f8a-4c28-9f2a-6f0a8f0d1000',
  );
  static final pebblePayloadCharacteristicUuid = Guid(
    '7b7d0002-4f8a-4c28-9f2a-6f0a8f0d1000',
  );
  static const _defaultDeviceNameKeywords = [
    'pebble',
    'test kit',
    'testkit',
    'pebble testkit',
  ];
  static const _deviceStatusCheckInterval = Duration(seconds: 4);
  static const _sameTdsDuplicateWindow = Duration(seconds: 2);

  final List<String> deviceNameKeywords;
  final WaterQualityReportsApi _reportsApi;
  final StreamController<DeviceConnection> _connectionController =
      StreamController<DeviceConnection>.broadcast();

  StreamSubscription<OnConnectionStateChangedEvent>? _connectionSubscription;
  StreamSubscription<List<int>>? _payloadSubscription;
  Timer? _deviceStatusTimer;
  BluetoothDevice? _activeDevice;
  BluetoothCharacteristic? _payloadCharacteristic;
  DeviceConnection _lastConnection = const DeviceConnection.unconnected();
  int? _lastBatteryPercent;
  int? _lastReceivedTds;
  DateTime? _lastReceivedTdsAt;
  bool _isCheckingDeviceStatus = false;
  int _connectionWatcherCount = 0;

  Future<DeviceConnection> connectToPebble({
    Duration scanTimeout = const Duration(seconds: 8),
    Duration connectionTimeout = const Duration(seconds: 12),
  }) async {
    try {
      final connectedDevice = await _connectedPebbleDevice();
      if (connectedDevice != null) {
        return _activateDevice(connectedDevice);
      }

      final canUseBluetooth = await _ensureBluetoothReady();
      if (!canUseBluetooth) {
        return _publishConnection(const DeviceConnection.unconnected());
      }

      final device = await _findPebbleDevice(scanTimeout: scanTimeout);
      if (device == null) {
        return _publishConnection(const DeviceConnection.unconnected());
      }

      await _connectDevice(device, timeout: connectionTimeout);

      final isConnected = await _isConnected(device);
      if (!isConnected) {
        return _publishConnection(const DeviceConnection.unconnected());
      }

      return _activateDevice(device);
    } catch (_) {
      return _publishConnection(const DeviceConnection.unconnected());
    }
  }

  Stream<DeviceConnection> watchConnection() {
    _ensureConnectionEventsSubscription();

    return Stream<DeviceConnection>.multi((controller) {
      StreamSubscription<DeviceConnection>? connectionSubscription;
      var disposed = false;
      _connectionWatcherCount += 1;
      _ensureDeviceStatusMonitor();

      Future<void> publishCurrentConnection() async {
        final connection = await currentConnection();
        if (!disposed) {
          controller.add(connection);
        }
      }

      controller.add(_lastConnection);
      unawaited(publishCurrentConnection());

      connectionSubscription = _connectionController.stream.listen(
        controller.add,
        onError: controller.addError,
      );

      controller.onCancel = () {
        disposed = true;
        if (_connectionWatcherCount > 0) {
          _connectionWatcherCount -= 1;
        }
        if (_connectionWatcherCount == 0) {
          _stopDeviceStatusMonitor();
        }

        final cancelFuture = connectionSubscription?.cancel();
        if (cancelFuture != null) {
          unawaited(cancelFuture);
        }
      };
    });
  }

  Future<DeviceConnection> currentConnection() async {
    try {
      final canUseBluetooth = await _canUseBluetooth();
      if (!canUseBluetooth) {
        return _publishConnection(const DeviceConnection.unconnected());
      }

      final pebbleDevice = await _connectedPebbleDevice();
      if (pebbleDevice == null) {
        return _publishConnection(const DeviceConnection.unconnected());
      }

      _activeDevice = pebbleDevice;
      unawaited(_ensurePayloadBridge(pebbleDevice));
      return _publishConnectedDevice(pebbleDevice);
    } catch (_) {
      return _publishConnection(const DeviceConnection.unconnected());
    }
  }

  Future<DeviceConnection> _activateDevice(BluetoothDevice device) async {
    _ensureDeviceStatusMonitor();
    _activeDevice = device;
    _publishConnectedDevice(device);
    await _ensurePayloadBridge(device);

    return _publishConnectedDevice(device);
  }

  Future<void> _ensurePayloadBridge(BluetoothDevice device) async {
    if (_payloadCharacteristic != null &&
        _activeDevice?.remoteId == device.remoteId) {
      return;
    }

    await _payloadSubscription?.cancel();
    _payloadSubscription = null;
    _payloadCharacteristic = null;

    try {
      final characteristic = await _findPayloadCharacteristic(device);
      if (characteristic == null) {
        return;
      }

      _payloadCharacteristic = characteristic;
      _payloadSubscription = characteristic.onValueReceived.listen((value) {
        unawaited(
          _handlePayloadBytes(
            value,
            device: device,
            generateReportFromTds: true,
            generateReportOnlyWhenTdsChanges: true,
          ),
        );
      });

      try {
        await characteristic.setNotifyValue(true, timeout: 5);
      } catch (_) {
        // Keep read support even if notify setup fails on a platform.
      }

      try {
        final initialValue = await characteristic.read(timeout: 5);
        await _handlePayloadBytes(
          initialValue,
          device: device,
          generateReportFromTds: true,
          generateReportOnlyWhenTdsChanges: true,
        );
      } catch (_) {
        // The next notification will update the card.
      }
    } catch (_) {
      await _payloadSubscription?.cancel();
      _payloadSubscription = null;
      _payloadCharacteristic = null;
    }
  }

  Future<BluetoothCharacteristic?> _findPayloadCharacteristic(
    BluetoothDevice device,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final services = await device.discoverServices(timeout: 8);
    for (final service in services) {
      if (service.serviceUuid != pebbleServiceUuid) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        if (characteristic.characteristicUuid ==
            pebblePayloadCharacteristicUuid) {
          return characteristic;
        }
      }
    }

    return null;
  }

  Future<void> _handlePayloadBytes(
    List<int> value, {
    required BluetoothDevice device,
    required bool generateReportFromTds,
    bool generateReportOnlyWhenTdsChanges = false,
  }) async {
    final payload = _PebblePayload.tryParse(value);
    if (payload == null) {
      return;
    }

    final batteryPercent = payload.batteryPercent;
    if (batteryPercent != null) {
      _lastBatteryPercent = batteryPercent.clamp(0, 100).toInt();
      _publishConnectedDevice(device);
    }

    final tds = payload.tds;
    if (generateReportFromTds && tds != null && tds > 0) {
      final isDuplicateTds = _isDuplicateTdsPayload(tds);
      _lastReceivedTds = tds;
      _lastReceivedTdsAt = DateTime.now();

      if (!generateReportOnlyWhenTdsChanges || !isDuplicateTds) {
        await _reportsApi.addGeneratedTdsReport(tds);
      }
    } else if (tds != null) {
      _lastReceivedTds = tds;
      _lastReceivedTdsAt = DateTime.now();
    } else {
      _lastReceivedTds = null;
      _lastReceivedTdsAt = null;
    }
  }

  bool _isDuplicateTdsPayload(int tds) {
    final lastReceivedAt = _lastReceivedTdsAt;
    if (_lastReceivedTds != tds || lastReceivedAt == null) {
      return false;
    }

    return DateTime.now().difference(lastReceivedAt) < _sameTdsDuplicateWindow;
  }

  Future<void> _readLatestPayload(BluetoothDevice device) async {
    final characteristic = _payloadCharacteristic;
    if (characteristic == null) {
      return;
    }

    try {
      final value = await characteristic.read(timeout: 5);
      await _handlePayloadBytes(
        value,
        device: device,
        generateReportFromTds: true,
        generateReportOnlyWhenTdsChanges: true,
      );
    } catch (_) {
      // Notifications remain the primary update path.
    }
  }

  DeviceConnection _publishConnectedDevice(BluetoothDevice device) {
    return _publishConnection(
      DeviceConnection.connected(
        deviceName: _displayName(device),
        batteryPercent: _lastBatteryPercent,
      ),
    );
  }

  DeviceConnection _publishConnection(DeviceConnection connection) {
    _lastConnection = connection;
    if (!_connectionController.isClosed) {
      _connectionController.add(connection);
    }

    return connection;
  }

  void _ensureConnectionEventsSubscription() {
    if (_connectionSubscription != null) {
      return;
    }

    try {
      _connectionSubscription =
          FlutterBluePlus.events.onConnectionStateChanged.listen(
        (event) {
          unawaited(_handleConnectionStateChanged(event));
        },
        onError: (_) {
          _publishConnection(const DeviceConnection.unconnected());
        },
      );
    } catch (_) {
      _publishConnection(const DeviceConnection.unconnected());
    }
  }

  Future<void> _handleConnectionStateChanged(
    OnConnectionStateChangedEvent event,
  ) async {
    final device = event.device;
    if (event.connectionState == BluetoothConnectionState.connected) {
      if (_isPebbleDevice(device) ||
          _activeDevice?.remoteId == device.remoteId) {
        await _activateDevice(device);
      }
      return;
    }

    if (_activeDevice?.remoteId != device.remoteId) {
      return;
    }

    await _clearActiveConnection(device: device);
  }

  void _ensureDeviceStatusMonitor() {
    if (_deviceStatusTimer != null) {
      return;
    }

    _deviceStatusTimer = Timer.periodic(
      _deviceStatusCheckInterval,
      (_) => unawaited(_checkActiveDeviceStatus()),
    );
  }

  void _stopDeviceStatusMonitor() {
    _deviceStatusTimer?.cancel();
    _deviceStatusTimer = null;
  }

  Future<void> _checkActiveDeviceStatus() async {
    if (_isCheckingDeviceStatus) {
      return;
    }

    _isCheckingDeviceStatus = true;
    try {
      final activeDevice = _activeDevice;
      if (activeDevice == null) {
        if (_lastConnection.isConnected) {
          _publishConnection(const DeviceConnection.unconnected());
        }
        return;
      }

      final canUseBluetooth = await _canUseBluetooth();
      if (!canUseBluetooth) {
        await _clearActiveConnection(
          device: activeDevice,
          disconnectDevice: true,
        );
        return;
      }

      final isReportedConnected = FlutterBluePlus.connectedDevices.any(
        (device) => device.remoteId == activeDevice.remoteId,
      );
      final isStillConnected = await _isConnected(activeDevice);
      if (!isReportedConnected || !isStillConnected) {
        await _clearActiveConnection(
          device: activeDevice,
          disconnectDevice: isStillConnected,
        );
        return;
      }

      if (_payloadCharacteristic == null) {
        await _ensurePayloadBridge(activeDevice);
      } else {
        await _readLatestPayload(activeDevice);
      }
    } catch (_) {
      final activeDevice = _activeDevice;
      if (activeDevice != null || _lastConnection.isConnected) {
        await _clearActiveConnection(device: activeDevice);
      }
    } finally {
      _isCheckingDeviceStatus = false;
    }
  }

  Future<void> _clearActiveConnection({
    BluetoothDevice? device,
    bool disconnectDevice = false,
  }) async {
    await _payloadSubscription?.cancel();
    _payloadSubscription = null;
    _payloadCharacteristic = null;

    final deviceToDisconnect = device ?? _activeDevice;
    _activeDevice = null;
    _lastBatteryPercent = null;
    _lastReceivedTds = null;
    _lastReceivedTdsAt = null;

    if (disconnectDevice && deviceToDisconnect != null) {
      try {
        await deviceToDisconnect.disconnect(timeout: 5);
      } catch (_) {
        // The device may already be gone from the Bluetooth stack.
      }
    }

    _publishConnection(const DeviceConnection.unconnected());
  }

  Future<BluetoothDevice?> _connectedPebbleDevice() async {
    final activeDevice = _activeDevice;
    if (activeDevice != null && await _isConnected(activeDevice)) {
      return activeDevice;
    }

    final pebbleDevice = _firstRecognizedConnectedDevice(
      FlutterBluePlus.connectedDevices,
    );
    if (pebbleDevice == null) {
      return null;
    }

    final isConnected = await _isConnected(pebbleDevice);
    return isConnected ? pebbleDevice : null;
  }

  Future<bool> _canUseBluetooth() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      return false;
    }

    final adapterState = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => BluetoothAdapterState.unknown,
    );

    return adapterState != BluetoothAdapterState.off &&
        adapterState != BluetoothAdapterState.unavailable &&
        adapterState != BluetoothAdapterState.unauthorized;
  }

  Future<bool> _ensureBluetoothReady() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      return false;
    }

    var adapterState = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => BluetoothAdapterState.unknown,
    );

    if (adapterState == BluetoothAdapterState.off) {
      try {
        await FlutterBluePlus.turnOn(timeout: 8);
      } catch (_) {
        return false;
      }

      adapterState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
    }

    return adapterState != BluetoothAdapterState.off &&
        adapterState != BluetoothAdapterState.unavailable &&
        adapterState != BluetoothAdapterState.unauthorized;
  }

  Future<BluetoothDevice?> _findPebbleDevice({
    required Duration scanTimeout,
  }) async {
    final connectedDevice = await _connectedPebbleDevice();
    if (connectedDevice != null) {
      return connectedDevice;
    }

    final scanFuture = FlutterBluePlus.onScanResults
        .expand((results) => results)
        .where(_isPebbleScanResult)
        .map((result) => result.device)
        .first
        .timeout(scanTimeout,
            onTimeout: () => throw TimeoutException(
                  'Pebble Bluetooth scan timed out.',
                  scanTimeout,
                ));

    try {
      await FlutterBluePlus.startScan(
        withServices: [pebbleServiceUuid],
        timeout: scanTimeout,
        androidUsesFineLocation: true,
        webOptionalServices: [pebbleServiceUuid],
      );

      return await scanFuture;
    } on TimeoutException {
      return null;
    } finally {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // Scanning may have already stopped after the timeout.
      }
    }
  }

  Future<void> _connectDevice(
    BluetoothDevice device, {
    required Duration timeout,
  }) async {
    if (await _isConnected(device)) {
      return;
    }

    try {
      await device.connect(
        license: License.free,
        mtu: null,
        timeout: timeout,
      );
    } catch (_) {
      if (!await _isConnected(device)) {
        rethrow;
      }
    }
  }

  BluetoothDevice? _firstRecognizedConnectedDevice(
    Iterable<BluetoothDevice> devices,
  ) {
    for (final device in devices) {
      if (device.isConnected && _isPebbleDevice(device)) {
        return device;
      }
    }

    return null;
  }

  bool _isPebbleScanResult(ScanResult result) {
    return result.advertisementData.serviceUuids.contains(pebbleServiceUuid) ||
        _matchesKnownDeviceName(result.advertisementData.advName) ||
        _isPebbleDevice(result.device);
  }

  Future<bool> _isConnected(BluetoothDevice device) async {
    if (device.isConnected) {
      return true;
    }

    final state = await device.connectionState.first.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => BluetoothConnectionState.disconnected,
    );

    return state == BluetoothConnectionState.connected;
  }

  bool _isPebbleDevice(BluetoothDevice device) {
    return _matchesKnownDeviceName(device.platformName) ||
        _matchesKnownDeviceName(device.advName);
  }

  bool _matchesKnownDeviceName(String value) {
    final normalizedValue = _normalizeDeviceName(value);
    if (normalizedValue.isEmpty) {
      return false;
    }

    return deviceNameKeywords.any((keyword) {
      return normalizedValue.contains(_normalizeDeviceName(keyword));
    });
  }

  String _displayName(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) {
      return platformName;
    }

    final advertisedName = device.advName.trim();
    if (advertisedName.isNotEmpty) {
      return advertisedName;
    }

    return 'Pebble';
  }

  String _normalizeDeviceName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }
}

class _PebblePayload {
  const _PebblePayload({
    required this.batteryPercent,
    required this.tds,
  });

  final int? batteryPercent;
  final int? tds;

  static _PebblePayload? tryParse(List<int> value) {
    final rawPayload = utf8.decode(value, allowMalformed: true).trim();
    if (rawPayload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return _PebblePayload(
          batteryPercent: _intValue(
            decoded,
            const ['battery_number', 'batteryPercent', 'battery'],
          ),
          tds: _intValue(decoded, const ['tds_number', 'tds', 'tdsPpm']),
        );
      }

      if (decoded is Map) {
        final normalized = Map<String, dynamic>.from(decoded);
        return _PebblePayload(
          batteryPercent: _intValue(
            normalized,
            const ['battery_number', 'batteryPercent', 'battery'],
          ),
          tds: _intValue(normalized, const ['tds_number', 'tds', 'tdsPpm']),
        );
      }
    } on FormatException {
      final plainTds = int.tryParse(rawPayload);
      if (plainTds != null) {
        return _PebblePayload(batteryPercent: null, tds: plainTds);
      }
    }

    return null;
  }

  static int? _intValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final sanitized = value.replaceAll('%', '').trim();
        final parsed = num.tryParse(sanitized);
        if (parsed != null) {
          return parsed.round();
        }
      }
    }

    return null;
  }
}
