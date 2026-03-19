import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/utils/response_utils.dart';

/// AdminAdminsApiService - Service for managing admin users.
///
/// This service handles fetching, creating, updating, and deleting admin users
/// through API calls. It will use mock data for development environments.
class AdminAdminsApiService extends GetConnect {
  final AppConfig _appConfig = Get.find<AppConfig>();
  final AuthService _authService = Get.find<AuthService>();
  String get _baseUrl => '${ApiConstants.baseUrl}/admin/admins';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches a paginated list of admin users.
  ///
  /// GET /api/admin/admins
  /// Query Parameters:
  ///   - page: int (e.g., 1)
  ///   - limit: int (e.g., 20)
  ///   - sortBy: string (e.g., "createdAt:desc")
  ///
  /// Expected Success Response (200 OK):
  /// {
  ///   "data": [
  ///     {
  ///       "id": "admin-uuid-1",
  ///       "name": "Super Admin",
  ///       "email": "super@admin.com",
  ///       "role": "admin",
  ///       "isActive": true,
  ///       "createdAt": "2023-01-01T12:00:00Z"
  ///     },
  ///     // ... other admin users
  ///   ],
  ///   "pagination": {
  ///     "totalItems": 2,
  ///     "totalPages": 1,
  ///     "currentPage": 1
  ///   }
  /// }
  Future<List<User>> getAdmins({int page = 1, int limit = 20}) async {
    if (_appConfig.isDevelopment) {
      return Future.delayed(const Duration(seconds: 1), () => _mockAdmins);
    }

    final response = await get(
      '$_baseUrl?page=$page&limit=$limit',
      headers: await _getHeaders(),
    );
    print('check response for admin list $response');
    if (response.isOk &&
        response.body != null &&
        response.body['data'] != null) {
      final rawList = asList(response.body['data']);
      return rawList
          .map(
            (adminJson) => User.fromJson(Map<String, dynamic>.from(adminJson)),
          )
          .toList();
    } else {
      throw Exception('Failed to load admins: ${response.statusText}');
    }
  }

  // Mock data for development
  final List<User> _mockAdmins = [
    User(
      id: 'mock-admin-1',
      name: 'Alice Admin',
      email: 'alice.admin@example.com',
      role: 'admin',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    User(
      id: 'mock-admin-2',
      name: 'Bob SuperAdmin',
      email: 'bob.super@example.com',
      role: 'admin',
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
