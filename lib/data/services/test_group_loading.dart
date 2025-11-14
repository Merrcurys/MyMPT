import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки загрузки групп в репозитории
void main() async {
  print('=== Тест загрузки групп в репозитории ===');
  
  try {
    final repository = MptRepository();
    
    // Пробуем загрузить группы для разных специальностей
    final testSpecialties = [
      '09.02.01 Э',
      '09.02.07 П,Т',
      '09.02.07 ИС, БД, ВД',
      'Э-1-22',
      'Т-1-24'
    ];
    
    for (var specialty in testSpecialties) {
      print('\nТестируем загрузку групп для специальности: $specialty');
      final groups = await repository.getGroupsBySpecialty(specialty);
      print('  Найдено групп: ${groups.length}');
      
      if (groups.isNotEmpty) {
        print('  Первые 5 групп:');
        for (int i = 0; i < groups.length && i < 5; i++) {
          print('    ${groups[i].code}');
        }
      } else {
        print('  Группы не найдены');
      }
    }
    
    print('\n✅ Тест завершен!');
    
  } catch (e, stackTrace) {
    print('❌ Ошибка в тесте: $e');
    print('Stack trace: $stackTrace');
  }
}