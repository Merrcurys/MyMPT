import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/schedule_change.dart';

class ScheduleChangesService {
  final String baseUrl = 'https://mpt.ru/izmeneniya-v-raspisanii/';

  /// Парсит изменения в расписании для конкретной группы
  Future<List<ScheduleChange>> parseScheduleChangesForGroup(
    String groupCode,
  ) async {
    try {
      // Отправляем запрос к странице изменений в расписании
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

        // Создаем список для хранения изменений
        final List<ScheduleChange> changes = [];

        // Получаем сегодняшнюю и завтрашнюю даты
        final today = DateTime.now();
        final tomorrow = DateTime.now().add(Duration(days: 1));
        
        final String todayDate = '${today.day}.${today.month.toString().padLeft(2, '0')}.${today.year}';
        final String tomorrowDate = '${tomorrow.day}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';
        
        // Ищем все заголовки с датами
        final dateHeaders = document.querySelectorAll('h4');
        
        // Проходим по всем заголовкам с датами
        for (int i = 0; i < dateHeaders.length; i++) {
          final header = dateHeaders[i];
          final text = header.text.trim();
          
          if (text.startsWith('Замены на')) {
            // Извлекаем дату из заголовка
            final RegExp dateRegExp = RegExp(r'(\d{2}\.\d{2}\.\d{4})');
            final match = dateRegExp.firstMatch(text);
            
            if (match != null) {
              final currentDate = match.group(1)!;
              print('DEBUG: Найдены замены на дату: $currentDate');
              
              // Проверяем, что дата соответствует сегодня или завтра
              if (currentDate == todayDate || currentDate == tomorrowDate) {
                // Ищем все элементы до следующего заголовка или до конца документа
                List<Element> elementsBetweenHeaders = [];
                Element? nextElement = header.nextElementSibling;
                
                // Собираем все элементы до следующего заголовка
                while (nextElement != null) {
                  // Проверяем, является ли следующий элемент заголовком
                  if (nextElement is Element && nextElement.localName == 'h4' && nextElement.text.trim().startsWith('Замены на')) {
                    break;
                  }
                  elementsBetweenHeaders.add(nextElement);
                  nextElement = nextElement.nextElementSibling;
                }
                
                // Ищем таблицы среди собранных элементов
                for (var element in elementsBetweenHeaders) {
                  if (element is Element) {
                    Element? table;
                    
                    // Если это div с table-responsive, ищем таблицу внутри
                    if (element.localName == 'div' && element.classes.contains('table-responsive')) {
                      table = element.querySelector('table');
                    } 
                    // Если это непосредственно таблица
                    else if (element.localName == 'table' && element.classes.contains('table')) {
                      table = element;
                    }
                    
                    if (table != null) {
                      // Проверяем, содержит ли таблица изменения для нашей группы
                      final caption = table.querySelector('caption');
                      if (caption != null && caption.text.contains(groupCode)) {
                        print('DEBUG: Найдена таблица изменений на дату $currentDate для группы $groupCode');
                        
                        // Ищем все строки с изменениями
                        final rows = table.querySelectorAll('tr');
                        
                        // Обрабатываем строки, начиная со второй (пропускаем заголовок)
                        for (int j = 1; j < rows.length; j++) {
                          final row = rows[j];
                          final cells = row.querySelectorAll('td');
                          
                          // Проверяем, что в строке есть все необходимые данные (4 ячейки)
                          if (cells.length == 4) {
                            final lessonNumber = cells[0].text.trim();
                            final replaceFrom = cells[1].text.trim();
                            final replaceTo = cells[2].text.trim();
                            final updatedAt = cells[3].text.trim();
                            
                            // Создаем объект изменения с пометкой о дате
                            changes.add(
                              ScheduleChange(
                                lessonNumber: lessonNumber,
                                replaceFrom: replaceFrom,
                                replaceTo: replaceTo,
                                updatedAt: updatedAt, // Оригинальный timestamp
                                changeDate: currentDate, // Дата, когда применяется изменение
                              ),
                            );
                            
                            print('DEBUG: Добавлено изменение на дату: $lessonNumber | $replaceFrom -> $replaceTo | $updatedAt (на $currentDate)');
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        print('DEBUG: Всего найдено ${changes.length} изменений для группы $groupCode');
        return changes;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Ошибка парсинга изменений для группы $groupCode: $e');
      throw Exception('Error parsing schedule changes for group $groupCode: $e');
    }
  }
}