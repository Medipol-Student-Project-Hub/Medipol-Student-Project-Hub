import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userType => _currentUser is Student ? 'student' : 'faculty';

  /// Initialize auth state on app start
  Future<void> initializeAuth() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getProfile();
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      // User not logged in or token expired
      _isAuthenticated = false;
    }
  }

  /// Login user
  Future<bool> login(String email, String password, String userType) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authService.login(
        email: email,
        password: password,
        userType: userType,
      );

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Register student
  Future<bool> registerStudent({
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authService.registerStudent(
        email: email,
        password: password,
        name: name,
        studentId: studentId,
        department: department,
        year: year,
        faculty: faculty,
        skills: skills,
      );

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Register faculty
  Future<bool> registerFaculty({
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authService.registerFaculty(
        email: email,
        password: password,
        name: name,
        facultyId: facultyId,
        department: department,
        faculty: faculty,
        title: title,
        specialization: specialization,
      );

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore errors during logout
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    try {
      _currentUser = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
