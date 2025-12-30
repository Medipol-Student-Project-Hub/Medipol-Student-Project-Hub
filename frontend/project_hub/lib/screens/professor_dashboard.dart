import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';

/// Professor dashboard screen showing supervised projects and statistics.
///
/// Displays real-time data including:
/// - Active and completed project counts
/// - Total students across all supervised projects
/// - List of supervised projects with team members and progress
class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  // List of projects supervised by this faculty member
  List<Project> _supervisedProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupervisedProjects();
  }

  /// Load all projects supervised by the current faculty member from the API.
  Future<void> _loadSupervisedProjects() async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    // For faculty, loadMyProjects fetches supervised projects
    await projectProvider.loadMyProjects();
    setState(() {
      _supervisedProjects = projectProvider.myProjects;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final User? user = auth.currentUser;

    // Turkish name comes from backend (user.name)
    final String name = (user?.name ?? '').trim();

    // If user is Faculty, use its fields; otherwise fall back safely
    final Faculty? faculty = user is Faculty ? user : null;

    final String title = (faculty?.title ?? '').trim().isNotEmpty
        ? faculty!.title.trim()
        : 'Prof. Dr.';

    final String department = (faculty?.department ?? '').trim().isNotEmpty
        ? faculty!.department.trim()
        : 'Computer Engineering Department';

    final String experience = faculty != null
        ? '${faculty.yearsOfExperience} years of experience'
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF0EA5E9),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? '—' : '$title $name',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(department),
                        const SizedBox(height: 2),
                        Text(
                          experience,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatisticsGrid(context),
              ),

            const SizedBox(height: 24),

            // Supervised Projects
            if (!_isLoading)
              _buildSection(
                context,
                title: 'Supervised Projects',
                child: _supervisedProjects.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No supervised projects yet',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : Column(
                        children: _supervisedProjects
                            .map((project) => _buildProjectCard(context, project))
                            .toList(),
                      ),
              ),

            const SizedBox(height: 16),

            // Account/Logout Section
            _buildSection(
              context,
              title: 'Account',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Log out', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build the statistics grid showing key metrics.
  ///
  /// Calculates and displays:
  /// - Active projects (not completed)
  /// - Total unique students across all projects
  /// - Pending reviews (placeholder - not implemented yet)
  /// - Completed projects
  Widget _buildStatisticsGrid(BuildContext context) {
    // Calculate project status counts
    final activeProjects = _supervisedProjects.where((p) => p.status != 'Completed').length;
    final completedProjects = _supervisedProjects.where((p) => p.status == 'Completed').length;

    // Count unique students across all supervised projects
    // Using a Set to automatically handle duplicates
    final allStudents = <String>{};
    for (var project in _supervisedProjects) {
      allStudents.addAll(project.teamMembers.map((m) => m.name));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(child: _buildStatCard(context, LucideIcons.folderOpen, '$activeProjects', 'Active Projects', const Color(0xFF0EA5E9))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, LucideIcons.users, '${allStudents.length}', 'Total Students', const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, LucideIcons.clock, '0', 'Pending Reviews', const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, LucideIcons.circleCheck, '$completedProjects', 'Completed', const Color(0xFF8B5CF6))),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard(context, LucideIcons.folderOpen, '$activeProjects', 'Active Projects', const Color(0xFF0EA5E9))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, LucideIcons.users, '${allStudents.length}', 'Total Students', const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, LucideIcons.clock, '0', 'Pending Reviews', const Color(0xFFF59E0B))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, LucideIcons.circleCheck, '$completedProjects', 'Completed', const Color(0xFF8B5CF6))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (project.category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(project.category, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (project.teamMembers.isNotEmpty)
              Text(
                'Students: ${project.teamMembers.map((m) => m.name).join(', ')}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: project.progress / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${project.progress}% Complete', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text('Team: ${project.teamSizeDisplay}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
