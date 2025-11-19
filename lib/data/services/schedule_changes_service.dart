import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/schedule_change.dart';

/// Сервис для парсинга изменений в расписании с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации об изменениях в расписании
/// с официального сайта техникума mpt.ru/izmeneniya-v-raspisanii/
class ScheduleChangesService {
  /// Базовый URL страницы с изменениями в расписании
  final String baseUrl = 'https://mpt.ru/izmeneniya-v-raspisanii/';

  /// Парсит изменения в расписании для конкретной группы
  ///
  /// Метод извлекает HTML-страницу с изменениями в расписании и находит
  /// все изменения, относящиеся к указанной группе, на сегодня и завтра
  ///
  /// Параметры:
  /// - [groupCode]: Код группы для которой нужно получить изменения
  ///
  /// Возвращает:
  /// - List<ScheduleChange>: Список изменений в расписании для группы
  Future<List<ScheduleChange>> parseScheduleChangesForGroup(
    String groupCode,
  ) async {
    try {
      // Отправляем HTTP-запрос к странице изменений в расписании
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

        // Создаем список для хранения изменений
        final List<ScheduleChange> changes = [];

        // Получаем сегодняшнюю и завтрашнюю даты для фильтрации изменений
        final today = DateTime.now();
        final tomorrow = DateTime.now().add(Duration(days: 1));

        // Форматируем даты в строковый формат для сравнения
        final String todayDate =
            '${today.day}.${today.month.toString().padLeft(2, '0')}.${today.year}';
        final String tomorrowDate =
            '${tomorrow.day}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

        // Ищем все заголовки с датами изменений
        final dateHeaders = document.querySelectorAll('h4');

        // Проходим по всем заголовкам с датами
        for (int i = 0; i < dateHeaders.length; i++) {
          final header = dateHeaders[i];
          final text = header.text.trim();

          // Проверяем, является ли заголовок заголовком изменений
          if (text.startsWith('Замены на')) {
            // Извлекаем дату из заголовка с помощью регулярного выражения
            final RegExp dateRegExp = RegExp(r'(\d{2}\.\d{2}\.\d{4})');
            final match = dateRegExp.firstMatch(text);

            // Если дата найдена
            if (match != null) {
              final currentDate = match.group(1)!;

              // Проверяем, что дата соответствует сегодня или завтра
              if (currentDate == todayDate || currentDate == tomorrowDate) {
                // Ищем все элементы до следующего заголовка или до конца документа
                List<Element> elementsBetweenHeaders = [];
                Element? nextElement = header.nextElementSibling;

                // Собираем все элементы до следующего заголовка
                while (nextElement != null) {
                  // Проверяем, является ли следующий элемент заголовком
                  if (nextElement is Element &&
                      nextElement.localName == 'h4' &&
                      nextElement.text.trim().startsWith('Замены на')) {
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
                    if (element.localName == 'div' &&
                        element.classes.contains('table-responsive')) {
                      table = element.querySelector('table');
                    }
                    // Если это непосредственно таблица
                    else if (element.localName == 'table' &&
                        element.classes.contains('table')) {
                      table = element;
                    }

                    // Если таблица найдена
                    if (table != null) {
                      // Проверяем, содержит ли таблица изменения для нашей группы
                      final caption = table.querySelector('caption');
                      if (caption != null && caption.text.contains(groupCode)) {
                        // Ищем все строки с изменениями
                        final rows = table.querySelectorAll('tr');

                        // Обрабатываем строки, начиная со второй (пропускаем заголовок)
                        for (int j = 1; j < rows.length; j++) {
                          final row = rows[j];
                          final cells = row.querySelectorAll('td');

                          // Проверяем, что в строке есть все необходимые данные (4 ячейки)
                          if (cells.length == 4) {
                            // Извлекаем данные из ячеек таблицы
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
                                changeDate:
                                    currentDate, // Дата, когда применяется изменение
                              ),
                            );
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

        return changes;
      } else {
        throw Exception(
          'Не удалось загрузить страницу: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Ошибка при парсинге изменений для группы $groupCode: $e',
      );
    }
  }
}
