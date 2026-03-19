import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/modules/merchant/catalog/catalog_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';

class CatalogView extends GetView<CatalogController> {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Catalog Management',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Categories'),
                  Tab(text: 'Subcategories'),
                  Tab(text: 'Brands'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _CategoriesTab(controller: controller),
                    _SubcategoriesTab(controller: controller),
                    _BrandsTab(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final CatalogController controller;

  const _CategoriesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final item = controller.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.description ?? '-'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showCategoryDialog(
                        context,
                        controller,
                        category: item,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => controller.deleteCategory(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubcategoriesTab extends StatelessWidget {
  final CatalogController controller;

  const _SubcategoriesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final subcategories = controller.allSubcategories;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: controller.categories.isEmpty
                ? null
                : () => _showSubcategoryDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Add Subcategory'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final item = subcategories[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.description ?? '-'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showSubcategoryDialog(
                        context,
                        controller,
                        subcategory: item,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => controller.deleteSubcategory(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrandsTab extends StatelessWidget {
  final CatalogController controller;

  const _BrandsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showBrandDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Add Brand'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: controller.brands.length,
            itemBuilder: (context, index) {
              final item = controller.brands[index];
              return ListTile(
                leading: _BrandAvatar(imageUrl: item.imageUrl, name: item.name),
                title: Text(item.name),
                subtitle: Text(item.description ?? '-'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showBrandDialog(context, controller, brand: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => controller.deleteBrand(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> _showCategoryDialog(
  BuildContext context,
  CatalogController controller, {
  CategoryWithSubcategories? category,
}) async {
  final nameCtrl = TextEditingController(text: category?.name ?? '');
  final descCtrl = TextEditingController(text: category?.description ?? '');

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(category == null ? 'Add Category' : 'Edit Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            if (category == null) {
              await controller.createCategory(name, descCtrl.text.trim());
            } else {
              await controller.updateCategory(
                category.id,
                name,
                descCtrl.text.trim(),
              );
            }
            if (context.mounted) {
              Navigator.of(ctx).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _BrandAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _BrandAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return CircleAvatar(child: Text(initial));
    }

    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.network(
          url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: Text(initial)),
        ),
      ),
    );
  }
}

Future<void> _showSubcategoryDialog(
  BuildContext context,
  CatalogController controller, {
  SubcategoryRef? subcategory,
}) async {
  final nameCtrl = TextEditingController(text: subcategory?.name ?? '');
  final descCtrl = TextEditingController(text: subcategory?.description ?? '');
  String selectedCategoryId =
      subcategory?.categoryId ??
      (controller.categories.isNotEmpty ? controller.categories.first.id : '');

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: Text(
            subcategory == null ? 'Add Subcategory' : 'Edit Subcategory',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryId.isEmpty
                    ? null
                    : selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: controller.categories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedCategoryId = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || selectedCategoryId.isEmpty) return;
                if (subcategory == null) {
                  await controller.createSubcategory(
                    selectedCategoryId,
                    name,
                    descCtrl.text.trim(),
                  );
                } else {
                  await controller.updateSubcategory(
                    subcategory.id,
                    selectedCategoryId,
                    name,
                    descCtrl.text.trim(),
                  );
                }
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showBrandDialog(
  BuildContext context,
  CatalogController controller, {
  BrandRef? brand,
}) async {
  final nameCtrl = TextEditingController(text: brand?.name ?? '');
  final descCtrl = TextEditingController(text: brand?.description ?? '');
  final imageCtrl = TextEditingController(text: brand?.imageUrl ?? '');

  bool isSaving = false;
  String? backendError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        // No client-side duplicate check here; rely on backend validation.
        return AlertDialog(
          title: Text(brand == null ? 'Add Brand' : 'Edit Brand'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() => backendError = null),
              ),
              if (backendError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
                  child: Text(
                    backendError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Google Drive or direct link)',
                  hintText:
                      'https://drive.google.com/... or https://.../image.jpg',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() => isSaving = true);
                      bool ok = false;
                      if (brand == null) {
                        final res = await controller.createBrandRaw(
                          name,
                          descCtrl.text.trim(),
                          imageUrl: imageCtrl.text.trim(),
                        );
                        final okRes = res['ok'] == true;
                        final msg =
                            res['message']?.toString() ??
                            'Failed to create brand';
                        if (!okRes) {
                          setState(() => backendError = msg);
                          ok = false;
                        } else {
                          ok = true;
                        }
                      } else {
                        ok = await controller.updateBrand(
                          brand.id,
                          name,
                          descCtrl.text.trim(),
                        );
                      }
                      setState(() => isSaving = false);
                      if (ok && context.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
