import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/week_info.dart';
import 'package:my_mpt/data/models/group_info.dart';

/// Сервис для парсинга данных с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации о специальностях, группах и типе недели
/// с официального сайта техникума mpt.ru/raspisanie/
class MptParserService {
  /// Базовый URL сайта с расписанием
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Парсит список вкладок специальностей с главной страницы расписания
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все вкладки специальностей,
  /// которые представлены в виде ссылок в навигационном меню
  ///
  /// Возвращает:
  /// - List<TabInfo>: Список информации о вкладках специальностей
  Future<List<TabInfo>> parseTabList() async {
    try {
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

        // Ищем элемент навигационного меню со списком вкладок
        final tablist = document.querySelector('ul[role="tablist"]');

        // Проверяем наличие элемента
        if (tablist == null) {
          throw Exception('Элемент навигационного меню не найден на странице');
        }

        // Ищем все элементы вкладок в навигационном меню
        final tabItems = tablist.querySelectorAll('li[role="presentation"]');

        // Создаем список для хранения информации о вкладках
        final List<TabInfo> tabs = [];

        // Проходим по всем вкладкам и извлекаем информацию
        for (var item in tabItems) {
          // Ищем ссылку внутри элемента вкладки
          final anchor = item.querySelector('a');
          if (anchor != null) {
            // Извлекаем атрибуты ссылки
            final href = anchor.attributes['href'];
            final ariaControls = anchor.attributes['aria-controls'];
            final name = anchor.text?.trim() ?? '';

            // Добавляем информацию о вкладке в список, если есть необходимые атрибуты
            if (href != null && ariaControls != null) {
              tabs.add(
                TabInfo(href: href, ariaControls: ariaControls, name: name),
              );
            }
          }
        }

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

  /// Парсит информацию о текущей неделе
  ///
  /// Метод извлекает HTML-страницу с расписанием и определяет тип текущей недели
  /// (числитель или знаменатель), а также текущую дату и день недели
  ///
  /// Возвращает:
  /// - WeekInfo: Информация о текущей неделе
  Future<WeekInfo> parseWeekInfo() async {
    try {
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

        // Инициализируем переменные для хранения информации
        String date = '';
        String day = '';

        // Ищем заголовок с датой и днем недели
        final dateHeader = document.querySelector('h2');
        if (dateHeader != null) {
          // Извлекаем текст заголовка и разбиваем по разделителю
          final dateText = dateHeader.text.trim();
          final parts = dateText.split(' - ');
          if (parts.length >= 2) {
            date = parts[0]; // Дата
            day = parts[1]; // День недели
          } else {
            date = dateText;
          }
        }

        // Ищем информацию о типе недели
        String weekType = '';
        final weekHeaders = document.querySelectorAll('h3');

        // Проходим по всем заголовкам h3 и ищем информацию о неделе
        for (var header in weekHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Неделя:')) {
            // Извлекаем тип недели из текста
            weekType = text.substring(7).trim();
            // Проверяем наличие дополнительной информации в элементе .label
            final labelElement = header.querySelector('.label');
            if (labelElement != null) {
              weekType = labelElement.text.trim();
            }
            break;
          }
        }

        // Если тип недели не найден в заголовках h3, ищем в элементах .label
        if (weekType.isEmpty) {
          final labelElements = document.querySelectorAll('.label');
          for (var label in labelElements) {
            final labelText = label.text.trim();
            // Проверяем, является ли текст "Числитель" или "Знаменатель"
            if (labelText == 'Числитель' || labelText == 'Знаменатель') {
              weekType = labelText;
              break;
            }
          }
        }

        // Создаем и возвращаем объект с информацией о неделе
        return WeekInfo(weekType: weekType, date: date, day: day);
      } else {
        throw Exception(
          'Не удалось загрузить страницу: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка при парсинге информации о неделе: $e');
    }
  }

  /// Парсит список групп с возможной фильтрацией по специальности
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы,
  /// при необходимости фильтруя их по коду специальности
  ///
  /// Параметры:
  /// - [specialtyFilter]: Опциональный фильтр по коду специальности
  ///
  /// Возвращает:
  /// - List<GroupInfo>: Список информации о группах
  Future<List<GroupInfo>> parseGroups([String? specialtyFilter]) async {
    // Если задан фильтр специальности, используем оптимизированный метод
    if (specialtyFilter != null) {
      return _parseGroupsBySpecialty(specialtyFilter);
    }

    // Иначе используем метод для получения всех групп
    return _parseAllGroups();
  }

  /// Парсит все группы без фильтрации
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы
  /// во всех специальностях
  ///
  /// Возвращает:
  /// - List<GroupInfo>: Список информации о всех группах
  Future<List<GroupInfo>> _parseAllGroups() async {
    try {
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
        final List<GroupInfo> groups = [];

        // Ищем все заголовки и div элементы, которые могут содержать информацию о группах
        final groupHeaders = document.querySelectorAll('h2, h3, h4, h5');
        final groupDivs = document.querySelectorAll('div');

        // Проходим по всем заголовкам и ищем информацию о группах
        for (var header in groupHeaders) {
          final text = header.text.trim();
          // Проверяем, начинается ли текст с "Группа "
          if (text.startsWith('Группа ')) {
            // Парсим информацию о группе из текста заголовка
            final groupInfo = _parseGroupFromHeader(text, document);
            groups.addAll(groupInfo);
          }
        }

        // Если не найдено групп в заголовках, проверяем div элементы
        if (groups.isEmpty) {
          for (var div in groupDivs) {
            final text = div.text.trim();
            // Проверяем, начинается ли текст с "Группа "
            if (text.startsWith('Группа ')) {
              // Парсим информацию о группе из текста div элемента
              final groupInfo = _parseGroupFromHeader(text, document);
              if (groupInfo.isNotEmpty) {
                groups.addAll(groupInfo);
                break;
              }
            }
          }
        }

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
  /// - List<GroupInfo>: Список информации о группах для указанной специальности
  Future<List<GroupInfo>> _parseGroupsBySpecialty(
    String specialtyFilter,
  ) async {
    try {
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

        // Получаем список табов для поиска соответствия между specialtyFilter и ID
        final tabs = await parseTabList();

        // Ищем таб, который соответствует specialtyFilter
        String targetId = '';
        for (var tab in tabs) {
          // Проверяем совпадение по имени таба
          if (tab.name == specialtyFilter) {
            targetId = tab.ariaControls;
            break;
          }

          // Также проверяем совпадение по href (для хешей)
          if (tab.href == specialtyFilter) {
            targetId = tab.ariaControls;
            break;
          }
        }

        // Если не нашли точное совпадение, пытаемся найти частичное совпадение
        if (targetId.isEmpty) {
          for (var tab in tabs) {
            // Проверяем частичное совпадение по имени таба
            if (tab.name.contains(specialtyFilter) ||
                specialtyFilter.contains(tab.name)) {
              targetId = tab.ariaControls;
              break;
            }
          }
        }

        // Если не нашли ID, возвращаем пустой список
        if (targetId.isEmpty) {
          return [];
        }

        // Ищем tabpanel с нужным ID
        // Попробуем найти элемент несколькими способами
        var tabPanel = document.querySelector('#$targetId');

        // Если не нашли через querySelector, пробуем через поиск элементов с role="tabpanel"
        if (tabPanel == null) {
          // Ищем все элементы с role="tabpanel" и проверяем их ID
          final allTabPanels = document.querySelectorAll('[role="tabpanel"]');
          for (var panel in allTabPanels) {
            final id = panel.attributes['id'];
            if (id == targetId) {
              tabPanel = panel;
              break;
            }
          }
        }

        // Если не нашли tabpanel, возвращаем пустой список
        if (tabPanel == null) {
          return [];
        }

        // Создаем список для хранения информации о группах
        final List<GroupInfo> groups = [];

        // Ищем заголовки групп только внутри нужного tabpanel
        final groupHeaders = tabPanel.querySelectorAll('h2, h3, h4, h5');

        // Ищем заголовок h2 с информацией о специальности
        String specialtyFromContext = '';
        final h2Headers = tabPanel.querySelectorAll('h2');
        for (var h2 in h2Headers) {
          final h2Text = h2.text.trim();
          // Проверяем, начинается ли текст с "Расписание занятий для "
          if (h2Text.startsWith('Расписание занятий для ')) {
            // Извлекаем специальность из текста
            specialtyFromContext = h2Text
                .substring(23)
                .trim(); // 23 = "Расписание занятий для ".length
            break;
          }
        }

        // Проходим по всем заголовкам и парсим информацию о группах
        for (var header in groupHeaders) {
          final text = header.text.trim();
          // Проверяем, начинается ли текст с "Группа "
          if (text.startsWith('Группа ')) {
            // Парсим информацию о группе из текста заголовка
            final groupInfo = _parseGroupFromHeader(
              text,
              document,
              specialtyFromContext,
            );
            groups.addAll(groupInfo);
          }
        }

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
  /// - List<GroupInfo>: Список информации о группах (обычно один элемент)
  List<GroupInfo> _parseGroupFromHeader(
    String headerText,
    Document document, [
    String? specialtyFromContext,
  ]) {
    // Создаем список для хранения информации о группах
    final List<GroupInfo> groups = [];

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
          // Если не удалось определить специальность по префиксу, ищем в документе
          final specialtyListItems = document.querySelectorAll('ul li');
          for (var item in specialtyListItems) {
            final itemText = item.text.trim();
            // Проверяем, содержит ли текст информацию о специальности
            if (itemText.contains('.') &&
                (itemText.contains('Э') ||
                    itemText.contains('СА') ||
                    itemText.contains('П,Т') ||
                    itemText.contains('БАС') ||
                    itemText.contains('БИ') ||
                    itemText.contains('ИС') ||
                    itemText.contains('ВД') ||
                    itemText.contains('Ю') ||
                    itemText.contains('ВТ') ||
                    itemText.contains('БД'))) {
              // Извлекаем код специальности из текста
              final RegExp specialtyPattern = RegExp(
                r'([0-9]{2}\.[0-9]{2}\.[0-9]{2}[\s\S]*)',
              );
              final match = specialtyPattern.firstMatch(itemText);
              if (match != null) {
                specialtyCode = match.group(1)?.trim() ?? '';
                specialtyName = itemText;
                break;
              }
            }
          }
        }
      }

      // Добавляем информацию о группе в список
      groups.add(
        GroupInfo(
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
}
