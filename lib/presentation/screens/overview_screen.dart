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
import 'package:my_mpt/presentation/widgets/overview/today_header.dart';
import 'package:my_mpt/presentation/widgets/shared/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/shared/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/shared/location.dart';

/// Экран "Сегодня" с обновлённым тёмным стилем
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const Color _lessonAccent = Colors.grey;

  /// Получает градиент заголовка в зависимости от типа недели
  List<Color> _getHeaderGradient(String weekType) {
    if (weekType == 'Знаменатель') {
      return const [Color(0xFF111111), Color(0xFF4FC3F7)];
    } else if (weekType == 'Числитель') {
      return const [Color(0xFF111111), Color(0xFFFF8C00)];
    } else {
      return const [Color(0xFF111111), Color(0xFF333333)];
    }
  }

  late ScheduleRepository _repository;
  late ReplacementRepository _changesRepository;

  List<Schedule> _todayScheduleData = [];
  List<Schedule> _tomorrowScheduleData = [];
  List<Replacement> _scheduleChanges = [];

  bool _isLoading = false;

  /// true = показываем бейдж "Офлайн" (когда пытались обновиться и не смогли, но кэш есть)
  bool _isOffline = false;

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _changesRepository = ReplacementRepository();
    _repository.dataUpdatedNotifier.addListener(_onDataUpdated);

    _initializeSchedule();
  }

  Future<void> _initializeSchedule() async {
    await _fetchScheduleData(forceRefresh: false, showLoader: false);
    _fetchScheduleData(forceRefresh: true, showLoader: false);
  }

  void _onDataUpdated() {
    _fetchScheduleData(forceRefresh: false, showLoader: false);
  }

  Future<void> _fetchScheduleData({
    required bool forceRefresh,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    bool? refreshOk;
    try {
      if (forceRefresh) {
        refreshOk = await _repository.forceRefreshWithStatus();
      }

      final scheduleResults = await Future.wait([
        _repository.getTodaySchedule(),
        _repository.getTomorrowSchedule(),
      ]);

      if (!mounted) return;
      setState(() {
        _todayScheduleData = scheduleResults[0];
        _tomorrowScheduleData = scheduleResults[1];

        // Если была реальная попытка обновления и она провалилась — показываем офлайн.
        // Если не было попытки — берём флаг из репозитория.
        _isOffline = refreshOk == null
            ? _repository.isOfflineBadgeVisible
            : !refreshOk;

        if (showLoader) {
          _isLoading = false;
        }
      });
    } catch (e) {
      if (showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки расписания')),
        );
      }
      return;
    }

    try {
      final scheduleChanges = await _changesRepository.getScheduleChanges();

      if (!mounted) return;
      setState(() {
        _scheduleChanges = scheduleChanges;
      });

      final notificationService = NotificationService();
      await notificationService.updateLastCheckedReplacements();
    } catch (_) {
      // Игнорируем ошибки при загрузке изменений
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _repository.dataUpdatedNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCachedData =
        _todayScheduleData.isNotEmpty || _tomorrowScheduleData.isNotEmpty;
    final isInitialLoading = _isLoading && !hasCachedData;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: isInitialLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    children: [
                      RefreshIndicator(
                        onRefresh: () => _fetchScheduleData(forceRefresh: true),
                        color: Colors.white,
                        child: _buildSchedulePage(
                          _todayScheduleData,
                          'Сегодня',
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: () => _fetchScheduleData(forceRefresh: true),
                        color: Colors.white,
                        child: _buildSchedulePage(
                          _tomorrowScheduleData,
                          'Завтра',
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: PageIndicator(currentPageIndex: _currentPageIndex),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _offlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 14,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Text(
            'Офлайн',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage(List<Schedule> scheduleData, String pageTitle) {
    final targetDate = pageTitle == 'Сегодня'
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));

    final weekType = _getWeekTypeForDate(targetDate);

    final filteredScheduleData = _filterScheduleByWeekType(
      scheduleData,
      weekType,
    );

    final filteredChanges = _getFilteredScheduleChanges(pageTitle);
    final callsData = CallsUtil.getCalls();

    final _ScheduleChangesResult changesResult = filteredChanges.isEmpty
        ? _ScheduleChangesResult(
            schedule: filteredScheduleData,
            hasBuildingOverride: false,
          )
        : _applyScheduleChanges(
            filteredScheduleData,
            filteredChanges,
            callsData,
          );

    final scheduleWithChanges = changesResult.schedule;
    final hasBuildingOverride = changesResult.hasBuildingOverride;

    final building = _primaryBuilding(scheduleWithChanges);
    final dateLabel = _formatDate(targetDate);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TodayHeader(
            dateLabel: dateLabel,
            lessonsCount: scheduleWithChanges.length,
            gradient: _getHeaderGradient(weekType),
            pageTitle: pageTitle,
            weekType: weekType,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
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
                            if (_isOffline) _offlineBadge(),
                          ],
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
                              accentColor: _lessonAccent,
                            ),
                          ];

                          if (index < scheduleWithChanges.length - 1) {
                            String nextLessonStartTime =
                                scheduleWithChanges[index + 1].startTime;

                            try {
                              final nextPeriodInt = int.tryParse(
                                scheduleWithChanges[index + 1].number,
                              );
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
                            padding: EdgeInsets.only(
                              bottom: index == scheduleWithChanges.length - 1
                                  ? 14
                                  : 14,
                            ),
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
                        ...filteredChanges.whereType<Replacement>().map((change) {
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

  String _getWeekTypeForDate(DateTime date) {
    return DateFormatter.getWeekType(date);
  }

  List<Schedule> _filterScheduleByWeekType(
    List<Schedule> schedule,
    String? weekType,
  ) {
    if (weekType == null) {
      return schedule;
    }

    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in schedule) {
      final period = lesson.number;
      if (!lessonsByPeriod.containsKey(period)) {
        lessonsByPeriod[period] = [];
      }
      lessonsByPeriod[period]!.add(lesson);
    }

    final List<Schedule> filteredSchedule = [];

    lessonsByPeriod.forEach((period, lessons) {
      final numeratorLessons = lessons
          .where(
            (lesson) =>
                lesson.lessonType == 'numerator' &&
                lesson.subject.trim().isNotEmpty,
          )
          .toList();
      final denominatorLessons = lessons
          .where(
            (lesson) =>
                lesson.lessonType == 'denominator' &&
                lesson.subject.trim().isNotEmpty,
          )
          .toList();
      final regularLessons = lessons
          .where(
            (lesson) =>
                lesson.lessonType == null && lesson.subject.trim().isNotEmpty,
          )
          .toList();

      if (numeratorLessons.isNotEmpty || denominatorLessons.isNotEmpty) {
        if (weekType == 'Числитель' && numeratorLessons.isNotEmpty) {
          filteredSchedule.addAll(numeratorLessons);
        } else if (weekType == 'Знаменатель' && denominatorLessons.isNotEmpty) {
          filteredSchedule.addAll(denominatorLessons);
        }
      } else {
        filteredSchedule.addAll(regularLessons);
      }
    });

    return filteredSchedule;
  }

  _ScheduleChangesResult _applyScheduleChanges(
    List<Schedule> schedule,
    List<Replacement?> changes,
    List callsData,
  ) {
    if (changes.isEmpty) {
      return _ScheduleChangesResult(
        schedule: List<Schedule>.from(schedule),
        hasBuildingOverride: false,
      );
    }

    final List<Schedule> result = List<Schedule>.from(schedule);
    bool hasBuildingOverride = false;

    for (final change in changes.whereType<Replacement>()) {
      final lessonNumber = change.lessonNumber.trim();
      if (lessonNumber.isEmpty) continue;

      final normalizedReplaceTo =
          change.replaceTo.replaceAll('\u00A0', ' ').trim();
      final shouldHide = _shouldHideLessonFromOverview(normalizedReplaceTo);
      final existingIndex = result.indexWhere(
        (lesson) => lesson.number.trim() == lessonNumber,
      );

      if (shouldHide) {
        if (existingIndex != -1) {
          result.removeAt(existingIndex);
        }
        continue;
      }

      final parsedDetails = parseLessonDetails(normalizedReplaceTo);
      final subject = parsedDetails.subject.isNotEmpty
          ? parsedDetails.subject
          : normalizedReplaceTo;
      final teacher = parsedDetails.teacher;

      final updatedBuilding = _resolveBuildingFromChange(
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
          building:
              updatedBuilding.isNotEmpty ? updatedBuilding : existing.building,
          lessonType: existing.lessonType,
        );
      } else {
        final timing = _lessonTimingForNumber(lessonNumber, callsData);
        result.add(
          Schedule(
            id: 'change_${lessonNumber}_${change.updatedAt}',
            number: lessonNumber,
            subject: subject,
            teacher: teacher,
            startTime: timing.start,
            endTime: timing.end,
            building:
                updatedBuilding.isNotEmpty ? updatedBuilding : 'Дистанционно',
            lessonType: null,
          ),
        );
        if (updatedBuilding.isNotEmpty) {
          hasBuildingOverride = true;
        }
      }
    }

    result.sort((a, b) {
      final aNumber = _tryParseLessonNumber(a.number);
      final bNumber = _tryParseLessonNumber(b.number);
      if (aNumber != null && bNumber != null) {
        return aNumber.compareTo(bNumber);
      }
      return a.number.compareTo(b.number);
    });

    return _ScheduleChangesResult(
      schedule: result,
      hasBuildingOverride: hasBuildingOverride,
    );
  }

  bool _shouldHideLessonFromOverview(String replaceTo) {
    final normalized = replaceTo.toLowerCase();
    return normalized.startsWith('занятие отменено') ||
        normalized.startsWith('занятие перенесено на');
  }

  String _resolveBuildingFromChange(String replaceTo, String fallbackBuilding) {
    final upper = replaceTo.toUpperCase();
    if (upper.contains('НЕЖИНСК')) return 'Нежинская';
    if (upper.contains('НАХИМОВ')) return 'Нахимовский';
    return fallbackBuilding;
  }

  _LessonTiming _lessonTimingForNumber(String lessonNumber, List callsData) {
    final sanitized = lessonNumber.trim();
    for (final call in callsData) {
      if (call.period == sanitized) {
        return _LessonTiming(start: call.startTime, end: call.endTime);
      }
    }
    return const _LessonTiming(start: '--:--', end: '--:--');
  }

  int? _tryParseLessonNumber(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  String _primaryBuilding(List<Schedule> schedule) {
    if (schedule.isEmpty) return '';

    final counts = <String, int>{};
    for (final lesson in schedule) {
      counts[lesson.building] = (counts[lesson.building] ?? 0) + 1;
    }

    String primary = schedule.first.building;
    var maxCount = 0;
    counts.forEach((building, count) {
      if (count > maxCount) {
        maxCount = count;
        primary = building;
      }
    });
    return primary;
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDayWithMonth(date);
  }

  List<Replacement?> _getFilteredScheduleChanges(String pageTitle) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(Duration(days: 1));

    final String todayDate =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
    final String tomorrowDate =
        '${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

    String targetDate = '';
    if (pageTitle == 'Сегодня') {
      targetDate = todayDate;
    } else if (pageTitle == 'Завтра') {
      targetDate = tomorrowDate;
    }

    return _scheduleChanges
        .where((change) => change.changeDate == targetDate)
        .toList();
  }
}

class _LessonTiming {
  final String start;
  final String end;

  const _LessonTiming({required this.start, required this.end});
}

class _ScheduleChangesResult {
  final List<Schedule> schedule;
  final bool hasBuildingOverride;

  _ScheduleChangesResult({
    required this.schedule,
    required this.hasBuildingOverride,
  });
}
