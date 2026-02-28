import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:my_mpt/data/models/teacher.dart';

class TeacherParser {
  List<Teacher> parse(String html) {
    final document = html_parser.parse(html);
    final Set<String> result = {};
    final List<Teacher> teachers = [];

    // Регекс для поиска ФИО (ищем хотя бы один шаблон И.О. Фамилия)
    final fioRegex = RegExp(r'[А-ЯЁA-Z]\.[А-ЯЁA-Z]\.\s?[А-ЯЁа-яёA-Za-z\-]+');

    final tables = document.querySelectorAll('table');

    for (var table in tables) {
      int teacherIndex = _findTeacherColumnIndex(table);

      final rows = table.querySelectorAll('tbody tr');
      final iterRows = rows.isNotEmpty ? rows : table.querySelectorAll('tr');

      for (var row in iterRows) {
        if (row.querySelectorAll('th').isNotEmpty) continue;

        final cols = row.querySelectorAll('td');
        if (cols.isEmpty) continue;

        Element teacherCell;
        if (teacherIndex >= 0 && teacherIndex < cols.length) {
          teacherCell = cols[teacherIndex];
        } else {
          teacherCell = cols.last;
        }

        // 1) вытаскиваем label-danger / label-info 
        final labels = teacherCell.querySelectorAll('.label-danger, .label-info');
        
        if (labels.isNotEmpty) {
           for (var lbl in labels) {
            final txt = lbl.text.replaceAll(RegExp(r'\s+'), ' ').trim();
            // Исправлено: Извлекаем ВСЕ совпадения ФИО из текста, чтобы избежать склеивания "Иванов А.А., Петров В.В."
            final matches = fioRegex.allMatches(txt);
            for (var match in matches) {
                result.add(match.group(0)!.trim());
            }
          }
        } else {
          // 2) иначе — берем весь текст ячейки
          final raw = teacherCell.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          final matches = fioRegex.allMatches(raw);
          if (matches.isNotEmpty) {
             for (var match in matches) {
                result.add(match.group(0)!.trim());
             }
          } else {
            // дополнительная защита: иногда ФИО находятся внутри <strong> или <b>
            final strong = teacherCell.querySelector('strong, b');
            if (strong != null) {
              final s = strong.text.replaceAll(RegExp(r'\s+'), ' ').trim();
              final strongMatches = fioRegex.allMatches(s);
              for (var match in strongMatches) {
                 result.add(match.group(0)!.trim());
              }
            }
          }
        }
      }
    }

    // Сортировка по фамилии (последнее слово).
    final list = result.toList();
    list.sort((a, b) {
      final ka = _surnameKey(a);
      final kb = _surnameKey(b);
      final c = ka.compareTo(kb);
      return c != 0 ? c : a.compareTo(b);
    });

    for (var teacher in list){
      teachers.add(Teacher(teacherName: teacher));
    }

    return teachers;
  }

  int _findTeacherColumnIndex(Element table) {
    final headerCells = <Element>[];
    headerCells.addAll(table.querySelectorAll('thead th'));
    if (headerCells.isEmpty) {
      final firstRow = table.querySelector('tbody tr') ?? table.querySelector('tr');
      if (firstRow != null) {
        headerCells.addAll(firstRow.querySelectorAll('th'));
      }
    }
    if (headerCells.isEmpty) {
      headerCells.addAll(table.querySelectorAll('th'));
    }

    for (int i = 0; i < headerCells.length; i++) {
      final text = headerCells[i].text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      if (text.contains('преподав')) return i;
    }

    return -1;
  }

  String _surnameKey(String s) {
    final cleaned = s.replaceAll(RegExp(r'[,\\.\\(\\)]'), '').trim();
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.isEmpty) return cleaned.toLowerCase();
    return words.last.toLowerCase();
  }
}