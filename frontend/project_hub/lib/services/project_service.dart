import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../models/project.dart';

/// Project Service
/// Handles all project-related API calls
class ProjectService {
  final ApiClient _apiClient = ApiClient();

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _apiClient.get(ApiConfig.projectsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my projects (projects I'm part of)
  Future<List<Project>> getMyProjects() async {
    try {
      final response = await _apiClient.get('${ApiConfig.projectsEndpoint}my-projects/');

      if (response.statusCode == 200) {
        // my-projects returns a list directly, not paginated
        final dynamic rawData = response.data;
        final List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map && rawData['results'] != null) {
          data = rawData['results'];
        } else {
          data = [];
        }
        return data.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my projects');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get project by ID
  Future<Project> getProjectById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.projectsEndpoint}$id/');

      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        throw Exception('Failed to load project');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new project
  Future<Project> createProject({
    required String title,
    required String description,
    required String category,
    required List<String> lookingFor,
    int? maxTeamSize,
    String? startDate,
    String? duration,
    List<String>? requirements,
    List<String>? objectives,
    String? supervisorName,
  }) async {
    try {
      // Validate category value (backend expects lowercase values)
      final validCategories = ['engineering', 'design', 'health', 'business', 'ai', 'web', 'mobile', 'research', 'other'];
      final categoryValue = category.toLowerCase();

      if (!validCategories.contains(categoryValue)) {
        throw Exception('Invalid category: $category');
      }

      // Build request data
      final Map<String, dynamic> requestData = {
        'title': title.trim(),
        'description': description.trim(),
        'category': categoryValue,  // ✅ Use validated lowercase value
        'tags': lookingFor,
        'status': 'draft',  // ✅ Explicitly set status
      };

      // Add optional fields only if they have values
      if (maxTeamSize != null && maxTeamSize > 0) {
        requestData['max_team_size'] = maxTeamSize;
      }

      if (startDate != null && startDate.isNotEmpty) {
        requestData['start_date'] = startDate;
      }

      if (duration != null && duration.isNotEmpty) {
        requestData['expected_duration'] = duration;
      }

      if (requirements != null && requirements.isNotEmpty) {
        requestData['required_skills'] = requirements;
      }

      if (objectives != null && objectives.isNotEmpty) {
        requestData['objectives'] = objectives;
      }

      // ✅ Supervisor name as string (backend now supports this)
      if (supervisorName != null && supervisorName.trim().isNotEmpty) {
        requestData['supervisor_name'] = supervisorName.trim();
      }

      print('📤 Creating project with data: $requestData');

      final response = await _apiClient.post(
        ApiConfig.projectsEndpoint,
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Project created successfully!');
        print('📥 Response data: ${response.data}');
        return Project.fromJson(response.data);
      } else {
        print('❌ Failed to create project: ${response.statusCode}');
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Error creating project: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  /// Update project
  Future<Project> updateProject(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.projectsEndpoint}$id/',
        data: data,
      );

      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      } else {
        throw Exception('Failed to update project');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete project
  Future<void> deleteProject(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.projectsEndpoint}$id/');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete project');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send join request
  Future<void> sendJoinRequest(String projectId, {String message = ''}) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.projectsEndpoint}$projectId/join/',
        data: {'message': message},
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send join request');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all join requests for the current user
  Future<List<Map<String, dynamic>>> getJoinRequests() async {
    try {
      final response = await _apiClient.get(ApiConfig.joinRequestsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Failed to load join requests');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve a join request
  Future<void> approveJoinRequest(int requestId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.joinRequestsEndpoint}$requestId/approve/',
        data: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to approve request');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reject a join request
  Future<void> rejectJoinRequest(int requestId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.joinRequestsEndpoint}$requestId/reject/',
        data: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject request');
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