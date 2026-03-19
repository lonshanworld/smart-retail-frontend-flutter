import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/providers/api_constants.dart';
import 'package:smart_retail/app/core/config/runtime_portal.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

enum AuthSessionMode { remember, alwaysLogin }

extension AuthSessionModeParser on AuthSessionMode {
  static AuthSessionMode fromEnv(String? rawValue) {
    switch ((rawValue ?? 'true').trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'remember':
        return AuthSessionMode.remember;
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'always_login':
      case 'always-login':
      case 'alwayslogin':
      case 'always':
        return AuthSessionMode.alwaysLogin;
      default:
        return AuthSessionMode.remember;
    }
  }
}

class AuthService extends GetxService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _shopKey = 'auth_shop';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final RxnString authToken = RxnString();
  final Rxn<User> user = Rxn<User>();
  final Rxn<Shop> currentShop = Rxn<Shop>();
  final RxnString userRole = RxnString();
  final RxnString userId = RxnString();
  final RxnString shopId = RxnString();
  final RxString errorMessage = ''.obs;
  final RxBool isLoggingOut = false.obs;
  Future<void>? _initializeFuture;

  final _connect = GetConnect(timeout: const Duration(seconds: 30));
  final AppConfig _appConfig = Get.find<AppConfig>();

  AuthSessionMode get _sessionMode =>
      AuthSessionModeParser.fromEnv(_sessionModeEnvValue());

  String? _sessionModeEnvValue() {
    final portal = RuntimePortal.value;
    final portalSpecificKey = switch (portal) {
      'admin' => 'AUTH_SESSION_MODE_ADMIN',
      'merchant' => 'AUTH_SESSION_MODE_MERCHANT',
      'staff' => 'AUTH_SESSION_MODE_STAFF',
      'shop' => 'AUTH_SESSION_MODE_SHOP',
      _ => null,
    };

    if (portalSpecificKey != null) {
      final portalValue = dotenv.env[portalSpecificKey];
      if (portalValue != null && portalValue.trim().isNotEmpty) {
        return portalValue;
      }
    }

    return dotenv.env['AUTH_SESSION_MODE'];
  }

  bool get _shouldPersistAuthData => _sessionMode == AuthSessionMode.remember;

  bool get _useSecureStorage =>
      !kIsWeb &&
      _shouldPersistAuthData &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() {
    return _initializeFuture ??= _loadAuthDataFromStorage();
  }

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  void setIsLoggingOut(bool value) {
    isLoggingOut.value = value;
  }

  Future<void> _loadAuthDataFromStorage() async {
    if (!_shouldPersistAuthData) {
      await _clearPersistedAuthData();
      return;
    }

    authToken.value = await _readString(_tokenKey);

    final userJson = await _readString(_userKey);
    print('checking auth user json $userJson');
    if (userJson != null) {
      try {
        user.value = User.fromJson(jsonDecode(userJson));
        userRole.value = user.value?.role;
        userId.value = user.value?.id;
        shopId.value = user.value?.assignedShopId;
      } catch (e) {
        print("AuthService: Failed to decode user from JSON. Error: $e");
        await clearAuthData();
      }
    }

    final shopJson = await _readString(_shopKey);
    if (shopJson != null) {
      try {
        currentShop.value = Shop.fromJson(jsonDecode(shopJson));
      } catch (e) {
        print("AuthService: Failed to decode shop from JSON. Error: $e");
        await clearAuthData();
      }
    }
  }

  Future<void> _saveAuthData(
    String token,
    User userData, {
    Shop? shopData,
  }) async {
    if (_shouldPersistAuthData) {
      await _writeString(_userKey, jsonEncode(userData.toJson()));
      await _writeString(_tokenKey, token);

      if (shopData != null) {
        await _writeString(_shopKey, jsonEncode(shopData.toJson()));
      } else {
        await _removeString(_shopKey);
      }
    } else {
      await _clearPersistedAuthData();
    }

    authToken.value = token;
    user.value = userData;
    currentShop.value = shopData;
    userRole.value = userData.role;
    userId.value = userData.id;
    shopId.value = userData.assignedShopId;

    print(
      "AuthService: Auth data SAVED. Role: ${userData.role}, Email: ${userData.email}",
    );
  }

  /// Save authentication data directly from a token and user JSON payload.
  /// Useful for signup or token-exchange flows where the backend returns an access token.
  Future<void> saveAuthDataFromPayload(
    String token,
    Map<String, dynamic> userJson, {
    Map<String, dynamic>? shopJson,
  }) async {
    try {
      final userData = User.fromJson(userJson);
      Shop? shopData;
      if (shopJson != null) {
        shopData = Shop.fromJson(shopJson);
      }
      await _saveAuthData(token, userData, shopData: shopData);
    } catch (e) {
      print('[AuthService] Failed to save auth data from payload: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async => authToken.value;
  Future<String?> getUserId() async => userId.value;
  Future<String?> getUserRole() async => userRole.value;
  Future<String?> getShopId() async => shopId.value;

  bool get isAuthenticated => authToken.value != null;

  Future<String?> _readString(String key) async {
    if (_useSecureStorage) {
      return _secureStorage.read(key: key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _writeString(String key, String value) async {
    if (_useSecureStorage) {
      await _secureStorage.write(key: key, value: value);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _removeString(String key) async {
    if (_useSecureStorage) {
      await _secureStorage.delete(key: key);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> _clearPersistedAuthData() async {
    if (_useSecureStorage) {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _shopKey);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_shopKey);
  }

  Future<void> clearAuthData() async {
    await _clearPersistedAuthData();

    authToken.value = null;
    user.value = null;
    currentShop.value = null;
    userRole.value = null;
    userId.value = null;
    shopId.value = null;
    errorMessage.value = '';
    print("AuthService: Auth data CLEARED.");
  }

  Future<void> logout() async {
    await clearAuthData();
    print("AuthService: User logged out, auth data cleared.");
  }

  /// Login for Shop-specific staff users.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/auth/shop-login`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "shopId": "your_shop_id",
  ///     "email": "your_staff_email",
  ///     "password": "your_password"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "accessToken": "your_jwt_token",
  ///     "user": { ...User object... },
  ///     "shop": { ...Shop object... }
  ///   }
  ///   ```
  Future<bool> loginToShop(String shopId, String email, String password) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final mockShopId = dotenv.env['MOCK_SHOP_ID'] ?? '1';
      if (shopId == mockShopId &&
          email == dotenv.env['STAFF_EMAIL'] &&
          password == dotenv.env['STAFF_PASSWORD']) {
        final mockUser = User(
          id: 'mock_staff_id',
          name: 'Mock Staff',
          email: email,
          role: 'staff',
          assignedShopId: shopId,
        );
        final mockShop = Shop(
          id: mockShopId,
          name: 'Mock Central Shop',
          merchantId: 'mock-merchant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveAuthData('mock_staff_token', mockUser, shopData: mockShop);
        return true;
      }
      return false;
    }

    final response = await _connect.post(
      '${ApiConstants.baseUrl}/auth/shop-login',
      {'shopId': shopId, 'email': email, 'password': password},
    );

    if (response.statusCode == 200 && response.body['accessToken'] != null) {
      final token = response.body['accessToken'];
      final userData = response.body['user'];
      final shopData = response.body['shop'];
      if (token is String && userData is Map<String, dynamic>) {
        await _saveAuthData(
          token,
          User.fromJson(userData),
          shopData: shopData != null ? Shop.fromJson(shopData) : null,
        );
        return true;
      }
    }
    return false;
  }

  /// General login for Merchant and Admin users.
  ///
  /// __Request:__
  /// - __Method:__ POST
  /// - __Endpoint:__ `/api/v1/auth/login`
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "email": "your_email",
  ///     "password": "your_password",
  ///     "userType": "merchant"
  ///   }
  ///   ```
  ///
  /// __Expected Response (Success):__
  /// - __Status Code:__ 200
  /// - __Body (JSON):__
  ///   ```json
  ///   {
  ///     "accessToken": "your_jwt_token",
  ///     "user": { ...User object... }
  ///   }
  ///   ```
  Future<bool> login(
    String email,
    String password, {
    String? role,
    String? onSuccessNavigateTo,
  }) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final adminEmail = dotenv.env['ADMIN_EMAIL'];
      final adminPassword = dotenv.env['ADMIN_PASSWORD'];
      final merchantEmail = dotenv.env['MERCHANT_EMAIL'];
      final merchantPassword = dotenv.env['MERCHANT_PASSWORD'];
      final staffEmail = dotenv.env['STAFF_EMAIL'];
      final staffPassword = dotenv.env['STAFF_PASSWORD'];

      User? mockUser;

      if (role == 'admin' && email == adminEmail && password == adminPassword) {
        mockUser = User(
          id: 'mock-admin-id',
          name: 'Mock Admin',
          email: email,
          role: 'admin',
        );
        await _saveAuthData('mock_admin_token', mockUser);
        Get.offAllNamed(onSuccessNavigateTo ?? Routes.ADMIN_DASHBOARD);
        return true;
      } else if ((role == null || role == 'merchant') &&
          email == merchantEmail &&
          password == merchantPassword) {
        mockUser = User(
          id: 'mock-merchant-id',
          name: 'Mock Merchant',
          email: email,
          role: 'merchant',
        );
        await _saveAuthData('mock_merchant_token', mockUser);
        Get.offAllNamed(onSuccessNavigateTo ?? Routes.MERCHANT_DASHBOARD);
        return true;
      } else if (role == 'staff' &&
          email == staffEmail &&
          password == staffPassword) {
        mockUser = User(
          id: 'mock-staff-id',
          name: 'Mock Staff',
          email: email,
          role: 'staff',
        );
        await _saveAuthData('mock_staff_token', mockUser);
        Get.offAllNamed(onSuccessNavigateTo ?? Routes.STAFF_DASHBOARD);
        return true;
      }
      errorMessage.value = 'Invalid mock credentials for the selected role';
      return false;
    }

    errorMessage.value = '';
    final loginUrl = "${ApiConstants.baseUrl}/auth/login";
    final payload = {'email': email, 'password': password, 'userType': role};

    try {
      final response = await _connect.post(loginUrl, payload);
      print("[AUTH_SERVICE] Login response: ${response.body}");

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body;
        final token = responseData['accessToken'];
        final userData = responseData['user'];
        print('check response body in auth service ${response.body}');
        if (token is String &&
            token.isNotEmpty &&
            userData is Map<String, dynamic>) {
          final loggedInUser = User.fromJson(userData);
          await _saveAuthData(token, loggedInUser);

          if (onSuccessNavigateTo != null) {
            Get.offAllNamed(onSuccessNavigateTo);
          } else if (loggedInUser.role == 'admin') {
            Get.offAllNamed(Routes.ADMIN_DASHBOARD);
          } else if (loggedInUser.role == 'merchant') {
            Get.offAllNamed(Routes.MERCHANT_DASHBOARD);
          } else if (loggedInUser.role == 'staff') {
            Get.offAllNamed(Routes.STAFF_DASHBOARD);
          }
          return true;
        }
      }
      // Defensive parsing: response.body can be a Map (JSON) or a plain String (error HTML/text).
      String msg;
      if (response.body is Map && response.body['message'] != null) {
        msg = response.body['message'].toString();
      } else if (response.body != null) {
        msg = response.body.toString();
      } else {
        msg = 'Login failed';
      }
      errorMessage.value = '$msg (Status: ${response.statusCode})';
      return false;
    } catch (e, stackTrace) {
      print("[AUTH_SERVICE] Login exception: $e\n$stackTrace");
      errorMessage.value = 'An unexpected error occurred during login.';
      return false;
    }
  }

  /// Logs in a merchant with shop verification.
  /// This method verifies that the merchant owns the specified shop during login.
  ///
  /// __Parameters:__
  /// - `shopId`: The ID of the shop the merchant wants to access
  /// - `email`: Merchant's email
  /// - `password`: Merchant's password
  ///
  /// __Returns:__
  /// - `true` if login is successful and merchant owns the shop
  /// - `false` if login fails or merchant doesn't own the shop
  Future<bool> loginMerchantToShop(
    String shopId,
    String email,
    String password,
  ) async {
    if (_appConfig.isDevelopment) {
      await Future.delayed(const Duration(seconds: 1));
      final merchantEmail = dotenv.env['MERCHANT_EMAIL'];
      final merchantPassword = dotenv.env['MERCHANT_PASSWORD'];

      if (email == merchantEmail && password == merchantPassword) {
        // In development, assume merchant owns the shop
        final mockUser = User(
          id: 'mock-merchant-id',
          name: 'Mock Merchant',
          email: email,
          role: 'merchant',
          assignedShopId: shopId,
        );
        await _saveAuthData('mock_merchant_token', mockUser);
        return true;
      }
      errorMessage.value = 'Invalid merchant credentials';
      return false;
    }

    errorMessage.value = '';
    final loginUrl = "${ApiConstants.baseUrl}/auth/login";
    final payload = {
      'email': email,
      'password': password,
      'userType': 'merchant',
      'shopId': shopId, // Include shopId for backend verification
    };

    try {
      final response = await _connect.post(loginUrl, payload);
      print("[AUTH_SERVICE] Merchant shop login response: ${response.body}");

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body;
        final token = responseData['accessToken'];
        final userData = responseData['user'];

        if (token is String &&
            token.isNotEmpty &&
            userData is Map<String, dynamic>) {
          final loggedInUser = User.fromJson(userData).copyWith(
            assignedShopId: shopId,
          );

          // Verify the user is actually a merchant
          if (loggedInUser.role != 'merchant') {
            errorMessage.value = 'User is not a merchant';
            return false;
          }

          await _saveAuthData(token, loggedInUser);
          return true;
        }
      }

      String msg =
          response.body?['message'] ?? 'Login failed or shop access denied';
      errorMessage.value = '$msg (Status: ${response.statusCode})';
      return false;
    } catch (e, stackTrace) {
      print("[AUTH_SERVICE] Merchant shop login exception: $e\n$stackTrace");
      errorMessage.value = 'An unexpected error occurred during login.';
      return false;
    }
  }
}
