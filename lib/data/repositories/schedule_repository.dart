import 'package:flutter/foundation.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'schedule_parser_repository.dart';

/// Реализация репозитория для работы с расписанием
///
/// Этот класс реализует интерфейс репозитория расписания и делегирует
/// выполнение операций репозиторию парсера расписания
class ScheduleRepository implements ScheduleRepositoryInterface {
  /// Репозиторий парсера расписания
  final ScheduleParserRepository _parserRepository = ScheduleParserRepository();

  /// Получить расписание на неделю
  ///
  /// Метод делегирует выполнение получения расписания на неделю
  /// репозиторию парсера расписания
  ///
  /// Возвращает:
  /// - Future<Map<String, List<Schedule>>>: Расписание на неделю, где ключ - день недели
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
  ///
  /// Метод делегирует выполнение получения расписания на сегодня
  /// репозиторию парсера расписания
  ///
  /// Возвращает:
  /// - Future<List<Schedule>>: Список элементов расписания на сегодня
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
  ///
  /// Метод делегирует выполнение получения расписания на завтра
  /// репозиторию парсера расписания
  ///
  /// Возвращает:
  /// - Future<List<Schedule>>: Список элементов расписания на завтра
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
