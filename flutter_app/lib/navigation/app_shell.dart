import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_snapshot.dart';
import '../pages/ask_page.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../services/ask_ai_responder.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';
import 'app_destination.dart';
import 'app_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.askAiResponder = const ApiAskAiResponder(),
  });

  final AskAiResponder askAiResponder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const AppSnapshot _snapshot = AppSnapshot.demo();

  AppDestination _destination = AppDestination.home;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;

    final page = switch (_destination) {
      AppDestination.home => HomePage(
          snapshot: _snapshot,
          onMenuPressed: _openMenu,
        ),
      AppDestination.map => const MapPage(snapshot: _snapshot),
      AppDestination.ask => AskPage(
          snapshot: _snapshot,
          aiResponder: widget.askAiResponder,
          onMenuPressed: _openMenu,
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
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
                          setState(() {
                            _destination = next;
                            _isMenuOpen = false;
                          });
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: _HomeMenuOverlay(
                        isOpen: _isMenuOpen,
                        onDismiss: _closeMenu,
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

  void _openMenu() {
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    if (!_isMenuOpen) {
      return;
    }

    setState(() {
      _isMenuOpen = false;
    });
  }
}

class _HomeMenuOverlay extends StatelessWidget {
  const _HomeMenuOverlay({
    required this.isOpen,
    required this.onDismiss,
  });

  static const _animationDuration = Duration(milliseconds: 260);

  final bool isOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(267.0, constraints.maxWidth * 0.78);

        return IgnorePointer(
          ignoring: !isOpen,
          child: Stack(
            children: [
              AnimatedOpacity(
                opacity: isOpen ? 1 : 0,
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: Container(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
              AnimatedPositioned(
                duration: _animationDuration,
                curve: isOpen ? Curves.easeOutCubic : Curves.easeInCubic,
                left: isOpen ? 0 : -panelWidth,
                top: 0,
                bottom: 0,
                width: panelWidth,
                child: const _HomeMenuPanel(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeMenuPanel extends StatelessWidget {
  const _HomeMenuPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3D3D3D),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/figma/menu-user.svg',
                width: 39,
                height: 39,
              ),
              SvgPicture.asset(
                'assets/figma/menu-mail.svg',
                width: 35,
                height: 35,
              ),
            ],
          ),
          const SizedBox(height: 19),
          const SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yansong Teng',
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Signssssss',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.controlFill,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.control,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/figma/menu-setting.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Setting',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
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
