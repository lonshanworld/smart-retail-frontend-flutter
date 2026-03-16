// lib/app/middlewares/auth_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class AuthMiddleware extends GetMiddleware {
  final List<UserRole>? requiredRoles; // UPDATED: To accept a list of roles
  final UserRole? requiredRole; // Keep single role for backward compatibility
  late final AuthService authService;

  AuthMiddleware({this.requiredRoles, this.requiredRole}) {
    authService = Get.find<AuthService>();
  }

  @override
  RouteSettings? redirect(String? route) {
    if (!authService.isAuthenticated) {
      // If user is not authenticated, always redirect to login.
      return const RouteSettings(name: Routes.LOGIN);
    }

    final UserRole currentRole = userRoleFromString(
      authService.userRole.value,
    );
    bool isAuthorized = false;

    if (requiredRoles != null && requiredRoles!.isNotEmpty) {
      // Check if the user's role is in the list of required roles.
      if (currentRole != null && requiredRoles!.contains(currentRole)) {
        isAuthorized = true;
      }
    } else if (requiredRole != null) {
      // Fallback to checking a single role.
      if (currentRole == requiredRole) {
        isAuthorized = true;
      }
    } else {
      // If no roles are required, the user is authorized.
      isAuthorized = true;
    }

    if (!isAuthorized) {
      DialogUtils.showInfo('You do not have permission to access this page.');
      // Redirect to a default page if not authorized
      return const RouteSettings(name: Routes.LOGIN);
    }

    return null; // User is authenticated and authorized
  }
}
