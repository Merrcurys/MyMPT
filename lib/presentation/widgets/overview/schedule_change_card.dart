import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/lesson_details_parser.dart';
import 'package:my_mpt/data/services/calls_service.dart';

/// Виджет карточки изменения в расписании
///
/// Этот виджет отображает информацию об изменениях в расписании,
/// таких как замены предметов или дополнительные занятия
class ScheduleChangeCard extends StatelessWidget {
  /// Номер пары, к которой применяется изменение
  final String lessonNumber;

  /// Исходный предмет (до изменения)
  final String replaceFrom;

  /// Новый предмет (после изменения)
  final String replaceTo;

  const ScheduleChangeCard({
    super.key,
    required this.lessonNumber,
    required this.replaceFrom,
    required this.replaceTo,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedReplaceFrom = (replaceFrom == '\u00A0' ? '' : replaceFrom)
        .trim();
    final sanitizedReplaceTo = replaceTo.replaceAll('\u00A0', ' ').trim();
    final LessonDetails newLessonDetails = parseLessonDetails(
      sanitizedReplaceTo,
    );
    final LessonDetails previousLessonDetails = parseLessonDetails(
      sanitizedReplaceFrom,
    );
    final bool hasPreviousLesson = previousLessonDetails.hasData;

    final bool isAdditionalClass =
        sanitizedReplaceFrom.isEmpty ||
        sanitizedReplaceTo.toLowerCase().startsWith('дополнительное занятие');

    final _LessonTimes lessonTimes = _lessonTimesForNumber(lessonNumber);
    final Color accentColor = isAdditionalClass
        ? const Color(0xFFFF8C00).withValues(alpha: 0.5)
        : const Color(0xFFFF8C00);

    final String subjectText = newLessonDetails.subject.isNotEmpty
        ? newLessonDetails.subject
        : (isAdditionalClass
              ? 'Дополнительное занятие'
              : 'Замена в расписании');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NumberBadge(number: lessonNumber, accentColor: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isAdditionalClass
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (newLessonDetails.teacher.isNotEmpty)
                        Text(
                          newLessonDetails.teacher,
                          style: TextStyle(
                            fontSize: 12,
                            color: isAdditionalClass
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lessonTimes.start,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lessonTimes.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (hasPreviousLesson) ...[
              const SizedBox(height: 12),
              _PreviousLessonInfo(details: previousLessonDetails),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет бейджа с номером пары
class _NumberBadge extends StatelessWidget {
  /// Номер пары
  final String number;

  /// Акцентный цвет бейджа
  final Color accentColor;

  const _NumberBadge({required this.number, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Блок с зачеркнутой оригинальной парой
class _PreviousLessonInfo extends StatelessWidget {
  final LessonDetails details;

  const _PreviousLessonInfo({required this.details});

  bool get _isAdditionalLesson =>
      details.subject.trim().toLowerCase() == 'дополнительное занятие';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.subject.isNotEmpty)
          Text(
            details.subject,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
              decoration: _isAdditionalLesson
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
        if (details.teacher.isNotEmpty) ...[
          if (details.subject.isNotEmpty) const SizedBox(height: 2),
          Text(
            details.teacher,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
              decoration: _isAdditionalLesson
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

class _LessonTimes {
  final String start;
  final String end;

  const _LessonTimes({required this.start, required this.end});
}

_LessonTimes _lessonTimesForNumber(String lessonNumber) {
  final sanitizedNumber = lessonNumber.trim();
  String start = '--:--';
  String end = '--:--';

  for (final call in CallsService.getCalls()) {
    if (call.period == sanitizedNumber) {
      start = call.startTime;
      end = call.endTime;
      break;
    }
  }

  return _LessonTimes(start: start, end: end);
}
