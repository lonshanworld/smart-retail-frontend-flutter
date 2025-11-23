import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/services/ui_keys.dart';

/// Utility class for showing dialogs and snackbars that work reliably on web
class DialogUtils {
  /// Show a snackbar with proper web compatibility
  static void showSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    SnackPosition snackPosition = SnackPosition.TOP,
    bool isError = false,
  }) {
    // Compute common values first
    final showDuration = duration ?? const Duration(seconds: 3);
    final bg = backgroundColor ?? (isError ? Colors.red.shade600 : Colors.green.shade600);

    // Prefer showing via the app's ScaffoldMessenger (most robust).
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: colorText ?? Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: colorText ?? Colors.white)),
        ],
      );
      final snack = SnackBar(
        content: content,
        backgroundColor: bg,
        duration: showDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
      // Show using the global scaffold messenger
      try {
        messenger.showSnackBar(snack);
        return;
      } catch (_) {
        // fall through to overlay fallback
      }
    }

    // Prefer showing a manual overlay Snackbar so it's reliably visible on web.
    final ctx = Get.overlayContext ?? Get.context;

    if (ctx != null) {
      final overlay = Overlay.of(ctx);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) {
            final media = MediaQuery.of(context);
            final width = media.size.width;
            final maxWidth = width > 540 ? 500.0 : width - 40.0;
            return Positioned(
              top: 20,
              left: (media.size.width - maxWidth) / 2,
              width: maxWidth,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  minimum: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: TextStyle(color: colorText ?? Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(message, style: TextStyle(color: colorText ?? Colors.white)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            try {
                              entry.remove();
                            } catch (_) {}
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(Icons.close, color: colorText ?? Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

      overlay.insert(entry);
      Future.delayed(showDuration, () {
        try {
          entry.remove();
        } catch (_) {}
      });
      return;
    }

    // Fallback to Get.snackbar when no overlay/context is available
    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: bg,
      colorText: colorText ?? Colors.white,
      duration: showDuration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      maxWidth: 500,
    );
  }

  /// Show an error snackbar
  static void showError(
    String message, {
    String title = 'Error',
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    showSnackbar(
      title: title,
      message: message,
      isError: true,
      snackPosition: snackPosition ?? SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: colorText,
      duration: duration,
    );
  }

  /// Show a success snackbar
  static void showSuccess(
    String message, {
    String title = 'Success',
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    showSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.green.shade600,
      snackPosition: snackPosition ?? SnackPosition.TOP,
      colorText: colorText,
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    String message, {
    String title = 'Info',
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    showSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.blue.shade600,
      snackPosition: snackPosition ?? SnackPosition.TOP,
      colorText: colorText,
      duration: duration,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    String message, {
    String title = 'Warning',
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    showSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor ?? Colors.orange.shade600,
      snackPosition: snackPosition ?? SnackPosition.TOP,
      colorText: colorText,
      duration: duration,
    );
  }

  /// Show a confirmation dialog with proper web support
  static Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDanger = false,
  }) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  confirmColor ?? (isDanger ? Colors.red : Colors.deepPurple),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show a custom dialog with proper web support
  static Future<T?> showCustomDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    return await Get.dialog<T>(dialog, barrierDismissible: barrierDismissible);
  }

  /// Show a loading dialog
  static void showLoading({String message = 'Loading...'}) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Show an alert dialog
  static Future<void> showAlert({
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: Text(buttonText)),
        ],
      ),
    );
  }
}
