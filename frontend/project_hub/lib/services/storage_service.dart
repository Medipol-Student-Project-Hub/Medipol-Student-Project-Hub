import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage service for tokens/user info.
/// - On Web: uses SharedPreferences (stable on browsers)
/// - On Mobile/Desktop: uses FlutterSecureStorage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  FlutterSecureStorage? get _secureStorage {
    if (kIsWeb) return null;
    return const FlutterSecureStorage();
  }

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _userEmailKey = 'user_email';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // ---- write helpers ----
  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final p = await _prefs();
      await p.setString(key, value);
    } else {
      await _secureStorage!.write(key: key, value: value);
    }
  }

  // ---- read helpers ----
  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final p = await _prefs();
      return p.getString(key);
    } else {
      return await _secureStorage!.read(key: key);
    }
  }

  // ---- delete helpers ----
  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final p = await _prefs();
      await p.clear();
    } else {
      await _secureStorage!.deleteAll();
    }
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _write(_accessTokenKey, token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _read(_accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _write(_refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _read(_refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _read(_userIdKey);
  }

  /// Save user type (student/faculty)
  Future<void> saveUserType(String userType) async {
    await _write(_userTypeKey, userType);
  }

  /// Get user type
  Future<String?> getUserType() async {
    return await _read(_userTypeKey);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _write(_userEmailKey, email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _read(_userEmailKey);
  }

  /// Save authentication data
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userType,
    required String email,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
      saveUserType(userType),
      saveUserEmail(email),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _deleteAll();
  }

  /// Clear specific key
  Future<void> delete(String key) async {
    if (kIsWeb) {
      final p = await _prefs();
      await p.remove(key);
    } else {
      await _secureStorage!.delete(key: key);
    }
  }
}
