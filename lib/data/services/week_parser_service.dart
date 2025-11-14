import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:my_mpt/data/models/week_info.dart';

class WeekParserService {
  final String baseUrl = 'https://mpt.ru/raspisanie/';

  /// Parses the MPT schedule page and extracts week information
  /// including week type (numerator/denominator), date and day
  Future<WeekInfo> parseWeekInfo() async {
    try {
      // Fetch the HTML content from the website
      final response = await http.get(Uri.parse(baseUrl));
      
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
}