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

  /// Parses the MPT schedule page and extracts href and aria-controls attributes
  /// from the tablist elements
  Future<List<TabInfo>> parseTabList() async {
    try {
      // Fetch the HTML content from the website with timeout
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        // Parse the HTML document
        final document = parser.parse(response.body);
        
        // Find the tablist element
        final tablist = document.querySelector('ul[role="tablist"]');
        
        if (tablist == null) {
          throw Exception('Tablist not found on the page');
        }
        
        // Find all li elements with role="presentation" within the tablist
        final tabItems = tablist.querySelectorAll('li[role="presentation"]');
        
        final List<TabInfo> tabs = [];
        
        // Extract href, aria-controls, and name from each tab
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

  /// Parses the MPT schedule page and extracts week information
  /// including week type (numerator/denominator), date and day
  Future<WeekInfo> parseWeekInfo() async {
    try {
      // Fetch the HTML content from the website with timeout
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        // Parse the HTML document
        final document = parser.parse(response.body);
        
        // Extract date and day information (e.g., "14 Ноября - Пятница")
        String date = '';
        String day = '';
        final dateHeader = document.querySelector('h2');
        if (dateHeader != null) {
          final dateText = dateHeader.text.trim();
          // Split by dash to separate date and day
          final parts = dateText.split(' - ');
          if (parts.length >= 2) {
            date = parts[0];
            day = parts[1];
          } else {
            date = dateText;
          }
        }
        
        // Extract week type information (e.g., "Числитель")
        String weekType = '';
        final weekHeaders = document.querySelectorAll('h3');
        for (var header in weekHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Неделя:')) {
            // Extract the week type after "Неделя:"
            weekType = text.substring(7).trim();
            // Remove any label classes if present
            final labelElement = header.querySelector('.label');
            if (labelElement != null) {
              weekType = labelElement.text.trim();
            }
            break;
          }
        }
        
        // If we couldn't find week type in h3, try to find it in spans with label classes
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

  /// Parses the MPT schedule page and extracts group information
  /// grouped by specialties
  Future<List<GroupInfo>> parseGroups() async {
    try {
      // Fetch the HTML content from the website with timeout
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );
      
      if (response.statusCode == 200) {
        // Parse the HTML document
        final document = parser.parse(response.body);
        
        final List<GroupInfo> groups = [];
        
        // Find all h2/h3/h4/h5 elements that might contain group information
        final groupHeaders = document.querySelectorAll('h2, h3, h4, h5');
        
        // Also look for div elements with specific classes that might contain group info
        final groupDivs = document.querySelectorAll('div');
        
        print('DEBUG: Найдено заголовков: ${groupHeaders.length}, div элементов: ${groupDivs.length}');
        
        // Process header elements
        for (var header in groupHeaders) {
          final text = header.text.trim();
          if (text.startsWith('Группа ')) {
            final groupInfo = _parseGroupFromHeader(text, document);
            groups.addAll(groupInfo);
          }
        }
        
        // Process div elements as fallback
        if (groups.isEmpty) {
          print('DEBUG: Не найдено групп в заголовках, проверяем div элементы');
          for (var div in groupDivs) {
            final text = div.text.trim();
            if (text.startsWith('Группа ')) {
              final groupInfo = _parseGroupFromHeader(text, document);
              if (groupInfo.isNotEmpty) {
                groups.addAll(groupInfo);
                break; // Take only first match to avoid duplicates
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
  
  /// Helper method to parse group information from header text
  List<GroupInfo> _parseGroupFromHeader(String headerText, Document document) {
    final List<GroupInfo> groups = [];
    
    try {
      print('DEBUG: Обрабатываем заголовок: "$headerText"');
      
      // Extract group code (e.g., "Группа Э-1-22, Э-11/1-23" -> "Э-1-22, Э-11/1-23")
      final groupCode = headerText.substring(7).trim();
      
      // Определяем специальность по префиксу группы
      String specialtyCode = '';
      String specialtyName = '';
      
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
        // Fallback - пытаемся найти специальность в документе
        // Approach 1: Look for specialty list items with more precise pattern matching
        final specialtyListItems = document.querySelectorAll('ul li');
        for (var item in specialtyListItems) {
          final itemText = item.text.trim();
          // Check if this item contains specialty information with precise pattern
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
      
      // ВАЖНО: Не разделяем группы типа "Т-1-24; Т-11/1-25" на отдельные записи
      // Это одна группа, а не три разных
      print('DEBUG: Добавляем группу как есть: $groupCode (специальность: $specialtyCode)');
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
