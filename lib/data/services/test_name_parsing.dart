import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Тест для проверки извлечения названий специальностей
void main() async {
  print('Тестируем извлечение названий специальностей...');
  
  final parser = MptParserService();
  
  try {
    final tabs = await parser.parseTabList();
    
    print('Найдено ${tabs.length} специальностей:');
    for (var tab in tabs) {
      print('  Название: "${tab.name}" (href: ${tab.href})');
    }
    
    // Проверим, что все записи имеют названия
    int emptyNames = 0;
    for (var tab in tabs) {
      if (tab.name.isEmpty) {
        emptyNames++;
      }
    }
    
    print('\nРезультаты проверки:');
    print('  Всего специальностей: ${tabs.length}');
    print('  С пустыми названиями: $emptyNames');
    print('  С непустыми названиями: ${tabs.length - emptyNames}');
    
    if (emptyNames == 0) {
      print('\n✅ Все специальности имеют названия!');
    } else {
      print('\n⚠️  Некоторые специальности не имеют названий');
    }
    
  } catch (e) {
    print('Ошибка при тестировании: $e');
  }
}