import 'package:flutter/foundation.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'schedule_parser_repository.dart';

/// Реализация репозитория для работы с расписанием
class ScheduleRepository implements ScheduleRepositoryInterface {
  final ScheduleParserRepository _parserRepository = ScheduleParserRepository();

  /// Получить расписание на неделю
  Future<Map<String, List<Schedule>>> getWeeklySchedule() async {
    try {
      // Всегда используем парсер для получения реального расписания
      final parsedSchedule = await _parserRepository.getWeeklySchedule();
      return parsedSchedule;
    } catch (e) {
      // В реальном приложении мы бы обработали ошибки соответствующим образом
      debugPrint('Ошибка при получении данных расписания: $e');
      // Вернуть пустые данные в качестве резервного варианта
      return {};
    }
  }

  /// Получить расписание на сегодня
  Future<List<Schedule>> getTodaySchedule() async {
    try {
      // Всегда используем парсер для получения реального расписания
      final parsedSchedule = await _parserRepository.getTodaySchedule();
      return parsedSchedule;
    } catch (e) {
      // В реальном приложении мы бы обработали ошибки соответствующим образом
      debugPrint('Ошибка при получении расписания на сегодня: $e');
      return [];
    }
  }

  /// Получить расписание на завтра
  Future<List<Schedule>> getTomorrowSchedule() async {
    try {
      // Всегда используем парсер для получения реального расписания
      final parsedSchedule = await _parserRepository.getTomorrowSchedule();
      return parsedSchedule;
    } catch (e) {
      // В реальном приложении мы бы обработали ошибки соответствующим образом
      debugPrint('Ошибка при получении расписания на завтра: $e');
      return [];
    }
  }
}
