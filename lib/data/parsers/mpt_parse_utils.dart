/// Shared parsing helpers for MPT schedule pages.
///
/// Keep this file free of Flutter dependencies so it can be used in isolates.
library;

/// Normalizes a group code for robust comparisons.
///
/// - Trims
/// - Uppercases
/// - Replaces long dashes with '-'
/// - Removes redundant spaces
String normalizeGroupCode(String input) {
  final s = input
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('−', '-')
      .trim()
      .toUpperCase();

  // Collapse all whitespace to single spaces, then remove spaces around '-'.
  final collapsed = s.replaceAll(RegExp(r'\s+'), ' ');
  return collapsed.replaceAll(RegExp(r'\s*-\s*'), '-');
}

/// Splits a possibly compound group field like "Э-1-22, Э-11/1-23".
List<String> splitGroupCodes(String raw) {
  final normalized = raw.replaceAll('\n', ' ');
  final parts = normalized.split(RegExp(r'[,/;]'));
  final out = <String>[];
  final seen = <String>{};

  for (final p in parts) {
    final v = normalizeGroupCode(p);
    if (v.isEmpty) continue;
    if (seen.add(v)) out.add(v);
  }

  return out;
}

/// Returns true if [tabText] matches [groupCode] (including compound codes).
bool groupMatchesTab(String tabText, String groupCode) {
  final t = normalizeGroupCode(tabText);
  if (t.isEmpty) return false;

  final candidates = splitGroupCodes(groupCode);
  if (candidates.isEmpty) {
    final g = normalizeGroupCode(groupCode);
    return g.isNotEmpty && (t == g || t.contains(g) || g.contains(t));
  }

  for (final c in candidates) {
    if (t == c || t.contains(c) || c.contains(t)) return true;
  }

  return false;
}
