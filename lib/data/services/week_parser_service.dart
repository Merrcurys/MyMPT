import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:my_mpt/data/models/week_info.dart';

/// Сервис для парсинга информации о текущей неделе с сайта МПТ
///
/// Этот сервис отвечает за извлечение информации о типе текущей недели
/// (числитель или знаменатель) с официального сайта техникума
class WeekParserService {
  /// Базовый URL сайта с расписанием
  final String baseUrl = 'https://mpt.ru/raspisanie/';

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
      final response = await http.get(Uri.parse(baseUrl));

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
          // Проверяем, начинается ли текст с "Неделя:"
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
        throw Exception('Ошибка загрузки страницы: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при парсинге данных: $e');
    }
  }
}
