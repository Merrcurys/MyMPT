import 'package:my_mpt/data/repositories/specialty_repository.dart';
import 'package:my_mpt/data/repositories/group_repository.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';

/// Фабрика репозиториев для координации работы между репозиториями специальностей и групп
class RepositoryFactory {
  static final RepositoryFactory _instance = RepositoryFactory._internal();

  late final SpecialtyRepositoryInterface _specialtyRepository;
  late final GroupRepositoryInterface _groupRepository;

  factory RepositoryFactory() {
    return _instance;
  }

  RepositoryFactory._internal() {
    _specialtyRepository = SpecialtyRepository();
    _groupRepository = GroupRepository();
  }

  /// Получить репозиторий специальностей
  SpecialtyRepositoryInterface get specialtyRepository => _specialtyRepository;

  /// Получить репозиторий групп
  GroupRepositoryInterface get groupRepository => _groupRepository;
}
