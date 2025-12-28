import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../models/message.dart';

/// Message Service
/// Handles all messaging-related API calls
class MessageService {
  final ApiClient _apiClient = ApiClient();

  /// Get all conversations
  Future<List<Conversation>> getAllConversations() async {
    try {
      final response = await _apiClient.get(ApiConfig.conversationsEndpoint);

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> items = data is Map ? (data['results'] ?? []) : data;
        return items.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.conversationsEndpoint}$conversationId/messages/',
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        final List<dynamic> items = data is Map ? (data['results'] ?? []) : data;
        return items.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.conversationsEndpoint}$conversationId/send_message/',
        data: {
          'content': content,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Message.fromJson(response.data);
      } else {
        throw Exception('Failed to send message');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new conversation
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? name,
    bool isGroup = false,
  }) async {
    try {
      late final Response response;

      if (!isGroup && participantIds.length == 1) {
        // One-on-one conversation
        final participantId = int.tryParse(participantIds.first) ?? participantIds.first;
        
        print('Creating 1-1 conversation with participant: $participantId');
        
        response = await _apiClient.post(
          '${ApiConfig.conversationsEndpoint}find_or_create/',
          data: {
            'participant_id': participantId,
          },
        );
      } else {
        // Group conversation
        print('Creating group conversation with ${participantIds.length} participants');
        
        response = await _apiClient.post(
          ApiConfig.conversationsEndpoint,
          data: {
            'participant_ids': participantIds
                .map((id) => int.tryParse(id) ?? id)
                .toList(),
            if (name != null && name.isNotEmpty) 'name': name,
            'is_group': isGroup,
          },
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Conversation created successfully: ${response.data}');
        return Conversation.fromJson(response.data);
      } else {
        throw Exception('Failed to create conversation: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException creating conversation: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error creating conversation: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.get('${ApiConfig.conversationsEndpoint}$conversationId/');
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
            if (value is List && value.isNotEmpty) return value.first.toString();
          }
        }
      }
      return 'Error: ${error.response!.statusCode} - ${error.response!.statusMessage ?? 'Unknown error'}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout. Please try again.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}