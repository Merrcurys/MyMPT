import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/schedule_change.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для парсинга изменений в расписании с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации об изменениях в расписании
/// с официального сайта техникума mpt.ru/izmeneniya-v-raspisanii/
class ScheduleChangesService {
  /// Базовый URL страницы с изменениями в расписании
  final String baseUrl = 'https://mpt.ru/izmeneniya-v-raspisanii/';

  /// Время жизни кэша (5 часов для замен)
  static const Duration _cacheTtl = Duration(hours: 5);
  
  /// Время начала обновления кэша (6:00 утра)
  static const int _cacheUpdateStartHour = 6;

  /// Ключи для кэширования
  static const String _cacheKeyChanges = 'schedule_changes_';
  static const String _cacheKeyChangesTimestamp = 'schedule_changes_timestamp_';

  /// Парсит изменения в расписании для конкретной группы
  ///
  /// Метод извлекает HTML-страницу с изменениями в расписании и находит
  /// все изменения, относящиеся к указанной группе, на сегодня и завтра
  ///
  /// Параметры:
  /// - [groupCode]: Код группы для которой нужно получить изменения
  /// - [forceRefresh]: Принудительное обновление без использования кэша
  ///
  /// Возвращает:
  /// Список изменений в расписании для группы
  Future<List<ScheduleChange>> parseScheduleChangesForGroup(
    String groupCode, {
    bool forceRefresh = false,
  }) async {
    try {
      // Проверяем кэш
      if (!forceRefresh) {
        final cachedChanges = await _getCachedChanges(groupCode);
        if (cachedChanges != null) {
          return cachedChanges;
        }
      }

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
            '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
        final String tomorrowDate =
            '${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

        // Нормализуем код группы для поиска
        final normalizedGroupCode = groupCode.trim().toUpperCase();

        // Ищем все заголовки h4 с датами изменений (строгий селектор)
        final dateHeaders = document.querySelectorAll('h4');

        // Регулярное выражение для извлечения даты (компилируем один раз)
        final RegExp dateRegExp = RegExp(r'(\d{2}\.\d{2}\.\d{4})');

        // Проходим по заголовкам с датами
        for (var header in dateHeaders) {
          final text = header.text.trim();

          // Проверяем, является ли заголовок заголовком изменений
          if (!text.startsWith('Замены на')) continue;

          // Извлекаем дату из заголовка
          final match = dateRegExp.firstMatch(text);
          if (match == null) continue;

          final currentDate = match.group(1)!;

          // Проверяем, что дата соответствует сегодня или завтра
          if (currentDate != todayDate && currentDate != tomorrowDate) continue;

          // Ищем таблицы напрямую после заголовка (оптимизированный поиск)
          Element? nextElement = header.nextElementSibling;
          
          while (nextElement != null) {
            // Если встретили следующий заголовок, прекращаем поиск
            if (nextElement.localName == 'h4' &&
                nextElement.text.trim().startsWith('Замены на')) {
              break;
            }

            // Ищем таблицы с изменениями (строгий селектор)
            Element? table;
            if (nextElement.localName == 'div' &&
                nextElement.classes.contains('table-responsive')) {
              table = nextElement.querySelector('table.table');
            } else if (nextElement.localName == 'table' &&
                nextElement.classes.contains('table')) {
              table = nextElement;
            }

            // Если таблица найдена, проверяем её на соответствие группе
            if (table != null) {
              final caption = table.querySelector('caption');
              if (caption != null) {
                final captionText = caption.text.trim().toUpperCase();
                // Проверяем, содержит ли таблица изменения для нашей группы
                if (normalizedGroupCode.isNotEmpty &&
                    captionText.contains(normalizedGroupCode)) {
                  // Ищем все строки с изменениями (пропускаем заголовок)
                  final rows = table.querySelectorAll('tbody > tr, tr:not(:first-child)');

                  // Обрабатываем строки
                  for (var row in rows) {
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
                          updatedAt: updatedAt,
                          changeDate: currentDate,
                        ),
                      );
                    }
                  }
                }
              }
            }

            nextElement = nextElement.nextElementSibling;
          }
        }

        // Сохраняем в кэш
        await _saveCachedChanges(groupCode, changes);

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

  /// Получает кэшированные изменения
  Future<List<ScheduleChange>?> _getCachedChanges(String groupCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyChanges${groupCode.hashCode}';
      final timestampKey = '$_cacheKeyChangesTimestamp${groupCode.hashCode}';
      
      final timestamp = prefs.getInt(timestampKey);
      final cachedJson = prefs.getString(cacheKey);

      if (timestamp != null && cachedJson != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final age = now.difference(cacheTime);
        
        // Проверяем, нужно ли обновить кэш
        // Кэш обновляется каждые 5 часов, начиная с 6:00 утра
        final shouldRefresh = _shouldRefreshCache(cacheTime, now, age);
        
        if (!shouldRefresh && age < _cacheTtl) {
          // Кэш действителен, возвращаем данные
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded.map((json) => ScheduleChange(
            lessonNumber: json['lessonNumber'] as String,
            replaceFrom: json['replaceFrom'] as String,
            replaceTo: json['replaceTo'] as String,
            updatedAt: json['updatedAt'] as String,
            changeDate: json['changeDate'] as String,
          )).toList();
        } else {
          // Кэш истек или требуется обновление, очищаем устаревшие данные
          await prefs.remove(cacheKey);
          await prefs.remove(timestampKey);
        }
      }
    } catch (e) {
      // Игнорируем ошибки кэша
    }
    return null;
  }

  /// Сохраняет изменения в кэш
  Future<void> _saveCachedChanges(String groupCode, List<ScheduleChange> changes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyChanges${groupCode.hashCode}';
      final timestampKey = '$_cacheKeyChangesTimestamp${groupCode.hashCode}';
      
      final json = jsonEncode(changes.map((change) => {
        'lessonNumber': change.lessonNumber,
        'replaceFrom': change.replaceFrom,
        'replaceTo': change.replaceTo,
        'updatedAt': change.updatedAt,
        'changeDate': change.changeDate,
      }).toList());
      await prefs.setString(cacheKey, json);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Игнорируем ошибки кэша
    }
  }

  /// Проверяет, нужно ли обновить кэш замен
  /// 
  /// Кэш обновляется каждые 5 часов, начиная с 6:00 утра
  /// Времена обновления: 6:00, 11:00, 16:00, 21:00, 0:00 (следующего дня)
  bool _shouldRefreshCache(DateTime cacheTime, DateTime now, Duration age) {
    // Если кэш старше 5 часов, обновляем
    if (age >= _cacheTtl) return true;
    
    // Определяем периоды обновления: 6:00-11:00, 11:00-16:00, 16:00-21:00, 21:00-0:00, 0:00-6:00
    final updateTimes = [
      _cacheUpdateStartHour, // 6:00
      _cacheUpdateStartHour + 5, // 11:00
      _cacheUpdateStartHour + 10, // 16:00
      _cacheUpdateStartHour + 15, // 21:00
      0, // 0:00 следующего дня
    ];
    
    // Находим период, в котором был создан кэш
    int cachePeriod = -1;
    final cacheHour = cacheTime.hour;
    
    for (int i = 0; i < updateTimes.length; i++) {
      final startHour = updateTimes[i];
      final endHour = i < updateTimes.length - 1 ? updateTimes[i + 1] : updateTimes[0];
      
      if (endHour > startHour) {
        // Обычный период в пределах одного дня
        if (cacheHour >= startHour && cacheHour < endHour) {
          cachePeriod = i;
          break;
        }
      } else {
        // Период, переходящий через полночь (21:00-0:00)
        if (cacheHour >= startHour || cacheHour < endHour) {
          cachePeriod = i;
          break;
        }
      }
    }
    
    if (cachePeriod == -1) {
      // Если не нашли период, обновляем
      return true;
    }
    
    // Определяем время следующего обновления
    final nextPeriodIndex = (cachePeriod + 1) % updateTimes.length;
    final nextUpdateHour = updateTimes[nextPeriodIndex];
    
    // Вычисляем время следующего обновления
    DateTime nextUpdateTime;
    if (nextPeriodIndex == 0) {
      // Следующее обновление - на следующий день в 6:00
      nextUpdateTime = DateTime(
        cacheTime.year,
        cacheTime.month,
        cacheTime.day + 1,
        nextUpdateHour,
        0,
      );
    } else if (nextUpdateHour < updateTimes[cachePeriod]) {
      // Период переходит через полночь
      nextUpdateTime = DateTime(
        cacheTime.year,
        cacheTime.month,
        cacheTime.day + 1,
        nextUpdateHour,
        0,
      );
    } else {
      // Обычный период в том же дне
      nextUpdateTime = DateTime(
        cacheTime.year,
        cacheTime.month,
        cacheTime.day,
        nextUpdateHour,
        0,
      );
    }
    
    // Если текущее время прошло время следующего обновления, обновляем
    return now.isAfter(nextUpdateTime) || now.isAtSameMomentAs(nextUpdateTime);
  }
}
