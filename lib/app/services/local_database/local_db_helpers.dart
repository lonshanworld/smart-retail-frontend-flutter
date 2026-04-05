Map<String, dynamic>? findById(List<Map<String, dynamic>> rows, String id) {
  try {
    return rows.firstWhere((r) => r['id'] == id);
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> filterBy(List<Map<String, dynamic>> rows, String key, dynamic value) {
  return rows.where((r) => r[key] == value).toList();
}

void upsertRow(List<Map<String, dynamic>> rows, Map<String, dynamic> row) {
  final idx = rows.indexWhere((r) => r['id'] == row['id']);
  if (idx >= 0) {
    rows[idx] = {...rows[idx], ...row};
  } else {
    rows.add(Map<String, dynamic>.from(row));
  }
}
