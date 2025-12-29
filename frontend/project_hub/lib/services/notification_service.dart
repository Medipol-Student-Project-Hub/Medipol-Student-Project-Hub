import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../models/notification.dart' as model;

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all notifications for current user
  Future<List<model.Notification>> getNotifications() async {
    try {
      final response = await _apiClient.get(ApiConfig.notificationsEndpoint);

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> items = data is Map 
            ? (data['results'] ?? data['notifications'] ?? []) 
            : data;
        
        return items
            .map((json) => model.Notification.fromJson(json))
            .toList();
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
      final response = await _apiClient.get(
        '${ApiConfig.notificationsEndpoint}unread-count/',
      );

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.notificationsEndpoint}$notificationId/mark-read/',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.notificationsEndpoint}mark-all-read/',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
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
        } else if (data.containsKey('message')) {
          return data['message'].toString();
        } else {
          for (var value in data.values) {
            if (value is String) return value;
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }
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