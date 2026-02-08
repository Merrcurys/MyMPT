import 'package:flutter_test/flutter_test.dart';
import 'package:my_mpt/data/parsers/mpt_parse_utils.dart';

void main() {
  test('normalizeGroupCode trims/uppercases and normalizes dashes', () {
    expect(normalizeGroupCode(' э—1—22 '), 'Э-1-22');
    expect(normalizeGroupCode('Э - 1 - 22'), 'Э-1-22');
  });

  test('splitGroupCodes splits by comma/slash/semicolon and dedupes', () {
    final r = splitGroupCodes('Э-1-22, Э-11/1-23; э-1-22');
    expect(r, ['Э-1-22', 'Э-11-1-23']);
  });

  test('groupMatchesTab matches compound group codes', () {
    expect(groupMatchesTab('Э-1-22', 'Э-1-22, Э-11/1-23'), isTrue);
    expect(groupMatchesTab('Э-11/1-23', 'Э-1-22, Э-11/1-23'), isTrue);
  });
}
