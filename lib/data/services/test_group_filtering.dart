import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Тест для проверки фильтрации групп по специальностям
void main() async {
  print('=== Тест фильтрации групп по специальностям ===');
  
  try {
    final parser = MptParserService();
    
    print('Получаем все группы...');
    final allGroups = await parser.parseGroups();
    print('Всего найдено групп: ${allGroups.length}');
    
    if (allGroups.isNotEmpty) {
      print('\nВсе группы:');
      for (int i = 0; i < allGroups.length; i++) {
        print('  ${allGroups[i].code} (специальность: "${allGroups[i].specialtyCode}")');
      }
      
      // Проверим фильтрацию по разным специальностям
      final testSpecialties = [
        '09.02.01 Э',
        '09.02.07 П,Т',
        '09.02.07 ИС, БД, ВД',
        'Э',
        'Т',
        'П'
      ];
      
      for (var specialty in testSpecialties) {
        print('\nФильтруем по специальности: "$specialty"');
        final filteredGroups = allGroups.where((group) => 
          group.specialtyCode.contains(specialty) || 
          group.specialtyName.contains(specialty)
        ).toList();
        
        print('  Найдено групп: ${filteredGroups.length}');
        if (filteredGroups.isNotEmpty) {
          print('  Первые 3 группы:');
          for (int i = 0; i < filteredGroups.length && i < 3; i++) {
            print('    ${filteredGroups[i].code}');
          }
        }
      }
    } else {
      print('Не найдено ни одной группы');
    }
    
    print('\n✅ Тест фильтрации завершен!');
    
  } catch (e, stackTrace) {
    print('❌ Ошибка в тесте фильтрации: $e');
    print('Stack trace: $stackTrace');
  }
}