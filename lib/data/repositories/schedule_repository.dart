import 'package:flutter/foundation.dart';
import 'package:my_mpt/data/datasources/cache/schedule_cache_datasource.dart';
import 'package:my_mpt/data/datasources/remote/schedule_remote_datasource.dart';
import 'package:my_mpt/data/models/lesson.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleRepository {
  ScheduleRepository({
    ScheduleRemoteDatasource? remoteDatasource,
    ScheduleCacheDatasource? cacheDatasource,
  })  : _remoteDatasource = remoteDatasource ?? ScheduleRemoteDatasource(),
        _cacheDatasource = cacheDatasource ?? ScheduleCacheDatasource();

  final ScheduleRemoteDatasource _remoteDatasource;
  final ScheduleCacheDatasource _cacheDatasource;

  static const String _selectedGroupKey = 'selected_group';
  static const String _selectedRoleKey = 'selected_role';
  static const String _teacherNameKey = 'teacher';

  Map<String, List<Lesson>>? _cachedWeeklySchedule;
  List<Lesson>? _cachedTodaySchedule;
  List<Lesson>? _cachedTomorrowSchedule;

  DateTime? _lastUpdate;
  bool _cacheInitialized = false;

  final ValueNotifier<bool> dataUpdatedNotifier = ValueNotifier<bool>(false);

  static final ScheduleRepository _instance = ScheduleRepository._internal();
  factory ScheduleRepository() => _instance;
  ScheduleRepository._internal();

  DateTime? get lastUpdate => _lastUpdate;

  Future<Map<String, List<Lesson>>> getWeeklySchedule({
    bool forceRefresh = false,
  }) async {
    await _restoreCacheIfNeeded();

    if (forceRefresh || _shouldRefreshData() || _cachedWeeklySchedule == null) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedWeeklySchedule ?? {};
  }

  Future<List<Lesson>> getTodaySchedule({bool forceRefresh = false}) async {
    await _restoreCacheIfNeeded();
    if (forceRefresh || _shouldRefreshData() || _cachedTodaySchedule == null) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedTodaySchedule ?? [];
  }

  Future<List<Lesson>> getTomorrowSchedule({bool forceRefresh = false}) async {
    await _restoreCacheIfNeeded();
    if (forceRefresh ||
        _shouldRefreshData() ||
        _cachedTomorrowSchedule == null) {
      await _refreshAllData(forceRefresh: forceRefresh);
    }
    return _cachedTomorrowSchedule ?? [];
  }

  Future<bool> refreshAllDataWithStatus({bool forceRefresh = false}) async {
    return _refreshAllData(forceRefresh: forceRefresh);
  }

  Future<bool> _refreshAllData({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_selectedRoleKey) ?? 'student';
      
      String targetName = '';
      bool isTeacher = false;
      
      if (role == 'student') {
         targetName = await _getSelectedGroupCode();
      } else {
         targetName = prefs.getString(_teacherNameKey) ?? '';
         isTeacher = true;
      }

      if (targetName.isEmpty) {
        await _clearCache();
        return false;
      }

      final weeklySchedule = await _remoteDatasource.fetchWeeklySchedule(
        targetName,
        forceRefresh: forceRefresh,
        isTeacher: isTeacher
      );

      _cachedWeeklySchedule = weeklySchedule;
      final today = _getTodayInRussian();
      final tomorrow = _getTomorrowInRussian();

      _cachedTodaySchedule = weeklySchedule[today] ?? [];
      _cachedTomorrowSchedule = weeklySchedule[tomorrow] ?? [];
      _lastUpdate = DateTime.now();

      await _cacheDatasource.save(
        weeklySchedule: _cachedWeeklySchedule ?? {},
        todaySchedule: _cachedTodaySchedule ?? [],
        tomorrowSchedule: _cachedTomorrowSchedule ?? [],
        lastUpdate: _lastUpdate!,
      );

      return true;
    } catch (e) {
      debugPrint('Schedule update error (falling back to cache): $e');
      await _restoreCacheIfNeeded();
      return false;
    }
  }

  bool _shouldRefreshData() {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!).inHours >= 24;
  }

  Future<void> _clearCache() async {
    _cachedWeeklySchedule = null;
    _cachedTodaySchedule = null;
    _cachedTomorrowSchedule = null;
    _lastUpdate = null;
    _remoteDatasource.clearCache();
    _cacheInitialized = false;
    await _cacheDatasource.clear();
  }

  Future<String> _getSelectedGroupCode() async {
    try {
      const envGroup = String.fromEnvironment('SELECTED_GROUP');
      if (envGroup.isNotEmpty) return envGroup;

      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedGroupKey) ?? '';
    } catch (e) {
      debugPrint('Error getting group code: $e');
      return '';
    }
  }

  String _getTodayInRussian() {
    final now = DateTime.now();
    return _dayToRussian(now.weekday);
  }

  String _getTomorrowInRussian() {
    final now = DateTime.now().add(const Duration(days: 1));
    return _dayToRussian(now.weekday);
  }

  String _dayToRussian(int weekday) {
    const days = [
      'ПОНЕДЕЛЬНИК',
      'ВТОРНИК',
      'СРЕДА',
      'ЧЕТВЕРГ',
      'ПЯТНИЦА',
      'СУББОТА',
      'ВОСКРЕСЕНЬЕ',
    ];
    return days[weekday - 1];
  }

  Future<void> _restoreCacheIfNeeded() async {
    if (_cacheInitialized) return;
    _cacheInitialized = true;

    try {
      final cacheData = await _cacheDatasource.load();
      if (cacheData == null) return;

      _cachedWeeklySchedule = cacheData.weeklySchedule;
      _cachedTodaySchedule = cacheData.todaySchedule;
      _cachedTomorrowSchedule = cacheData.tomorrowSchedule;
      _lastUpdate = cacheData.lastUpdate;
    } catch (_) {
      _cachedWeeklySchedule = null;
      _cachedTodaySchedule = null;
      _cachedTomorrowSchedule = null;
      _lastUpdate = null;
    }
  }
}