import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const WaterQualityApp());
}

class WaterQualityApp extends StatelessWidget {
  const WaterQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Quality Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF62D11A),
          surface: const Color(0xFFF1F6ED),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F6ED),
        useMaterial3: true,
      ),
      home: const RootPage(),
    );
  }
}

class WaterReading {
  final double ph;
  final int tds;
  final double temperature;
  final double cr6;
  final int score;

  const WaterReading({
    required this.ph,
    required this.tds,
    required this.temperature,
    required this.cr6,
    required this.score,
  });

  factory WaterReading.fromArduinoPayload(String raw) {
    final pairs = raw
        .split(';')
        .where((s) => s.contains(':'))
        .map((e) => e.split(':'))
        .where((pair) => pair.length == 2)
        .map((pair) => MapEntry(pair[0].trim().toLowerCase(), pair[1].trim()));

    final map = <String, String>{for (final item in pairs) item.key: item.value};

    return WaterReading(
      ph: double.tryParse(map['ph'] ?? '') ?? 7.05,
      tds: int.tryParse(map['tds'] ?? '') ?? 75,
      temperature: double.tryParse(map['temp'] ?? '') ?? 25,
      cr6: double.tryParse(map['cr6'] ?? '') ?? 0.15,
      score: int.tryParse(map['score'] ?? '') ?? 66,
    );
  }
}

class ArduinoBleService {
  final _controller = StreamController<WaterReading>.broadcast();
  StreamSubscription<List<int>>? _notifySubscription;

  static const serviceUuid =
      '0000ffe0-0000-1000-8000-00805f9b34fb'; // 常见HC-05示例，需按设备修改
  static const characteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  Stream<WaterReading> get readings => _controller.stream;

  Future<void> scanAndConnect() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final result = await FlutterBluePlus.scanResults
        .map((r) => r.where((e) => e.device.platformName.isNotEmpty).toList())
        .first;

    if (result.isEmpty) return;
    final target = result.first.device;
    await target.connect(timeout: const Duration(seconds: 8));
    final services = await target.discoverServices();

    for (final service in services) {
      if (service.uuid.str.toLowerCase() == serviceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid.str.toLowerCase() == characteristicUuid) {
            await c.setNotifyValue(true);
            _notifySubscription = c.onValueReceived.listen((bytes) {
              final payload = utf8.decode(bytes, allowMalformed: true);
              final reading = WaterReading.fromArduinoPayload(payload);
              _controller.add(reading);
            });
          }
        }
      }
    }
  }

  void injectMockData() {
    _controller.add(const WaterReading(
      ph: 7.05,
      tds: 75,
      temperature: 25,
      cr6: 0.15,
      score: 66,
    ));
  }

  Future<void> dispose() async {
    await _notifySubscription?.cancel();
    await _controller.close();
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 1;
  final ble = ArduinoBleService();
  WaterReading reading = const WaterReading(
    ph: 7.05,
    tds: 75,
    temperature: 25,
    cr6: 0.15,
    score: 66,
  );

  @override
  void initState() {
    super.initState();
    ble.injectMockData();
    ble.readings.listen((value) {
      if (mounted) {
        setState(() => reading = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HealthDashboardPage(reading: reading),
      MapOverviewPage(reading: reading),
      KnowledgePage(reading: reading),
      WaterQualityDetailPage(reading: reading),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.insights_outlined), label: ''),
            NavigationDestination(icon: Icon(Icons.map_outlined), label: ''),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: ''),
            NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: ''),
          ],
        ),
      ),
    );
  }
}

class HealthDashboardPage extends StatelessWidget {
  final WaterReading reading;
  const HealthDashboardPage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar('My Health Test'),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.88,
              children: [
                _card(
                  'Avg test Number',
                  Center(child: Text('75/100', style: Theme.of(context).textTheme.headlineMedium)),
                ),
                _card('Your\'s', const Center(child: Text('Test Kit\nConnected', textAlign: TextAlign.center))),
                _card('Test Life', _ring(reading.score, suffix: '%')),
                _card('Water Quality', _ring(reading.score, suffix: '/100')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapOverviewPage extends StatelessWidget {
  final WaterReading reading;
  const MapOverviewPage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8EEE2), Color(0xFFDDE8D2)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 24,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search place',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 80,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Animal Park', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('This place is better to\ndrink after filter'),
                      ],
                    ),
                  ),
                  _ring(reading.score, suffix: ''),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class KnowledgePage extends StatelessWidget {
  final WaterReading reading;
  const KnowledgePage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final list = ['What is TDS?', 'What is TDS Levels?', 'Is clear water safe?', 'How to improve water quality'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar('Knowledge of Water'),
          const SizedBox(height: 16),
          ...list.map((e) => Card(
                child: ListTile(
                  title: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 180,
              child: Column(
                children: const [
                  ListTile(title: Text('AI Search', style: TextStyle(fontWeight: FontWeight.bold))),
                  Spacer(),
                  Text('Click or Press to ask'),
                  SizedBox(height: 14),
                  CircleAvatar(radius: 22, backgroundColor: Color(0xFF8DB45B), child: Icon(Icons.multitrack_audio, color: Colors.white)),
                  SizedBox(height: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class WaterQualityDetailPage extends StatelessWidget {
  final WaterReading reading;
  const WaterQualityDetailPage({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar('Water quality'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ring(reading.score, suffix: '/100'),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric('PH', reading.ph.toStringAsFixed(2)),
                        _metric('TDS', '${reading.tds}'),
                        _metric('℃', reading.temperature.toStringAsFixed(0)),
                        _metric('mg/L\nCr6+', reading.cr6.toStringAsFixed(2)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minY: 40,
                          maxY: 80,
                          gridData: const FlGridData(show: true),
                          titlesData: const FlTitlesData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 55),
                                FlSpot(1, 60),
                                FlSpot(2, 50),
                                FlSpot(3, 66),
                              ],
                              isCurved: true,
                              color: const Color(0xFF1C2A2D),
                              barWidth: 3,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget _topBar(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu, size: 30),
          Chip(
            avatar: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Jun 10, 2024'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF62D11A), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tune),
          )
        ],
      ),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFF16262A))),
    ],
  );
}

Widget _card(String title, Widget child) {
  return Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

Widget _ring(int score, {required String suffix}) {
  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 150,
        height: 150,
        child: CircularProgressIndicator(
          value: score / 100,
          strokeWidth: 12,
          color: const Color(0xFF62D11A),
          backgroundColor: const Color(0xFFDFE8D7),
        ),
      ),
      Text('$score$suffix', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
    ],
  );
}

Widget _metric(String label, String value) {
  return Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
