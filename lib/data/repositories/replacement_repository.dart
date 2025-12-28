import 'package:my_mpt/data/datasources/remote/replacement_remote_datasource.dart';
import 'package:my_mpt/domain/entities/replacement.dart';
import 'package:my_mpt/domain/repositories/replacement_repository_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_mpt/core/services/notification_service.dart';

class ReplacementRepository implements ReplacementRepositoryInterface {
  final ReplacementRemoteDatasource _changesService =
      ReplacementRemoteDatasource();

  static const String _selectedGroupKey = 'selected_group';

  /// Получить замены в расписании для конкретной группы
  @override
  Future<List<Replacement>> getScheduleChanges() async {
    try {
      // Здесь нужно получить выбранную группу из настроек
      final groupCode = await _getSelectedGroupCode();

      if (groupCode.isEmpty) {
        return [];
      }

      final changes = await _changesService.parseScheduleChangesForGroup(
        groupCode,
      );

      // Преобразуем модели замен в сущности замен
      final replacementEntities = changes.map((change) {
        return Replacement(
          lessonNumber: change.lessonNumber,
          replaceFrom: change.replaceFrom,
          replaceTo: change.replaceTo,
          updatedAt: change.updatedAt,
          changeDate: change.changeDate,
        );
      }).toList();

      // Check for new replacements and show notifications
      await NotificationService().checkForNewReplacements(replacementEntities);
      
      // Count new replacements and show notification if needed
      final prefs = await SharedPreferences.getInstance();
      final storedReplacementsJson = prefs.getStringList(_lastCheckedKey) ?? [];
      final storedReplacements = _deserializeReplacements(storedReplacementsJson);
      
      // Find new replacements
      final newReplacements = _findNewReplacements(storedReplacements, replacementEntities);
      
      if (newReplacements.isNotEmpty) {
        await NotificationService().showNewReplacementsNotification(newReplacements.length);
      }
      
      // Update stored replacements
      await prefs.setStringList(_lastCheckedKey, _serializeReplacements(replacementEntities));
      
      return replacementEntities;
    } catch (e) {
      return [];
    }
  }

  /// Получает код выбранной группы из настроек или из переменной окружения
  Future<String> _getSelectedGroupCode() async {
    try {
      // Проверяем переменную окружения first
      const envGroup = String.fromEnvironment('SELECTED_GROUP');
      if (envGroup.isNotEmpty) {
        return envGroup;
      }

      // Если переменная окружения не задана, используем SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedGroupKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  static const String _lastCheckedKey = 'last_checked_replacements';

  List<Replacement> _deserializeReplacements(List<String> jsonList) {
    return jsonList.map((json) {
      final parts = json.split('|');
      if (parts.length >= 5) {
        return Replacement(
          lessonNumber: parts[0],
          replaceFrom: parts[1],
          replaceTo: parts[2],
          updatedAt: parts[3],
          changeDate: parts[4],
        );
      }
      return Replacement(lessonNumber: '', replaceFrom: '', replaceTo: '', updatedAt: '', changeDate: '');
    }).toList();
  }

  List<String> _serializeReplacements(List<Replacement> replacements) {
    return replacements.map((replacement) {
      return '${replacement.lessonNumber}|${replacement.replaceFrom}|${replacement.replaceTo}|${replacement.updatedAt}|${replacement.changeDate}';
    }).toList();
  }

  List<Replacement> _findNewReplacements(List<Replacement> oldReplacements, List<Replacement> newReplacements) {
    return newReplacements.where((newReplacement) {
      return !oldReplacements.any((oldReplacement) => 
        oldReplacement.lessonNumber == newReplacement.lessonNumber &&
        oldReplacement.replaceFrom == newReplacement.replaceFrom &&
        oldReplacement.replaceTo == newReplacement.replaceTo &&
        oldReplacement.updatedAt == newReplacement.updatedAt &&
        oldReplacement.changeDate == newReplacement.changeDate
      );
    }).toList();
  }
}
