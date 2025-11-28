import 'package:flutter/material.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';
import 'package:my_mpt/domain/entities/schedule.dart';
import 'package:my_mpt/domain/entities/schedule_change.dart';
import 'package:my_mpt/domain/usecases/get_weekly_schedule_usecase.dart';
import 'package:my_mpt/domain/usecases/get_schedule_changes_usecase.dart';
import 'package:my_mpt/data/repositories/unified_schedule_repository.dart';
import 'package:my_mpt/data/repositories/schedule_changes_repository.dart';
import 'package:my_mpt/presentation/widgets/building_chip.dart';
import 'package:my_mpt/presentation/widgets/lesson_card.dart';
import 'package:my_mpt/presentation/widgets/break_indicator.dart';
import 'package:my_mpt/presentation/widgets/numerator_denominator_card.dart';
import 'package:my_mpt/data/services/calls_service.dart';
import 'package:my_mpt/data/repositories/week_repository.dart';
import 'package:my_mpt/data/models/week_info.dart';

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

  /// Цвет границ элементов
  static const _borderColor = Color(0xFF333333);

  /// Репозиторий для работы с расписанием
  late UnifiedScheduleRepository _repository;

  /// Репозиторий для работы с изменениями в расписании
  late ScheduleChangesRepository _changesRepository;

  /// Use case для получения недельного расписания
  late GetWeeklyScheduleUseCase _getWeeklyScheduleUseCase;

  /// Use case для получения изменений в расписании
  late GetScheduleChangesUseCase _getScheduleChangesUseCase;

  /// Репозиторий для работы с информацией о неделе
  late WeekRepository _weekRepository;

  /// Недельное расписание
  Map<String, List<Schedule>> _weeklySchedule = {};

  /// Изменения в расписании
  List<ScheduleChangeEntity> _scheduleChanges = [];

  /// Информация о текущей неделе
  WeekInfo? _weekInfo;

  /// Флаг загрузки данных
  bool _isLoading = false;

  /// Акцентный цвет для элементов расписания
  static const Color _lessonAccent = Colors.grey;

  @override
  void initState() {
    super.initState();
    _repository = UnifiedScheduleRepository();
    _changesRepository = ScheduleChangesRepository();
    _weekRepository = WeekRepository();
    _getWeeklyScheduleUseCase = GetWeeklyScheduleUseCase(_repository);
    _getScheduleChangesUseCase = GetScheduleChangesUseCase(_changesRepository);

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
      final weeklySchedule = await _getWeeklyScheduleUseCase(
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
      final results = await Future.wait([
        _weekRepository.getWeekInfo(),
        _getScheduleChangesUseCase(),
      ]);

      if (!mounted) return;
      setState(() {
        _weekInfo = results[0] as WeekInfo;
        _scheduleChanges = results[1] as List<ScheduleChangeEntity>;
      });
    } catch (_) {
      // Если не удалось получить доп. данные, просто оставляем старые
    }
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
                      child: _Header(
                        borderColor: _borderColor,
                        dateLabel: _formatDate(DateTime.now()),
                        weekType: _weekInfo?.weekType ?? 'Неизвестно',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final day = days[index];
                          final building = _primaryBuilding(day.value);
                          return _DaySection(
                            title: day.key,
                            building: building,
                            lessons: day.value,
                            accentColor: _lessonAccent,
                            weekType: _weekInfo?.weekType,
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

/// Виджет заголовка экрана расписания
class _Header extends StatelessWidget {
  /// Цвет границы заголовка
  final Color borderColor;

  /// Текст даты
  final String dateLabel;

  /// Тип недели (числитель/знаменатель)
  final String weekType;

  const _Header({
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
  /// - List<Color>: Градиент для заголовка
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
            color: Colors.black.withOpacity(0.45),
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
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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

/// Виджет секции дня недели
class _DaySection extends StatelessWidget {
  /// Название дня недели
  final String title;

  /// Корпус проведения занятий
  final String building;

  /// Список занятий в этот день
  final List<Schedule> lessons;

  /// Акцентный цвет
  final Color accentColor;

  /// Тип недели (числитель/знаменатель)
  final String? weekType;

  const _DaySection({
    required this.title,
    required this.building,
    required this.lessons,
    required this.accentColor,
    this.weekType,
  });

  /// Преобразует день недели из ЗАГЛАВНЫХ букв в формат с заглавной буквы
  ///
  /// Параметры:
  /// - [day]: День недели в ЗАГЛАВНЫХ буквах
  ///
  /// Возвращает:
  /// - String: День недели с заглавной буквы
  String _formatDayTitle(String day) {
    if (day.isEmpty) return day;

    // Словарь для преобразования дней недели
    const dayMap = {
      'ПОНЕДЕЛЬНИК': 'Понедельник',
      'ВТОРНИК': 'Вторник',
      'СРЕДА': 'Среда',
      'ЧЕТВЕРГ': 'Четверг',
      'ПЯТНИЦА': 'Пятница',
      'СУББОТА': 'Суббота',
      'ВОСКРЕСЕНЬЕ': 'Воскресенье',
    };

    return dayMap[day] ?? day;
  }

  /// Создает виджеты для отображения уроков с поддержкой числителя/знаменателя
  ///
  /// Параметры:
  /// - [lessons]: Список занятий
  /// - [callsData]: Данные о звонках
  ///
  /// Возвращает:
  /// - List<Widget>: Список виджетов занятий
  List<Widget> _buildLessonWidgets(
    List<Schedule> lessons,
    List<dynamic> callsData,
  ) {
    final widgets = <Widget>[];

    // Группируем уроки по номеру пары
    final Map<String, List<Schedule>> lessonsByPeriod = {};
    for (final lesson in lessons) {
      final period = lesson.number;
      if (!lessonsByPeriod.containsKey(period)) {
        lessonsByPeriod[period] = [];
      }
      lessonsByPeriod[period]!.add(lesson);
    }

    // Сортируем номера пар
    final sortedPeriods = lessonsByPeriod.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    // Создаем виджеты для каждой пары
    for (int i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i];
      final periodLessons = lessonsByPeriod[period]!;

      // Определяем время пары
      String startTime = '';
      String endTime = '';

      try {
        final periodInt = int.tryParse(period);
        if (periodInt != null &&
            periodInt > 0 &&
            periodInt <= callsData.length) {
          final call = callsData[periodInt - 1];
          startTime = call.startTime;
          endTime = call.endTime;
        }
      } catch (e) {
        // Игнорируем ошибки
      }

      // Проверяем, есть ли уроки с типом (числитель/знаменатель)
      bool hasTypedLessons = periodLessons.any(
        (lesson) => lesson.lessonType != null,
      );

      if (hasTypedLessons) {
        // Обрабатываем пары с числителем/знаменателем
        // В недельном расписании показываем обе пары, независимо от типа недели
        Schedule? numeratorLesson;
        Schedule? denominatorLesson;

        for (final lesson in periodLessons) {
          if (lesson.lessonType == 'numerator') {
            numeratorLesson = lesson;
          } else if (lesson.lessonType == 'denominator') {
            denominatorLesson = lesson;
          }
        }

        widgets.add(
          NumeratorDenominatorCard(
            numeratorLesson: numeratorLesson,
            denominatorLesson: denominatorLesson,
            lessonNumber: period,
            startTime: startTime,
            endTime: endTime,
          ),
        );
      } else {
        // Обычные пары отображаем как раньше
        for (int j = 0; j < periodLessons.length; j++) {
          final lesson = periodLessons[j];
          widgets.add(
            LessonCard(
              number: lesson.number,
              subject: lesson.subject,
              teacher: lesson.teacher,
              startTime: startTime,
              endTime: endTime,
              accentColor: accentColor,
            ),
          );

          // Для обычных пар добавляем разделитель между уроками в одной паре
          if (j < periodLessons.length - 1) {
            widgets.add(const SizedBox(height: 8));
          }
        }
      }

      // Добавляем разделитель между парами, кроме последней
      if (i < sortedPeriods.length - 1) {
        String nextLessonStartTime = '';

        try {
          final nextPeriodInt = int.tryParse(sortedPeriods[i + 1]);
          if (nextPeriodInt != null &&
              nextPeriodInt > 0 &&
              nextPeriodInt <= callsData.length) {
            final nextCall = callsData[nextPeriodInt - 1];
            nextLessonStartTime = nextCall.startTime;
          }
        } catch (e) {
          // Игнорируем ошибки
        }

        widgets.add(
          BreakIndicator(startTime: endTime, endTime: nextLessonStartTime),
        );
      }

      // Добавляем отступ между парами
      if (i < sortedPeriods.length - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTitle = _formatDayTitle(title);

    final callsData = CallsService.getCalls();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formattedTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BuildingChip(label: building),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(children: _buildLessonWidgets(lessons, callsData)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.05), height: 32),
        ],
      ),
    );
  }
}
