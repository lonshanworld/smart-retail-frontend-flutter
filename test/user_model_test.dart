import 'package:test/test.dart';
import 'package:smart_retail/app/data/models/user_model.dart';

void main() {
  test('User.fromJson handles different field variants', () {
    final json = {
      'id': 'u1',
      'name': 'Alice',
      'email': 'a@example.com',
      'role': 'staff',
      'is_active': true,
      'phone': '123',
      'merchant_id': 'm1',
      'created_at': DateTime.now().toIso8601String(),
    };

    final user = User.fromJson(json);
    expect(user.id, 'u1');
    expect(user.name, 'Alice');
    expect(user.role, 'staff');
    expect(user.roleAsEnum.name, isNotNull);
  });

  test('User.copyWith and toJson', () {
    final u = User(
      id: 'u2',
      name: 'Bob',
      email: 'b@example.com',
      role: 'merchant',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final changed = u.copyWith(name: 'Bobby');
    expect(changed.name, 'Bobby');
    final map = changed.toJson();
    expect(map['name'], 'Bobby');
  });
}
