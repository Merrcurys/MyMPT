import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/week_info.dart';

class WeekParserService {
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  Future<WeekInfo> parseWeekInfo() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
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
        throw Exception('Ошибка загрузки страницы: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при парсинге данных: $e');
    }
  }
}