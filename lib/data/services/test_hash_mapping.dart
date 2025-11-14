import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки маппинга хешей в коды специальностей
void main() async {
  print('=== Тест маппинга хешей в коды специальностей ===');
  
  try {
    final repository = MptRepository();
    
    // Тестируем различные хеши специальностей
    final testHashes = [
      '#specialty-09-02-01-e',
      '#specialty-09-02-07-p-t',
      '#specialty-09-02-07-is-bd-vd',
      '#5a2462f4f2cdc10da3e787189fa33a1c' // Пример хеша из логов
    ];
    
    for (var hash in testHashes) {
      print('\nТестируем хеш: $hash');
      final groups = await repository.getGroupsBySpecialty(hash);
      print('  Найдено групп: ${groups.length}');
      
      if (groups.isNotEmpty) {
        print('  Первые 3 группы:');
        for (int i = 0; i < groups.length && i < 3; i++) {
          print('    ${groups[i].code}');
        }
      }
    }
    
    print('\n=== Тест завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
  }
}