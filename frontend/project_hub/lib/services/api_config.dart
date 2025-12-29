/// API Configuration
/// Contains base URLs and API endpoints configuration
class ApiConfig {
  // Base URL - change this to match your backend server
  // For Android emulator: use 10.0.2.2
  // For iOS simulator: use localhost
  // For physical device: use your computer's local IP address
  static const String baseUrl = 'http://localhost:8000';

  // Alternative URLs for different environments
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String productionUrl = 'https://your-production-url.com';

  // API Endpoints
  static const String apiPrefix = '/api';

  // Auth endpoints
  static const String loginEndpoint = '$apiPrefix/auth/login/';
  static const String registerStudentEndpoint = '$apiPrefix/auth/register/student/';
  static const String registerFacultyEndpoint = '$apiPrefix/auth/register/faculty/';
  static const String refreshTokenEndpoint = '$apiPrefix/auth/refresh/';
  static const String logoutEndpoint = '$apiPrefix/auth/logout/';
  static const String profileEndpoint = '$apiPrefix/auth/profile/';
  static const String changePasswordEndpoint = '$apiPrefix/auth/change-password/';
  static const String forgotPasswordEndpoint = '$apiPrefix/auth/forgot-password/';
  static const String resetPasswordEndpoint = '$apiPrefix/auth/reset-password/';

  // Users endpoints (under auth)
  static const String studentsEndpoint = '$apiPrefix/auth/students/';
  static const String facultyEndpoint = '$apiPrefix/auth/faculty/';

  // Projects endpoints
  static const String projectsEndpoint = '$apiPrefix/projects/';
  static const String joinRequestsEndpoint = '$apiPrefix/projects/requests/';
  static const String milestonesEndpoint = '$apiPrefix/projects/milestones/';

  // Teams endpoints
  static const String teamsEndpoint = '$apiPrefix/teams/';

  // Messaging endpoints
  static const String conversationsEndpoint = '$apiPrefix/messaging/conversations/';
  static const String messagesEndpoint = '$apiPrefix/messaging/messages/';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Get base URL based on platform
  static String getBaseUrl() {
    // You can add logic here to detect platform and return appropriate URL
    // For now, returning the default localhost URL
    return baseUrl;
  }
}
