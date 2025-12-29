import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../models/notification.dart';

/// Notification Service
/// Handles all notification-related API calls
class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all notifications for current user
  Future<List<Notification>> getNotifications() async {
    try {
      final response = await _apiClient.get('${ApiConfig.apiPrefix}/auth/notifications/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((json) => Notification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiConfig.apiPrefix}/auth/notifications/unread_count/');

      if (response.statusCode == 200) {
        return response.data['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } on DioException {
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.apiPrefix}/auth/notifications/$notificationId/mark_as_read/',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post(
        '${ApiConfig.apiPrefix}/auth/notifications/mark_all_read/',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        } else if (data.containsKey('error')) {
          return data['error'].toString();
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
