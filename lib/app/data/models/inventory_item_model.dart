class StockInfo {
  final int quantity;
  final String shopId;
  // ADDED: Optional shopName for easier display in the UI.
  final String? shopName;

  StockInfo({required this.quantity, required this.shopId, this.shopName});

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      quantity: json['quantity'] as int,
      shopId: json['shopId'] as String? ?? json['shop_id'] as String,
      shopName: json['shopName'] as String? ?? json['shop_name'] as String?,
    );
  }
}

class CategoryRef {
  final String id;
  final String name;
  final String? description;

  CategoryRef({required this.id, required this.name, this.description});

  factory CategoryRef.fromJson(Map<String, dynamic> json) {
    return CategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class SubcategoryRef {
  final String id;
  final String categoryId;
  final String name;
  final String? description;

  SubcategoryRef({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
  });

  factory SubcategoryRef.fromJson(Map<String, dynamic> json) {
    return SubcategoryRef(
      id: json['id'] as String,
      categoryId:
          json['categoryId'] as String? ?? json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class BrandRef {
  final String id;
  final String name;
  final String? description;

  BrandRef({required this.id, required this.name, this.description});

  factory BrandRef.fromJson(Map<String, dynamic> json) {
    return BrandRef(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class CategoryWithSubcategories extends CategoryRef {
  final List<SubcategoryRef> subcategories;

  CategoryWithSubcategories({
    required super.id,
    required super.name,
    super.description,
    required this.subcategories,
  });

  factory CategoryWithSubcategories.fromJson(Map<String, dynamic> json) {
    final rawSubs = (json['subcategories'] as List?) ?? const [];
    return CategoryWithSubcategories(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      subcategories: rawSubs
          .map((e) => SubcategoryRef.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CatalogOptionsResponse {
  final List<CategoryWithSubcategories> categories;
  final List<BrandRef> brands;

  CatalogOptionsResponse({required this.categories, required this.brands});

  factory CatalogOptionsResponse.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as List?) ?? const [];
    final rawBrands = (json['brands'] as List?) ?? const [];
    return CatalogOptionsResponse(
      categories: rawCategories
          .map(
            (e) => CategoryWithSubcategories.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      brands: rawBrands
          .map((e) => BrandRef.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class InventoryItem {
  String? id;
  String merchantId;
  String name;
  String? description;
  String? sku;
  double sellingPrice;
  double? originalPrice;
  int? lowStockThreshold;
  String? category;
  String? categoryId;
  String? subcategoryId;
  String? brandId;
  String? supplier;
  CategoryRef? categoryObj;
  SubcategoryRef? subcategoryObj;
  BrandRef? brandObj;
  bool isArchived;
  DateTime createdAt;
  DateTime updatedAt;

  bool isSynced;
  bool needsUpdate;
  bool needsCreate;

  // ENHANCED: Changed to a list to hold stock levels for multiple shops.
  List<StockInfo>? stockInfo;

  InventoryItem({
    this.id,
    required this.merchantId,
    required this.name,
    this.description,
    this.sku,
    required this.sellingPrice,
    this.originalPrice,
    this.lowStockThreshold,
    this.category,
    this.categoryId,
    this.subcategoryId,
    this.brandId,
    this.supplier,
    this.categoryObj,
    this.subcategoryObj,
    this.brandObj,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.needsUpdate = false,
    this.needsCreate = false,
    this.stockInfo,
  });

  InventoryItem copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    String? sku,
    double? sellingPrice,
    double? originalPrice,
    int? lowStockThreshold,
    String? category,
    String? categoryId,
    String? subcategoryId,
    String? brandId,
    String? supplier,
    CategoryRef? categoryObj,
    SubcategoryRef? subcategoryObj,
    BrandRef? brandObj,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? needsUpdate,
    bool? needsCreate,
    List<StockInfo>? stockInfo,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brandId: brandId ?? this.brandId,
      supplier: supplier ?? this.supplier,
      categoryObj: categoryObj ?? this.categoryObj,
      subcategoryObj: subcategoryObj ?? this.subcategoryObj,
      brandObj: brandObj ?? this.brandObj,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      needsUpdate: needsUpdate ?? this.needsUpdate,
      needsCreate: needsCreate ?? this.needsCreate,
      stockInfo: stockInfo ?? this.stockInfo,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle quantity field from backend (InventoryItemWithQuantity)
    List<StockInfo>? stockInfoList;

    if (json.containsKey('quantity') && json['quantity'] != null) {
      // Backend sends quantity directly for shop-specific inventory
      stockInfoList = [
        StockInfo(
          quantity: json['quantity'] as int,
          shopId: '', // Shop ID is context-dependent
        ),
      ];
    } else if (json.containsKey('stockInfo') && json['stockInfo'] != null) {
      stockInfoList = (json['stockInfo'] as List)
          .map((s) => StockInfo.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('stock_info') && json['stock_info'] != null) {
      stockInfoList = (json['stock_info'] as List)
          .map((s) => StockInfo.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('stock') && json['stock'] != null) {
      stockInfoList = [
        StockInfo.fromJson(json['stock'] as Map<String, dynamic>),
      ];
    }

    return InventoryItem(
      id: json['id'] as String?,
      merchantId:
          json['merchantId'] as String? ?? json['merchant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      sellingPrice:
          (json['sellingPrice'] as num? ?? json['selling_price'] as num)
              .toDouble(),
      originalPrice:
          (json['originalPrice'] as num? ?? json['original_price'] as num?)
              ?.toDouble(),
      lowStockThreshold:
          (json['lowStockThreshold'] as num? ??
                  json['low_stock_threshold'] as num?)
              ?.toInt(),
      category: json['category'] as String?,
      categoryId:
          json['categoryId'] as String? ?? json['category_id'] as String?,
      subcategoryId:
          json['subcategoryId'] as String? ?? json['subcategory_id'] as String?,
      brandId: json['brandId'] as String? ?? json['brand_id'] as String?,
      supplier: json['supplier'] as String?,
      categoryObj: json['categoryObj'] != null
          ? CategoryRef.fromJson(
              Map<String, dynamic>.from(json['categoryObj'] as Map),
            )
          : null,
      subcategoryObj: json['subcategoryObj'] != null
          ? SubcategoryRef.fromJson(
              Map<String, dynamic>.from(json['subcategoryObj'] as Map),
            )
          : null,
      brandObj: json['brandObj'] != null
          ? BrandRef.fromJson(
              Map<String, dynamic>.from(json['brandObj'] as Map),
            )
          : null,
      isArchived:
          json['isArchived'] as bool? ?? json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
      isSynced: true,
      stockInfo: stockInfoList,
    );
  }

  factory InventoryItem.fromDbMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String?,
      merchantId: map['merchantId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      originalPrice: map['originalPrice'] as double?,
      lowStockThreshold: map['lowStockThreshold'] as int?,
      category: map['category'] as String?,
      categoryId: map['categoryId'] as String?,
      subcategoryId: map['subcategoryId'] as String?,
      brandId: map['brandId'] as String?,
      supplier: map['supplier'] as String?,
      isArchived: map['isArchived'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: map['isSynced'] == 1,
      needsUpdate: map['needsUpdate'] == 1,
      needsCreate: map['needsCreate'] == 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'sku': sku,
      'sellingPrice': sellingPrice,
      'originalPrice': originalPrice,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'brandId': brandId,
      'supplier': supplier,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'needsUpdate': needsUpdate ? 1 : 0,
      'needsCreate': needsCreate ? 1 : 0,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'name': name,
      'description': description,
      'sku': sku,
      'sellingPrice': sellingPrice,
      'originalPrice': originalPrice,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'brandId': brandId,
      'supplier': supplier,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    if (description != null) data['description'] = description;
    if (sku != null) data['sku'] = sku;
    data['sellingPrice'] = sellingPrice;
    if (originalPrice != null) data['originalPrice'] = originalPrice;
    if (lowStockThreshold != null) {
      data['lowStockThreshold'] = lowStockThreshold;
    }
    if (category != null) data['category'] = category;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (subcategoryId != null) data['subcategoryId'] = subcategoryId;
    if (brandId != null) data['brandId'] = brandId;
    if (supplier != null) data['supplier'] = supplier;
    // Note: Archiving is handled via a separate method/endpoint for clarity.
    return data;
  }

  // ADDED: Method to generate JSON for archiving/unarchiving.
  Map<String, dynamic> toJsonForArchive(bool archiveStatus) {
    return {'isArchived': archiveStatus};
  }
}

class PaginatedInventoryResponse {
  final List<InventoryItem> items;
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  PaginatedInventoryResponse({
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedInventoryResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<InventoryItem> items = itemsList
        .map((i) => InventoryItem.fromJson(i))
        .toList();

    return PaginatedInventoryResponse(
      items: items,
      totalItems:
          (json['totalItems'] as num? ??
                  json['total_items'] as num? ??
                  json['totalCount'] as num? ??
                  json['total_count'] as num? ??
                  items.length)
              .toInt(),
      currentPage:
          (json['currentPage'] as num? ?? json['current_page'] as num? ?? 1)
              .toInt(),
      pageSize:
          (json['pageSize'] as num? ??
                  json['page_size'] as num? ??
                  items.length)
              .toInt(),
      totalPages:
          (json['totalPages'] as num? ?? json['total_pages'] as num? ?? 1)
              .toInt(),
    );
  }
}
