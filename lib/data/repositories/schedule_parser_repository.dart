import 'package:my_mpt/data/services/schedule_parser_service.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/repositories/schedule_repository_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleParserRepository implements ScheduleRepositoryInterface {
  final ScheduleParserService _parserService = ScheduleParserService();

  static const String _selectedGroupKey = 'selected_group';

  /// Получить расписание на неделю для конкретной группы
  @override
  Future<Map<String, List<Schedule>>> getWeeklySchedule() async {
    try {
      // Здесь нужно получить выбранную группу из настроек
      final groupCode = await _getSelectedGroupCode();

      if (groupCode.isEmpty) {
        return {};
      }

      final parsedSchedule = await _parserService.parseScheduleForGroup(
        groupCode,
      );

      // Преобразуем Lesson в Schedule
      final Map<String, List<Schedule>> weeklySchedule = {};

      parsedSchedule.forEach((day, lessons) {
        final List<Schedule> scheduleList = lessons.map((lesson) {
          return Schedule(
            id: '${day}_${lesson.number}',
            number: lesson.number,
            subject: lesson.subject,
            teacher: lesson.teacher,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            building: lesson.building,
            lessonType: lesson.lessonType,
          );
        }).toList();

        weeklySchedule[day] = scheduleList;
      });

      return weeklySchedule;
    } catch (e) {
      return {};
    }
  }

  /// Получить расписание на сегодня для конкретной группы
  @override
  Future<List<Schedule>> getTodaySchedule() async {
    try {
      // Здесь нужно получить выбранную группу из настроек
      final groupCode = await _getSelectedGroupCode();

      if (groupCode.isEmpty) {
        return [];
      }

      final parsedSchedule = await _parserService.parseScheduleForGroup(
        groupCode,
      );

      // Получаем текущий день недели
      final today = _getTodayInRussian();

      // Показываем все доступные дни для отладки
      // parsedSchedule.forEach((day, lessons) {
      //   print('DEBUG: День в расписании: "$day", уроков: ${lessons.length}');
      // });

      if (parsedSchedule.containsKey(today)) {
        final lessons = parsedSchedule[today]!;

        // Преобразуем Lesson в Schedule
        return lessons.map((lesson) {
          return Schedule(
            id: '${today}_${lesson.number}',
            number: lesson.number,
            subject: lesson.subject,
            teacher: lesson.teacher,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            building: lesson.building,
            lessonType: lesson.lessonType,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Получить расписание на завтра для конкретной группы
  @override
  Future<List<Schedule>> getTomorrowSchedule() async {
    try {
      // Здесь нужно получить выбранную группу из настроек
      final groupCode = await _getSelectedGroupCode();

      if (groupCode.isEmpty) {
        return [];
      }

      final parsedSchedule = await _parserService.parseScheduleForGroup(
        groupCode,
      );

      // Получаем завтрашний день недели
      final tomorrow = _getTomorrowInRussian();

      // Показываем все доступные дни для отладки
      // parsedSchedule.forEach((day, lessons) {
      //   print('DEBUG: День в расписании: "$day", уроков: ${lessons.length}');
      // });

      if (parsedSchedule.containsKey(tomorrow)) {
        final lessons = parsedSchedule[tomorrow]!;

        // Преобразуем Lesson в Schedule
        return lessons.map((lesson) {
          return Schedule(
            id: '${tomorrow}_${lesson.number}',
            number: lesson.number,
            subject: lesson.subject,
            teacher: lesson.teacher,
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            building: lesson.building,
            lessonType: lesson.lessonType,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Получает код выбранной группы из настроек или из переменной окружения
  Future<String> _getSelectedGroupCode() async {
    try {
      // Проверяем переменную окружения first
      const envGroup = String.fromEnvironment('SELECTED_GROUP');
      if (envGroup.isNotEmpty) {
        return envGroup;
      }

      // Если переменная окружения не задана, используем SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedGroupKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Получает название текущего дня недели на русском языке ЗАГЛАВНЫМИ буквами
  String _getTodayInRussian() {
    final now = DateTime.now();
    final weekdays = [
      'ПОНЕДЕЛЬНИК',
      'ВТОРНИК',
      'СРЕДА',
      'ЧЕТВЕРГ',
      'ПЯТНИЦА',
      'СУББОТА',
      'ВОСКРЕСЕНЬЕ',
    ];
    return weekdays[now.weekday - 1];
  }

  /// Получает название завтрашнего дня недели на русском языке ЗАГЛАВНЫМИ буквами
  String _getTomorrowInRussian() {
    final now = DateTime.now().add(Duration(days: 1));
    final weekdays = [
      'ПОНЕДЕЛЬНИК',
      'ВТОРНИК',
      'СРЕДА',
      'ЧЕТВЕРГ',
      'ПЯТНИЦА',
      'СУББОТА',
      'ВОСКРЕСЕНЬЕ',
    ];
    return weekdays[now.weekday - 1];
  }
}
