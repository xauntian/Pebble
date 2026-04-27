import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../pages/ask_page.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/responsive_layout.dart';
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

    final page = switch (_destination) {
      AppDestination.home => const HomePage(snapshot: _snapshot),
      AppDestination.map => const MapPage(snapshot: _snapshot),
      AppDestination.ask => const AskPage(snapshot: _snapshot),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shellWidth = constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: shellWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: page,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            ResponsiveLayout.horizontalPadding(constraints.maxWidth);
        final navWidth = math.min(
          430.0,
          math.max(0.0, constraints.maxWidth - horizontalPadding * 2),
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.lg,
            horizontalPadding,
            AppSpacing.navBottomOffset + bottomInset,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: navWidth,
              child: AppNavBar(
                currentDestination: destination,
                onChanged: onChanged,
              ),
            ),
          ),
        );
      },
    );
  }
}
