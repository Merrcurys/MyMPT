import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

/// Подробный тест парсера групп для диагностики проблемы
void main() async {
  print('=== Подробная диагностика парсера групп ===');
  final baseUrl = 'https://mpt.ru/raspisanie/';
  
  try {
    print('\n1. Выполняем HTTP запрос...');
    final startTime = DateTime.now();
    
    final response = await http.get(Uri.parse(baseUrl)).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Request timeout after 15 seconds');
      },
    );
    
    final endTime = DateTime.now();
    print('   Статус ответа: ${response.statusCode}');
    print('   Время запроса: ${endTime.difference(startTime).inMilliseconds} мс');
    print('   Размер ответа: ${response.body.length} символов');
    
    if (response.statusCode != 200) {
      print('   ❌ Ошибка HTTP: ${response.statusCode}');
      return;
    }
    
    print('\n2. Парсим HTML документ...');
    final parseStartTime = DateTime.now();
    final document = parser.parse(response.body);
    final parseEndTime = DateTime.now();
    print('   Время парсинга: ${parseEndTime.difference(parseStartTime).inMilliseconds} мс');
    
    print('\n3. Ищем элементы с информацией о группах...');
    
    // Проверим разные селекторы
    print('   Ищем h3 элементы...');
    final h3Headers = document.querySelectorAll('h3');
    print('   Найдено h3 элементов: ${h3Headers.length}');
    
    print('   Ищем h4 элементы...');
    final h4Headers = document.querySelectorAll('h4');
    print('   Найдено h4 элементов: ${h4Headers.length}');
    
    print('   Ищем элементы с текстом "Группа"...');
    int groupHeadersCount = 0;
    final List<Element> groupHeaders = [];
    
    // Проверим h3 элементы
    for (var header in h3Headers) {
      final text = header.text.trim();
      if (text.startsWith('Группа ')) {
        groupHeadersCount++;
        groupHeaders.add(header);
        print('     Найден h3: "$text"');
      }
    }
    
    // Проверим h4 элементы
    for (var header in h4Headers) {
      final text = header.text.trim();
      if (text.startsWith('Группа ')) {
        groupHeadersCount++;
        groupHeaders.add(header);
        print('     Найден h4: "$text"');
      }
    }
    
    print('   Всего найдено заголовков групп: $groupHeadersCount');
    
    if (groupHeadersCount > 0) {
      print('\n4. Анализируем найденные заголовки групп...');
      for (int i = 0; i < groupHeaders.length && i < 3; i++) {
        final header = groupHeaders[i];
        final text = header.text.trim();
        print('   Заголовок $i: "$text"');
        
        // Попробуем извлечь код группы
        if (text.startsWith('Группа ')) {
          final groupCode = text.substring(7).trim();
          print('     Код группы: "$groupCode"');
          
          // Разделим по разделителям
          final separators = [',', ';', '/'];
          for (var sep in separators) {
            if (groupCode.contains(sep)) {
              final parts = groupCode.split(sep);
              print('     Разделены по "$sep": ${parts.map((p) => '"${p.trim()}"').toList()}');
            }
          }
        }
      }
    } else {
      print('   ⚠️  Не найдено заголовков групп. Проверяем структуру страницы...');
      
      // Покажем фрагмент HTML для анализа
      print('\n5. Фрагмент HTML для анализа (первые 2000 символов):');
      final bodyFragment = response.body.substring(0, response.body.length > 2000 ? 2000 : response.body.length);
      print(bodyFragment);
    }
    
    print('\n✅ Подробная диагностика завершена!');
    
  } catch (e, stackTrace) {
    print('❌ Ошибка при диагностике: $e');
    print('Stack trace: $stackTrace');
  }
}