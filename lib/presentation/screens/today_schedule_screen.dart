import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/usecases/get_today_schedule_usecase.dart';
import 'package:my_mpt/domain/usecases/get_tomorrow_schedule_usecase.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';
import 'package:my_mpt/data/services/calls_service.dart';
import 'package:my_mpt/data/repositories/week_repository.dart';
import 'package:my_mpt/data/models/week_info.dart';

/// Экран "Сегодня" с обновлённым тёмным стилем
class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const Color _lessonAccent = Color(0xFFFF8C00);
  static const List<Color> _headerGradient = [
    Color(0xFF333333),
    Color(0xFF111111),
  ];

  late ScheduleRepositoryInterface _repository;
  late GetTodayScheduleUseCase _getTodayScheduleUseCase;
  late GetTomorrowScheduleUseCase _getTomorrowScheduleUseCase;
  late WeekRepository _weekRepository;
  List<Schedule> _todayScheduleData = [];
  List<Schedule> _tomorrowScheduleData = [];
  WeekInfo? _weekInfo;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _weekRepository = WeekRepository();
    _getTodayScheduleUseCase = GetTodayScheduleUseCase(_repository);
    _getTomorrowScheduleUseCase = GetTomorrowScheduleUseCase(_repository);
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Загружаем информацию о неделе...');
      final weekInfo = await _weekRepository.getWeekInfo();
      print('DEBUG: Тип недели: ${weekInfo.weekType}');

      print('DEBUG: Загружаем расписание на сегодня...');
      final todaySchedule = await _getTodayScheduleUseCase();
      print('DEBUG: Загружено ${todaySchedule.length} уроков на сегодня');

      print('DEBUG: Загружаем расписание на завтра...');
      final tomorrowSchedule = await _getTomorrowScheduleUseCase();
      print('DEBUG: Загружено ${tomorrowSchedule.length} уроков на завтра');

      setState(() {
        _weekInfo = weekInfo;
        _todayScheduleData = todaySchedule;
        _tomorrowScheduleData = tomorrowSchedule;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Ошибка загрузки расписания: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
              )
            : PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: [
                  RefreshIndicator(
                    onRefresh: _loadScheduleData,
                    child: _buildSchedulePage(_todayScheduleData, 'Сегодня'),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadScheduleData,
                    child: _buildSchedulePage(_tomorrowScheduleData, 'Завтра'),
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
    final filteredScheduleData = _filterScheduleByWeekType(scheduleData, weekType);
    
    print(
      'DEBUG: Отображаем страницу "$pageTitle" с ${filteredScheduleData.length} уроками (изначально ${scheduleData.length})',
    );
    final building = _primaryBuilding(filteredScheduleData);
    final dateLabel = _formatDate(targetDate);

    // Если нет уроков, показываем сообщение о выходном дне
    if (filteredScheduleData.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TodayHeader(
              dateLabel: dateLabel,
              lessonsCount: filteredScheduleData.length,
              gradient: _headerGradient,
              pageTitle: pageTitle,
              weekType: weekType ?? _weekInfo?.weekType ?? 'Неизвестно',
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.weekend_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Сегодня выходной',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нет запланированных занятий',
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final callsData = CallsService.getCalls();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TodayHeader(
            dateLabel: dateLabel,
            lessonsCount: filteredScheduleData.length,
            gradient: _headerGradient,
            pageTitle: pageTitle,
            weekType: weekType ?? _weekInfo?.weekType ?? 'Неизвестно',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      if (building.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: BuildingChip(label: building),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(filteredScheduleData.length, (index) {
                      final item = filteredScheduleData[index];
                      print(
                        'DEBUG: Отображаем урок: ${item.number}. ${item.subject}',
                      );

                      String lessonStartTime = item.startTime;
                      String lessonEndTime = item.endTime;

                      try {
                        final periodInt = int.tryParse(item.number);
                        if (periodInt != null &&
                            periodInt > 0 &&
                            periodInt <= callsData.length) {
                          final call =
                              callsData[periodInt -
                                  1];
                          lessonStartTime = call.startTime;
                          lessonEndTime = call.endTime;
                        }
                      } catch (e) {
                        // Потом
                      }

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

                      if (index < filteredScheduleData.length - 1) {
                        String nextLessonStartTime =
                            filteredScheduleData[index + 1].startTime;

                        try {
                          final nextPeriodInt = int.tryParse(
                            filteredScheduleData[index + 1].number,
                          );
                          if (nextPeriodInt != null &&
                              nextPeriodInt > 0 &&
                              nextPeriodInt <= callsData.length) {
                            final nextCall =
                                callsData[nextPeriodInt -
                                    1];
                            nextLessonStartTime = nextCall.startTime;
                          }
                        } catch (e) {
                          // Потом
                        }

                        widgets.add(
                          BreakIndicator(
                            startTime:
                                lessonEndTime,
                            endTime:
                                nextLessonStartTime,
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredScheduleData.length - 1 ? 0 : 14,
                        ),
                        child: Column(children: widgets),
                      );
                    }),
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
  String? _getWeekTypeForDate(DateTime date) {
    // Если информация о неделе недоступна, возвращаем null
    if (_weekInfo == null) {
      return null;
    }

    // Получаем текущую дату из информации о неделе
    // Для простоты предполагаем, что _weekInfo.date содержит текущую дату
    // В реальной реализации может потребоваться более сложная логика
    
    // Если дата - понедельник и это завтра, то это может быть новая неделя
    if (date.weekday == DateTime.monday && 
        date.difference(DateTime.now()).inDays == 1) {
      // Если сегодня воскресенье, то завтра будет новая неделя
      if (DateTime.now().weekday == DateTime.sunday) {
        // Меняем тип недели
        if (_weekInfo!.weekType == 'Числитель') {
          return 'Знаменатель';
        } else if (_weekInfo!.weekType == 'Знаменатель') {
          return 'Числитель';
        }
      }
    }
    
    // В остальных случаях возвращаем текущий тип недели
    return _weekInfo!.weekType;
  }

  /// Фильтрует пары в зависимости от типа недели
  List<Schedule> _filterScheduleByWeekType(List<Schedule> schedule, String? weekType) {
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
      // Фильтруем пустые уроки - у которых subject или teacher пустые
      final numeratorLessons = lessons
          .where((lesson) => lesson.lessonType == 'numerator' && 
                 lesson.subject.trim().isNotEmpty && 
                 lesson.teacher.trim().isNotEmpty)
          .toList();
      final denominatorLessons = lessons
          .where((lesson) => lesson.lessonType == 'denominator' && 
                 lesson.subject.trim().isNotEmpty && 
                 lesson.teacher.trim().isNotEmpty)
          .toList();
      final regularLessons = lessons
          .where((lesson) => lesson.lessonType == null && 
                 lesson.subject.trim().isNotEmpty && 
                 lesson.teacher.trim().isNotEmpty)
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
            color: Colors.black.withOpacity(0.45),
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
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
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
