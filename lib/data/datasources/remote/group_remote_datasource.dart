import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:my_mpt/data/models/group.dart';
import 'package:my_mpt/data/parsers/group_parser.dart';
import 'package:my_mpt/data/datasources/remote/speciality_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для парсинга групп с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации о группах
/// с официального сайта техникума mpt.ru/raspisanie/
class GroupRemoteDatasource {
  /// Базовый URL сайта с расписанием
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Время жизни кэша (48 часов)
  static const Duration _cacheTtl = Duration(hours: 48);

  /// Парсер групп
  final GroupParser _groupParser = GroupParser();

  /// Источник данных для специальностей
  final SpecialityRemoteDatasource _specialityRemoteDatasource =
      SpecialityRemoteDatasource();

  /// Ключи для кэширования
  static const String _cacheKeyGroups = 'mpt_parser_groups_';
  static const String _cacheKeyGroupsTimestamp = 'mpt_parser_groups_timestamp_';

  /// Парсит список групп с возможной фильтрацией по специальности
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы,
  /// при необходимости фильтруя их по коду специальности
  ///
  /// Параметры:
  /// - [specialtyFilter]: Опциональный фильтр по коду специальности
  /// - [forceRefresh]: Принудительное обновление без использования кэша
  ///
  /// Возвращает:
  /// Список информации о группах
  Future<List<Group>> parseGroups([
    String? specialtyFilter,
    bool forceRefresh = false,
  ]) async {
    // Если задан фильтр специальности, используем оптимизированный метод
    if (specialtyFilter != null) {
      return _parseGroupsBySpecialty(
        specialtyFilter,
        forceRefresh: forceRefresh,
      );
    }

    // Иначе используем метод для получения всех групп
    return _parseAllGroups(forceRefresh: forceRefresh);
  }

  /// Парсит все группы без фильтрации
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы
  /// во всех специальностях
  ///
  /// Возвращает:
  /// Список информации о всех группах
  Future<List<Group>> _parseAllGroups({bool forceRefresh = false}) async {
    try {
      // Проверяем кэш
      if (!forceRefresh) {
        final cachedGroups = await _getCachedGroups(null);
        if (cachedGroups != null) {
          return cachedGroups;
        }
      }

      // Отправляем HTTP-запрос к странице с расписанием
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Превышено время ожидания ответа от сервера (15 секунд)',
              );
            },
          );

      // Проверяем успешность запроса
      if (response.statusCode == 200) {
        // Парсим HTML документ с помощью библиотеки html
        final document = parser.parse(response.body);

        // Парсим группы с помощью парсера
        final groups = _groupParser.parseGroups(document);

        // Сохраняем в кэш
        await _saveCachedGroups(null, groups);

        return groups;
      } else {
        throw Exception(
          'Не удалось загрузить страницу: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка при парсинге групп: $e');
    }
  }

  /// Парсит группы для конкретной специальности
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы
  /// для указанной специальности
  ///
  /// Параметры:
  /// - [specialtyFilter]: Код специальности для фильтрации групп
  ///
  /// Возвращает:
  /// Список информации о группах для указанной специальности
  Future<List<Group>> _parseGroupsBySpecialty(
    String specialtyFilter, {
    bool forceRefresh = false,
  }) async {
    try {
      // Проверяем кэш
      if (!forceRefresh) {
        final cachedGroups = await _getCachedGroups(specialtyFilter);
        if (cachedGroups != null) {
          return cachedGroups;
        }
      }

      // Отправляем HTTP-запрос к странице с расписанием
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Превышено время ожидания ответа от сервера (15 секунд)',
              );
            },
          );

      // Проверяем успешность запроса
      if (response.statusCode == 200) {
        // Парсим HTML документ с помощью библиотеки html
        final document = parser.parse(response.body);

        // Получаем список табов для поиска соответствия между specialtyFilter и ID (используем кэш)
        final tabs = await _specialityRemoteDatasource.parseTabList(
          forceRefresh: forceRefresh,
        );

        // Ищем таб, который соответствует specialtyFilter (оптимизированный поиск)
        // Может быть передан как имя специальности, так и код (href)
        String? targetId;
        for (var tab in tabs) {
          // Проверяем точное совпадение по имени таба
          if (tab['name'] == specialtyFilter) {
            targetId = tab['ariaControls'];
            break;
          }
          // Проверяем совпадение по href (код специальности)
          if (tab['href'] == specialtyFilter ||
              tab['href'] == '#$specialtyFilter' ||
              tab['href']!
                      .replaceAll('#', '')
                      .replaceAll('-', '.')
                      .toUpperCase() ==
                  specialtyFilter) {
            targetId = tab['ariaControls'];
            break;
          }
        }

        // Если не нашли точное совпадение, пытаемся найти частичное совпадение
        if (targetId == null) {
          for (var tab in tabs) {
            // Проверяем частичное совпадение по имени таба
            if (tab['name']!.contains(specialtyFilter) ||
                specialtyFilter.contains(tab['name']!)) {
              targetId = tab['ariaControls'];
              break;
            }
            // Проверяем частичное совпадение по href
            final normalizedHref = tab['href']!
                .replaceAll('#', '')
                .replaceAll('-', '.')
                .toUpperCase();
            if (normalizedHref.contains(specialtyFilter) ||
                specialtyFilter.contains(normalizedHref)) {
              targetId = tab['ariaControls'];
              break;
            }
          }
        }

        // Если не нашли ID, возвращаем пустой список
        if (targetId == null || targetId.isEmpty) {
          return [];
        }

        // Ищем tabpanel с нужным ID (строгий селектор)
        final tabPanel = document.querySelector(
          '[role="tabpanel"][id="$targetId"]',
        );

        // Если не нашли tabpanel, возвращаем пустой список
        if (tabPanel == null) {
          return [];
        }

        // Парсим группы с помощью парсера, передавая фильтр специальности
        final groups = _groupParser.parseGroups(document, specialtyFilter);

        // Сохраняем в кэш
        await _saveCachedGroups(specialtyFilter, groups);

        return groups;
      } else {
        throw Exception(
          'Не удалось загрузить страницу: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Ошибка при парсинге групп для специальности "$specialtyFilter": $e',
      );
    }
  }

  /// Получает кэшированные группы
  Future<List<Group>?> _getCachedGroups(String? specialtyFilter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = specialtyFilter != null
          ? '$_cacheKeyGroups${specialtyFilter.hashCode}'
          : '${_cacheKeyGroups}all';
      final timestampKey = specialtyFilter != null
          ? '$_cacheKeyGroupsTimestamp${specialtyFilter.hashCode}'
          : '${_cacheKeyGroupsTimestamp}all';

      final timestamp = prefs.getInt(timestampKey);
      final cachedJson = prefs.getString(cacheKey);

      if (timestamp != null && cachedJson != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);

        if (age < _cacheTtl) {
          // Кэш действителен, возвращаем данные
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded
              .map(
                (json) => Group(
                  code: json['code'] as String,
                  specialtyCode: json['specialtyCode'] as String,
                  specialtyName: json['specialtyName'] as String,
                ),
              )
              .toList();
        } else {
          // Кэш истек, очищаем устаревшие данные
          await prefs.remove(cacheKey);
          await prefs.remove(timestampKey);
        }
      }
    } catch (e) {
      // Игнорируем ошибки кэша
    }
    return null;
  }

  /// Сохраняет группы в кэш
  Future<void> _saveCachedGroups(
    String? specialtyFilter,
    List<Group> groups,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = specialtyFilter != null
          ? '$_cacheKeyGroups${specialtyFilter.hashCode}'
          : '${_cacheKeyGroups}all';
      final timestampKey = specialtyFilter != null
          ? '$_cacheKeyGroupsTimestamp${specialtyFilter.hashCode}'
          : '${_cacheKeyGroupsTimestamp}all';

      final json = jsonEncode(groups.map((group) => group.toJson()).toList());
      await prefs.setString(cacheKey, json);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Игнорируем ошибки кэша
    }
  }
}
