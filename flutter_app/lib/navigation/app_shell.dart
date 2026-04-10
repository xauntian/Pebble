import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../pages/ask_page.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_destination.dart';
import 'app_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const AppSnapshot _snapshot = AppSnapshot.demo();

  AppDestination _destination = AppDestination.home;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;

    final pages = <Widget>[
      const HomePage(snapshot: _snapshot),
      const MapPage(snapshot: _snapshot),
      const AskPage(snapshot: _snapshot),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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
                        index: _destination.index,
                        children: pages,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _NavigationLayer(
                        destination: _destination,
                        bottomInset: bottomInset,
                        onChanged: (next) {
                          setState(() => _destination = next);
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
    required this.destination,
    required this.bottomInset,
    required this.onChanged,
  });

  final AppDestination destination;
  final double bottomInset;
  final ValueChanged<AppDestination> onChanged;

  @override
  Widget build(BuildContext context) {
    final showMapFade = destination == AppDestination.map;

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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.lg,
          AppSpacing.pageHorizontal,
          AppSpacing.navBottomOffset + bottomInset,
        ),
        child: AppNavBar(
          currentDestination: destination,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
