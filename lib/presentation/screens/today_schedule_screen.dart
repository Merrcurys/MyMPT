import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/usecases/get_today_schedule_usecase.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';

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
  List<Schedule> _scheduleData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ScheduleRepository();
    _getTodayScheduleUseCase = GetTodayScheduleUseCase(_repository);
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schedule = await _getTodayScheduleUseCase();
      setState(() {
        _scheduleData = schedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки расписания')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final building = _primaryBuilding(_scheduleData);
    final dateLabel = _formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
            : RefreshIndicator(
                onRefresh: _loadTodaySchedule,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TodayHeader(
                        dateLabel: dateLabel,
                        lessonsCount: _scheduleData.length,
                        gradient: _headerGradient,
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
                                  const Expanded(
                                    child: Text(
                                      'Сегодня',
                                      style: TextStyle(
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
                            Column(
                              children: List.generate(_scheduleData.length, (index) {
                                final item = _scheduleData[index];
                                final widgets = <Widget>[
                                  LessonCard(
                                    number: item.number,
                                    subject: item.subject,
                                    teacher: item.teacher,
                                    startTime: item.startTime,
                                    endTime: item.endTime,
                                    accentColor: _lessonAccent,
                                  ),
                                ];

                                // Add break indicator after each lesson except the last one
                                if (index < _scheduleData.length - 1) {
                                  final nextItem = _scheduleData[index + 1];
                                  widgets.add(
                                    BreakIndicator(
                                      duration: '20 минут', // This could be calculated based on actual times
                                      startTime: item.endTime,
                                      endTime: nextItem.startTime,
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == _scheduleData.length - 1 ? 0 : 14,
                                  ),
                                  child: Column(
                                    children: widgets,
                                  ),
                                );
                              }),
                            ),
                          ],
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

  const _TodayHeader({
    required this.dateLabel,
    required this.lessonsCount,
    required this.gradient,
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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              'Сегодня',
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
      );
  }
}