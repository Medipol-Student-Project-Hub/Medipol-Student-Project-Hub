class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String productionUrl = 'https://your-production-url.com';

  static const String apiPrefix = '/api';

  // Auth endpoints
  static const String loginEndpoint = '$apiPrefix/auth/login/';
  static const String registerStudentEndpoint = '$apiPrefix/auth/register/student/';
  static const String registerFacultyEndpoint = '$apiPrefix/auth/register/faculty/';
  static const String refreshTokenEndpoint = '$apiPrefix/auth/refresh/';
  static const String logoutEndpoint = '$apiPrefix/auth/logout/';
  static const String profileEndpoint = '$apiPrefix/auth/profile/';
  static const String changePasswordEndpoint = '$apiPrefix/auth/change-password/';
  
  // Password reset endpoints
  static const String forgotPasswordEndpoint = '$apiPrefix/auth/forgot-password/';
  static const String resetPasswordEndpoint = '$apiPrefix/auth/reset-password/';

  // Users
  static const String usersEndpoint = '$apiPrefix/auth/';

  // Projects
  static const String projectsEndpoint = '$apiPrefix/projects/';
  static const String joinRequestsEndpoint = '$apiPrefix/requests/';
  static const String milestonesEndpoint = '$apiPrefix/milestones/';

  // Teams
  static const String teamsEndpoint = '$apiPrefix/teams/';

  // Messaging
  static const String conversationsEndpoint = '$apiPrefix/messaging/conversations/';

  // Notifications
  static const String notificationsEndpoint = '$apiPrefix/notifications/';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static String getBaseUrl() {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;
    return baseUrl;
  }
}