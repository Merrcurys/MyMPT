import 'package:flutter/material.dart';

/// Виджет заголовка экрана расписания
class ScheduleHeader extends StatelessWidget {
  /// Цвет границы заголовка
  final Color borderColor;

  /// Текст даты
  final String dateLabel;

  /// Тип недели (числитель/знаменатель)
  final String weekType;

  const ScheduleHeader({
    super.key,
    required this.borderColor,
    required this.dateLabel,
    required this.weekType,
  });

  /// Получает градиент заголовка в зависимости от типа недели
  ///
  /// Параметры:
  /// - [weekType]: Тип недели (Числитель/Знаменатель)
  ///
  /// Возвращает:
  /// Градиент для заголовка
  List<Color> _getHeaderGradient(String weekType) {
    if (weekType == 'Знаменатель') {
      return const [Color(0xFF111111), Color(0xFF4FC3F7)];
    } else if (weekType == 'Числитель') {
      return const [Color(0xFF111111), Color(0xFFFF8C00)];
    } else {
      return const [Color(0xFF111111), Color(0xFF333333)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: _getHeaderGradient(weekType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
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
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
