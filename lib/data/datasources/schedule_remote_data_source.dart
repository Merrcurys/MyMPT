import 'dart:io';

import 'package:http/http.dart' as http;

/// Удаленный источник данных для получения HTML-страницы расписания
///
/// Этот класс отвечает за загрузку HTML-страницы с расписанием с сервера
/// и реализует кэширование для уменьшения количества сетевых запросов
class ScheduleRemoteDataSource {
  /// Конструктор источника данных
  ///
  /// Параметры:
  /// - [client]: HTTP-клиент для выполнения запросов (опционально)
  /// - [baseUrl]: Базовый URL для запросов (по умолчанию 'https://mpt.ru/raspisanie/')
  /// - [cacheTtl]: Время жизни кэша (по умолчанию 5 минут)
  ScheduleRemoteDataSource({
    http.Client? client,
    this.baseUrl = 'https://mpt.ru/raspisanie/',
    this.cacheTtl = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  /// HTTP-клиент для выполнения запросов
  final http.Client _client;

  /// Базовый URL для запросов
  final String baseUrl;

  /// Время жизни кэша
  final Duration cacheTtl;

  /// Кэшированное содержимое HTML-страницы
  String? _cachedHtml;

  /// Время последней загрузки страницы
  DateTime? _lastFetch;

  /// Загружает HTML-страницу с расписанием
  ///
  /// Метод проверяет наличие действительного кэша и при необходимости
  /// загружает свежую версию страницы с сервера
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительная загрузка без использования кэша
  ///
  /// Возвращает:
  /// - Future<String>: HTML-страница с расписанием
  Future<String> fetchSchedulePage({bool forceRefresh = false}) async {
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

  /// Очищает кэш
  ///
  /// Метод удаляет кэшированное содержимое и время последней загрузки
  void clearCache() {
    _cachedHtml = null;
    _lastFetch = null;
  }

  /// Загружает HTML-страницу с сервера
  ///
  /// Метод выполняет HTTP-запрос к базовому URL и возвращает содержимое страницы
  ///
  /// Возвращает:
  /// - Future<String>: HTML-страница с расписанием
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
}
