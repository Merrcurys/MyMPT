import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:my_mpt/data/parsers/speciality_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Удаленный источник данных для получения списка специальностей
///
/// Этот класс отвечает за загрузку HTML-страницы с расписанием,
/// парсинг списка специальностей и реализует кэширование
class SpecialityRemoteDatasource {
  /// Конструктор источника данных
  ///
  /// Параметры:
  /// - [client]: HTTP-клиент для выполнения запросов (опционально)
  /// - [baseUrl]: Базовый URL для запросов (по умолчанию 'https://mpt.ru/raspisanie/')
  /// - [cacheTtl]: Время жизни кэша (по умолчанию 1 час)
  /// - [specialityParser]: Парсер для обработки HTML-данных (опционально)
  SpecialityRemoteDatasource({
    http.Client? client,
    this.baseUrl = 'https://mpt.ru/raspisanie/',
    this.cacheTtl = const Duration(hours: 1),
    SpecialityParser? specialityParser,
  }) : _client = client ?? http.Client(),
       _specialityParser = specialityParser ?? SpecialityParser();

  /// HTTP-клиент для выполнения запросов
  final http.Client _client;

  /// Парсер для обработки HTML-данных
  final SpecialityParser _specialityParser;

  /// Базовый URL для запросов
  final String baseUrl;

  /// Время жизни кэша
  final Duration cacheTtl;

  /// Ключи для кэширования
  static const String _cacheKeyTabs = 'speciality_tabs';
  static const String _cacheKeyTabsTimestamp = 'speciality_tabs_timestamp';

  /// Парсит список вкладок специальностей
  ///
  /// Метод проверяет наличие действительного кэша и при необходимости
  /// загружает свежую версию страницы с сервера, парсит её и возвращает
  /// структурированные данные
  ///
  /// Параметры:
  /// - [forceRefresh]: Принудительная загрузка без использования кэша
  ///
  /// Возвращает:
  /// Список информации о вкладках специальностей
  Future<List<Map<String, String>>> parseTabList({
    bool forceRefresh = false,
  }) async {
    try {
      // Проверяем кэш
      if (!forceRefresh) {
        final cachedTabs = await _getCachedTabs();
        if (cachedTabs != null) {
          return cachedTabs;
        }
      }

      // Отправляем HTTP-запрос к странице с расписанием
      final response = await _client
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Превышено время ожидания ответа от сервера');
            },
          );

      // Проверяем успешность запроса
      if (response.statusCode == 200) {
        // Парсим HTML документ с помощью библиотеки html
        final document = parse(response.body);

        // Парсим список вкладок с помощью парсера
        final tabs = _specialityParser.parse(document);

        // Сохраняем в кэш
        await _saveCachedTabs(tabs);

        return tabs;
      } else {
        throw Exception(
          'Не удалось загрузить страницу: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка при парсинге списка вкладок: $e');
    }
  }

  /// Получает кэшированные вкладки
  Future<List<Map<String, String>>?> _getCachedTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheKeyTabsTimestamp);
      final cachedJson = prefs.getString(_cacheKeyTabs);

      if (timestamp != null && cachedJson != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);

        if (age < cacheTtl) {
          // Кэш действителен, возвращаем данные
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded
              .map(
                (json) => {
                  'href': json['href'] as String,
                  'ariaControls': json['ariaControls'] as String,
                  'name': json['name'] as String,
                },
              )
              .toList();
        } else {
          // Кэш истек, очищаем устаревшие данные
          await prefs.remove(_cacheKeyTabs);
          await prefs.remove(_cacheKeyTabsTimestamp);
        }
      }
    } catch (e) {
      // Игнорируем ошибки кэша
    }
    return null;
  }

  /// Сохраняет вкладки в кэш
  Future<void> _saveCachedTabs(List<Map<String, String>> tabs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(tabs);
      await prefs.setString(_cacheKeyTabs, json);
      await prefs.setInt(
        _cacheKeyTabsTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Игнорируем ошибки кэша
    }
  }
}
