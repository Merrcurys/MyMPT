import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'package:my_mpt/data/repositories/schedule_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';

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
      // Handle error appropriately
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
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
            children: List.generate(lessons.length, (index) {
              final lesson = lessons[index];
              final widgets = <Widget>[
                LessonCard(
                  number: lesson.number,
                  subject: lesson.subject,
                  teacher: lesson.teacher,
                  startTime: lesson.startTime,
                  endTime: lesson.endTime,
                  accentColor: accentColor,
                ),
              ];

              // Add break indicator after each lesson except the last one
              if (index < lessons.length - 1) {
                final nextLesson = lessons[index + 1];
                widgets.add(
                  BreakIndicator(
                    startTime: lesson.endTime,
                    endTime: nextLesson.startTime,
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == lessons.length - 1 ? 0 : 14,
                ),
                child: Column(
                  children: widgets,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.05), height: 32),
        ],
      ),
    );
  }
}
