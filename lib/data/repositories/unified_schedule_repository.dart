import 'package:flutter/foundation.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/data/services/schedule_parser_service.dart';
import 'package:my_mpt/data/datasources/schedule_cache_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Единое хранилище для всех данных расписания
class UnifiedScheduleRepository {
  final ScheduleParserService _parserService = ScheduleParserService();
  final ScheduleCacheDataSource _cacheDataSource = ScheduleCacheDataSource();
  static const String _selectedGroupKey = 'selected_group';

  // Кэшированные данные
  Map<String, List<Schedule>>? _cachedWeeklySchedule;
  List<Schedule>? _cachedTodaySchedule;
  List<Schedule>? _cachedTomorrowSchedule;
  DateTime? _lastUpdate;
  bool _cacheInitialized = false;

  // Уведомление об изменении данных
  final ValueNotifier<bool> dataUpdatedNotifier = ValueNotifier<bool>(false);

  static final UnifiedScheduleRepository _instance = UnifiedScheduleRepository._internal();
  factory UnifiedScheduleRepository() => _instance;
  UnifiedScheduleRepository._internal();

  /// Получить расписание на неделю
  Future<Map<String, List<Schedule>>> getWeeklySchedule({bool forceRefresh = false}) async {
    await _restoreCacheIfNeeded();
    final needRefresh = forceRefresh || _shouldRefreshData() || _cachedWeeklySchedule == null;
    if (needRefresh) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedWeeklySchedule ?? {};
  }

  /// Получить расписание на сегодня
  Future<List<Schedule>> getTodaySchedule({bool forceRefresh = false}) async {
    await _restoreCacheIfNeeded();
    final needRefresh = forceRefresh || _shouldRefreshData() || _cachedTodaySchedule == null;
    if (needRefresh) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedTodaySchedule ?? [];
  }

  /// Получить расписание на завтра
  Future<List<Schedule>> getTomorrowSchedule({bool forceRefresh = false}) async {
    await _restoreCacheIfNeeded();
    final needRefresh = forceRefresh || _shouldRefreshData() || _cachedTomorrowSchedule == null;
    if (needRefresh) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedTomorrowSchedule ?? [];
  }

  /// Обновить все данные
  Future<void> refreshAllData() async {
    await _refreshAllData(forceRefresh: true);
  }

  /// Принудительно обновить все данные и уведомить слушателей
  Future<void> forceRefresh() async {
    // Очищаем кэш перед обновлением
    await _clearCache();
    await _refreshAllData(forceRefresh: true);
    // Уведомляем слушателей об обновлении данных
    dataUpdatedNotifier.value = !dataUpdatedNotifier.value;
  }

  /// Проверить, нужно ли обновить данные (обновляем каждые 24 часа)
  bool _shouldRefreshData() {
    if (_lastUpdate == null) return true;
    final now = DateTime.now();
    return now.difference(_lastUpdate!).inHours >= 24;
  }

  /// Обновить все данные из источника
  Future<void> _refreshAllData({bool forceRefresh = false}) async {
    try {
      // Получаем выбранную группу
      final groupCode = await _getSelectedGroupCode();
      if (groupCode.isEmpty) {
        await _clearCache();
        return;
      }

      // Получаем расписание с парсера
      final parsedSchedule = await _parserService.parseScheduleForGroup(
        groupCode,
        forceRefresh: forceRefresh,
      );
      
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

      await _cacheDataSource.save(
        ScheduleCache(
          weeklySchedule: _cachedWeeklySchedule ?? {},
          todaySchedule: _cachedTodaySchedule ?? [],
          tomorrowSchedule: _cachedTomorrowSchedule ?? [],
          lastUpdate: _lastUpdate!,
        ),
      );
    } catch (e) {
      debugPrint('Ошибка при обновлении данных расписания: $e');
      // Очищаем кэш в случае ошибки
      await _clearCache();
    }
  }

  /// Очистить кэш
  Future<void> _clearCache() async {
    _cachedWeeklySchedule = null;
    _cachedTodaySchedule = null;
    _cachedTomorrowSchedule = null;
    _lastUpdate = null;
    _parserService.clearCache();
    _cacheInitialized = false;
    await _cacheDataSource.clear();
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

  Future<void> _restoreCacheIfNeeded() async {
    if (_cacheInitialized) return;
    _cacheInitialized = true;

    try {
      final cache = await _cacheDataSource.load();
      if (cache == null) return;

      _cachedWeeklySchedule = cache.weeklySchedule;
      _cachedTodaySchedule = cache.todaySchedule;
      _cachedTomorrowSchedule = cache.tomorrowSchedule;
      _lastUpdate = cache.lastUpdate;
    } catch (_) {
      _cachedWeeklySchedule = null;
      _cachedTodaySchedule = null;
      _cachedTomorrowSchedule = null;
      _lastUpdate = null;
    }
  }
}