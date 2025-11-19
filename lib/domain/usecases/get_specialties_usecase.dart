import 'package:my_mpt/domain/entities/specialty.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';

/// Получение списка специальностей
///
/// Этот класс реализует бизнес-логику для получения списка специальностей
/// с использованием репозитория специальностей
class GetSpecialtiesUseCase {
  /// Репозиторий для работы со специальностями
  final SpecialtyRepositoryInterface repository;

  /// Конструктор use case для получения списка специальностей
  ///
  /// Параметры:
  /// - [repository]: Репозиторий специальностей
  GetSpecialtiesUseCase(this.repository);

  /// Выполнить получение списка специальностей
  ///
  /// Метод делегирует выполнение получения списка специальностей
  /// репозиторию специальностей
  ///
  /// Возвращает:
  /// - Future<List<Specialty>>: Список специальностей
  Future<List<Specialty>> call() async {
    return await repository.getSpecialties();
  }
}
