import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';
import 'package:my_mpt/data/repositories/replacement_repository.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/entities/replacement.dart';
import 'package:my_mpt/presentation/widgets/schedule/schedule_header.dart';
import 'package:my_mpt/presentation/widgets/schedule/day_section.dart';

/// Экран "Расписание" — тёмный минималистичный лонг-лист
///
/// Этот экран отображает недельное расписание занятий с поддержкой
/// отображения изменений в расписании и различий между числителем и знаменателем
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

/// Состояние экрана расписания
class _ScheduleScreenState extends State<ScheduleScreen> {
  /// Цвет фона экрана
  static const _backgroundColor = Color(0xFF000000);

  /// Единое хранилище для работы с расписанием
  late UnifiedScheduleRepository _repository;

  /// Хранилище для работы с изменениями в расписании
  late ReplacementRepository _changesRepository;

  /// Недельное расписание
  Map<String, List<Schedule>> _weeklySchedule = {};

  /// Изменения в расписании
  List<Replacement> _scheduleChanges = [];

  /// Флаг загрузки данных
  bool _isLoading = false;

  /// Акцентный цвет для элементов расписания
  static const Color _lessonAccent = Colors.grey;

  @override
  void initState() {
    super.initState();
    _repository = UnifiedScheduleRepository();
    _changesRepository = ReplacementRepository();

    // Слушаем уведомления об обновлении данных
    _repository.dataUpdatedNotifier.addListener(_onDataUpdated);

    _initializeSchedule();
  }

  /// Инициализация расписания
  Future<void> _initializeSchedule() async {
    await _loadScheduleData(forceRefresh: false, showLoader: false);
    _loadScheduleData(forceRefresh: true, showLoader: false);
  }

  /// Обработчик уведомлений об обновлении данных
  void _onDataUpdated() {
    _loadScheduleData(forceRefresh: false, showLoader: false);
  }

  /// Загрузка данных расписания
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительное обновление данных
  /// - [showLoader]: Показывать индикатор загрузки
  Future<void> _loadScheduleData({
    required bool forceRefresh,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final weeklySchedule = await _repository.getWeeklySchedule(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _weeklySchedule = weeklySchedule;
        if (showLoader) {
          _isLoading = false;
        }
      });
    } catch (e) {
      if (showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки расписания')),
        );
      }
      return;
    }

    try {
      final scheduleChanges = await _changesRepository.getScheduleChanges();

      if (!mounted) return;
      setState(() {
        _scheduleChanges = scheduleChanges;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final days = _weeklySchedule.entries.toList();

    final isInitialLoading = _isLoading && _weeklySchedule.isEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: isInitialLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: () => _loadScheduleData(forceRefresh: true),
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScheduleHeader(
                        borderColor: const Color(0xFF333333),
                        dateLabel: _formatDate(DateTime.now()),
                        weekType: DateFormatter.getWeekType(DateTime.now()),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final day = days[index];
                          final building = _primaryBuilding(day.value);
                          return DaySection(
                            title: day.key,
                            building: building,
                            lessons: day.value,
                            accentColor: _lessonAccent,
                            weekType: DateFormatter.getWeekType(DateTime.now()),
                          );
                        }, childCount: days.length),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Определяет основной корпус по количеству занятий
  ///
  /// Параметры:
  /// - [schedule]: Список занятий для анализа
  ///
  /// Возвращает:
  /// - String: Название основного корпуса
  String _primaryBuilding(List<Schedule> schedule) {
    if (schedule.isEmpty) return '';
    final counts = <String, int>{};
    for (final lesson in schedule) {
      counts[lesson.building] = (counts[lesson.building] ?? 0) + 1;
    }

    String primary = schedule.first.building;
    var maxCount = 0;
    counts.forEach((building, count) {
      if (count > maxCount) {
        maxCount = count;
        primary = building;
      }
    });
    return primary;
  }

  @override
  void dispose() {
    // Удаляем слушателя уведомлений
    _repository.dataUpdatedNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  /// Форматирует дату для отображения
  ///
  /// Параметры:
  /// - [date]: Дата для форматирования
  ///
  /// Возвращает:
  /// - String: Отформатированная дата
  String _formatDate(DateTime date) {
    return DateFormatter.formatDayWithMonth(date);
  }
}
