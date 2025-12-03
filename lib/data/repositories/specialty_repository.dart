import 'package:my_mpt/data/datasources/remote/speciality_remote_datasource.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/entities/specialty.dart';

class SpecialtyRepository implements SpecialtyRepositoryInterface {
  final SpecialityRemoteDatasource _parserService =
      SpecialityRemoteDatasource();

  // Кэш для специальностей
  List<Specialty>? _cachedSpecialties;
  Map<String, String>? _codeToNameCache;

  @override
  Future<List<Specialty>> getSpecialties() async {
    try {
      // Используем кэш, если он есть
      if (_cachedSpecialties != null) {
        return _cachedSpecialties!;
      }

      final tabs = await _parserService.parseTabList();
      final specialties = tabs
          .map((tab) => _createSpecialtyFromTab(tab))
          .toList();

      specialties.sort((a, b) => a.name.compareTo(b.name));

      // Сохраняем в кэш
      _cachedSpecialties = specialties;
      _codeToNameCache = {for (var s in specialties) s.code: s.name};

      return specialties;
    } catch (e) {
      return [];
    }
  }

  Specialty _createSpecialtyFromTab(Map<String, String> tab) {
    String code = tab['href'] ?? '';
    if (code.startsWith('#specialty-')) {
      code = code
          .substring(11)
          .toUpperCase()
          .replaceAll('-', '.')
          .replaceAll('E', 'Э');
    }

    String name = tab['name'] ?? '';
    if (name.isEmpty) {
      name = tab['ariaControls'] ?? '';
    }

    return Specialty(code: code, name: name);
  }

  // Метод для получения имени специальности по коду из кэша
  String? getSpecialtyNameByCode(String code) {
    return _codeToNameCache?[code];
  }
}
