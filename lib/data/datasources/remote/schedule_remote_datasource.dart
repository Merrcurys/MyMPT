import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_mpt/data/models/lesson.dart';
import 'package:my_mpt/data/parsers/schedule_parser.dart';

/// Удаленный источник данных для получения расписания на неделю
///
/// Этот класс отвечает за загрузку HTML-страницы с расписанием с сервера,
/// парсинг данных и реализует кэширование для уменьшения количества сетевых запросов
class ScheduleRemoteDatasource {
  /// Конструктор источника данных
  ///
  /// Параметры:
  /// - [client]: HTTP-клиент для выполнения запросов (опционально)
  /// - [baseUrl]: Базовый URL для запросов (по умолчанию 'https://mpt.ru/raspisanie/')
  /// - [cacheTtl]: Время жизни кэша (по умолчанию 24 часа)
  /// - [scheduleParser]: Парсер для обработки HTML-данных (опционально)
  ScheduleRemoteDatasource({
    http.Client? client,
    this.baseUrl = 'https://mpt.ru/raspisanie/',
    this.cacheTtl = const Duration(hours: 24),
    ScheduleParser? scheduleParser,
  }) : _client = client ?? http.Client(),
       _scheduleParser = scheduleParser ?? ScheduleParser();

  /// HTTP-клиент для выполнения запросов
  final http.Client _client;

  /// Парсер для обработки HTML-данных
  final ScheduleParser _scheduleParser;

  /// Базовый URL для запросов
  final String baseUrl;

  /// Время жизни кэша
  final Duration cacheTtl;

  /// Кэшированное содержимое HTML-страницы
  String? _cachedHtml;

  /// Время последней загрузки страницы
  DateTime? _lastFetch;

  /// Загружает и парсит расписание для конкретной группы
  ///
  /// Метод проверяет наличие действительного кэша и при необходимости
  /// загружает свежую версию страницы с сервера, парсит её и возвращает структурированные данные
  ///
  /// Параметры:
  /// - [groupCode]: Код группы для которой нужно получить расписание
  /// - [forceRefresh]: Принудительная загрузка без использования кэша
  ///
  /// Возвращает:
  /// Расписание на неделю для группы
  Future<Map<String, List<Lesson>>> fetchWeeklySchedule(
    String groupCode, {
    bool forceRefresh = false,
  }) async {
    if (groupCode.isEmpty) return {};

    try {
      // Загружаем HTML-страницу с расписанием
      final html = await _fetchSchedulePage(forceRefresh: forceRefresh);

      // Парсим данные с помощью парсера
      return _scheduleParser.parse(html, groupCode);
    } catch (error) {
      throw Exception('Error fetching schedule for group $groupCode: $error');
    }
  }

  /// Загружает HTML-страницу с расписанием
  ///
  /// Метод проверяет наличие действительного кэша и при необходимости
  /// загружает свежую версию страницы с сервера
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительная загрузка без использования кэша
  ///
  /// Возвращает:
  /// HTML-страница с расписанием
  Future<String> _fetchSchedulePage({bool forceRefresh = false}) async {
    // Проверяем, действителен ли кэш
    final isCacheValid =
        _cachedHtml != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < cacheTtl;

    // Если не требуется принудительное обновление и кэш действителен, возвращаем кэш
    if (!forceRefresh && isCacheValid) {
      return _cachedHtml!;
    }

    // Загружаем свежую версию страницы с сервера
    final freshHtml = await _loadFromNetwork();
    _cachedHtml = freshHtml;
    _lastFetch = DateTime.now();
    return freshHtml;
  }

  /// Загружает HTML-страницу с сервера
  ///
  /// Метод выполняет HTTP-запрос к базовому URL и возвращает содержимое страницы
  ///
  /// Возвращает:
  /// HTML-страница с расписанием
  Future<String> _loadFromNetwork() async {
    // Выполняем HTTP-запрос с таймаутом 15 секунд
    final response = await _client
        .get(Uri.parse(baseUrl))
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw const HttpException(
            'Превышено время ожидания ответа от сервера (15 секунд)',
          ),
        );

    // Проверяем успешность запроса
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Не удалось загрузить страницу: ${response.statusCode}',
      );
    }

    return response.body;
  }

  /// Очищает кэш
  ///
  /// Метод удаляет кэшированное содержимое и время последней загрузки
  void clearCache() {
    _cachedHtml = null;
    _lastFetch = null;
  }
}
