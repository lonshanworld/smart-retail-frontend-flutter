import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/supplier_model.dart';
import 'package:smart_retail/app/data/services/supplier_api_service.dart';

class SupplierManagementController extends GetxController {
  final SupplierApiService _apiService = Get.find<SupplierApiService>();

  // Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();

  // Observables
  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _apiService.getSuppliers();
      suppliers.assignAll(result);
    } catch (e) {
      errorMessage.value = "Failed to load suppliers: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createSupplier() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSaving.value = true;
    try {
      final data = {
        'name': nameController.text.trim(),
        'contactName': contactNameController.text.trim(),
        'contactEmail': contactEmailController.text.trim(),
        'contactPhone': contactPhoneController.text.trim(),
        'address': addressController.text.trim(),
        'notes': notesController.text.trim(),
      };

      final newSupplier = await _apiService.createSupplier(data);
      suppliers.add(newSupplier);

      // Clear the form
      formKey.currentState?.reset();
      nameController.clear();
      contactNameController.clear();
      contactEmailController.clear();
      contactPhoneController.clear();
      addressController.clear();
      notesController.clear();

      DialogUtils.showSuccess('Supplier "${newSupplier.name}" created.');
    } catch (e) {
      DialogUtils.showError("Failed to create supplier: ${e.toString()}");
    } finally {
      isSaving.value = false;
    }
  }

  /// Deletes a supplier after confirmation and refreshes the list.
  Future<void> deleteSupplier(String supplierId) async {
    final supplier = suppliers.firstWhereOrNull((s) => s.id == supplierId);
    final confirm = await DialogUtils.showConfirmDialog(
      title: 'Delete Supplier',
      message:
          'Are you sure you want to permanently delete "${supplier?.name ?? 'this supplier'}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDanger: true,
    );
    if (confirm != true) return;

    try {
      isLoading.value = true;
      final success = await _apiService.deleteSupplier(supplierId);
      if (success) {
        suppliers.removeWhere((s) => s.id == supplierId);
        DialogUtils.showSuccess('Supplier deleted');
      } else {
        DialogUtils.showError('Failed to delete supplier');
      }
    } catch (e) {
      DialogUtils.showError('Error deleting supplier: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    contactNameController.dispose();
    contactEmailController.dispose();
    contactPhoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
