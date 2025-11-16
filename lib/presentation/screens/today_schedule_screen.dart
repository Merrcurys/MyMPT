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
  List<Schedule> _todayScheduleData = [];
  List<Schedule> _tomorrowScheduleData = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _getTodayScheduleUseCase = GetTodayScheduleUseCase(_repository);
    _getTomorrowScheduleUseCase = GetTomorrowScheduleUseCase(_repository);
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Загружаем расписание на сегодня...');
      final todaySchedule = await _getTodayScheduleUseCase();
      print('DEBUG: Загружено ${todaySchedule.length} уроков на сегодня');

      print('DEBUG: Загружаем расписание на завтра...');
      final tomorrowSchedule = await _getTomorrowScheduleUseCase();
      print('DEBUG: Загружено ${tomorrowSchedule.length} уроков на завтра');

      setState(() {
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
            : RefreshIndicator(
                onRefresh: _loadScheduleData,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    _buildSchedulePage(_todayScheduleData, 'Сегодня'),
                    _buildSchedulePage(_tomorrowScheduleData, 'Завтра'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSchedulePage(List<Schedule> scheduleData, String pageTitle) {
    print(
      'DEBUG: Отображаем страницу "$pageTitle" с ${scheduleData.length} уроками',
    );
    final building = _primaryBuilding(scheduleData);
    final dateLabel = _formatDate(
      pageTitle == 'Сегодня'
          ? DateTime.now()
          : DateTime.now().add(const Duration(days: 1)),
    );

    // Если нет уроков, показываем сообщение о выходном дне
    if (scheduleData.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TodayHeader(
              dateLabel: dateLabel,
              lessonsCount: scheduleData.length,
              gradient: _headerGradient,
              pageTitle: pageTitle,
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
            lessonsCount: scheduleData.length,
            gradient: _headerGradient,
            pageTitle: pageTitle,
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
                    children: List.generate(scheduleData.length, (index) {
                      final item = scheduleData[index];
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

                      if (index < scheduleData.length - 1) {
                        String nextLessonStartTime =
                            scheduleData[index + 1].startTime;

                        try {
                          final nextPeriodInt = int.tryParse(
                            scheduleData[index + 1].number,
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
                          bottom: index == scheduleData.length - 1 ? 0 : 14,
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

  const _TodayHeader({
    required this.dateLabel,
    required this.lessonsCount,
    required this.gradient,
    required this.pageTitle,
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
