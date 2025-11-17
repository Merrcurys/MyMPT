import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/numerator_denominator_card.dart';
import 'package:my_mpt/data/services/calls_service.dart';

/// Экран "Расписание" — тёмный минималистичный лонг-лист
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _backgroundColor = Color(0xFF000000);
  static const _borderColor = Color(0xFF333333);

  late ScheduleRepositoryInterface _repository;
  late GetWeeklyScheduleUseCase _getWeeklyScheduleUseCase;
  Map<String, List<Schedule>> _weeklySchedule = {};
  bool _isLoading = true;

  static const Color _lessonAccent = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _getWeeklyScheduleUseCase = GetWeeklyScheduleUseCase(_repository);
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scheduleData = await _getWeeklyScheduleUseCase();
      setState(() {
        _weeklySchedule = scheduleData;
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

  String _formatDate(DateTime date) {
    return DateFormatter.formatDayWithMonth(date);
  }
}

class _Header extends StatelessWidget {
  final Color borderColor;
  final String dateLabel;

  static const List<Color> _gradient = [Color(0xFF333333), Color(0xFF111111)];

  const _Header({required this.borderColor, required this.dateLabel});

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
              child: const Text(
                'Числитель',
                style: TextStyle(
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

  const _DaySection({
    required this.title,
    required this.building,
    required this.lessons,
    required this.accentColor,
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

  /// Создает виджеты для отображения уроков с поддержкой числителя/знаменателя
  List<Widget> _buildLessonWidgets(List<Schedule> lessons, List<dynamic> callsData) {
    final widgets = <Widget>[];
    
    // Группируем уроки по номеру пары
    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in lessons) {
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
