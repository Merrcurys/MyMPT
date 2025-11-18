import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:my_mpt/domain/usecases/get_schedule_changes_usecase.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';
import 'package:my_mpt/data/repositories/schedule_changes_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/numerator_denominator_card.dart';
import 'package:my_mpt/presentation/widgets/schedule_change_card.dart';
import 'package:my_mpt/data/services/calls_service.dart';
import 'package:my_mpt/data/repositories/week_repository.dart';
import 'package:my_mpt/data/models/week_info.dart';

/// Экран "Расписание" — тёмный минималистичный лонг-лист
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const _borderColor = Color(0xFF333333);

  late UnifiedScheduleRepository _repository;
  late ScheduleChangesRepository _changesRepository;
  late GetWeeklyScheduleUseCase _getWeeklyScheduleUseCase;
  late GetScheduleChangesUseCase _getScheduleChangesUseCase;
  late WeekRepository _weekRepository;
  Map<String, List<Schedule>> _weeklySchedule = {};
  List<ScheduleChangeEntity> _scheduleChanges = [];
  WeekInfo? _weekInfo;
  bool _isLoading = true;

  static const Color _lessonAccent = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _repository = UnifiedScheduleRepository();
    _changesRepository = ScheduleChangesRepository();
    _weekRepository = WeekRepository();
    _getWeeklyScheduleUseCase = GetWeeklyScheduleUseCase(_repository);
    _getScheduleChangesUseCase = GetScheduleChangesUseCase(_changesRepository);
    
    // Слушаем уведомления об обновлении данных
    _repository.dataUpdatedNotifier.addListener(_onDataUpdated);
    
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load week information
      final weekInfo = await _weekRepository.getWeekInfo();
      
      final scheduleData = await _getWeeklyScheduleUseCase(forceRefresh: true);
      
      // Load schedule changes
      final scheduleChanges = await _getScheduleChangesUseCase();
      
      setState(() {
        _weekInfo = weekInfo;
        _weeklySchedule = scheduleData;
        _scheduleChanges = scheduleChanges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
    }
  }

  /// Обработчик уведомлений об обновлении данных
  void _onDataUpdated() {
    // Перезагружаем данные без forceRefresh, чтобы использовать кэш
    _loadScheduleDataWithoutForceRefresh();
  }

  /// Загрузка данных без принудительного обновления
  Future<void> _loadScheduleDataWithoutForceRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load week information
      final weekInfo = await _weekRepository.getWeekInfo();
      
      final scheduleData = await _getWeeklyScheduleUseCase();
      
      // Load schedule changes
      final scheduleChanges = await _getScheduleChangesUseCase();
      
      setState(() {
        _weekInfo = weekInfo;
        _weeklySchedule = scheduleData;
        _scheduleChanges = scheduleChanges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _weeklySchedule.entries.toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
              )
            : RefreshIndicator(
                onRefresh: _loadScheduleData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        borderColor: _borderColor,
                        dateLabel: _formatDate(DateTime.now()),
                        weekType: _weekInfo?.weekType ?? 'Неизвестно',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final day = days[index];
                          final building = _primaryBuilding(day.value);
                          return _DaySection(
                            title: day.key,
                            building: building,
                            lessons: day.value,
                            accentColor: _lessonAccent,
                            weekType: _weekInfo?.weekType,
                          );
                        }, childCount: days.length),
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

  @override
  void dispose() {
    // Удаляем слушателя уведомлений
    _repository.dataUpdatedNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDayWithMonth(date);
  }
}

class _Header extends StatelessWidget {
  final Color borderColor;
  final String dateLabel;
  final String weekType;

  static const List<Color> _gradient = [Color(0xFF333333), Color(0xFF111111)];

  const _Header({required this.borderColor, required this.dateLabel, required this.weekType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor.withOpacity(0.4)),
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
            const Text(
              'Моё расписание',
              style: TextStyle(
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

class _DaySection extends StatelessWidget {
  final String title;
  final String building;
  final List<Schedule> lessons;
  final Color accentColor;
  final String? weekType;

  const _DaySection({
    required this.title,
    required this.building,
    required this.lessons,
    required this.accentColor,
    this.weekType,
  });

  /// Преобразует день недели из ЗАГЛАВНЫХ букв в формат с заглавной буквы
  String _formatDayTitle(String day) {
    if (day.isEmpty) return day;

    // Словарь для преобразования дней недели
    const dayMap = {
      'ПОНЕДЕЛЬНИК': 'Понедельник',
      'ВТОРНИК': 'Вторник',
      'СРЕДА': 'Среда',
      'ЧЕТВЕРГ': 'Четверг',
      'ПЯТНИЦА': 'Пятница',
      'СУББОТА': 'Суббота',
      'ВОСКРЕСЕНЬЕ': 'Воскресенье',
    };

    return dayMap[day] ?? day;
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
      // Фильтруем пустые уроки - у которых subject пустой
      final numeratorLessons = lessons
          .where((lesson) => lesson.lessonType == 'numerator' && 
                 lesson.subject.trim().isNotEmpty)
          .toList();
      final denominatorLessons = lessons
          .where((lesson) => lesson.lessonType == 'denominator' && 
                 lesson.subject.trim().isNotEmpty)
          .toList();
      final regularLessons = lessons
          .where((lesson) => lesson.lessonType == null && 
                 lesson.subject.trim().isNotEmpty)
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

  /// Создает виджеты для отображения уроков с поддержкой числителя/знаменателя
  List<Widget> _buildLessonWidgets(List<Schedule> lessons, List<dynamic> callsData) {
    // Фильтруем уроки в зависимости от типа недели
    final filteredLessons = _filterScheduleByWeekType(lessons, weekType);
    
    final widgets = <Widget>[];
    
    // Группируем уроки по номеру пары
    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in filteredLessons) {
      final period = lesson.number;
      if (!lessonsByPeriod.containsKey(period)) {
        lessonsByPeriod[period] = [];
      }
      lessonsByPeriod[period]!.add(lesson);
    }
    
    // Сортируем номера пар
    final sortedPeriods = lessonsByPeriod.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    
    // Создаем виджеты для каждой пары
    for (int i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i];
      final periodLessons = lessonsByPeriod[period]!;
      
      // Определяем время пары
      String startTime = '';
      String endTime = '';
      
      try {
        final periodInt = int.tryParse(period);
        if (periodInt != null && periodInt > 0 && periodInt <= callsData.length) {
          final call = callsData[periodInt - 1];
          startTime = call.startTime;
          endTime = call.endTime;
        }
      } catch (e) {
        // Игнорируем ошибки
      }
      
      // Проверяем, есть ли уроки с типом (числитель/знаменатель)
      bool hasTypedLessons = periodLessons.any((lesson) => lesson.lessonType != null);
      
      if (hasTypedLessons) {
        // Обрабатываем пары с числителем/знаменателем
        Schedule? numeratorLesson;
        Schedule? denominatorLesson;
        
        for (final lesson in periodLessons) {
          if (lesson.lessonType == 'numerator') {
            numeratorLesson = lesson;
          } else if (lesson.lessonType == 'denominator') {
            denominatorLesson = lesson;
          }
        }
        
        widgets.add(
          NumeratorDenominatorCard(
            numeratorLesson: numeratorLesson,
            denominatorLesson: denominatorLesson,
            lessonNumber: period,
            startTime: startTime,
            endTime: endTime,
          ),
        );
      } else {
        // Обычные пары отображаем как раньше
        for (int j = 0; j < periodLessons.length; j++) {
          final lesson = periodLessons[j];
          widgets.add(
            LessonCard(
              number: lesson.number,
              subject: lesson.subject,
              teacher: lesson.teacher,
              startTime: startTime,
              endTime: endTime,
              accentColor: accentColor,
            ),
          );
          
          // Для обычных пар добавляем разделитель между уроками в одной паре
          if (j < periodLessons.length - 1) {
            widgets.add(const SizedBox(height: 8));
          }
        }
      }
      
      // Добавляем разделитель между парами, кроме последней
      if (i < sortedPeriods.length - 1) {
        String nextLessonStartTime = '';
        
        try {
          final nextPeriodInt = int.tryParse(sortedPeriods[i + 1]);
          if (nextPeriodInt != null && nextPeriodInt > 0 && nextPeriodInt <= callsData.length) {
            final nextCall = callsData[nextPeriodInt - 1];
            nextLessonStartTime = nextCall.startTime;
          }
        } catch (e) {
          // Игнорируем ошибки
        }
        
        widgets.add(
          BreakIndicator(
            startTime: endTime,
            endTime: nextLessonStartTime,
          ),
        );
      }
      
      // Добавляем отступ между парами
      if (i < sortedPeriods.length - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = _formatDayTitle(title);

    final callsData = CallsService.getCalls();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formattedTitle,
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
                  child: BuildingChip(label: building),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: _buildLessonWidgets(lessons, callsData),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.05), height: 32),
        ],
      ),
    );
  }
}
