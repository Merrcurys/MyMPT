import 'package:flutter_test/flutter_test.dart';
import 'package:my_mpt/data/parsers/schedule_parser.dart';

void main() {
  test('parses schedule from tab-pane tables', () {
    const html = '''
<html><body>
<ul class="nav-tabs">
  <li><a href="#tab1">Э-1-22</a></li>
</ul>
<div role="tabpanel" id="tab1">
  <table class="table">
    <thead><tr><th><h4>ПОНЕДЕЛЬНИК <span>К1</span></h4></th></tr></thead>
    <tbody>
      <tr>
        <td>1 08:30-10:00</td>
        <td>Математика</td>
        <td>Иванов</td>
      </tr>
    </tbody>
  </table>
</div>
</body></html>
''';

    final parsed = ScheduleParser().parse(html, 'Э-1-22');
    expect(parsed.keys, contains('ПОНЕДЕЛЬНИК'));
    expect(parsed['ПОНЕДЕЛЬНИК']!.length, 1);
    expect(parsed['ПОНЕДЕЛЬНИК']!.first.subject, 'Математика');
  });

  test('fallback: parses schedule by scanning document when tabs are absent', () {
    const html = '''
<html><body>
<h2>Расписание занятий для ИС</h2>
<h3>Группа Э-1-22</h3>
<div>ПОНЕДЕЛЬНИК, Корпус 1</div>
<table class="table">
  <tbody>
    <tr>
      <td>1 08:30-10:00</td>
      <td>Физика</td>
      <td>Петров</td>
    </tr>
  </tbody>
</table>
</body></html>
''';

    final parsed = ScheduleParser().parse(html, 'Э-1-22');
    expect(parsed.keys, contains('ПОНЕДЕЛЬНИК'));
    expect(parsed['ПОНЕДЕЛЬНИК']!.first.subject, 'Физика');
  });

  test('splits numerator/denominator by <br> when labels are absent', () {
    const html = '''
<html><body>
<ul class="nav-tabs">
  <li><a href="#tab1">Э-1-22</a></li>
</ul>
<div role="tabpanel" id="tab1">
  <table class="table">
    <thead><tr><th><h4>СРЕДА <span>К2</span></h4></th></tr></thead>
    <tbody>
      <tr>
        <td>2 10:10-11:40</td>
        <td>Алгебра<br>Геометрия</td>
        <td>Сидоров<br>Смирнов</td>
      </tr>
    </tbody>
  </table>
</div>
</body></html>
''';

    final parsed = ScheduleParser().parse(html, 'Э-1-22');
    final lessons = parsed['СРЕДА']!;
    expect(lessons.length, 2);
    expect(lessons[0].lessonType, 'numerator');
    expect(lessons[0].subject, 'Алгебра');
    expect(lessons[1].lessonType, 'denominator');
    expect(lessons[1].subject, 'Геометрия');
  });
}
