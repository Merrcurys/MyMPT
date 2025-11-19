import 'package:flutter/material.dart';

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

  /// Время добавления изменения
  final String updatedAt;

  /// Дата применения изменения
  final String changeDate;

  const ScheduleChangeCard({
    super.key,
    required this.lessonNumber,
    required this.replaceFrom,
    required this.replaceTo,
    required this.updatedAt,
    required this.changeDate,
  });

  @override
  Widget build(BuildContext context) {
    // Проверяем, является ли это дополнительным занятием (нет оригинального предмета)
    final isAdditionalClass =
        replaceFrom.isEmpty ||
        replaceFrom == '\u00A0'; // \u00A0 is &nbsp; in HTML

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
              children: [
                _NumberBadge(number: lessonNumber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAdditionalClass
                        ? 'Дополнительное занятие'
                        : 'Замена в расписании',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.withOpacity(0.8),
                    ),
                  ),
                ),
                Text(
                  // Показываем дату применения изменений
                  changeDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Показываем "Было:" только если это не дополнительное занятие
            if (!isAdditionalClass) ...[
              _ChangeRow(
                label: 'Было:',
                value: replaceFrom,
                isReplacement: false,
              ),
              const SizedBox(height: 8),
            ],
            _ChangeRow(
              label: isAdditionalClass ? '' : 'Стало:',
              value: replaceTo,
              isReplacement: true,
            ),
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

  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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

/// Виджет строки изменения
class _ChangeRow extends StatelessWidget {
  /// Метка строки (например, "Было:" или "Стало:")
  final String label;

  /// Значение строки
  final String value;

  /// Флаг, указывающий является ли это заменой
  final bool isReplacement;

  const _ChangeRow({
    required this.label,
    required this.value,
    required this.isReplacement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Показываем метку только если она не пустая
        if (label.isNotEmpty) ...[
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isReplacement ? FontWeight.w600 : FontWeight.normal,
              color: isReplacement ? Colors.orange : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
