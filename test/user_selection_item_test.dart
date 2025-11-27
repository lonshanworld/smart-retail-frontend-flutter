import 'package:test/test.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart';

void main() {
  test('UserSelectionItem.fromJson maps role to display string', () {
    final json = {
      'id': 'u1',
      'name': 'Alice',
      'email': 'a@ex.com',
      'role': 'admin',
    };
    final item = UserSelectionItem.fromJson(json);
    expect(item.id, 'u1');
    expect(item.name, 'Alice');
    expect(item.role, isNotNull);
  });
}
