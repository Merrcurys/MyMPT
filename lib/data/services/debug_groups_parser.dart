import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Отладочный тест для проверки работы парсера групп
void main() async {
  print('Запуск отладочного теста парсера групп...');
  
  final parser = MptParserService();
  
  try {
    print('Получаем информацию о группах с сайта...');
    final groups = await parser.parseGroups();
    
    print('Найдено ${groups.length} групп:');
    for (var group in groups) {
      print('  Группа: ${group.code}');
      print('    Специальность: ${group.specialtyCode}');
      print('    Название специальности: ${group.specialtyName}');
    }
    
    // Проверим фильтрацию по конкретной специальности
    if (groups.isNotEmpty) {
      final sampleSpecialty = groups.first.specialtyCode;
      print('\nФильтрация по специальности: $sampleSpecialty');
      
      final filteredGroups = groups.where((group) => 
        group.specialtyCode.contains(sampleSpecialty)
      ).toList();
      
      print('Найдено ${filteredGroups.length} групп для специальности $sampleSpecialty:');
      for (var group in filteredGroups) {
        print('  ${group.code}');
      }
    }
    
    print('\n✅ Отладочный тест успешно завершен!');
    
  } catch (e) {
    print('❌ Ошибка при отладочном тестировании: $e');
  }
}