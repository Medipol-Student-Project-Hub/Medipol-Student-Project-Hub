import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<Project> _projects = [];
  List<Project> _myProjects = [];
  bool _isLoading = false;
  String? _error;

  List<Project> get projects => _projects;
  List<Project> get myProjects => _myProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _projects = await _projectService.getAllProjects();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _projects = [];
      notifyListeners();
    }
  }

  Future<void> loadMyProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _myProjects = await _projectService.getMyProjects();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _myProjects = [];
      notifyListeners();
    }
  }

  Future<Project?> getProjectById(String id) async {
    try {
      return await _projectService.getProjectById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void searchProjects(String query) {
    // UI tarafında filtreleniyorsa burada sadece notify yeter
    notifyListeners();
  }

  /// Create new project (backend’e uyumlu kategori value ile gönderilecek)
  Future<bool> createProject({
    required String title,
    required String description,
    required String category,
    required List<String> lookingFor,
    int? maxTeamSize,
    String? startDate,
    String? duration,
    List<String>? requirements,
    List<String>? objectives,
    String? supervisorId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _projectService.createProject(
        title: title,
        description: description,
        category: category,
        lookingFor: lookingFor,
        maxTeamSize: maxTeamSize,
        startDate: startDate,
        duration: duration,
        requirements: requirements,
        objectives: objectives,
        supervisorId: supervisorId,
      );

      await loadProjects();
      await loadMyProjects();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestJoinProject(String projectId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _projectService.sendJoinRequest(projectId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([
      loadProjects(),
      loadMyProjects(),
    ]);
  }
}
