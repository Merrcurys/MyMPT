import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/calls_util.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/presentation/widgets/shared/location.dart';
import 'package:my_mpt/presentation/widgets/shared/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/shared/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/schedule/numerator_denominator_card.dart';

/// Виджет секции дня недели
class DaySection extends StatelessWidget {
  /// Название дня недели
  final String title;

  /// Корпус проведения занятий
  final String building;

  /// Список занятий в этот день
  final List<Schedule> lessons;

  /// Акцентный цвет
  final Color accentColor;

  /// Тип недели (числитель/знаменатель)
  final String? weekType;

  const DaySection({
    super.key,
    required this.title,
    required this.building,
    required this.lessons,
    required this.accentColor,
    this.weekType,
  });

  /// Преобразует день недели из ЗАГЛАВНЫХ букв в формат с заглавной буквы
  ///
  /// Параметры:
  /// - [day]: День недели в ЗАГЛАВНЫХ буквах
  ///
  /// Возвращает:
  /// - String: День недели с заглавной буквы
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
  ///
  /// Параметры:
  /// - [lessons]: Список занятий
  /// - [callsData]: Данные о звонках
  ///
  /// Возвращает:
  /// Список виджетов занятий
  List<Widget> _buildLessonWidgets(
    List<Schedule> lessons,
    List<dynamic> callsData,
  ) {
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
        if (periodInt != null &&
            periodInt > 0 &&
            periodInt <= callsData.length) {
          final call = callsData[periodInt - 1];
          startTime = call.startTime;
          endTime = call.endTime;
        }
      } catch (e) {
        // Игнорируем ошибки
      }

      // Проверяем, есть ли уроки с типом (числитель/знаменатель)
      bool hasTypedLessons = periodLessons.any(
        (lesson) => lesson.lessonType != null,
      );

      if (hasTypedLessons) {
        // Обрабатываем пары с числителем/знаменателем
        // В недельном расписании показываем обе пары, независимо от типа недели
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
          if (nextPeriodInt != null &&
              nextPeriodInt > 0 &&
              nextPeriodInt <= callsData.length) {
            final nextCall = callsData[nextPeriodInt - 1];
            nextLessonStartTime = nextCall.startTime;
          }
        } catch (e) {
          // Игнорируем ошибки
        }

        widgets.add(
          BreakIndicator(startTime: endTime, endTime: nextLessonStartTime),
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
    final callsData = CallsUtil.getCalls();

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
                  child: Location(label: building),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(children: _buildLessonWidgets(lessons, callsData)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 32),
        ],
      ),
    );
  }
}
