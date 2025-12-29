import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAllFaculty() async {
    try {
      final response = await _apiClient.get(ApiConfig.facultyEndpoint);

      if (response.statusCode == 200) {
        final dynamic raw = response.data;
        final List<dynamic> data = (raw is Map && raw['results'] is List) ? raw['results'] : (raw as List);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Failed to load faculty');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _apiClient.get(ApiConfig.studentsEndpoint);

      if (response.statusCode == 200) {
        final dynamic raw = response.data;
        final List<dynamic> data = (raw is Map && raw['results'] is List) ? raw['results'] : (raw as List);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Failed to load students');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data.containsKey('detail')) return data['detail'].toString();
        if (data.containsKey('error')) return data['error'].toString();
        for (var value in data.values) {
          if (value is String) return value;
          if (value is List && value.isNotEmpty) return value.first.toString();
        }
      }
      return 'Error: ${error.response!.statusCode}';
    }
    return 'Network error. Please check your connection.';
  }
}
