import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/group_repository.dart';

/// Тест для проверки работы парсера групп
void main() async {
  print('Тестируем парсер групп...');
  
  // Создаем экземпляр парсера
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
    
    // Тестируем репозиторий
    print('\nТестируем репозиторий групп...');
    final repository = GroupRepository();
    final allGroups = await repository.getAllGroups();
    
    print('Всего групп в репозитории: ${allGroups.length}');
    
    // Пример фильтрации по специальности
    if (allGroups.isNotEmpty) {
      final firstSpecialty = allGroups.first.specialtyCode;
      print('\nФильтруем группы по специальности: $firstSpecialty');
      final filteredGroups = await repository.getGroupsBySpecialty(firstSpecialty);
      print('Найдено ${filteredGroups.length} групп для специальности $firstSpecialty');
      
      for (var group in filteredGroups) {
        print('  ${group.code}');
      }
    }
    
    print('\nТест завершен успешно!');
  } catch (e) {
    print('Ошибка при тестировании: $e');
  }
}