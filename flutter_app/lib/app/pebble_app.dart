import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/water_test_report.dart';
import '../navigation/app_shell.dart';
import '../pages/water_quality_page.dart';
import '../services/ask_ai_responder.dart';
import '../services/water_quality_reports_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class PebbleApp extends StatefulWidget {
  const PebbleApp({
    super.key,
    this.askAiResponder = const ApiAskAiResponder(),
  });

  final AskAiResponder askAiResponder;

  @override
  State<PebbleApp> createState() => _PebbleAppState();
}

class _PebbleAppState extends State<PebbleApp> {
  static const _systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarDividerColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiOverlayStyle,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'pebble',
        theme: buildAppTheme(),
        home: AppShell(askAiResponder: widget.askAiResponder),
        builder: (context, child) {
          return _NewTestNoticeOverlay(
            navigatorKey: _navigatorKey,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _NewTestNoticeOverlay extends StatefulWidget {
  const _NewTestNoticeOverlay({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<_NewTestNoticeOverlay> createState() => _NewTestNoticeOverlayState();
}

class _NewTestNoticeOverlayState extends State<_NewTestNoticeOverlay> {
  late final StreamSubscription<WaterTestReport> _generatedReportSubscription;
  final Queue<WaterTestReport> _queuedReports = Queue<WaterTestReport>();
  WaterTestReport? _pendingReport;
  bool _isOpeningReport = false;

  @override
  void initState() {
    super.initState();
    _generatedReportSubscription =
        WaterQualityReportsApi.shared.generatedReports.listen((report) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_pendingReport == null) {
          _pendingReport = report;
        } else {
          _queuedReports.add(report);
        }
        _isOpeningReport = false;
      });
    });
  }

  @override
  void dispose() {
    _generatedReportSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingReport = _pendingReport;

    return Stack(
      children: [
        widget.child,
        if (pendingReport != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clearNotice,
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
        if (pendingReport != null)
          Positioned.fill(
            child: Center(
              child: _NewTestNoticeCard(
                onCancel: _clearNotice,
                onView: () {
                  _openGeneratedReport(pendingReport);
                },
              ),
            ),
          ),
      ],
    );
  }

  void _clearNotice() {
    setState(() {
      _isOpeningReport = false;
      _showNextNotice();
    });
  }

  void _openGeneratedReport(WaterTestReport report) {
    if (_isOpeningReport) {
      return;
    }

    setState(() {
      _isOpeningReport = true;
      _pendingReport = null;
    });

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      setState(() {
        _isOpeningReport = false;
        _showNextNotice();
      });
      return;
    }

    navigator
        .push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: WaterQualityPage.routeName),
        builder: (context) {
          return WaterQualityPage(
            initialLocationId: report.locationId,
            initialRegionCode: report.regionCode,
            initialReportId: report.id,
          );
        },
      ),
    )
        .whenComplete(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _isOpeningReport = false;
        _showNextNotice();
      });
    });
  }

  void _showNextNotice() {
    _pendingReport =
        _queuedReports.isEmpty ? null : _queuedReports.removeFirst();
  }
}

class _NewTestNoticeCard extends StatelessWidget {
  const _NewTestNoticeCard({
    required this.onCancel,
    required this.onView,
  });

  final VoidCallback onCancel;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);

    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.62),
              borderRadius: borderRadius,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A4C7C09),
                  blurRadius: 18,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: SizedBox(
              width: 219,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You have a new test result',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NoticeActionButton(
                              label: 'Cancel',
                              backgroundColor: AppColors.controlSubtleFill,
                              foregroundColor: AppColors.textPrimary,
                              onTap: onCancel,
                            ),
                            const SizedBox(width: 10),
                            _NoticeActionButton(
                              label: 'View',
                              backgroundColor: AppColors.controlPrimary,
                              foregroundColor: AppColors.white,
                              boxShadow: AppShadows.control,
                              onTap: onView,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeActionButton extends StatelessWidget {
  const _NoticeActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.boxShadow = AppShadows.control,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: boxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
