import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки маппинга групп к специальностям
void main() async {
  print('=== Тест маппинга групп к специальностям ===');
  
  try {
    final parser = MptParserService();
    final repository = MptRepository();
    
    // Получаем все группы
    print('\n1. Получаем все группы...');
    final allGroups = await parser.parseGroups();
    print('   Всего групп: ${allGroups.length}');
    
    if (allGroups.isNotEmpty) {
      print('\n2. Список групп с их специальностями:');
      for (int i = 0; i < allGroups.length && i < 10; i++) {
        print('   ${allGroups[i].code} -> ${allGroups[i].specialtyCode}');
      }
      
      // Получаем список специальностей
      print('\n3. Получаем список специальностей...');
      final specialties = await repository.getSpecialties();
      print('   Всего специальностей: ${specialties.length}');
      
      if (specialties.isNotEmpty) {
        print('\n4. Список специальностей:');
        for (int i = 0; i < specialties.length; i++) {
          print('   ${specialties[i].code} - ${specialties[i].name}');
        }
        
        // Пробуем фильтровать группы по первой специальности
        final firstSpecialty = specialties.first;
        print('\n5. Фильтруем группы по первой специальности:');
        print('   Специальность: ${firstSpecialty.code} - ${firstSpecialty.name}');
        
        final filteredGroups = await repository.getGroupsBySpecialty(firstSpecialty.code);
        print('   Найдено групп: ${filteredGroups.length}');
        
        if (filteredGroups.isNotEmpty) {
          print('   Первые 5 отфильтрованных групп:');
          for (int i = 0; i < filteredGroups.length && i < 5; i++) {
            print('     ${filteredGroups[i].code}');
          }
        }
      }
    }
    
    print('\n=== Тест завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
  }
}