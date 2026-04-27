import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/water_test_report.dart';
import '../services/water_quality_reports_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';
import '../widgets/pebble_glass_card.dart';
import '../widgets/pill_chip.dart';
import '../widgets/progress_ring.dart';

class WaterQualityPage extends StatefulWidget {
  WaterQualityPage({
    super.key,
    this.initialLocationId,
    this.initialRegionCode,
    WaterQualityReportsApi? reportsApi,
  }) : reportsApi = reportsApi ?? WaterQualityReportsApi.shared;

  static const routeName = '/water-quality';

  final String? initialLocationId;
  final String? initialRegionCode;
  final WaterQualityReportsApi reportsApi;

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage> {
  late final Future<List<WaterTestReport>> _reportsFuture;
  String? _selectedLocationId;
  String? _selectedRegionCode;
  String? _selectedReportId;

  @override
  void initState() {
    super.initState();
    _reportsFuture = widget.reportsApi.fetchReports();
    _selectedLocationId = widget.initialLocationId;
    _selectedRegionCode = widget.initialRegionCode;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WaterTestReport>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        final reports = snapshot.data;

        if (reports == null) {
          return const _WaterQualityPageShell(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (reports.isEmpty) {
          return const _WaterQualityPageShell(
            child: Center(
              child: Text(
                'No water quality data',
                style: AppTextStyles.bodyBold,
              ),
            ),
          );
        }

        return _buildLoadedPage(reports);
      },
    );
  }

  Widget _buildLoadedPage(List<WaterTestReport> reports) {
    final locations = _latestLocations(reports);
    final regionCodes = _regionCodes(locations);
    final selectedRegionCode = _resolveRegionCode(locations, regionCodes);
    final locationItems = locations
        .where((location) => location.regionCode == selectedRegionCode)
        .toList(growable: false);
    final selectedLocation = _resolveLocation(locationItems);
    final selectedReports = _reportsForLocation(reports, selectedLocation.id);
    final selectedReport = _resolveReport(selectedReports);

    _selectedRegionCode = selectedRegionCode;
    _selectedLocationId = selectedLocation.id;
    _selectedReportId = selectedReport.id;

    return _WaterQualityPageShell(
      selectedReport: selectedReport,
      selectedRegionCode: selectedRegionCode,
      reports: reports,
      onReportSelected: _selectReport,
      builder: (context, availableHeight, contentWidth) {
        return _buildLoadedContent(
          context: context,
          availableHeight: availableHeight,
          contentWidth: contentWidth,
          selectedLocation: selectedLocation,
          locationItems: locationItems,
          selectedRegionCode: selectedRegionCode,
          regionCodes: regionCodes,
          locations: locations,
          selectedReport: selectedReport,
          selectedReports: selectedReports,
        );
      },
    );
  }

  Widget _buildLoadedContent({
    required BuildContext context,
    required double availableHeight,
    required double contentWidth,
    required _WaterLocationOption selectedLocation,
    required List<_WaterLocationOption> locationItems,
    required String selectedRegionCode,
    required List<String> regionCodes,
    required List<_WaterLocationOption> locations,
    required WaterTestReport selectedReport,
    required List<WaterTestReport> selectedReports,
  }) {
    const titleHeight = 24.0;
    const titleGap = AppSpacing.section;
    const minContentCardHeight = 575.0;
    final contentCardHeight = math.max(
        minContentCardHeight, availableHeight - titleHeight - titleGap);
    final innerContentHeight =
        math.max(0.0, contentCardHeight - AppSpacing.cardPadding * 2);
    final compactness = _compactnessFor(innerContentHeight);
    final sectionGap = _lerp(30, 14, compactness);
    final ringSize = _lerp(152, 112, compactness);
    final measurementRunSpacing = _lerp(27, 12, compactness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: titleHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Water quality',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        const SizedBox(height: titleGap),
        SizedBox(
          width: contentWidth,
          height: contentCardHeight,
          child: PebbleGlassCard(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: SizedBox(
              height: innerContentHeight,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _WaterQualityFilterDropdown<_WaterLocationOption>(
                          value: selectedLocation,
                          items: locationItems,
                          labelFor: (location) => location.name,
                          maxWidth: 150,
                          onSelected: (location) {
                            setState(() {
                              _selectedLocationId = location.id;
                              _selectedRegionCode = location.regionCode;
                              _selectedReportId = null;
                            });
                          },
                        ),
                        _WaterQualityFilterDropdown<String>(
                          value: selectedRegionCode,
                          items: regionCodes,
                          labelFor: (region) => region,
                          maxWidth: 128,
                          onSelected: (region) {
                            setState(() {
                              _selectedRegionCode = region;
                              _selectedLocationId = _firstLocationIdForRegion(
                                locations,
                                region,
                              );
                              _selectedReportId = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  _WaterQualityScore(
                    report: selectedReport,
                    size: ringSize,
                  ),
                  SizedBox(height: sectionGap),
                  _WaterQualityMeasurements(
                    report: selectedReport,
                    runSpacing: measurementRunSpacing,
                  ),
                  SizedBox(height: sectionGap),
                  Expanded(
                    child: _WaterQualityHistoryCard(reports: selectedReports),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _compactnessFor(double height) {
    return ((680 - height) / 180).clamp(0.0, 1.0).toDouble();
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  String _resolveRegionCode(
    List<_WaterLocationOption> locations,
    List<String> regionCodes,
  ) {
    final selectedRegion = _selectedRegionCode;
    if (selectedRegion != null && regionCodes.contains(selectedRegion)) {
      return selectedRegion;
    }

    final selectedLocation = _selectedLocationId;
    if (selectedLocation != null) {
      for (final location in locations) {
        if (location.id == selectedLocation) {
          return location.regionCode;
        }
      }
    }

    return regionCodes.first;
  }

  _WaterLocationOption _resolveLocation(List<_WaterLocationOption> locations) {
    final selectedLocationId = _selectedLocationId;
    if (selectedLocationId != null) {
      for (final location in locations) {
        if (location.id == selectedLocationId) {
          return location;
        }
      }
    }

    return locations.first;
  }

  WaterTestReport _resolveReport(List<WaterTestReport> reports) {
    final selectedReportId = _selectedReportId;
    if (selectedReportId != null) {
      for (final report in reports) {
        if (report.id == selectedReportId) {
          return report;
        }
      }
    }

    return reports.last;
  }

  void _selectReport(WaterTestReport report) {
    setState(() {
      _selectedRegionCode = report.regionCode;
      _selectedLocationId = report.locationId;
      _selectedReportId = report.id;
    });
  }

  List<_WaterLocationOption> _latestLocations(List<WaterTestReport> reports) {
    final latestReports = <String, WaterTestReport>{};

    for (final report in reports) {
      final current = latestReports[report.locationId];
      if (current == null || report.testedAt.isAfter(current.testedAt)) {
        latestReports[report.locationId] = report;
      }
    }

    return latestReports.values.map(_WaterLocationOption.fromReport).toList()
      ..sort((a, b) {
        final regionCompare = _regionSortOrder(a.regionCode)
            .compareTo(_regionSortOrder(b.regionCode));
        if (regionCompare != 0) {
          return regionCompare;
        }

        final regionNameCompare = a.regionCode.compareTo(b.regionCode);
        if (regionNameCompare != 0) {
          return regionNameCompare;
        }

        return a.name.compareTo(b.name);
      });
  }

  List<String> _regionCodes(List<_WaterLocationOption> locations) {
    return List<String>.unmodifiable(
      locations.map((location) => location.regionCode).toSet(),
    );
  }

  List<WaterTestReport> _reportsForLocation(
    List<WaterTestReport> reports,
    String locationId,
  ) {
    return reports
        .where((report) => report.locationId == locationId)
        .toList(growable: false)
      ..sort((a, b) => a.testedAt.compareTo(b.testedAt));
  }

  String _firstLocationIdForRegion(
    List<_WaterLocationOption> locations,
    String regionCode,
  ) {
    for (final location in locations) {
      if (location.regionCode == regionCode) {
        return location.id;
      }
    }

    return locations.first.id;
  }

  int _regionSortOrder(String regionCode) => regionCode == 'SF, CA' ? 0 : 1;
}

class _WaterQualityPageShell extends StatelessWidget {
  const _WaterQualityPageShell({
    this.selectedReport,
    this.selectedRegionCode,
    this.reports = const [],
    this.onReportSelected,
    this.child,
    this.builder,
  });

  final WaterTestReport? selectedReport;
  final String? selectedRegionCode;
  final List<WaterTestReport> reports;
  final ValueChanged<WaterTestReport>? onReportSelected;
  final Widget? child;
  final Widget Function(
    BuildContext context,
    double availableHeight,
    double contentWidth,
  )? builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shellWidth = constraints.maxWidth;
            final horizontalPadding =
                ResponsiveLayout.horizontalPadding(shellWidth);
            final contentWidth =
                math.max(0.0, shellWidth - horizontalPadding * 2);
            final bodyHeight = math.max(
              0.0,
              constraints.maxHeight -
                  AppSpacing.pageTop -
                  48 -
                  AppSpacing.topBarHeight -
                  AppSpacing.section,
            );
            final bodyChild = builder == null
                ? SizedBox(
                    height: bodyHeight,
                    child: child,
                  )
                : builder!(context, bodyHeight, contentWidth);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: shellWidth,
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.pageTop,
                    horizontalPadding,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: AppSpacing.topBarHeight,
                        child: _WaterQualityHeader(
                          selectedReport: selectedReport,
                          selectedRegionCode: selectedRegionCode,
                          reports: reports,
                          contentWidth: contentWidth,
                          onReportSelected: onReportSelected,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      bodyChild,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WaterQualityHeader extends StatelessWidget {
  const _WaterQualityHeader({
    required this.selectedReport,
    required this.selectedRegionCode,
    required this.reports,
    required this.contentWidth,
    required this.onReportSelected,
  });

  final WaterTestReport? selectedReport;
  final String? selectedRegionCode;
  final List<WaterTestReport> reports;
  final double contentWidth;
  final ValueChanged<WaterTestReport>? onReportSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 29,
            height: 29,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (selectedReport case final report?)
          _WaterQualityDatePicker(
            selectedReport: report,
            selectedRegionCode: selectedRegionCode ?? report.regionCode,
            reports: reports,
            contentWidth: contentWidth,
            onReportSelected: onReportSelected,
          )
        else
          const _DatePill(label: '--'),
      ],
    );
  }
}

class _WaterQualityDatePicker extends StatefulWidget {
  const _WaterQualityDatePicker({
    required this.selectedReport,
    required this.selectedRegionCode,
    required this.reports,
    required this.contentWidth,
    required this.onReportSelected,
  });

  final WaterTestReport selectedReport;
  final String selectedRegionCode;
  final List<WaterTestReport> reports;
  final double contentWidth;
  final ValueChanged<WaterTestReport>? onReportSelected;

  @override
  State<_WaterQualityDatePicker> createState() =>
      _WaterQualityDatePickerState();
}

class _WaterQualityDatePickerState extends State<_WaterQualityDatePicker>
    with SingleTickerProviderStateMixin {
  static const _panelMaxWidth = 361.0;
  static const _panelShadowInset = 18.0;
  static const _pillWidth = 126.0;
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdayLabels = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT'
  ];

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;
  late final Animation<Offset> _panelSlideAnimation;
  late final Animation<double> _panelScaleAnimation;
  late DateTime _visibleMonth;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _visibleMonth = _monthStart(widget.selectedReport.testedAt);
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.035),
      end: Offset.zero,
    ).animate(_menuAnimation);
    _panelScaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(_menuAnimation);
  }

  @override
  void didUpdateWidget(covariant _WaterQualityDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = _monthStart(widget.selectedReport.testedAt);
    if (selectedMonth != _monthStart(oldWidget.selectedReport.testedAt)) {
      _visibleMonth = selectedMonth;
    }
    _rebuildOverlayAfterFrame();
  }

  @override
  void dispose() {
    _removeOverlay();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    if (_isOpen) {
      _closeCalendar();
    } else {
      _openCalendar();
    }
  }

  void _openCalendar() {
    if (_overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final panelWidth = math.min(_panelMaxWidth, widget.contentWidth);
        final horizontalOffset = -(panelWidth - _pillWidth) - _panelShadowInset;
        final regionReports = widget.reports
            .where((report) => report.regionCode == widget.selectedRegionCode)
            .toList(growable: false);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeCalendar,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(horizontalOffset, 49 - _panelShadowInset),
              child: FadeTransition(
                opacity: _menuAnimation,
                child: SlideTransition(
                  position: _panelSlideAnimation,
                  child: ScaleTransition(
                    scale: _panelScaleAnimation,
                    alignment: Alignment.topRight,
                    child: SizeTransition(
                      sizeFactor: _menuAnimation,
                      axisAlignment: -1,
                      child: Material(
                        type: MaterialType.transparency,
                        child: SizedBox(
                          width: panelWidth + (_panelShadowInset * 2),
                          child: Padding(
                            padding: const EdgeInsets.all(_panelShadowInset),
                            child: SizedBox(
                              width: panelWidth,
                              child: _CalendarPanel(
                                visibleMonth: _visibleMonth,
                                selectedDate: widget.selectedReport.testedAt,
                                selectedRegionCode: widget.selectedRegionCode,
                                reports: regionReports,
                                onPreviousMonth: _showPreviousMonth,
                                onNextMonth: _showNextMonth,
                                onReportSelected: _selectReport,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _menuController.forward(from: 0);
  }

  void _closeCalendar({bool updateState = true}) {
    if (_overlayEntry == null) {
      if (updateState && mounted && _isOpen) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
      return;
    }

    if (!updateState) {
      _removeOverlay();
      _isOpen = false;
      return;
    }

    _menuController.reverse().whenComplete(() {
      if (_overlayEntry == null) {
        return;
      }

      _removeOverlay();
      if (mounted) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _rebuildOverlayAfterFrame() {
    if (_overlayEntry == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) {
        return;
      }

      _overlayEntry!.markNeedsBuild();
    });
  }

  void _showPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _selectReport(WaterTestReport report) {
    if (_overlayEntry == null) {
      widget.onReportSelected?.call(report);
      return;
    }

    _menuController.reverse().whenComplete(() {
      if (!mounted) {
        return;
      }

      _removeOverlay();
      setState(() => _isOpen = false);
      widget.onReportSelected?.call(report);
    });
  }

  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: _DatePill(
            label: widget.selectedReport.testedAtLabel,
            activeProgress: _menuAnimation.value,
            onTap: _toggleCalendar,
          ),
        );
      },
    );
  }

  static String monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.visibleMonth,
    required this.selectedDate,
    required this.selectedRegionCode,
    required this.reports,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onReportSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final String selectedRegionCode;
  final List<WaterTestReport> reports;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<WaterTestReport> onReportSelected;

  @override
  Widget build(BuildContext context) {
    final reportsByDate = _reportsByDate();
    final rows = _calendarRows();

    return PebbleGlassCard(
      color: AppColors.white.withValues(alpha: 0.8),
      blurSigma: 18,
      boxShadow: AppShadows.card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _WaterQualityDatePickerState.monthLabel(visibleMonth),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 22 / 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.lime,
              ),
              const Spacer(),
              _CalendarArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 18),
              _CalendarArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _WaterQualityDatePickerState._weekdayLabels)
                SizedBox(
                  width: 32,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final day in row)
                  _CalendarDayCell(
                    date: day,
                    report: day == null
                        ? null
                        : reportsByDate[
                            _WaterQualityDatePickerState.dateKey(day)],
                    selected: day != null &&
                        _WaterQualityDatePickerState.dateKey(day) ==
                            _WaterQualityDatePickerState.dateKey(selectedDate),
                    onReportSelected: onReportSelected,
                  ),
              ],
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Map<String, WaterTestReport> _reportsByDate() {
    final byDate = <String, WaterTestReport>{};

    for (final report in reports) {
      if (report.regionCode != selectedRegionCode) {
        continue;
      }

      final testedAt = report.testedAt;
      if (testedAt.year != visibleMonth.year ||
          testedAt.month != visibleMonth.month) {
        continue;
      }

      final key = _WaterQualityDatePickerState.dateKey(testedAt);
      final current = byDate[key];
      if (current == null || report.testedAt.isAfter(current.testedAt)) {
        byDate[key] = report;
      }
    }

    return byDate;
  }

  List<List<DateTime?>> _calendarRows() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingBlankCount = firstDay.weekday % 7;
    final totalSlots = ((leadingBlankCount + daysInMonth + 6) ~/ 7) * 7;
    final slots = <DateTime?>[];

    for (var index = 0; index < totalSlots; index++) {
      final dayNumber = index - leadingBlankCount + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        slots.add(null);
      } else {
        slots.add(DateTime(visibleMonth.year, visibleMonth.month, dayNumber));
      }
    }

    return [
      for (var index = 0; index < slots.length; index += 7)
        slots.sublist(index, index + 7),
    ];
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(
        icon,
        size: 30,
        color: AppColors.lime,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.report,
    required this.selected,
    required this.onReportSelected,
  });

  final DateTime? date;
  final WaterTestReport? report;
  final bool selected;
  final ValueChanged<WaterTestReport> onReportSelected;

  @override
  Widget build(BuildContext context) {
    final date = this.date;
    if (date == null) {
      return const SizedBox(width: 44, height: 44);
    }

    final report = this.report;
    final hasRecord = report != null;
    final dayKey =
        'water-date-day-${_WaterQualityDatePickerState.dateKey(date)}';
    if (!hasRecord) {
      return SizedBox(
        key: ValueKey(dayKey),
        width: 44,
        height: 44,
      );
    }

    final fontSize = selected ? 24.0 : 20.0;
    final fontWeight = selected ? FontWeight.w600 : FontWeight.w400;

    final cell = SizedBox(
      key: ValueKey(dayKey),
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: selected ? 1 : 0,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: 25 / fontSize,
              color: AppColors.lime,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onReportSelected(report),
      child: cell,
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    this.activeProgress = 0,
    this.onTap,
  });

  final String label;
  final double activeProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.pill);
    final progress = activeProgress.clamp(0.0, 1.0);
    final shadow = [
      BoxShadow(
        color: Color.lerp(
          AppShadows.card.first.color,
          const Color(0x26073433),
          progress,
        )!,
        blurRadius: ui.lerpDouble(5, 12, progress)!,
        offset: Offset.zero,
      ),
    ];

    final pill = Transform.translate(
      offset: Offset(0, ui.lerpDouble(0, -1.5, progress)!),
      child: Transform.scale(
        scale: ui.lerpDouble(1, 1.015, progress)!,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.8),
            borderRadius: borderRadius,
            boxShadow: shadow,
          ),
          child: SizedBox(
            width: 126,
            height: 34,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.date,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return pill;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: pill,
    );
  }
}

class _WaterQualityFilterDropdown<T> extends StatefulWidget {
  const _WaterQualityFilterDropdown({
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    required this.maxWidth,
  });

  final T value;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T> onSelected;
  final double maxWidth;

  @override
  State<_WaterQualityFilterDropdown<T>> createState() =>
      _WaterQualityFilterDropdownState<T>();
}

class _WaterQualityFilterDropdownState<T>
    extends State<_WaterQualityFilterDropdown<T>>
    with SingleTickerProviderStateMixin {
  static const double _scale = 1.6;
  static const double _menuInset = 3 * _scale;
  static const double _shadowOutset = 20 * _scale;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _menuController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WaterQualityFilterDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen &&
        (oldWidget.value != widget.value || oldWidget.items != widget.items)) {
      _closeMenu(updateState: false);
    }
  }

  bool get _canOpen => widget.items.any((item) => item != widget.value);

  void _toggleMenu() {
    if (!_canOpen) {
      return;
    }

    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_overlayEntry != null || !_canOpen) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _ScaledDropdownOverlay<T>(
          layerLink: _layerLink,
          offset: const Offset(
            -_shadowOutset - _menuInset,
            -_shadowOutset - _menuInset,
          ),
          animation: _menuAnimation,
          value: widget.value,
          items: widget.items,
          labelFor: widget.labelFor,
          maxWidth: widget.maxWidth,
          onDismiss: _closeMenu,
          onSelected: (item) {
            _closeMenu();
            widget.onSelected(item);
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _menuController.forward(from: 0);
  }

  void _closeMenu({bool updateState = true}) {
    if (_overlayEntry == null) {
      if (updateState && mounted && _isOpen) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
      return;
    }

    if (!updateState) {
      _removeOverlay();
      _isOpen = false;
      return;
    }

    _menuController.reverse().whenComplete(() {
      if (_overlayEntry == null) {
        return;
      }

      _removeOverlay();
      if (mounted) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = _canOpen;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canOpen ? _toggleMenu : null,
        child: Semantics(
          button: canOpen,
          enabled: canOpen,
          expanded: _isOpen,
          child: AnimatedOpacity(
            opacity: _isOpen ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: _ScaledDropdownPillChip(
                label: widget.labelFor(widget.value),
                scale: _scale,
                showIcon: canOpen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaledDropdownOverlay<T> extends StatelessWidget {
  const _ScaledDropdownOverlay({
    required this.layerLink,
    required this.offset,
    required this.animation,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    required this.onDismiss,
    required this.maxWidth,
  });

  static const double _scale = 1.6;
  static const double _menuInset = 3 * _scale;
  static const double _shadowOutset = 20 * _scale;
  static const double _menuWidth = 96 * _scale;

  final LayerLink layerLink;
  final Offset offset;
  final Animation<double> animation;
  final T value;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final availableItems =
        items.where((item) => item != value).toList(growable: false);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: offset,
          child: FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.all(_shadowOutset),
                child: SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(0, -0.04),
                      end: Offset.zero,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: math.max(_menuWidth, maxWidth),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12 * _scale),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A073433),
                              blurRadius: 20 * _scale,
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(_menuInset),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _ScaledSelectedDropdownItem<T>(
                                value: value,
                                label: labelFor(value),
                                onSelected: onSelected,
                              ),
                              for (final item in availableItems)
                                _ScaledDropdownMenuItem<T>(
                                  value: item,
                                  label: labelFor(item),
                                  onSelected: onSelected,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScaledSelectedDropdownItem<T> extends StatelessWidget {
  const _ScaledSelectedDropdownItem({
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final String label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: _ScaledDropdownPillChip(
        label: label,
        scale: 1.6,
      ),
    );
  }
}

class _ScaledDropdownMenuItem<T> extends StatelessWidget {
  const _ScaledDropdownMenuItem({
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final String label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    const scale = 1.6;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: SizedBox(
        width: double.infinity,
        height: 20 * scale,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            8 * scale,
            4 * scale,
            10 * scale,
            4 * scale,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaledDropdownPillChip extends StatelessWidget {
  const _ScaledDropdownPillChip({
    required this.label,
    required this.scale,
    this.showIcon = true,
  });

  final String label;
  final double scale;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return PillChip(
      label: label,
      height: 20 * scale,
      labelWidth: null,
      padding: EdgeInsets.fromLTRB(
        8 * scale,
        4 * scale,
        10 * scale,
        4 * scale,
      ),
      borderRadius: AppRadius.pill,
      textStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 10 * scale,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
        color: AppColors.textPrimary,
      ),
      leading: showIcon
          ? Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 10 * scale,
              color: AppColors.textPrimary,
            )
          : null,
    );
  }
}

class _WaterQualityScore extends StatelessWidget {
  const _WaterQualityScore({
    required this.report,
    required this.size,
  });

  final WaterTestReport report;
  final double size;

  @override
  Widget build(BuildContext context) {
    final score = report.score.clamp(0, 100);
    final valueFontSize = (size * 0.263).clamp(30.0, 40.0).toDouble();
    final suffixFontSize = (size * 0.079).clamp(10.0, 12.0).toDouble();

    return Center(
      child: ProgressRing(
        value: score / 100,
        size: size,
        strokeWidth: size * 0.099,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: '$score',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ).copyWith(fontSize: valueFontSize),
                children: [
                  TextSpan(
                    text: '/ 100',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: suffixFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Score', style: AppTextStyles.sectionLabel),
          ],
        ),
      ),
    );
  }
}

class _WaterQualityMeasurements extends StatelessWidget {
  const _WaterQualityMeasurements({
    required this.report,
    required this.runSpacing,
  });

  final WaterTestReport report;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 276.0;
        final columns = _measurementColumnCount(availableWidth);
        final spacing = columns == 2 ? 36.0 : 28.0;
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = ((availableWidth - totalSpacing) / columns)
            .clamp(68.0, 128.0)
            .toDouble();
        final gridWidth = itemWidth * columns + totalSpacing;

        return Center(
          child: SizedBox(
            width: gridWidth,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: spacing,
              runSpacing: runSpacing,
              children: [
                _WaterMeasurement(
                  width: itemWidth,
                  value: _formatDecimal(report.ph, maxFractionDigits: 2),
                  label: 'PH',
                ),
                _WaterMeasurement(
                  width: itemWidth,
                  value: '${report.tds}',
                  label: 'TDS',
                ),
                _WaterMeasurement(
                  width: itemWidth,
                  value: '${report.temperatureCelsius.round()}',
                  label: '\u00B0C',
                ),
                _WaterMeasurement(
                  width: itemWidth,
                  value: _formatCr6(report.cr6MgPerL),
                  label: 'mg/L\nCr6+',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _measurementColumnCount(double availableWidth) {
    if (availableWidth >= 560) {
      return 4;
    }
    if (availableWidth >= 420) {
      return 3;
    }

    return 2;
  }

  String _formatDecimal(double value, {required int maxFractionDigits}) {
    var formatted = value.toStringAsFixed(maxFractionDigits);
    while (formatted.contains('.') && formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted;
  }

  String _formatCr6(double value) {
    if (value < 0.01) {
      return value.toStringAsFixed(4);
    }

    return _formatDecimal(value, maxFractionDigits: 2);
  }
}

class _WaterMeasurement extends StatelessWidget {
  const _WaterMeasurement({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: 24,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterQualityHistoryCard extends StatelessWidget {
  const _WaterQualityHistoryCard({required this.reports});

  final List<WaterTestReport> reports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 340.0;
        final maxVisibleReports = _maxVisibleReportsForWidth(availableWidth);
        final visibleReports = reports.length <= maxVisibleReports
            ? reports
            : reports.sublist(reports.length - maxVisibleReports);
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (availableWidth * 0.72).clamp(220.0, 360.0).toDouble();

        return SizedBox(
          width: double.infinity,
          height: height,
          child: _InnerShadowContainer(
            color: const Color(0x0D6EDB1A),
            borderRadius: BorderRadius.circular(AppRadius.card),
            shadowColor: const Color(0x33094A49),
            blurRadius: 6.3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test history score',
                    style: AppTextStyles.sectionLabel,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: CustomPaint(
                      painter: _WaterHistoryChartPainter(visibleReports),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _maxVisibleReportsForWidth(double availableWidth) {
    const horizontalPadding = 50.0;
    const scoreAxisWidth = 47.0;
    const minPointSpacing = 56.0;
    const minVisibleReports = 4;
    const maxVisibleReports = 9;

    final plotWidth = math.max(
      0.0,
      availableWidth - horizontalPadding - scoreAxisWidth,
    );
    final count = (plotWidth / minPointSpacing).floor() + 1;

    return count.clamp(minVisibleReports, maxVisibleReports);
  }
}

class _InnerShadowContainer extends StatelessWidget {
  const _InnerShadowContainer({
    required this.child,
    required this.color,
    required this.borderRadius,
    required this.shadowColor,
    required this.blurRadius,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final Color shadowColor;
  final double blurRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
        child: CustomPaint(
          foregroundPainter: _InnerShadowPainter(
            borderRadius: borderRadius,
            color: shadowColor,
            blurRadius: blurRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({
    required this.borderRadius,
    required this.color,
    required this.blurRadius,
  });

  final BorderRadius borderRadius;
  final Color color;
  final double blurRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final outerRect = rect.inflate(blurRadius * 2);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(AppRadius.card + blurRadius * 2),
    );
    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outerRRect)
      ..addRRect(rrect);

    final shadowPaint = Paint()
      ..color = color
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        _blurRadiusToSigma(blurRadius),
      );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  double _blurRadiusToSigma(double radius) => radius * 0.57735 + 0.5;

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.blurRadius != blurRadius;
  }
}

class _WaterHistoryChartPainter extends CustomPainter {
  const _WaterHistoryChartPainter(this.reports);

  final List<WaterTestReport> reports;

  @override
  void paint(Canvas canvas, Size size) {
    const scoreLabelHeight = 14.0;
    final plotRect = Rect.fromLTRB(
      39,
      scoreLabelHeight / 2,
      size.width - 8,
      size.height - 30,
    );
    final axisPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final guidePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final secondaryGuidePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.2)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(plotRect.left, plotRect.bottom),
      Offset(plotRect.right, plotRect.bottom),
      axisPaint,
    );

    if (reports.isEmpty) {
      return;
    }

    final scoreRange = _visibleScoreRange(reports);
    final scores = reports.map((report) => report.score.clamp(0, 100)).toList();
    final finalScore = scores.last;
    final minScore = scores.reduce(math.min);
    final maxScore = scores.reduce(math.max);
    final guideY = _scoreToY(finalScore, plotRect, scoreRange);
    final minScoreY = _scoreToY(minScore, plotRect, scoreRange);
    final maxScoreY = _scoreToY(maxScore, plotRect, scoreRange);
    const scoreLabelStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    final secondaryScoreLabelStyle = scoreLabelStyle.copyWith(
      color: AppColors.textPrimary.withValues(alpha: 0.3),
    );

    _drawDashedLine(
      canvas,
      Offset(plotRect.left, guideY),
      Offset(plotRect.right, guideY),
      guidePaint,
    );
    final finalLabelTop = _scoreLabelTop(guideY, size.height);
    final labelTops = <double>[finalLabelTop];

    _drawText(
      canvas,
      '$finalScore',
      Offset(0, finalLabelTop),
      scoreLabelStyle,
    );

    if (maxScore != finalScore) {
      _drawDashedLine(
        canvas,
        Offset(plotRect.left, maxScoreY),
        Offset(plotRect.right, maxScoreY),
        secondaryGuidePaint,
      );
      final maxLabelTop = _scoreLabelTop(
        maxScoreY,
        size.height,
        avoidTops: labelTops,
      );
      labelTops.add(maxLabelTop);
      _drawText(
        canvas,
        '$maxScore',
        Offset(0, maxLabelTop),
        secondaryScoreLabelStyle,
      );
    }

    if (minScore != finalScore && minScore != maxScore) {
      _drawDashedLine(
        canvas,
        Offset(plotRect.left, minScoreY),
        Offset(plotRect.right, minScoreY),
        secondaryGuidePaint,
      );
      final minLabelTop = _scoreLabelTop(
        minScoreY,
        size.height,
        avoidTops: labelTops,
      );
      _drawText(
        canvas,
        '$minScore',
        Offset(0, minLabelTop),
        secondaryScoreLabelStyle,
      );
    }

    final points = <Offset>[];
    final lastIndex = math.max(1, reports.length - 1);

    for (var index = 0; index < reports.length; index++) {
      final report = reports[index];
      final x = reports.length == 1
          ? plotRect.left
          : plotRect.left + (plotRect.width * index / lastIndex);
      final y = _scoreToY(report.score, plotRect, scoreRange);
      final point = Offset(x, y);
      points.add(point);

      _drawDashedLine(
        canvas,
        point,
        Offset(x, plotRect.bottom),
        secondaryGuidePaint,
      );
      _drawCenteredText(
        canvas,
        _shortDateLabel(
          report,
          includeShortYear: index == reports.length - 1,
        ),
        Offset(x, plotRect.bottom + 9),
        const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      );
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, 3, linePaint..style = PaintingStyle.fill);
      return;
    }

    canvas.drawPath(_smoothPath(points, plotRect), linePaint);
  }

  Path _smoothPath(List<Offset> points, Rect bounds) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    const tension = 0.2;

    for (var index = 0; index < points.length - 1; index++) {
      final p0 = index == 0 ? points[index] : points[index - 1];
      final p1 = points[index];
      final p2 = points[index + 1];
      final p3 = index + 2 < points.length ? points[index + 2] : p2;
      final control1 = _clampToBounds(p1 + (p2 - p0) * tension, bounds);
      final control2 = _clampToBounds(p2 - (p3 - p1) * tension, bounds);

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        p2.dx,
        p2.dy,
      );
    }

    return path;
  }

  Offset _clampToBounds(Offset offset, Rect bounds) {
    return Offset(
      offset.dx.clamp(bounds.left, bounds.right).toDouble(),
      offset.dy.clamp(bounds.top, bounds.bottom).toDouble(),
    );
  }

  _ScoreRange _visibleScoreRange(List<WaterTestReport> reports) {
    final scores = reports.map((report) => report.score.clamp(0, 100));
    final minScore = scores.reduce(math.min);
    final maxScore = scores.reduce(math.max);
    final lowerBound =
        minScore <= 20 ? 0.0 : math.max(0.0, minScore - 8).toDouble();
    final upperBound = maxScore.toDouble();

    return _ScoreRange(lowerBound: lowerBound, upperBound: upperBound);
  }

  double _scoreToY(num score, Rect rect, _ScoreRange range) {
    final normalized =
        ((score.clamp(0, 100) - range.lowerBound) / range.span).clamp(0, 1);
    return rect.bottom - rect.height * normalized;
  }

  double _scoreLabelTop(
    double scoreY,
    double canvasHeight, {
    List<double> avoidTops = const [],
  }) {
    const labelHeight = 14.0;
    const minGap = 3.0;
    var top = (scoreY - labelHeight / 2).clamp(
      0.0,
      math.max(0.0, canvasHeight - labelHeight),
    );
    final maxTop = math.max(0.0, canvasHeight - labelHeight);

    if (_hasLabelRoom(top.toDouble(), avoidTops, labelHeight, minGap)) {
      return top.toDouble();
    }

    final candidates = <double>[
      for (final avoidTop in avoidTops) ...[
        avoidTop + labelHeight + minGap,
        avoidTop - labelHeight - minGap,
      ],
    ]..sort((a, b) {
        final distanceCompare = (a - top).abs().compareTo((b - top).abs());
        if (distanceCompare != 0) {
          return distanceCompare;
        }
        return a.compareTo(b);
      });

    for (final candidate in candidates) {
      final clamped = candidate.clamp(0.0, maxTop).toDouble();
      if (_hasLabelRoom(clamped, avoidTops, labelHeight, minGap)) {
        return clamped;
      }
    }

    return top.toDouble();
  }

  bool _hasLabelRoom(
    double top,
    List<double> avoidTops,
    double labelHeight,
    double minGap,
  ) {
    return avoidTops.every(
      (avoidTop) => (top - avoidTop).abs() >= labelHeight + minGap,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dash = 5.0;
    const gap = 5.0;
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return;
    }

    final direction = delta / distance;
    var travelled = 0.0;
    while (travelled < distance) {
      final segmentEnd = math.min(travelled + dash, distance);
      canvas.drawLine(
        start + direction * travelled,
        start + direction * segmentEnd,
        paint,
      );
      travelled += dash + gap;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset centerTop,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 56);
    painter.paint(
      canvas,
      Offset(centerTop.dx - painter.width / 2, centerTop.dy),
    );
  }

  String _shortDateLabel(
    WaterTestReport report, {
    required bool includeShortYear,
  }) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = report.testedAt;
    final year = (date.year % 100).toString().padLeft(2, '0');

    return includeShortYear
        ? '${months[date.month - 1]} ${date.day}, $year'
        : '${months[date.month - 1]} ${date.day}';
  }

  @override
  bool shouldRepaint(covariant _WaterHistoryChartPainter oldDelegate) {
    return oldDelegate.reports != reports;
  }
}

class _ScoreRange {
  const _ScoreRange({
    required this.lowerBound,
    required this.upperBound,
  });

  final double lowerBound;
  final double upperBound;

  double get span => math.max(1.0, upperBound - lowerBound);
}

class _WaterLocationOption {
  const _WaterLocationOption({
    required this.id,
    required this.name,
    required this.regionCode,
  });

  factory _WaterLocationOption.fromReport(WaterTestReport report) {
    return _WaterLocationOption(
      id: report.locationId,
      name: report.locationName,
      regionCode: report.regionCode,
    );
  }

  final String id;
  final String name;
  final String regionCode;
}
