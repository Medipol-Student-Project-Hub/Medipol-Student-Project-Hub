import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import 'edit_project_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  bool _hasRequestedJoin = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.currentUser?.name == project.creator;
    final isStudent = authProvider.userType == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Project',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProjectPage(project: project),
                  ),
                );

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please refresh to see changes')),
                  );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title.isNotEmpty ? project.title : 'Untitled Project',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(project.status),
                    ],
                  ),
                  if (project.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      project.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${project.progress}% Complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (project.description.isNotEmpty)
              _buildSection(
                context,
                title: 'Description',
                child: Text(
                  project.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // Project Details
            _buildSection(
              context,
              title: 'Project Details',
              child: Column(
                children: [
                  _buildDetailRow(context, 'Team Size', project.teamSizeDisplay),
                  if (project.startDate.isNotEmpty)
                    _buildDetailRow(context, 'Start Date', project.startDate),
                  if (project.duration.isNotEmpty)
                    _buildDetailRow(context, 'Duration', project.duration),
                  if (project.faculty.isNotEmpty)
                    _buildDetailRow(context, 'Faculty', project.faculty),
                ],
              ),
            ),

            // Looking For
            if (project.lookingFor.isNotEmpty)
              _buildSection(
                context,
                title: 'Looking For',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.lookingFor
                      .map((role) => Chip(
                            label: Text(role),
                            backgroundColor: const Color.fromRGBO(14, 165, 233, 0.1),
                            labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                          ))
                      .toList(),
                ),
              ),

            // Requirements
            if (project.requirements.isNotEmpty)
              _buildSection(
                context,
                title: 'Requirements',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: project.requirements
                      .map((req) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 20)),
                                Expanded(child: Text(req)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Objectives
            if (project.objectives.isNotEmpty)
              _buildSection(
                context,
                title: 'Project Objectives',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: project.objectives
                      .map((obj) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 20)),
                                Expanded(child: Text(obj)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Creator Info
            if (project.creator.isNotEmpty)
              _buildSection(
                context,
                title: 'Project Creator',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0EA5E9),
                    child: Text(
                      project.creator[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(project.creator),
                  subtitle: project.faculty.isNotEmpty ? Text(project.faculty) : null,
                ),
              ),

            // Students Section
            _buildSection(
              context,
              title: 'Students',
              child: project.teamMembers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No students have joined this project yet',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      children: project.teamMembers
                          .map((member) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(member.name.isNotEmpty ? member.name : 'Team Member'),
                                subtitle: Text(member.role),
                              ))
                          .toList(),
                    ),
            ),

            // Supervisor
            if (project.supervisor != null && project.supervisor!.isNotEmpty)
              _buildSection(
                context,
                title: 'Supervisor',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0EA5E9),
                    child: Icon(Icons.school, color: Colors.white),
                  ),
                  title: Text(project.supervisor!),
                  subtitle: const Text('Project Advisor'),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: (isOwner || !isStudent) ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _hasRequestedJoin ? null : () {
              _showJoinRequestDialog(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_hasRequestedJoin ? 'Request Sent' : 'Request to Join Project'),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    const greenColor = Color(0xFF10B981);
    const blueColor = Color(0xFF0EA5E9);
    const grayColor = Color(0xFF6B7280);
    
    Color color;
    switch (status) {
      case 'Recruiting':
        color = greenColor;
        break;
      case 'In Progress':
        color = blueColor;
        break;
      default:
        color = grayColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.isNotEmpty ? status : 'Planning',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showJoinRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join Request'),
        content: const Text(
          'Your request to join this project will be sent to the project creator. '
          'They will review your profile and respond accordingly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
              final success = await projectProvider.requestJoinProject(widget.project.id);

              if (mounted) {
                if (success) {
                  setState(() {
                    _hasRequestedJoin = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Join request sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(projectProvider.error ?? 'Failed to send join request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}