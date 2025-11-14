import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';

/// Экран "Расписание" — тёмный минималистичный лонг-лист
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const _backgroundColor = Color(0xFF05070C);
  static const _borderColor = Color(0xFF1C2233);

  static final Map<String, List<Schedule>> _weeklySchedule = {
    'Понедельник': [
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
    ],
    'Вторник': [
      Schedule(
        id: '4',
        number: '1',
        subject: 'Английский язык',
        teacher: 'Козлова К.К.',
        startTime: '08:30',
        endTime: '09:15',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '5',
        number: '2',
        subject: 'Физическая культура',
        teacher: 'Васильев В.В.',
        startTime: '09:25',
        endTime: '10:10',
        building: 'Нежинская',
      ),
    ],
    'Среда': [
      Schedule(
        id: '6',
        number: '1',
        subject: 'Математика',
        teacher: 'Иванова И.И.',
        startTime: '08:30',
        endTime: '09:15',
        building: 'Нежинская',
      ),
      Schedule(
        id: '7',
        number: '2',
        subject: 'Программирование',
        teacher: 'Сидоров С.С.',
        startTime: '09:25',
        endTime: '10:10',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '8',
        number: '3',
        subject: 'Физика',
        teacher: 'Петров П.П.',
        startTime: '10:30',
        endTime: '11:15',
        building: 'Нежинская',
      ),
    ],
    'Четверг': [
      Schedule(
        id: '9',
        number: '1',
        subject: 'Математика',
        teacher: 'Иванова И.И.',
        startTime: '08:30',
        endTime: '09:15',
        building: 'Нежинская',
      ),
      Schedule(
        id: '10',
        number: '2',
        subject: 'Физика',
        teacher: 'Петров П.П.',
        startTime: '09:25',
        endTime: '10:10',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '11',
        number: '3',
        subject: 'Программирование',
        teacher: 'Сидоров С.С.',
        startTime: '10:30',
        endTime: '11:15',
        building: 'Нежинская',
      ),
      Schedule(
        id: '12',
        number: '4',
        subject: 'Английский язык',
        teacher: 'Козлова К.К.',
        startTime: '11:25',
        endTime: '12:10',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '13',
        number: '5',
        subject: 'Физическая культура',
        teacher: 'Васильев В.В.',
        startTime: '12:30',
        endTime: '13:15',
        building: 'Нежинская',
      ),
    ],
    'Пятница': [
      Schedule(
        id: '14',
        number: '1',
        subject: 'Физика',
        teacher: 'Петров П.П.',
        startTime: '08:30',
        endTime: '09:15',
        building: 'Нахимовский',
      ),
      Schedule(
        id: '15',
        number: '2',
        subject: 'Математика',
        teacher: 'Иванова И.И.',
        startTime: '09:25',
        endTime: '10:10',
        building: 'Нежинская',
      ),
    ],
  };

  static const _accentPalette = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFE11D48),
  ];

  @override
  Widget build(BuildContext context) {
    final days = _weeklySchedule.entries.toList();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
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
                    accentResolver: (lessonIndex) =>
                        _accentPalette[(lessonIndex) % _accentPalette.length],
                  );
                }, childCount: days.length),
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

class _Header extends StatelessWidget {
  final Color borderColor;
  final String dateLabel;

  const _Header({required this.borderColor, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF212B52), Color(0xFF1A1F32)],
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
  final Color Function(int index) accentResolver;

  const _DaySection({
    required this.title,
    required this.building,
    required this.lessons,
    required this.accentResolver,
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
                Flexible(child: BuildingChip(label: building)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(lessons.length, (index) {
              final lesson = lessons[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == lessons.length - 1 ? 0 : 14,
                ),
                child: LessonCard(
                  number: lesson.number,
                  subject: lesson.subject,
                  teacher: lesson.teacher,
                  startTime: lesson.startTime,
                  endTime: lesson.endTime,
                  accentColor: accentResolver(index),
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
