import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/core/utils/lesson_details_parser.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';
import 'package:my_mpt/data/repositories/schedule_changes_repository.dart';
import 'package:my_mpt/data/services/calls_service.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/schedule_change_card.dart';

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
  ///
  /// Параметры:
  /// - [weekType]: Тип недели (Числитель/Знаменатель)
  ///
  /// Возвращает:
  /// Градиент для заголовка
  List<Color> _getHeaderGradient(String weekType) {
    if (weekType == 'Знаменатель') {
      return const [Color(0xFF111111), Color(0xFF4FC3F7)];
    } else if (weekType == 'Числитель') {
      return const [Color(0xFF111111), Color(0xFFFF8C00)];
    } else {
      return const [Color(0xFF111111), Color(0xFF333333)];
    }
  }

  late UnifiedScheduleRepository _repository;
  late ScheduleChangesRepository _changesRepository;
  List<Schedule> _todayScheduleData = [];
  List<Schedule> _tomorrowScheduleData = [];
  List<ScheduleChangeEntity> _scheduleChanges = [];
  bool _isLoading = false;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = UnifiedScheduleRepository();
    _changesRepository = ScheduleChangesRepository();
    _repository.dataUpdatedNotifier.addListener(_onDataUpdated);

    _initializeSchedule();
  }

  Future<void> _initializeSchedule() async {
    await _fetchScheduleData(forceRefresh: false, showLoader: false);
    _fetchScheduleData(forceRefresh: true, showLoader: false);
  }

  /// Обработчик уведомлений об обновлении данных
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

    try {
      if (forceRefresh) {
        await _repository.forceRefresh();
      }

      final scheduleResults = await Future.wait([
        _repository.getTodaySchedule(),
        _repository.getTomorrowSchedule(),
      ]);

      if (!mounted) return;
      setState(() {
        _todayScheduleData = scheduleResults[0];
        _tomorrowScheduleData = scheduleResults[1];
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
      // Обновляем только для изменения расписания
      final scheduleChanges = await _changesRepository.getScheduleChanges();

      if (!mounted) return;
      setState(() {
        _scheduleChanges = scheduleChanges;
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Удаляем слушателя уведомлений
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
                  // Добавляем индикатор страниц внизу экрана
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: _PageIndicator(currentPageIndex: _currentPageIndex),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSchedulePage(List<Schedule> scheduleData, String pageTitle) {
    // Определяем дату для которой отображаем расписание
    final targetDate = pageTitle == 'Сегодня'
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));

    // Определяем тип недели для целевой даты
    final weekType = _getWeekTypeForDate(targetDate);

    // Фильтруем пары в зависимости от типа недели
    final filteredScheduleData = _filterScheduleByWeekType(
      scheduleData,
      weekType,
    );

    final filteredChanges = _getFilteredScheduleChanges(pageTitle);
    final callsData = CallsService.getCalls();
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
          child: _TodayHeader(
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
                          child: BuildingChip(
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
                          } catch (e) {}

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
                            } catch (e) {}

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
                        ...filteredChanges
                            .whereType<ScheduleChangeEntity>()
                            .map((change) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ScheduleChangeCard(
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

  /// Определяет тип недели для заданной даты
  String _getWeekTypeForDate(DateTime date) {
    return DateFormatter.getWeekType(date);
  }

  /// Фильтрует пары в зависимости от типа недели
  List<Schedule> _filterScheduleByWeekType(
    List<Schedule> schedule,
    String? weekType,
  ) {
    // Если информация о неделе недоступна, возвращаем все пары
    if (weekType == null) {
      return schedule;
    }

    // Группируем пары по номеру
    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in schedule) {
      final period = lesson.number;
      if (!lessonsByPeriod.containsKey(period)) {
        lessonsByPeriod[period] = [];
      }
      lessonsByPeriod[period]!.add(lesson);
    }

    // Фильтруем пары
    final List<Schedule> filteredSchedule = [];

    lessonsByPeriod.forEach((period, lessons) {
      // Проверяем, есть ли пары с типом (числитель/знаменатель)
      // Фильтруем пустые уроки - у которых subject пустой
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
        // Если есть пары с типом, выбираем только те, которые соответствуют текущей неделе
        if (weekType == 'Числитель' && numeratorLessons.isNotEmpty) {
          filteredSchedule.addAll(numeratorLessons);
        } else if (weekType == 'Знаменатель' && denominatorLessons.isNotEmpty) {
          filteredSchedule.addAll(denominatorLessons);
        }
        // Если для текущей недели нет пары, не добавляем ничего (остается пустой слот)
      } else {
        // Если нет пар с типом, добавляем все обычные пары
        filteredSchedule.addAll(regularLessons);
      }
    });

    return filteredSchedule;
  }

  _ScheduleChangesResult _applyScheduleChanges(
    List<Schedule> schedule,
    List<ScheduleChangeEntity?> changes,
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

    for (final change in changes.whereType<ScheduleChangeEntity>()) {
      final lessonNumber = change.lessonNumber.trim();
      if (lessonNumber.isEmpty) continue;

      final normalizedReplaceTo = change.replaceTo
          .replaceAll('\u00A0', ' ')
          .trim();
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
          building: updatedBuilding.isNotEmpty
              ? updatedBuilding
              : existing.building,
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
            building: updatedBuilding.isNotEmpty
                ? updatedBuilding
                : 'Дистанционно',
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

  /// Фильтрует изменения в расписании по дате для отображения только на соответствующей странице
  List<ScheduleChangeEntity?> _getFilteredScheduleChanges(String pageTitle) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(Duration(days: 1));

    // Форматируем даты в строку для сравнения с changeDate
    // Используем padLeft(2, '0') для дня, чтобы соответствовать формату в ScheduleChangesService
    final String todayDate =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
    final String tomorrowDate =
        '${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

    // Определяем, какие изменения показывать на текущей странице
    String targetDate = '';
    if (pageTitle == 'Сегодня') {
      targetDate = todayDate;
    } else if (pageTitle == 'Завтра') {
      targetDate = tomorrowDate;
    }

    // Фильтруем изменения по дате применения (changeDate)
    return _scheduleChanges
        .where((change) => change.changeDate == targetDate)
        .toList();
  }
}

class _TodayHeader extends StatelessWidget {
  final String dateLabel;
  final int lessonsCount;
  final List<Color> gradient;
  final String pageTitle;
  final String weekType;

  const _TodayHeader({
    required this.dateLabel,
    required this.lessonsCount,
    required this.gradient,
    required this.pageTitle,
    required this.weekType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                weekType,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
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

class _PageIndicator extends StatelessWidget {
  final int currentPageIndex;

  const _PageIndicator({required this.currentPageIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageDot(isActive: currentPageIndex == 0),
        const SizedBox(width: 8),
        _PageDot(isActive: currentPageIndex == 1),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool isActive;

  const _PageDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
