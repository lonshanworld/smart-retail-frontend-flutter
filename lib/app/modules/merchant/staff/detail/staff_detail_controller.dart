import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';

// Controller will call API to check deletable and perform delete

class StaffDetailController extends GetxController {
  final Rxn<User> staff = Rxn<User>();
  final MerchantStaffApiService _staffApiService =
      Get.find<MerchantStaffApiService>();

  final RxBool isCheckingDelete = false.obs;
  final RxBool isDeletable = false.obs;
  final RxMap<String, int> deleteBlockers = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is User) {
      staff.value = Get.arguments as User;
    } else {
      // Handle error case where staff data is missing
      Get.back();
      DialogUtils.showError('Could not load staff details.');
    }
  }

  void goToEditStaff() {
    if (staff.value != null) {
      Get.toNamed(Routes.MERCHANT_STAFF_EDIT, arguments: staff.value);
    }
  }

  Future<void> checkAndDeleteStaff() async {
    final s = staff.value;
    if (s == null) return;
    if (isCheckingDelete.value) return;
    isCheckingDelete.value = true;
    deleteBlockers.clear();
    isDeletable.value = false;
    try {
      final result = await _staffApiService.checkStaffDeletable(s.id);
      if (result == null) {
        DialogUtils.showError('Failed to check deletion status.');
        return;
      }
      final bool deletable = result['deletable'] == true;
      final Map<String, dynamic> blockers = result['blockers'] ?? {};
      blockers.forEach((k, v) {
        if (v is int) {
          deleteBlockers[k] = v;
        } else if (v is String) {
          deleteBlockers[k] = int.tryParse(v) ?? 0;
        } else {}
      });
      isDeletable.value = deletable;
      if (!deletable) {
        final entries = deleteBlockers.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        DialogUtils.showError(
          'Cannot delete staff. References found:\n$entries',
        );
        return;
      }

      final confirm = await DialogUtils.showConfirmDialog(
        title: 'Delete Staff',
        message:
            'Are you sure you want to permanently delete ${s.name}? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDanger: true,
      );
      if (confirm != true) return;

      await _staffApiService.deleteStaff(s.id);
      DialogUtils.showSuccess('Staff deleted');
      Get.back(result: true);
    } catch (e) {
      DialogUtils.showError('Error deleting staff: ${e.toString()}');
    } finally {
      isCheckingDelete.value = false;
    }
  }
}
