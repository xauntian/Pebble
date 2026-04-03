import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../pages/ask_page.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../theme/design_tokens.dart';
import '../widgets/core_bottom_nav_bar.dart';

class PebbleApp extends StatelessWidget {
  const PebbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pebble',
      theme: buildAppTheme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const AppSnapshot _snapshot = AppSnapshot.demo();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(snapshot: _snapshot),
      const MapPage(snapshot: _snapshot),
      const AskPage(snapshot: _snapshot),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shellWidth = math.min(430.0, constraints.maxWidth);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: shellWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: pages,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _NavigationLayer(
                        currentIndex: _currentIndex,
                        onChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavigationLayer extends StatelessWidget {
  const _NavigationLayer({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final showMapFade = currentIndex == 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: showMapFade
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00DAEECB), Color(0xFFDAEECB)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent],
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        child: CoreBottomNavBar(
          currentIndex: currentIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
