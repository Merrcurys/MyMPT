import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Тест для проверки получения групп по специальностям
void main() async {
  print('Тестируем получение групп по специальностям...');
  
  final parser = MptParserService();
  
  try {
    // Получаем все группы
    final allGroups = await parser.parseGroups();
    print('Всего найдено групп: ${allGroups.length}');
    
    // Группируем группы по специальностям
    final groupsBySpecialty = <String, List<String>>{};
    
    for (var group in allGroups) {
      final specialty = group.specialtyCode;
      if (!groupsBySpecialty.containsKey(specialty)) {
        groupsBySpecialty[specialty] = [];
      }
      groupsBySpecialty[specialty]!.add(group.code);
    }
    
    // Выводим группы по специальностям
    print('\nГруппы по специальностям:');
    groupsBySpecialty.forEach((specialty, groups) {
      print('Специальность: $specialty');
      for (var group in groups) {
        print('  - $group');
      }
      print('');
    });
    
    // Пример фильтрации по конкретной специальности
    if (allGroups.isNotEmpty) {
      final sampleSpecialty = allGroups.first.specialtyCode;
      print('Пример фильтрации по специальности: $sampleSpecialty');
      
      final filteredGroups = allGroups.where((group) => 
        group.specialtyCode.contains(sampleSpecialty)
      ).toList();
      
      print('Найдено ${filteredGroups.length} групп для специальности $sampleSpecialty:');
      for (var group in filteredGroups) {
        print('  ${group.code}');
      }
    }
    
    print('\n✅ Тест успешно завершен!');
    
  } catch (e) {
    print('❌ Ошибка при тестировании: $e');
  }
}