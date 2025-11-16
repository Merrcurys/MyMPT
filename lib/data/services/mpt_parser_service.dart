import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/week_info.dart';
import 'package:my_mpt/data/models/group_info.dart';

class MptParserService {
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  Future<List<TabInfo>> parseTabList() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        final tablist = document.querySelector('ul[role="tablist"]');
        
        if (tablist == null) {
          throw Exception('Tablist not found on the page');
        }
        
        final tabItems = tablist.querySelectorAll('li[role="presentation"]');
        
        final List<TabInfo> tabs = [];
        
        for (var item in tabItems) {
          final anchor = item.querySelector('a');
          if (anchor != null) {
            final href = anchor.attributes['href'];
            final ariaControls = anchor.attributes['aria-controls'];
            final name = anchor.text?.trim() ?? '';
            
            if (href != null && ariaControls != null) {
              tabs.add(TabInfo(href: href, ariaControls: ariaControls, name: name));
            }
          }
        }
        
        return tabs;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error parsing tablist: $e');
    }
  }

  Future<WeekInfo> parseWeekInfo() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        String date = '';
        String day = '';
        final dateHeader = document.querySelector('h2');
        if (dateHeader != null) {
          final dateText = dateHeader.text.trim();
          final parts = dateText.split(' - ');
          if (parts.length >= 2) {
            date = parts[0];
            day = parts[1];
          } else {
            date = dateText;
          }
        }
        
        String weekType = '';
        final weekHeaders = document.querySelectorAll('h3');
        for (var header in weekHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Неделя:')) {
            weekType = text.substring(7).trim();
            final labelElement = header.querySelector('.label');
            if (labelElement != null) {
              weekType = labelElement.text.trim();
            }
            break;
          }
        }
        
        if (weekType.isEmpty) {
          final labelElements = document.querySelectorAll('.label');
          for (var label in labelElements) {
            final labelText = label.text.trim();
            if (labelText == 'Числитель' || labelText == 'Знаменатель') {
              weekType = labelText;
              break;
            }
          }
        }
        
        return WeekInfo(
          weekType: weekType,
          date: date,
          day: day,
        );
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error parsing week info: $e');
    }
  }

  Future<List<GroupInfo>> parseGroups([String? specialtyFilter]) async {
    // Если задан фильтр специальности, используем оптимизированный метод
    if (specialtyFilter != null) {
      return _parseGroupsBySpecialty(specialtyFilter);
    }
    
    // Иначе используем старый метод для обратной совместимости
    return _parseAllGroups();
  }
  
  Future<List<GroupInfo>> _parseAllGroups() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        final List<GroupInfo> groups = [];
        
        final groupHeaders = document.querySelectorAll('h2, h3, h4, h5');
        
        final groupDivs = document.querySelectorAll('div');
        
        print('DEBUG: Найдено заголовков: ${groupHeaders.length}, div элементов: ${groupDivs.length}');
        
        for (var header in groupHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Группа ')) {
            final groupInfo = _parseGroupFromHeader(text, document);
            groups.addAll(groupInfo);
          }
        }
        
        if (groups.isEmpty) {
          print('DEBUG: Не найдено групп в заголовках, проверяем div элементы');
          for (var div in groupDivs) {
            final text = div.text.trim();
            if (text.startsWith('Группа ')) {
              final groupInfo = _parseGroupFromHeader(text, document);
              if (groupInfo.isNotEmpty) {
                groups.addAll(groupInfo);
                break;
              }
            }
          }
        }
        
        print('DEBUG: Всего найдено групп: ${groups.length}');
        
        return groups;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Ошибка парсинга групп: $e');
      throw Exception('Error parsing groups: $e');
    }
  }
  
  Future<List<GroupInfo>> _parseGroupsBySpecialty(String specialtyFilter) async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );
      
      if (response.statusCode == 200) {
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
            if (tab.name.contains(specialtyFilter) || specialtyFilter.contains(tab.name)) {
              targetId = tab.ariaControls;
              break;
            }
          }
        }
        
        print('DEBUG: Поиск групп для специальности "$specialtyFilter", target ID: "$targetId"');
        
        // Если не нашли ID, возвращаем пустой список
        if (targetId.isEmpty) {
          print('DEBUG: Не найден ID для специальности "$specialtyFilter"');
          return [];
        }
        
        // Ищем tabpanel с нужным ID
        // Попробуем найти элемент несколькими способами
        var tabPanel = document.querySelector('#$targetId');
        
        // Если не нашли через querySelector, попробуем через getElementById
        if (tabPanel == null) {
          // В html пакете нет getElementById, поэтому пробуем другой подход
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
        
        if (tabPanel == null) {
          print('DEBUG: Не найден tabpanel с ID "$targetId"');
          // Для отладки выведем все доступные tabpanel ID
          final allTabPanels = document.querySelectorAll('[role="tabpanel"]');
          print('DEBUG: Доступные tabpanel ID:');
          for (var panel in allTabPanels) {
            final id = panel.attributes['id'];
            final className = panel.attributes['class'];
            print('DEBUG:   ID: "$id", Class: "$className"');
          }
          return [];
        }
        
        final List<GroupInfo> groups = [];
        
        // Ищем заголовки групп только внутри нужного tabpanel
        final groupHeaders = tabPanel.querySelectorAll('h2, h3, h4, h5');
        
        print('DEBUG: Найдено заголовков в tabpanel: ${groupHeaders.length}');
        
        // Ищем заголовок h2 с информацией о специальности
        String specialtyFromContext = '';
        final h2Headers = tabPanel.querySelectorAll('h2');
        for (var h2 in h2Headers) {
          final h2Text = h2.text.trim();
          if (h2Text.startsWith('Расписание занятий для ')) {
            // Извлекаем специальность из текста "Расписание занятий для 40.02.01, 40.02.04 Ю"
            specialtyFromContext = h2Text.substring(23).trim(); // 23 = "Расписание занятий для ".length
            print('DEBUG: Найдена специальность из контекста: $specialtyFromContext');
            break;
          }
        }
        
        // Process header elements
        for (var header in groupHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Группа ')) {
            final groupInfo = _parseGroupFromHeader(text, document, specialtyFromContext);
            groups.addAll(groupInfo);
          }
        }
        
        print('DEBUG: Найдено групп для специальности "$specialtyFilter": ${groups.length}');
        
        return groups;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Ошибка парсинга групп для специальности "$specialtyFilter": $e');
      throw Exception('Error parsing groups for specialty "$specialtyFilter": $e');
    }
  }
  
  List<GroupInfo> _parseGroupFromHeader(String headerText, Document document, [String? specialtyFromContext]) {
    final List<GroupInfo> groups = [];
    
    try {
      print('DEBUG: Обрабатываем заголовок: "$headerText"');
      
      // Extract group code (e.g., "Группа Э-1-22, Э-11/1-23" -> "Э-1-22, Э-11/1-23")
      final groupCode = headerText.substring(7).trim();
      
      // Определяем специальность
      String specialtyCode = '';
      String specialtyName = '';
      
      // Если передана специальность из контекста, используем её
      if (specialtyFromContext != null && specialtyFromContext.isNotEmpty) {
        specialtyCode = specialtyFromContext;
        specialtyName = specialtyFromContext;
        print('DEBUG: Используем специальность из контекста: $specialtyCode');
      } else {
        // Иначе определяем специальность по префиксу группы
        // Извлекаем префикс из первой части кода группы
        final groupCodeParts = groupCode.split(RegExp(r'[;,\/]'));
        String prefix = '';
        if (groupCodeParts.isNotEmpty) {
          final firstGroup = groupCodeParts[0].trim();
          // Extract prefix pattern (e.g., ВД-2-23 -> ВД)
          final prefixMatch = RegExp(r'^([А-Яа-я0-9]+)-').firstMatch(firstGroup);
          if (prefixMatch != null) {
            prefix = prefixMatch.group(1) ?? '';
            print('DEBUG: Извлечен префикс из кода группы: $prefix');
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
          'П': '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'Т': '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'ИС': '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БД': '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'ВД': '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БАС': '09.02.08 Безопасность автоматизированных систем',
          'БИ': '38.02.07 Банковское дело',
          'Ю': '40.02.01 Право и организация социального обеспечения',
          'ВТ': '09.02.07 Веб-технологии',
        };
        
        // Определяем код и название специальности по префиксу
        if (prefixToSpecialtyCode.containsKey(prefix)) {
          specialtyCode = prefixToSpecialtyCode[prefix]!;
          specialtyName = prefixToSpecialtyName[prefix] ?? prefix;
          print('DEBUG: Определена специальность по префиксу "$prefix": $specialtyCode');
        } else {
          print('DEBUG: Не удалось определить специальность для префикса "$prefix"');
          final specialtyListItems = document.querySelectorAll('ul li');
          for (var item in specialtyListItems) {
            final itemText = item.text.trim();
            if (itemText.contains('.') && (itemText.contains('Э') || itemText.contains('СА') || 
                itemText.contains('П,Т') || itemText.contains('БАС') || itemText.contains('БИ') || 
                itemText.contains('ИС') || itemText.contains('ВД') || itemText.contains('Ю') || 
                itemText.contains('ВТ') || itemText.contains('БД'))) {
              // Извлекаем код специальности из текста
              final RegExp specialtyPattern = RegExp(r'([0-9]{2}\.[0-9]{2}\.[0-9]{2}[\s\S]*)');
              final match = specialtyPattern.firstMatch(itemText);
              if (match != null) {
                specialtyCode = match.group(1)?.trim() ?? '';
                specialtyName = itemText;
                print('DEBUG: Найдена специальность в документе: $specialtyCode');
                break;
              }
            }
          }
        }
      }
      
      print('DEBUG: Добавляем группу: $groupCode (специальность: $specialtyCode)');
      groups.add(GroupInfo(
        code: groupCode, // Сохраняем полное название группы
        specialtyCode: specialtyCode,
        specialtyName: specialtyName,
      ));
      
    } catch (e) {
      print('DEBUG: Ошибка при парсинге заголовка "$headerText": $e');
    }
    
    return groups;
  }
}
