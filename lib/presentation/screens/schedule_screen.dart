import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/presentation/widgets/schedule/day_section.dart';

/// Экран "Расписание" — недельный лонг-лист + pinned шапка, которая сжимается только по высоте.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const Color _lessonAccent = Colors.grey;

  late final ScheduleRepository _repository;

  Map<String, List<Schedule>> _weeklySchedule = {};
  bool _isLoading = false;

  /// true = показываем иконку wifi_off в шапке.
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _repository.dataUpdatedNotifier.addListener(_onDataUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSchedule();
    });
  }

  Future<void> _initializeSchedule() async {
    await _loadScheduleData(forceRefresh: false, showLoader: true);
    await _loadScheduleData(forceRefresh: true, showLoader: false);
  }

  void _onDataUpdated() {
    _loadScheduleData(forceRefresh: false, showLoader: false);
  }

  Future<void> _loadScheduleData({
    required bool forceRefresh,
    bool showLoader = true,
  }) async {
    if (showLoader) setState(() => _isLoading = true);

    bool? refreshOk;

    try {
      if (forceRefresh) {
        refreshOk = await _repository.forceRefreshWithStatus();
      }

      final weekly = await _repository.getWeeklySchedule();
      if (!mounted) return;

      setState(() {
        _weeklySchedule = weekly;

        // Логика как в OverviewScreen:
        // - если не было попытки forceRefresh -> берём флаг из репозитория
        // - если была попытка -> офлайн = !refreshOk
        _isOffline = refreshOk == null ? _repository.isOfflineBadgeVisible : !refreshOk;

        if (showLoader) _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (showLoader) setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
    }
  }

  List<Color> _getHeaderGradient(String weekType) {
    if (weekType == 'Знаменатель') {
      return const [Color(0xFF111111), Color(0xFF4FC3F7)];
    } else if (weekType == 'Числитель') {
      return const [Color(0xFF111111), Color(0xFFFF8C00)];
    } else {
      return const [Color(0xFF111111), Color(0xFF333333)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = _isLoading && _weeklySchedule.isEmpty;
    final days = _weeklySchedule.entries.toList();

    final now = DateTime.now();
    final weekType = DateFormatter.getWeekType(now);
    final dateLabel = DateFormatter.formatDayWithMonth(now);

    const headerMaxHeight = 176.0;
    const headerMinHeight = 120.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: isInitialLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: () => _loadScheduleData(forceRefresh: true),
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HeightPinnedHeaderDelegate(
                        backgroundColor: _backgroundColor,
                        maxHeight: headerMaxHeight,
                        minHeight: headerMinHeight,
                        child: _CollapsibleWeekHeader(
                          maxHeight: headerMaxHeight,
                          minHeight: headerMinHeight,
                          title: 'Неделя',
                          dateLabel: dateLabel,
                          weekType: weekType,
                          gradient: _getHeaderGradient(weekType),
                          isOffline: _isOffline,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final day = days[index];
                            final building = _primaryBuilding(day.value);

                            return DaySection(
                              title: day.key,
                              building: building,
                              lessons: day.value,
                              accentColor: _lessonAccent,
                              weekType: weekType,
                            );
                          },
                          childCount: days.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _primaryBuilding(List<Schedule> schedule) {
    if (schedule.isEmpty) return '';

    final Map<String, int> counts = {};
    for (final lesson in schedule) {
      counts[lesson.building] = (counts[lesson.building] ?? 0) + 1;
    }

    String primary = schedule.first.building;
    int maxCount = 0;

    counts.forEach((building, count) {
      if (count > maxCount) {
        maxCount = count;
        primary = building;
      }
    });

    return primary;
  }

  @override
  void dispose() {
    _repository.dataUpdatedNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }
}

/// Делегат pinned-хедера: меняется только высота.
class _HeightPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeightPinnedHeaderDelegate({
    required this.backgroundColor,
    required this.maxHeight,
    required this.minHeight,
    required this.child,
  });

  final Color backgroundColor;
  final double maxHeight;
  final double minHeight;
  final Widget child;

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _HeightPinnedHeaderDelegate old) {
    return old.backgroundColor != backgroundColor ||
        old.maxHeight != maxHeight ||
        old.minHeight != minHeight ||
        old.child != child;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(child: child),
    );
  }
}

/// Одинаковая компоновка и в раскрытом, и в мини-режиме — всё только уменьшается:
/// LEFT: title + dateLabel
/// RIGHT: weekType pill, под ним wifi_off (если offline)
class _CollapsibleWeekHeader extends StatelessWidget {
  const _CollapsibleWeekHeader({
    required this.maxHeight,
    required this.minHeight,
    required this.title,
    required this.dateLabel,
    required this.weekType,
    required this.gradient,
    required this.isOffline,
  });

  final double maxHeight;
  final double minHeight;

  final String title;
  final String dateLabel;
  final String weekType;
  final List<Color> gradient;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.clamp(minHeight, maxHeight);
        final t = ((maxHeight - h) / (maxHeight - minHeight)).clamp(0.0, 1.0); // 0 expanded -> 1 mini

        final radius = lerpDouble(32, 22, t)!;

        final padH = lerpDouble(20, 16, t)!;
        final padTop = lerpDouble(18, 10, t)!;
        final padBottom = lerpDouble(18, 10, t)!;

        final titleSize = lerpDouble(28, 20, t)!;
        final dateSize = lerpDouble(16, 12.5, t)!;

        final pillFont = lerpDouble(13, 11.5, t)!;
        final pillPH = lerpDouble(14, 10, t)!;
        final pillPV = lerpDouble(6, 4.5, t)!;

        final gapTitleDate = lerpDouble(4, 2, t)!;
        final gapPillIcon = lerpDouble(10, 6, t)!;

        final iconSize = lerpDouble(18, 14, t)!;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: lerpDouble(0.45, 0.25, t)!),
                blurRadius: lerpDouble(30, 18, t)!,
                offset: Offset(0, lerpDouble(18, 10, t)!),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: gapTitleDate),
                        Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: dateSize,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _WeekTypePill(
                      text: weekType,
                      fontSize: pillFont,
                      padH: pillPH,
                      padV: pillPV,
                    ),
                    SizedBox(height: gapPillIcon),

                    // Резервируем место всегда, но показываем только при офлайне.
                    SizedBox(
                      height: iconSize,
                      child: Opacity(
                        opacity: isOffline ? 1.0 : 0.0,
                        child: Icon(
                          Icons.wifi_off,
                          size: iconSize,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekTypePill extends StatelessWidget {
  const _WeekTypePill({
    required this.text,
    required this.fontSize,
    required this.padH,
    required this.padV,
  });

  final String text;
  final double fontSize;
  final double padH;
  final double padV;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
      ),
    );
  }
}
