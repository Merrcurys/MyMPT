import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/group.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для парсинга данных с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации о специальностях, группах и типе недели
/// с официального сайта техникума mpt.ru/raspisanie/
class MptRemoteDatasource {
  /// Базовый URL сайта с расписанием
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Время жизни кэша (48 часов)
  static const Duration _cacheTtl = Duration(hours: 48);

  /// Ключи для кэширования
  static const String _cacheKeyTabs = 'mpt_parser_tabs';
  static const String _cacheKeyTabsTimestamp = 'mpt_parser_tabs_timestamp';
  static const String _cacheKeyGroups = 'mpt_parser_groups_';
  static const String _cacheKeyGroupsTimestamp = 'mpt_parser_groups_timestamp_';

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

        // Ищем элемент навигационного меню со списком вкладок (более строгий селектор)
        final tablist = document.querySelector('ul[role="tablist"]');

        // Проверяем наличие элемента
        if (tablist == null) {
          throw Exception('Элемент навигационного меню не найден на странице');
        }

        // Ищем все элементы вкладок в навигационном меню (строгий селектор)
        final tabItems = tablist.querySelectorAll(
          'li[role="presentation"] > a[href^="#"]',
        );

        // Создаем список для хранения информации о вкладках
        final List<TabInfo> tabs = [];

        // Проходим по всем вкладкам и извлекаем информацию
        for (var anchor in tabItems) {
          // Извлекаем атрибуты ссылки
          final href = anchor.attributes['href'];
          final ariaControls = anchor.attributes['aria-controls'];
          final name = anchor.text.trim();

          // Добавляем информацию о вкладке в список, если есть необходимые атрибуты
          if (href != null &&
              href.startsWith('#') &&
              ariaControls != null &&
              name.isNotEmpty) {
            tabs.add(
              TabInfo(href: href, ariaControls: ariaControls, name: name),
            );
          }
        }

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

        // Создаем список для хранения информации о группах
        final List<Group> groups = [];

        // Ищем все tabpanel элементы (более строгий селектор)
        final tabPanels = document.querySelectorAll('[role="tabpanel"]');

        // Проходим по всем tabpanel и ищем группы
        for (var tabPanel in tabPanels) {
          // Ищем заголовки групп только внутри tabpanel (строгий селектор h2, h3)
          final groupHeaders = tabPanel.querySelectorAll('h2, h3');

          // Ищем заголовок h2 с информацией о специальности
          String specialtyFromContext = '';
          for (var h2 in tabPanel.querySelectorAll('h2')) {
            final h2Text = h2.text.trim();
            if (h2Text.startsWith('Расписание занятий для ')) {
              specialtyFromContext = h2Text.substring(23).trim();
              break;
            }
          }

          // Проходим по заголовкам и парсим информацию о группах
          for (var header in groupHeaders) {
            final text = header.text.trim();
            // Проверяем, начинается ли текст строго с "Группа "
            if (text.startsWith('Группа ')) {
              // Парсим информацию о группе из текста заголовка
              final groupInfo = _parseGroupFromHeader(
                text,
                document,
                specialtyFromContext.isNotEmpty ? specialtyFromContext : null,
              );
              groups.addAll(groupInfo);
            }
          }
        }

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
        final tabs = await parseTabList(forceRefresh: forceRefresh);

        // Ищем таб, который соответствует specialtyFilter (оптимизированный поиск)
        // Может быть передан как имя специальности, так и код (href)
        String? targetId;
        for (var tab in tabs) {
          // Проверяем точное совпадение по имени таба
          if (tab.name == specialtyFilter) {
            targetId = tab.ariaControls;
            break;
          }
          // Проверяем совпадение по href (код специальности)
          if (tab.href == specialtyFilter ||
              tab.href == '#$specialtyFilter' ||
              tab.href.replaceAll('#', '').replaceAll('-', '.').toUpperCase() ==
                  specialtyFilter) {
            targetId = tab.ariaControls;
            break;
          }
        }

        // Если не нашли точное совпадение, пытаемся найти частичное совпадение
        if (targetId == null) {
          for (var tab in tabs) {
            // Проверяем частичное совпадение по имени таба
            if (tab.name.contains(specialtyFilter) ||
                specialtyFilter.contains(tab.name)) {
              targetId = tab.ariaControls;
              break;
            }
            // Проверяем частичное совпадение по href
            final normalizedHref = tab.href
                .replaceAll('#', '')
                .replaceAll('-', '.')
                .toUpperCase();
            if (normalizedHref.contains(specialtyFilter) ||
                specialtyFilter.contains(normalizedHref)) {
              targetId = tab.ariaControls;
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

        // Создаем список для хранения информации о группах
        final List<Group> groups = [];

        // Ищем заголовок h2 с информацией о специальности (строгий селектор)
        String specialtyFromContext = '';
        final h2Header = tabPanel.querySelector('h2');
        if (h2Header != null) {
          final h2Text = h2Header.text.trim();
          if (h2Text.startsWith('Расписание занятий для ')) {
            specialtyFromContext = h2Text.substring(23).trim();
          }
        }

        // Ищем заголовки групп только внутри нужного tabpanel (строгий селектор h2, h3)
        final groupHeaders = tabPanel.querySelectorAll('h2, h3');

        // Проходим по заголовкам и парсим информацию о группах
        for (var header in groupHeaders) {
          final text = header.text.trim();
          // Проверяем, начинается ли текст строго с "Группа "
          if (text.startsWith('Группа ')) {
            // Парсим информацию о группе из текста заголовка
            final groupInfo = _parseGroupFromHeader(
              text,
              document,
              specialtyFromContext.isNotEmpty ? specialtyFromContext : null,
            );
            groups.addAll(groupInfo);
          }
        }

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

  /// Парсит информацию о группе из текста заголовка
  ///
  /// Метод извлекает информацию о группе из текста заголовка и определяет
  /// соответствующую специальность по префиксу кода группы
  ///
  /// Параметры:
  /// - [headerText]: Текст заголовка, содержащего информацию о группе
  /// - [document]: HTML-документ для извлечения дополнительной информации
  /// - [specialtyFromContext]: Опциональная информация о специальности из контекста
  ///
  /// Возвращает:
  /// Список информации о группах (обычно один элемент)
  List<Group> _parseGroupFromHeader(
    String headerText,
    Document document, [
    String? specialtyFromContext,
  ]) {
    // Создаем список для хранения информации о группах
    final List<Group> groups = [];

    try {
      // Извлекаем код группы из текста заголовка (например, "Группа Э-1-22, Э-11/1-23" -> "Э-1-22, Э-11/1-23")
      final groupCode = headerText.substring(7).trim();

      // Инициализируем переменные для хранения информации о специальности
      String specialtyCode = '';
      String specialtyName = '';

      // Если передана специальность из контекста, используем её
      if (specialtyFromContext != null && specialtyFromContext.isNotEmpty) {
        specialtyCode = specialtyFromContext;
        specialtyName = specialtyFromContext;
      } else {
        // Иначе определяем специальность по префиксу группы
        // Извлекаем префикс из первой части кода группы
        final groupCodeParts = groupCode.split(RegExp(r'[;,\/]'));
        String prefix = '';
        if (groupCodeParts.isNotEmpty) {
          final firstGroup = groupCodeParts[0].trim();
          // Извлекаем префикс из кода группы (например, ВД-2-23 -> ВД)
          final prefixMatch = RegExp(
            r'^([А-Яа-я0-9]+)-',
          ).firstMatch(firstGroup);
          if (prefixMatch != null) {
            prefix = prefixMatch.group(1) ?? '';
          }
        }

        // Маппинг префиксов групп к кодам специальностей
        final Map<String, String> prefixToSpecialtyCode = {
          'Э': '09.02.01 Э',
          'СА': '09.02.02 СА',
          'П': '09.02.07 П,Т',
          'Т': '09.02.07 П,Т',
          'ИС': '09.02.07 ИС, БД, ВД',
          'БД': '09.02.07 ИС, БД, ВД',
          'ВД': '09.02.07 ИС, БД, ВД',
          'БАС': '09.02.08 БАС',
          'БИ': '38.02.07 БИ',
          'Ю': '40.02.01 Ю',
          'ВТ': '09.02.07 ВТ',
        };

        // Маппинг префиксов групп к полным названиям специальностей
        final Map<String, String> prefixToSpecialtyName = {
          'Э': '09.02.01 Экономика и бухгалтерский учет',
          'СА': '09.02.02 Сети и системы связи',
          'П':
              '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'Т':
              '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'ИС':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БД':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'ВД':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БАС': '09.02.08 Безопасность автоматизированных систем',
          'БИ': '38.02.07 Банковское дело',
          'Ю': '40.02.01 Право и организация социального обеспечения',
          'ВТ': '09.02.07 Веб-технологии',
        };

        // Определяем код и название специальности по префиксу
        if (prefixToSpecialtyCode.containsKey(prefix)) {
          specialtyCode = prefixToSpecialtyCode[prefix]!;
          specialtyName = prefixToSpecialtyName[prefix] ?? prefix;
        } else {
          // Если не удалось определить специальность по префиксу, используем префикс как код
          specialtyCode = prefix.isNotEmpty
              ? prefix
              : 'Неизвестная специальность';
          specialtyName = prefix.isNotEmpty
              ? prefix
              : 'Неизвестная специальность';
        }
      }

      // Добавляем информацию о группе в список
      groups.add(
        Group(
          code: groupCode, // Сохраняем полное название группы
          specialtyCode: specialtyCode,
          specialtyName: specialtyName,
        ),
      );
    } catch (e) {
      // В случае ошибки возвращаем пустой список
    }

    return groups;
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
    } catch (e) {}
  }
}
