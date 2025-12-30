import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'storage_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  /// Login user
  Future<User> login({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        await _storage.saveAuthData(
          accessToken: data['access'],
          refreshToken: data['refresh'],
          userId: data['user']['id'].toString(),
          userType: data['user']['user_type'],
          email: data['user']['email'],
        );

        return _parseUser(data['user']);
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register student
  Future<User> registerStudent({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required String year,
    String? faculty,
    List<String>? skills,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.registerStudentEndpoint,
        data: {
          'email': email,
          'password': password,
          'password_confirm': password,
          'name': name,
          'student_id': studentId,
          'department': department,
          'year': year,
          if (faculty != null) 'faculty': faculty,
          if (skills != null) 'skills': skills,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;

        await _storage.saveAuthData(
          accessToken: data['access'],
          refreshToken: data['refresh'],
          userId: data['user']['id'].toString(),
          userType: 'student',
          email: data['user']['email'],
        );

        return _parseUser(data['user']);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register faculty
  Future<User> registerFaculty({
    required String email,
    required String password,
    required String name,
    required String facultyId,
    required String department,
    String? faculty,
    String? title,
    String? specialization,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.registerFacultyEndpoint,
        data: {
          'email': email,
          'password': password,
          'password_confirm': password,
          'name': name,
          'faculty_id': facultyId,
          'department': department,
          if (faculty != null) 'faculty': faculty,
          if (title != null) 'title': title,
          if (specialization != null) 'specialization': specialization,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;

        await _storage.saveAuthData(
          accessToken: data['access'],
          refreshToken: data['refresh'],
          userId: data['user']['id'].toString(),
          userType: 'faculty',
          email: data['user']['email'],
        );

        return _parseUser(data['user']);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Forgot password - send reset email
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.forgotPasswordEndpoint,
        data: {'email': email},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send reset email');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.resetPasswordEndpoint,
        data: {
          'token': token,
          'password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          ApiConfig.logoutEndpoint,
          data: {'refresh': refreshToken},
        );
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _storage.clearAll();
    }
  }

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.profileEndpoint);

      if (response.statusCode == 200) {
        return _parseUser(response.data);
      } else {
        throw Exception('Failed to get profile');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final userType = await _storage.getUserType();
      final endpoint = userType == 'student'
          ? '${ApiConfig.baseUrl}/students/update_profile/'
          : '${ApiConfig.baseUrl}/faculty/update_profile/';

      final response = await _apiClient.patch(endpoint, data: data);

      if (response.statusCode == 200) {
        return _parseUser(response.data);
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  /// Parse user from JSON
  User _parseUser(Map<String, dynamic> json) {
    final userType = json['user_type'];

    if (userType == 'student') {
      return Student.fromJson(json);
    } else {
      return Faculty.fromJson(json);
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data.containsKey('detail')) {
          return data['detail'];
        } else if (data.containsKey('error')) {
          return data['error'];
        } else {
          for (var value in data.values) {
            if (value is String) return value;
            if (value is List && value.isNotEmpty) return value.first.toString();
          }
        }
      }
      return 'Error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}