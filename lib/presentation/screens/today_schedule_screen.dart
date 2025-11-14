import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';

/// Экран "Сегодня" с обновлённым тёмным стилем
class TodayScheduleScreen extends StatelessWidget {
  const TodayScheduleScreen({super.key});

  static const _backgroundColor = Color(0xFF05070C);
  static const _accentPalette = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFE11D48),
  ];

  static final List<Schedule> _scheduleData = [
    Schedule(
      id: '1',
      number: '1',
      subject: 'Математика',
      teacher: 'Иванова И.И.',
      startTime: '08:30',
      endTime: '09:15',
      building: 'Нежинская',
    ),
    Schedule(
      id: '2',
      number: '2',
      subject: 'Физика',
      teacher: 'Петров П.П.',
      startTime: '09:25',
      endTime: '10:10',
      building: 'Нахимовский',
    ),
    Schedule(
      id: '3',
      number: '3',
      subject: 'Программирование',
      teacher: 'Сидоров С.С.',
      startTime: '10:30',
      endTime: '11:15',
      building: 'Нежинская',
    ),
    Schedule(
      id: '4',
      number: '4',
      subject: 'Английский язык',
      teacher: 'Козлова К.К.',
      startTime: '11:25',
      endTime: '12:10',
      building: 'Нахимовский',
    ),
    Schedule(
      id: '5',
      number: '5',
      subject: 'Физическая культура',
      teacher: 'Васильев В.В.',
      startTime: '12:30',
      endTime: '13:15',
      building: 'Нежинская',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final building = _primaryBuilding(_scheduleData);
    final dateLabel = _formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TodayHeader(
                dateLabel: dateLabel,
                lessonsCount: _scheduleData.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          Flexible(child: BuildingChip(label: building)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_scheduleData.length, (index) {
                      final item = _scheduleData[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _scheduleData.length - 1 ? 0 : 16,
                        ),
                        child: LessonCard(
                          number: item.number,
                          subject: item.subject,
                          teacher: item.teacher,
                          startTime: item.startTime,
                          endTime: item.endTime,
                          accentColor:
                              _accentPalette[index % _accentPalette.length],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
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
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    final weekday = days[(date.weekday - 1) % days.length];
    final month = months[(date.month - 1) % months.length];
    return '$weekday, ${date.day} $month';
  }
}

class _TodayHeader extends StatelessWidget {
  final String dateLabel;
  final int lessonsCount;

  const _TodayHeader({required this.dateLabel, required this.lessonsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
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
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Сегодня',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _MetricChip(
                  icon: Icons.book_outlined,
                  label: '$lessonsCount занятий',
                ),
                const SizedBox(width: 12),
                const _MetricChip(
                  icon: Icons.schedule_outlined,
                  label: 'Числитель',
                ),
              ],
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
