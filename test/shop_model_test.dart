import 'package:test/test.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';

void main() {
  test('Shop fromJson and toJson roundtrip', () {
    final now = DateTime.now();
    final json = {
      'id': 's1',
      'merchantId': 'm1',
      'name': 'Test Shop',
      'address': '123 Street',
      'phone': '555-1234',
      'isActive': true,
      'isPrimary': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final shop = Shop.fromJson(json);
    expect(shop.id, 's1');
    expect(shop.merchantId, 'm1');
    expect(shop.name, 'Test Shop');
    final out = shop.toJson();
    expect(out['name'], 'Test Shop');
    expect(out['createdAt'], isNotNull);
  });

  test('PaginationInfo.fromJson and PaginatedShopResponse.fromJson', () {
    final json = {
      'data': {
        'shops': [
          {
            'id': 's1',
            'merchantId': 'm1',
            'name': 'A',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
        'total_items': 1,
        'current_page': 1,
        'page_size': 10,
        'total_pages': 1
      }
    };

    final paged = PaginatedShopResponse.fromJson(json);
    expect(paged.totalItems, 1);
    expect(paged.shops.length, 1);
  });
}
