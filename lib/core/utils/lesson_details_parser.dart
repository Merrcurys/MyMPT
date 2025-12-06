/// Вспомогательная структура данных для деталей занятия
class LessonDetails {
  /// Название предмета
  final String subject;

  /// Имя преподавателя
  final String teacher;

  /// Специальное окончание (например, "НЕЖИНСКАЯ" или "НАХИМОВСКИЙ")
  final String specialEnding;

  const LessonDetails({
    required this.subject,
    required this.teacher,
    this.specialEnding = '',
  });

  /// Проверяет, есть ли данные для отображения
  bool get hasData => subject.isNotEmpty || teacher.isNotEmpty;
}

/// Парсит строку с информацией о занятии в детали предмета и преподавателя
LessonDetails parseLessonDetails(String raw) {
  final sanitized = raw.replaceAll('\u00A0', ' ').replaceAll('\r', '').trim();
  if (sanitized.isEmpty) {
    return const LessonDetails(subject: '', teacher: '');
  }

  var working = sanitized;
  String specialEnding = '';

  // Проверяем наличие специальных окончаний в конце строки
  final specialEndingRegex = RegExp(r'\s*\((НЕЖИНСКАЯ|НАХИМОВСКИЙ)\)\s*$');
  final specialEndingMatch = specialEndingRegex.firstMatch(working);
  if (specialEndingMatch != null) {
    specialEnding = specialEndingMatch.group(1)!;
    // Удаляем найденное окончание из строки для дальнейшей обработки
    working = working.substring(0, specialEndingMatch.start).trimRight();
  } else {
    // Проверяем другие скобки в конце строки
    final trailingNoteMatch = RegExp(
      r'\s*\(([^()]+)\)\s*$',
    ).firstMatch(working);
    if (trailingNoteMatch != null) {
      working = working.substring(0, trailingNoteMatch.start).trimRight();
    }
  }

  final newlineParts = working
      .split(RegExp(r'[\n]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (newlineParts.length >= 2) {
    return LessonDetails(
      subject:
          newlineParts.first +
          (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
      teacher: newlineParts.sublist(1).join(' '),
      specialEnding: specialEnding,
    );
  }

  final multipleSpaceParts = working
      .split(RegExp(r'\s{2,}'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (multipleSpaceParts.length >= 2) {
    return LessonDetails(
      subject:
          multipleSpaceParts.first +
          (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
      teacher: multipleSpaceParts.sublist(1).join(' '),
      specialEnding: specialEnding,
    );
  }

  final dashParts = working.split(RegExp(r'\s[-–—]\s'));
  if (dashParts.length == 2) {
    return LessonDetails(
      subject:
          dashParts.first.trim() +
          (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
      teacher: dashParts.last.trim(),
      specialEnding: specialEnding,
    );
  }

  final parenthesisRegExp = RegExp(r'(.+?)\s*\(([^)]+)\)$');
  final parenthesisMatch = parenthesisRegExp.firstMatch(working);
  if (parenthesisMatch != null) {
    return LessonDetails(
      subject:
          parenthesisMatch.group(1)!.trim() +
          (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
      teacher: parenthesisMatch.group(2)!.trim(),
      specialEnding: specialEnding,
    );
  }

  // Проверяем, содержит ли строка запятую вне скобок
  final RegExp teacherSeparatorRegExp = RegExp(r'^(.+?)\s+([А-ЯA-Z]\.[А-ЯA-Z]\.?\s+[А-Яа-яA-Za-z-]+(?:,\s*[А-ЯA-Z]\.[А-ЯA-Z]\.?\s*[А-Яа-яA-Za-z-]+)*)$');
  final teacherSeparatorMatch = teacherSeparatorRegExp.firstMatch(working);
  if (teacherSeparatorMatch != null) {
    return LessonDetails(
      subject:
          teacherSeparatorMatch.group(1)!.trim() +
          (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
      teacher: teacherSeparatorMatch.group(2)!.trim(),
      specialEnding: specialEnding,
    );
  }

  return LessonDetails(
    subject: working + (specialEnding.isNotEmpty ? ' ($specialEnding)' : ''),
    teacher: '',
    specialEnding: specialEnding,
  );
}
