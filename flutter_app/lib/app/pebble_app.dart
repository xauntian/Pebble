import 'package:flutter/material.dart';

import '../navigation/app_shell.dart';
import '../theme/app_theme.dart';

class PebbleApp extends StatelessWidget {
  const PebbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pebble',
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
