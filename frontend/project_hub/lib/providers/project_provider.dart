import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<Project> _allProjects = [];
  List<Project> _allMyProjects = [];
  List<Project> _filteredProjects = [];
  List<Project> _filteredMyProjects = [];
  
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Project> get projects => _searchQuery.isEmpty ? _allProjects : _filteredProjects;
  List<Project> get myProjects => _searchQuery.isEmpty ? _allMyProjects : _filteredMyProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allProjects = await _projectService.getAllProjects();
      _applySearch();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _allProjects = [];
      _filteredProjects = [];
      notifyListeners();
    }
  }

  Future<void> loadMyProjects() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allMyProjects = await _projectService.getMyProjects();
      _applySearch();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _allMyProjects = [];
      _filteredMyProjects = [];
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
    _searchQuery = query.toLowerCase().trim();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProjects = _allProjects;
      _filteredMyProjects = _allMyProjects;
      return;
    }

    _filteredProjects = _allProjects.where((project) {
      return project.title.toLowerCase().contains(_searchQuery) ||
          project.description.toLowerCase().contains(_searchQuery) ||
          project.category.toLowerCase().contains(_searchQuery) ||
          project.creator.toLowerCase().contains(_searchQuery) ||
          project.lookingFor.any((role) => role.toLowerCase().contains(_searchQuery));
    }).toList();

    _filteredMyProjects = _allMyProjects.where((project) {
      return project.title.toLowerCase().contains(_searchQuery) ||
          project.description.toLowerCase().contains(_searchQuery) ||
          project.category.toLowerCase().contains(_searchQuery) ||
          project.creator.toLowerCase().contains(_searchQuery) ||
          project.lookingFor.any((role) => role.toLowerCase().contains(_searchQuery));
    }).toList();
  }

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
    String? supervisorName,
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
        supervisorName: supervisorName,
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

  Future<bool> updateProject(String projectId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _projectService.updateProject(projectId, data);

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