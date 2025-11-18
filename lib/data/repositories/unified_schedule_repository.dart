import 'package:flutter/foundation.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/data/services/schedule_parser_service.dart';
import 'package:my_mpt/data/models/lesson.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Единое хранилище для всех данных расписания
class UnifiedScheduleRepository {
  final ScheduleParserService _parserService = ScheduleParserService();
  static const String _selectedGroupKey = 'selected_group';

  // Кэшированные данные
  Map<String, List<Schedule>>? _cachedWeeklySchedule;
  List<Schedule>? _cachedTodaySchedule;
  List<Schedule>? _cachedTomorrowSchedule;
  DateTime? _lastUpdate;

  // Уведомление об изменении данных
  final ValueNotifier<bool> dataUpdatedNotifier = ValueNotifier<bool>(false);

  static final UnifiedScheduleRepository _instance = UnifiedScheduleRepository._internal();
  factory UnifiedScheduleRepository() => _instance;
  UnifiedScheduleRepository._internal();

  /// Получить расписание на неделю
  Future<Map<String, List<Schedule>>> getWeeklySchedule({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновить данные
    if (_shouldRefreshData() || forceRefresh || _cachedWeeklySchedule == null) {
      await _refreshAllData();
    }
    
    return _cachedWeeklySchedule ?? {};
  }

  /// Получить расписание на сегодня
  Future<List<Schedule>> getTodaySchedule({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновить данные
    if (_shouldRefreshData() || forceRefresh || _cachedTodaySchedule == null) {
      await _refreshAllData();
    }
    
    return _cachedTodaySchedule ?? [];
  }

  /// Получить расписание на завтра
  Future<List<Schedule>> getTomorrowSchedule({bool forceRefresh = false}) async {
    // Проверяем, нужно ли обновить данные
    if (_shouldRefreshData() || forceRefresh || _cachedTomorrowSchedule == null) {
      await _refreshAllData();
    }
    
    return _cachedTomorrowSchedule ?? [];
  }

  /// Обновить все данные
  Future<void> refreshAllData() async {
    await _refreshAllData();
  }

  /// Принудительно обновить все данные и уведомить слушателей
  Future<void> forceRefresh() async {
    // Очищаем кэш перед обновлением
    _clearCache();
    await _refreshAllData();
    // Уведомляем слушателей об обновлении данных
    dataUpdatedNotifier.value = !dataUpdatedNotifier.value;
  }

  /// Проверить, нужно ли обновить данные (обновляем каждые 5 минут)
  bool _shouldRefreshData() {
    if (_lastUpdate == null) return true;
    final now = DateTime.now();
    return now.difference(_lastUpdate!).inMinutes > 5;
  }

  /// Обновить все данные из источника
  Future<void> _refreshAllData() async {
    try {
      // Получаем выбранную группу
      final groupCode = await _getSelectedGroupCode();
      if (groupCode.isEmpty) {
        _clearCache();
        return;
      }

      // Получаем расписание с парсера
      final parsedSchedule = await _parserService.parseScheduleForGroup(groupCode);
      
      // Преобразуем данные в Schedule
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

      // Обновляем кэш
      _cachedWeeklySchedule = weeklySchedule;
      
      // Получаем сегодняшний и завтрашний день
      final today = _getTodayInRussian();
      final tomorrow = _getTomorrowInRussian();
      
      // Устанавливаем сегодняшнее и завтрашнее расписание
      _cachedTodaySchedule = weeklySchedule[today] ?? [];
      _cachedTomorrowSchedule = weeklySchedule[tomorrow] ?? [];
      
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Ошибка при обновлении данных расписания: $e');
      // Очищаем кэш в случае ошибки
      _clearCache();
    }
  }

  /// Очистить кэш
  void _clearCache() {
    _cachedWeeklySchedule = null;
    _cachedTodaySchedule = null;
    _cachedTomorrowSchedule = null;
    _lastUpdate = null;
  }

  /// Получает код выбранной группы из настроек
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
      debugPrint('Ошибка получения выбранной группы из настроек: $e');
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
    final now = DateTime.now().add(const Duration(days: 1));
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