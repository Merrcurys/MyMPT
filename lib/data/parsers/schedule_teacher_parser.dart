import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:my_mpt/data/models/lesson.dart';

class ScheduleTeacherParser {
  Map<String, List<Lesson>> parse(String html, String teacherName) {
    if (teacherName.isEmpty) return {};

    final document = html_parser.parse(html);
    final schedule = <String, List<Lesson>>{};

    final teacherNameParts = teacherName.split(' ');
    final lastName = teacherNameParts.last.toLowerCase();
    final initials = teacherNameParts.sublist(0, teacherNameParts.length - 1).join(' ').toLowerCase();

    final tabPanels = document.querySelectorAll('[role="tabpanel"]');
    
    // Создаем карту соответствия id вкладки -> Название группы
    final Map<String, String> idToGroup = {};
    final tabLinks = document.querySelectorAll('ul.nav-tabs > li > a[href^="#"]');
    for (var link in tabLinks) {
       final href = link.attributes['href'];
       if (href != null && href.startsWith('#')) {
          final tabId = href.substring(1);
          // Берем текст из вкладки (обычно там как раз группа, например П50-1-23)
          idToGroup[tabId] = _extractGroup(link.text.trim());
       }
    }

    for (var tabPanel in tabPanels) {
      final tabId = tabPanel.attributes['id'];
      
      // Получаем название группы из вкладки. Специально не берем специальность из h2, 
      // чтобы избежать длинных названий типа "09.02.07 Информационные системы..."
      String currentGroup = tabId != null ? (idToGroup[tabId] ?? '') : '';

      // Резервный вариант, если вкладки вдруг нет - попытаться вытащить именно группу из h2,
      // но отрезав всё лишнее
      if (currentGroup.isEmpty) {
        final h2Headers = tabPanel.querySelectorAll('h2');
        for (var h2 in h2Headers) {
          final text = h2.text.trim();
          if (text.startsWith('Расписание занятий для')) {
            final fullText = text.replaceFirst('Расписание занятий для', '').trim();
            currentGroup = _extractGroup(fullText);
            break;
          }
        }
      }

      final tables = tabPanel.querySelectorAll('table.table');

      for (var table in tables) {
        final thead = table.querySelector('thead');
        if (thead == null) continue;

        final h4 = thead.querySelector('h4');
        if (h4 == null) continue;

        String rawDay = h4.nodes.first.text?.trim() ?? '';
        final day = rawDay.toUpperCase();
        if (day.isEmpty) continue;

        final rows = table.querySelectorAll('tbody tr');
        final iterRows = rows.isNotEmpty ? rows : table.querySelectorAll('tr');

        for (var row in iterRows) {
          if (row.querySelectorAll('th').isNotEmpty) continue;
          final cols = row.querySelectorAll('td');
          if (cols.length < 3) continue;

          final numberTimeText = cols[0].text;
          final numberMatch = RegExp(r'\d+').firstMatch(numberTimeText);
          final number = numberMatch?.group(0) ?? '';

          final timeMatch = RegExp(r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})').firstMatch(numberTimeText);
          final startTime = timeMatch?.group(1) ?? '';
          final endTime = timeMatch?.group(2) ?? '';

          final subjectCell = cols[1];
          final teacherCell = cols[2];

          final subjectLabels = subjectCell.querySelectorAll('div.label');
          final teacherLabels = teacherCell.querySelectorAll('div.label');

          if (subjectLabels.isEmpty || teacherLabels.isEmpty) {
            final cellTeacherText = teacherCell.text.toLowerCase();
            if (_isTeacherMatch(cellTeacherText, lastName, initials)) {
               final building = h4.querySelector('span')?.text.trim() ?? '';
               final subject = subjectCell.text.trim();

               if (!schedule.containsKey(day)) schedule[day] = [];
               schedule[day]!.add(Lesson(
                 number: number,
                 subject: subject,
                 teacher: currentGroup,
                 startTime: startTime,
                 endTime: endTime,
                 building: building,
                 lessonType: null
               ));
            }
          } else {
             final count = _pairedLabelsCount(subjectLabels, teacherLabels);
             for (var i = 0; i < count; i++) {
                final cellTeacherText = teacherLabels[i].text.toLowerCase();
                if (_isTeacherMatch(cellTeacherText, lastName, initials)) {
                   final building = h4.querySelector('span')?.text.trim() ?? '';
                   final subject = subjectLabels[i].text.trim();
                   final lessonType = _resolveLessonType(subjectLabels[i]);
                   
                   if (!schedule.containsKey(day)) schedule[day] = [];
                   schedule[day]!.add(Lesson(
                     number: number,
                     subject: subject,
                     teacher: currentGroup, // Сохраняем группу
                     startTime: startTime,
                     endTime: endTime,
                     building: building,
                     lessonType: lessonType
                   ));
                }
             }
          }
        }
      }
    }
    
    return _mergeTeacherLessons(schedule);
  }

  /// Пытается вытащить только название группы (например, П50-1-23),
  /// отбрасывая длинные названия специальностей.
  String _extractGroup(String rawText) {
    // Ищем паттерн группы: БуквыЦифры-Цифра-Цифры (например П50-1-23, ИСП-2-22, Р21-1)
    // Поддерживает различные форматы групп МПТ
    final groupRegex = RegExp(r'[А-Яа-яЁёA-Za-z0-9]+-\d+(?:-\d+)?');
    final match = groupRegex.firstMatch(rawText);
    
    if (match != null) {
      return match.group(0)!; // Возвращаем только саму группу
    }
    
    // Если регулярка не нашла группу, просто берем первое слово 
    // (обычно специальность идет дальше после пробелов/скобок)
    // но если строка короткая (<15 символов), возвращаем целиком
    if (rawText.length < 15) {
      return rawText;
    }
    
    return rawText.split(' ').first;
  }

  bool _isTeacherMatch(String cellText, String lastName, String initials) {
    // 1. Поиск точного совпадения фамилии (с границами)
    // Используем [^а-яёa-z] чтобы исключить совпадения внутри других слов
    final nameRegex = RegExp(r'(^|\s|[^а-яёa-z])' + RegExp.escape(lastName) + r'($|\s|[^а-яёa-z])', caseSensitive: false);
    
    if (!nameRegex.hasMatch(cellText)) {
      return false; // Фамилии нет — точно не он
    }

    final cleanInitials = initials.replaceAll(' ', '');
    
    // Если у искомого преподавателя нет инициалов (маловероятно, но бывает), 
    // считаем, что совпало по фамилии.
    if (cleanInitials.isEmpty) return true;

    // Если в ячейке вообще нет инициалов (например просто "Иванов" без И.И.),
    // будем считать совпадением, так как фамилия совпала и нет противоречащих инициалов.
    if (!cellText.contains('.')) return true;

    // Иначе проверяем, содержатся ли именно нужные инициалы в тексте ячейки.
    return cellText.replaceAll(' ', '').contains(cleanInitials);
  }

  int _pairedLabelsCount(List<Element> subjects, List<Element> teachers) {
    if (subjects.isEmpty || teachers.isEmpty) return 0;
    return subjects.length < teachers.length ? subjects.length : teachers.length;
  }

  String? _resolveLessonType(Element label) {
    final classes = label.attributes['class'] ?? '';
    if (classes.contains('label-danger')) return 'numerator';
    if (classes.contains('label-info')) return 'denominator';
    return null;
  }

  Map<String, List<Lesson>> _mergeTeacherLessons(Map<String, List<Lesson>> rawSchedule) {
     final result = <String, List<Lesson>>{};
     
     rawSchedule.forEach((day, lessons) {
        final Map<String, Lesson> merged = {};
        for (var lesson in lessons) {
           final key = '${lesson.number}_${lesson.lessonType ?? "all"}';
           if (merged.containsKey(key)) {
              final existing = merged[key]!;
              final newGroup = existing.teacher == null || existing.teacher!.isEmpty 
                  ? (lesson.teacher ?? '') 
                  // Если группа уже есть в строке, не дублируем её
                  : (existing.teacher!.contains(lesson.teacher ?? '') 
                      ? existing.teacher 
                      : '${existing.teacher}, ${lesson.teacher ?? ''}');
                  
              merged[key] = Lesson(
                  number: existing.number,
                  subject: existing.subject,
                  teacher: newGroup,
                  startTime: existing.startTime,
                  endTime: existing.endTime,
                  building: existing.building,
                  lessonType: existing.lessonType
              );
           } else {
              merged[key] = lesson;
           }
        }
        result[day] = merged.values.toList()..sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
     });
     
     return _sortDays(result);
  }

  Map<String, List<Lesson>> _sortDays(Map<String, List<Lesson>> schedule) {
    const daysOrder = {
      'ПОНЕДЕЛЬНИК': 1,
      'ВТОРНИК': 2,
      'СРЕДА': 3,
      'ЧЕТВЕРГ': 4,
      'ПЯТНИЦА': 5,
      'СУББОТА': 6,
      'ВОСКРЕСЕНЬЕ': 7,
    };

    final sortedKeys = schedule.keys.toList()..sort((a, b) {
      final orderA = daysOrder[a] ?? 99;
      final orderB = daysOrder[b] ?? 99;
      return orderA.compareTo(orderB);
    });

    final sortedSchedule = <String, List<Lesson>>{};
    for (final key in sortedKeys) {
      sortedSchedule[key] = schedule[key]!;
    }

    return sortedSchedule;
  }
}
