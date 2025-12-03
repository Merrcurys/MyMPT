import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/parsers/speciality_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для парсинга специальностей с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации о специальностях
/// с официального сайта техникума mpt.ru/raspisanie/
class SpecialityRemoteDatasource {
  /// Базовый URL сайта с расписанием
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Время жизни кэша (48 часов)
  static const Duration _cacheTtl = Duration(hours: 48);

  /// Парсер специальностей
  final SpecialityParser _specialityParser = SpecialityParser();

  /// Ключи для кэширования
  static const String _cacheKeyTabs = 'mpt_parser_tabs';
  static const String _cacheKeyTabsTimestamp = 'mpt_parser_tabs_timestamp';

  /// Парсит список вкладок специальностей с главной страницы расписания
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все вкладки специальностей,
  /// которые представлены в виде ссылок в навигационном меню
  ///
  /// Возвращает:
  /// Список информации о вкладках специальностей
  Future<List<TabInfo>> parseTabList({bool forceRefresh = false}) async {
    try {
      // Проверяем кэш
      if (!forceRefresh) {
        final cachedTabs = await _getCachedTabs();
        if (cachedTabs != null) {
          return cachedTabs;
        }
      }

      // Отправляем HTTP-запрос к странице с расписанием
      final response = await http
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
        final document = parser.parse(response.body);

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
  Future<List<TabInfo>?> _getCachedTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheKeyTabsTimestamp);
      final cachedJson = prefs.getString(_cacheKeyTabs);

      if (timestamp != null && cachedJson != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);

        if (age < _cacheTtl) {
          // Кэш действителен, возвращаем данные
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded
              .map(
                (json) => TabInfo(
                  href: json['href'] as String,
                  ariaControls: json['ariaControls'] as String,
                  name: json['name'] as String,
                ),
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
  Future<void> _saveCachedTabs(List<TabInfo> tabs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(tabs.map((tab) => tab.toJson()).toList());
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
