import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:my_mpt/core/services/notification_service.dart';
import 'package:my_mpt/core/utils/calls_util.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/core/utils/lesson_details_parser.dart';
import 'package:my_mpt/data/repositories/replacement_repository.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/domain/entities/replacement.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/presentation/widgets/overview/page_indicator.dart';
import 'package:my_mpt/presentation/widgets/overview/replacement_card.dart';
import 'package:my_mpt/presentation/widgets/shared/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/shared/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/shared/location.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  static const backgroundColor = Color(0xFF000000);
  static const Color lessonAccent = Colors.grey;

  late final ScheduleRepository repository;
  late final ReplacementRepository changesRepository;

  List<Schedule> todayScheduleData = const [];
  List<Schedule> tomorrowScheduleData = const [];
  List<Replacement> scheduleChanges = const [];

  bool isLoading = false;

  /// true = показываем офлайн (когда пытались обновиться и не смогли, но кэш есть)
  bool isOffline = false;

  final PageController pageController = PageController();
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    repository = ScheduleRepository();
    changesRepository = ReplacementRepository();

    repository.dataUpdatedNotifier.addListener(onDataUpdated);

    // Даем первому кадру отрисоваться.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeSchedule();
    });
  }

  Future<void> initializeSchedule() async {
    await fetchScheduleData(forceRefresh: false, showLoader: true);
    await fetchScheduleData(forceRefresh: true, showLoader: false);
  }

  void onDataUpdated() {
    fetchScheduleData(forceRefresh: false, showLoader: false);
  }

  Future<void> fetchScheduleData({
    required bool forceRefresh,
    bool showLoader = true,
  }) async {
    if (showLoader) setState(() => isLoading = true);

    bool? refreshOk;

    try {
      if (forceRefresh) {
        refreshOk = await repository.forceRefreshWithStatus();
      }

      final scheduleResults = await Future.wait<List<Schedule>>([
        repository.getTodaySchedule(),
        repository.getTomorrowSchedule(),
      ]);

      if (!mounted) return;

      setState(() {
        todayScheduleData = scheduleResults[0];
        tomorrowScheduleData = scheduleResults[1];

        // Если была реальная попытка обновления и она провалилась — показываем офлайн.
        // Если не было попытки — берём флаг из репозитория.
        isOffline = refreshOk == null ? repository.isOfflineBadgeVisible : !refreshOk;

        if (showLoader) isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      if (showLoader) setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
      return;
    }

    // Изменения/уведомления — отдельным блоком, чтобы не ломать показ расписания.
    try {
      final loadedChanges = await changesRepository.getScheduleChanges();
      if (!mounted) return;

      setState(() {
        scheduleChanges = loadedChanges;
      });

      final notificationService = NotificationService();
      await notificationService.updateLastCheckedReplacements();
    } catch (_) {
      // ignore
    }
  }

  List<Color> getHeaderGradient(String weekType) {
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
    final hasCachedData = todayScheduleData.isNotEmpty || tomorrowScheduleData.isNotEmpty;
    final isInitialLoading = isLoading && !hasCachedData;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: isInitialLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Stack(
                children: [
                  PageView(
                    controller: pageController,
                    onPageChanged: (index) => setState(() => currentPageIndex = index),
                    children: [
                      RefreshIndicator(
                        onRefresh: () => fetchScheduleData(forceRefresh: true),
                        color: Colors.white,
                        child: buildSchedulePage(todayScheduleData, 'Сегодня'),
                      ),
                      RefreshIndicator(
                        onRefresh: () => fetchScheduleData(forceRefresh: true),
                        color: Colors.white,
                        child: buildSchedulePage(tomorrowScheduleData, 'Завтра'),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: PageIndicator(currentPageIndex: currentPageIndex),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildSchedulePage(List<Schedule> scheduleData, String pageTitle) {
    final targetDate =
        pageTitle == 'Сегодня' ? DateTime.now() : DateTime.now().add(const Duration(days: 1));

    final weekType = getWeekTypeForDate(targetDate);
    final filteredScheduleData = filterScheduleByWeekType(scheduleData, weekType);
    final filteredChanges = getFilteredScheduleChanges(pageTitle);
    final callsData = CallsUtil.getCalls(); // List<dynamic>

    final ScheduleChangesResult changesResult = filteredChanges.isEmpty
        ? ScheduleChangesResult(
            schedule: List<Schedule>.from(filteredScheduleData),
            hasBuildingOverride: false,
          )
        : applyScheduleChanges(filteredScheduleData, filteredChanges, callsData);

    final scheduleWithChanges = changesResult.schedule;
    final hasBuildingOverride = changesResult.hasBuildingOverride;

    final building = primaryBuilding(scheduleWithChanges);
    final dateLabel = formatDate(targetDate);

    const headerMaxHeight = 176.0;
    const headerMinHeight = 120.0;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeightPinnedHeaderDelegate(
            backgroundColor: backgroundColor,
            maxHeight: headerMaxHeight,
            minHeight: headerMinHeight,
            child: _CollapsibleOverviewHeader(
              maxHeight: headerMaxHeight,
              minHeight: headerMinHeight,
              pageTitle: pageTitle,
              dateLabel: dateLabel,
              weekType: weekType,
              gradient: getHeaderGradient(weekType),
              isOffline: isOffline,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pageTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Location(
                            label: building,
                            showOverrideIndicator: hasBuildingOverride,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: scheduleWithChanges.isEmpty ? 50.0 : 12.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (scheduleWithChanges.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.weekend_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '$pageTitle выходной',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Нет запланированных занятий',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...List.generate(scheduleWithChanges.length, (index) {
                          final item = scheduleWithChanges[index];

                          String lessonStartTime = item.startTime;
                          String lessonEndTime = item.endTime;

                          try {
                            final periodInt = int.tryParse(item.number);
                            if (periodInt != null &&
                                periodInt > 0 &&
                                periodInt <= callsData.length) {
                              final call = callsData[periodInt - 1];
                              lessonStartTime = call.startTime;
                              lessonEndTime = call.endTime;
                            }
                          } catch (_) {}

                          final widgets = <Widget>[
                            LessonCard(
                              number: item.number,
                              subject: item.subject,
                              teacher: item.teacher,
                              startTime: lessonStartTime,
                              endTime: lessonEndTime,
                              accentColor: lessonAccent,
                            ),
                          ];

                          if (index < scheduleWithChanges.length - 1) {
                            String nextLessonStartTime =
                                scheduleWithChanges[index + 1].startTime;

                            try {
                              final nextPeriodInt =
                                  int.tryParse(scheduleWithChanges[index + 1].number);
                              if (nextPeriodInt != null &&
                                  nextPeriodInt > 0 &&
                                  nextPeriodInt <= callsData.length) {
                                final nextCall = callsData[nextPeriodInt - 1];
                                nextLessonStartTime = nextCall.startTime;
                              }
                            } catch (_) {}

                            widgets.add(
                              BreakIndicator(
                                startTime: lessonEndTime,
                                endTime: nextLessonStartTime,
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(children: widgets),
                          );
                        }),
                      ],
                      if (filteredChanges.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        const Divider(color: Color(0xFF333333), thickness: 1),
                        const SizedBox(height: 20),
                        const Text(
                          'Изменения в расписании',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...filteredChanges.map((change) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ReplacementCard(
                              lessonNumber: change.lessonNumber,
                              replaceFrom: change.replaceFrom,
                              replaceTo: change.replaceTo,
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String getWeekTypeForDate(DateTime date) => DateFormatter.getWeekType(date);

  List<Schedule> filterScheduleByWeekType(List<Schedule> schedule, String? weekType) {
    if (weekType == null) return schedule;

    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in schedule) {
      (lessonsByPeriod[lesson.number] ??= <Schedule>[]).add(lesson);
    }

    final List<Schedule> filtered = [];
    lessonsByPeriod.forEach((_, lessons) {
      final numeratorLessons = lessons
          .where((l) => l.lessonType == 'numerator' && l.subject.trim().isNotEmpty)
          .toList();
      final denominatorLessons = lessons
          .where((l) => l.lessonType == 'denominator' && l.subject.trim().isNotEmpty)
          .toList();
      final regularLessons =
          lessons.where((l) => l.lessonType == null && l.subject.trim().isNotEmpty).toList();

      if (numeratorLessons.isNotEmpty || denominatorLessons.isNotEmpty) {
        if (weekType == 'Числитель' && numeratorLessons.isNotEmpty) {
          filtered.addAll(numeratorLessons);
        } else if (weekType == 'Знаменатель' && denominatorLessons.isNotEmpty) {
          filtered.addAll(denominatorLessons);
        } else {
          filtered.addAll(regularLessons);
        }
      } else {
        filtered.addAll(regularLessons);
      }
    });

    return filtered;
  }

  ScheduleChangesResult applyScheduleChanges(
    List<Schedule> schedule,
    List<Replacement> changes,
    List<dynamic> callsData,
  ) {
    if (changes.isEmpty) {
      return ScheduleChangesResult(
        schedule: List<Schedule>.from(schedule),
        hasBuildingOverride: false,
      );
    }

    final List<Schedule> result = List<Schedule>.from(schedule);
    bool hasBuildingOverride = false;

    for (final change in changes) {
      final lessonNumber = change.lessonNumber.trim();
      if (lessonNumber.isEmpty) continue;

      final normalizedReplaceTo = change.replaceTo.replaceAll('\u00A0', ' ').trim();
      final shouldHide = shouldHideLessonFromOverview(normalizedReplaceTo);

      final existingIndex = result.indexWhere((l) => l.number.trim() == lessonNumber);

      if (shouldHide) {
        if (existingIndex != -1) result.removeAt(existingIndex);
        continue;
      }

      final parsedDetails = parseLessonDetails(normalizedReplaceTo);
      final subject = parsedDetails.subject.isNotEmpty ? parsedDetails.subject : normalizedReplaceTo;
      final teacher = parsedDetails.teacher;

      final updatedBuilding = resolveBuildingFromChange(
        normalizedReplaceTo,
        existingIndex != -1 ? result[existingIndex].building : '',
      );

      if (updatedBuilding.isNotEmpty &&
          existingIndex != -1 &&
          updatedBuilding != result[existingIndex].building) {
        hasBuildingOverride = true;
      }

      if (existingIndex != -1) {
        final existing = result[existingIndex];
        result[existingIndex] = Schedule(
          id: existing.id,
          number: existing.number,
          subject: subject,
          teacher: teacher.isNotEmpty ? teacher : existing.teacher,
          startTime: existing.startTime,
          endTime: existing.endTime,
          building: updatedBuilding.isNotEmpty ? updatedBuilding : existing.building,
          lessonType: existing.lessonType,
        );
      } else {
        final timing = lessonTimingForNumber(lessonNumber, callsData);
        result.add(
          Schedule(
            id: 'change_${lessonNumber}_${change.updatedAt}',
            number: lessonNumber,
            subject: subject,
            teacher: teacher,
            startTime: timing.start,
            endTime: timing.end,
            building: updatedBuilding.isNotEmpty ? updatedBuilding : 'Дистанционно',
            lessonType: null,
          ),
        );
      }
    }

    result.sort((a, b) {
      final aN = tryParseLessonNumber(a.number);
      final bN = tryParseLessonNumber(b.number);
      if (aN != null && bN != null) return aN.compareTo(bN);
      return a.number.compareTo(b.number);
    });

    return ScheduleChangesResult(schedule: result, hasBuildingOverride: hasBuildingOverride);
  }

  bool shouldHideLessonFromOverview(String replaceTo) {
    final normalized = replaceTo.toLowerCase();
    return normalized.startsWith('занятие отменено') ||
        normalized.startsWith('занятие перенесено на');
  }

  String resolveBuildingFromChange(String replaceTo, String fallbackBuilding) {
    final upper = replaceTo.toUpperCase();
    if (upper.contains('НЕЖИНСК')) return 'Нежинская';
    if (upper.contains('НАХИМОВ')) return 'Нахимовский';
    return fallbackBuilding;
  }

  LessonTiming lessonTimingForNumber(String lessonNumber, List<dynamic> callsData) {
    final sanitized = lessonNumber.trim();
    for (final call in callsData) {
      try {
        if (call.period == sanitized) {
          return LessonTiming(start: call.startTime, end: call.endTime);
        }
      } catch (_) {}
    }
    return const LessonTiming(start: '--:--', end: '--:--');
  }

  int? tryParseLessonNumber(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  String primaryBuilding(List<Schedule> schedule) {
    if (schedule.isEmpty) return '';

    final Map<String, int> counts = {};
    for (final lesson in schedule) {
      counts[lesson.building] = (counts[lesson.building] ?? 0) + 1;
    }

    String primary = schedule.first.building;
    int maxCount = 0;

    counts.forEach((b, c) {
      if (c > maxCount) {
        maxCount = c;
        primary = b;
      }
    });

    return primary;
  }

  String formatDate(DateTime date) => DateFormatter.formatDayWithMonth(date);

  List<Replacement> getFilteredScheduleChanges(String pageTitle) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    final todayDate =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
    final tomorrowDate =
        '${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

    final targetDate = pageTitle == 'Сегодня' ? todayDate : tomorrowDate;

    return scheduleChanges.where((c) => c.changeDate == targetDate).toList();
  }

  @override
  void dispose() {
    pageController.dispose();
    repository.dataUpdatedNotifier.removeListener(onDataUpdated);
    super.dispose();
  }
}

class LessonTiming {
  final String start;
  final String end;

  const LessonTiming({required this.start, required this.end});
}

class ScheduleChangesResult {
  final List<Schedule> schedule;
  final bool hasBuildingOverride;

  ScheduleChangesResult({required this.schedule, required this.hasBuildingOverride});
}

/// Делегат pinned-хедера: меняется только высота, без Transform.scale.
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

/// Всегда одна и та же компоновка (как в примере), просто всё меньше при сжатии:
/// LEFT: pageTitle + dateLabel
/// RIGHT: weekType pill, под ним wifi_off (если offline)
class _CollapsibleOverviewHeader extends StatelessWidget {
  const _CollapsibleOverviewHeader({
    required this.maxHeight,
    required this.minHeight,
    required this.pageTitle,
    required this.dateLabel,
    required this.weekType,
    required this.gradient,
    required this.isOffline,
  });

  final double maxHeight;
  final double minHeight;

  final String pageTitle;
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
        final iconOpacity = lerpDouble(1.0, 0.95, t)!;

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
                          pageTitle,
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
                    SizedBox(
                      height: iconSize, // место резервируем всегда, чтобы шапка не прыгала
                      child: isOffline
                          ? Opacity(
                              opacity: iconOpacity,
                              child: Icon(
                                Icons.wifi_off,
                                size: iconSize,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            )
                          : const SizedBox.shrink(),
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
