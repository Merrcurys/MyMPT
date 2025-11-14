import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Тест для проверки извлечения информации о неделе
void main() async {
  print('Тестируем извлечение информации о неделе...');
  
  final parser = MptParserService();
  
  try {
    final weekInfo = await parser.parseWeekInfo();
    
    print('Информация о неделе:');
    print('  Тип недели: "${weekInfo.weekType}"');
    print('  Дата: "${weekInfo.date}"');
    print('  День: "${weekInfo.day}"');
    
    if (weekInfo.weekType.isNotEmpty) {
      print('\n✅ Тип недели успешно извлечен!');
    } else {
      print('\n⚠️  Не удалось извлечь тип недели');
    }
    
    if (weekInfo.date.isNotEmpty) {
      print('✅ Дата успешно извлечена!');
    } else {
      print('⚠️  Не удалось извлечь дату');
    }
    
    if (weekInfo.day.isNotEmpty) {
      print('✅ День успешно извлечен!');
    } else {
      print('⚠️  Не удалось извлечь день');
    }
    
  } catch (e) {
    print('Ошибка при тестировании: $e');
  }
}