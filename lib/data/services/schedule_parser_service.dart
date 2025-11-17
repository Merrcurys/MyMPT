import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/lesson.dart';

class ScheduleParserService {
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Парсит расписание для конкретной группы
  Future<Map<String, List<Lesson>>> parseScheduleForGroup(
    String groupCode,
  ) async {
    try {
      // Отправляем запрос к странице расписания
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout after 15 seconds');
            },
          );

      if (response.statusCode == 200) {
        // Парсим HTML документ
        final document = parser.parse(response.body);

        // Создаем карту для хранения расписания по дням недели
        final Map<String, List<Lesson>> weeklySchedule = {};

        // Сначала найдем ID вкладки для нужной группы
        String? targetTabId;

        // Ищем все ссылки на вкладки групп
        final tabLinks = document.querySelectorAll('ul.nav-tabs a');
        print('DEBUG: Найдено ${tabLinks.length} ссылок на вкладки');

        for (var link in tabLinks) {
          final linkText = link.text.trim();
          print('DEBUG: Проверяем ссылку: $linkText');

          // Проверяем, совпадает ли текст ссылки с кодом группы
          if (linkText == groupCode) {
            // Получаем ID вкладки из атрибута href (#id)
            final href = link.attributes['href'];
            if (href != null && href.startsWith('#')) {
              targetTabId = href.substring(1); // Убираем #
              print(
                'DEBUG: Найден точный ID вкладки для группы $groupCode: $targetTabId',
              );
              break;
            }
          }
        }

        // Если не нашли точное совпадение, ищем частичное совпадение
        if (targetTabId == null) {
          print(
            'DEBUG: Точное совпадение не найдено, ищем частичное совпадение',
          );
          for (var link in tabLinks) {
            final linkText = link.text.trim();
            // Проверяем, содержит ли текст ссылки код группы
            if (linkText.contains(groupCode)) {
              // Получаем ID вкладки из атрибута href (#id)
              final href = link.attributes['href'];
              if (href != null && href.startsWith('#')) {
                targetTabId = href.substring(1); // Убираем #
                print(
                  'DEBUG: Найден ID вкладки по частичному совпадению для группы $groupCode: $targetTabId',
                );
                break;
              }
            }
          }
        }

        // Если не нашли ID вкладки, возвращаем пустое расписание
        if (targetTabId == null) {
          print('DEBUG: Не найден ID вкладки для группы $groupCode');
          return weeklySchedule;
        }

        // Теперь ищем конкретный tab-pane с этим ID
        final targetTabPane = document.querySelector(
          'div[role="tabpanel"][id="$targetTabId"]',
        );

        // Если не нашли tab-pane для группы, возвращаем пустое расписание
        if (targetTabPane == null) {
          print(
            'DEBUG: Не найден tab-pane для группы $groupCode с ID $targetTabId',
          );
          return weeklySchedule;
        }

        print('DEBUG: Найден tab-pane для группы $groupCode');

        // Ищем заголовок с названием группы внутри tab-pane
        final groupHeader = targetTabPane.querySelector('h3');
        if (groupHeader != null) {
          print('DEBUG: Заголовок группы: ${groupHeader.text.trim()}');
        }

        // Ищем все таблицы с расписанием в этой вкладке
        final tables = targetTabPane.querySelectorAll('table.table');
        print('DEBUG: Найдено ${tables.length} таблиц с расписанием');

        for (var table in tables) {
          // Ищем заголовок таблицы с днем недели
          final thead = table.querySelector('thead');
          if (thead != null) {
            final h4 = thead.querySelector('h4');
            if (h4 != null) {
              // Извлекаем день недели и корпус из HTML
              final dayText = h4.text.trim();
              print('DEBUG: Найден день: $dayText');

              String day = '';
              String building = '';

              // Получаем непосредственных дочерних узлов h4
              final childNodes = h4.nodes;
              if (childNodes.isNotEmpty) {
                // Первый узел должен содержать название дня
                day = childNodes[0].text?.trim() ?? '';

                // Ищем span с информацией о корпусе
                final span = h4.querySelector('span');
                if (span != null) {
                  building = span.text.trim();
                }
              }

              // Если не удалось извлечь день, пробуем альтернативный способ
              if (day.isEmpty) {
                day = dayText.split(' ')[0];
              }

              print('DEBUG: День: $day, Корпус: $building');

              // Создаем список уроков для этого дня
              final List<Lesson> lessons = [];

              // Ищем все tbody элементы в таблице
              final tbodies = table.querySelectorAll('tbody');
              print(
                'DEBUG: Найдено ${tbodies.length} tbody элементов в таблице',
              );

              // Обрабатываем все tbody элементы
              for (var tbody in tbodies) {
                // Ищем все строки с данными об уроках
                final rows = tbody.querySelectorAll('tr');
                print('DEBUG: Найдено ${rows.length} строк в tbody');

                // Обрабатываем строки, пропуская первую (пустую) и вторую (заголовок)
                // и последнюю (пустую)
                for (int i = 1; i < rows.length - 1; i++) {
                  if (i < rows.length) {
                    final row = rows[i];
                    final cells = row.querySelectorAll('td');
                    print('DEBUG: Найдено ${cells.length} ячеек в строке $i');

                    // Проверяем, что в строке есть все необходимые данные (3 ячейки)
                    if (cells.length == 3) {
                      final number = cells[0].text.trim();
                      final subjectCell = cells[1];
                      final teacherCell = cells[2];

                      // Проверяем, есть ли в ячейке несколько предметов (числитель/знаменатель)
                      final subjectLabels = subjectCell.querySelectorAll('div.label');
                      final teacherLabels = teacherCell.querySelectorAll('div.label');

                      if (subjectLabels.isNotEmpty && teacherLabels.isNotEmpty) {
                        // Обрабатываем пары с числителем/знаменателем
                        for (int i = 0; i < subjectLabels.length && i < teacherLabels.length; i++) {
                          final subjectLabel = subjectLabels[i];
                          final teacherLabel = teacherLabels[i];
                          
                          final subjectText = subjectLabel.text.trim();
                          final teacherText = teacherLabel.text.trim();
                          
                          // Определяем тип (числитель или знаменатель) по классу
                          final classes = subjectLabel.attributes['class'] ?? '';
                          String lessonType = '';
                          if (classes.contains('label-danger')) {
                            lessonType = 'numerator';
                          } else if (classes.contains('label-info')) {
                            lessonType = 'denominator';
                          }
                          
                          print('DEBUG: Найден урок ($lessonType): $number, $subjectText, $teacherText');

                          // Создаем урок только если есть номер и предмет
                          if (number.isNotEmpty && subjectText.isNotEmpty) {
                            lessons.add(
                              Lesson(
                                number: number,
                                subject: subjectText,
                                teacher: teacherText,
                                startTime: '',
                                endTime: '',
                                building: building,
                                lessonType: lessonType,
                              ),
                            );
                            print(
                              'DEBUG: Добавлен урок ($lessonType): $number - $subjectText - $teacherText',
                            );
                          }
                        }
                      } else {
                        // Обычная пара
                        final subject = subjectCell.text.trim();
                        final teacher = teacherCell.text.trim();

                        print('DEBUG: Найден обычный урок: $number, $subject, $teacher');

                        // Создаем урок только если есть номер и предмет
                        if (number.isNotEmpty && subject.isNotEmpty) {
                          lessons.add(
                            Lesson(
                              number: number,
                              subject: subject,
                              teacher: teacher,
                              startTime: '',
                              endTime: '',
                              building: building,
                              lessonType: null,
                            ),
                          );
                          print(
                            'DEBUG: Добавлен обычный урок: $number - $subject - $teacher',
                          );
                        }
                      }
                    }
                  }
                }
              }

              // Добавляем уроки в расписание (только если есть уроки)
              if (lessons.isNotEmpty) {
                weeklySchedule[day] = lessons;
                print('DEBUG: Для дня $day добавлено ${lessons.length} уроков');
              } else {
                print('DEBUG: Для дня $day не найдено уроков');
              }
            }
          }
        }

        print('DEBUG: Всего дней с расписанием: ${weeklySchedule.length}');
        return weeklySchedule;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Ошибка парсинга расписания для группы $groupCode: $e');
      throw Exception('Error parsing schedule for group $groupCode: $e');
    }
  }

  /// Извлекает время начала и окончания урока из текста
  /// Формат: "08:30-09:15" или "08:30 - 09:15"
  List<String> _parseTimeRange(String text) {
    final RegExp timePattern = RegExp(
      r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})',
    );
    final match = timePattern.firstMatch(text);

    if (match != null) {
      return [match.group(1)!, match.group(2)!];
    }

    return ['', ''];
  }
}
