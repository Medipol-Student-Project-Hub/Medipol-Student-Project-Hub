import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';

class ProfessorDashboard extends StatelessWidget {
  const ProfessorDashboard({super.key});

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

            // Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = _buildStatCards(context);
                  if (constraints.maxWidth > 600) {
                    return Row(children: cards);
                  }
                  return Column(
                    children: [
                      Row(
                        children: [
                          cards[0],
                          const SizedBox(width: 12),
                          cards[1],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          cards[2],
                          const SizedBox(width: 12),
                          cards[3],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Supervised Projects (demo items — keep same UI)
            _buildSection(
              context,
              title: 'Supervised Projects',
              child: Column(
                children: [
                  _buildProjectCard(
                    context,
                    title: 'AI Medical Diagnosis',
                    students: const ['Beril Mutlu', 'Erva Şengül'],
                    progress: 15,
                    category: 'AI & ML',
                    lastUpdate: '2 days ago',
                  ),
                  _buildProjectCard(
                    context,
                    title: 'Smart Campus Navigation',
                    students: const ['Azra Karakaya', 'Erva Şengül'],
                    progress: 45,
                    category: 'Mobile Dev',
                    lastUpdate: '1 day ago',
                  ),
                ],
              ),
            ),

            // Pending Reviews
            _buildSection(
              context,
              title: 'Pending Reviews',
              child: Column(
                children: [
                  _buildReviewCard(
                    context,
                    title: 'Progress Report - Week 4',
                    student: 'Beril Mutlu',
                    type: 'Report',
                    priority: 'High',
                    date: 'Feb 18, 2025',
                  ),
                  _buildReviewCard(
                    context,
                    title: 'Milestone Completion Request',
                    student: 'Azra Karakaya',
                    type: 'Milestone',
                    priority: 'Medium',
                    date: 'Feb 17, 2025',
                  ),
                ],
              ),
            ),

            // Upcoming Meetings
            _buildSection(
              context,
              title: 'Upcoming Meetings',
              child: Column(
                children: [
                  _buildMeetingCard(
                    context,
                    title: 'Project Review Meeting',
                    students: const ['Beril Mutlu', 'Ayşe Çapacı'],
                    dateTime: 'Feb 22, 2025 - 10:00 AM',
                    location: 'Block A, Room 405',
                  ),
                  _buildMeetingCard(
                    context,
                    title: 'Milestone Discussion',
                    students: const ['Azra Karakaya'],
                    dateTime: 'Feb 23, 2025 - 2:00 PM',
                    location: 'Block A, Room 405',
                  ),
                ],
              ),
            ),

            // Recent Activity
            _buildSection(
              context,
              title: 'Recent Activity',
              child: Column(
                children: [
                  _buildActivityItem(
                    context,
                    icon: LucideIcons.fileText,
                    color: const Color(0xFF0EA5E9),
                    title: 'Beril Mutlu submitted a progress report',
                    time: '2 hours ago',
                  ),
                  _buildActivityItem(
                    context,
                    icon: LucideIcons.messageSquare,
                    color: const Color(0xFF10B981),
                    title: 'New message from Erva Şengül',
                    time: '5 hours ago',
                  ),
                  _buildActivityItem(
                    context,
                    icon: LucideIcons.circleCheck,
                    color: const Color(0xFF8B5CF6),
                    title: 'Azra Karakaya completed a milestone',
                    time: '1 day ago',
                  ),
                  _buildActivityItem(
                    context,
                    icon: LucideIcons.circleAlert,
                    color: const Color(0xFFF59E0B),
                    title: 'AI Medical Diagnosis project needs attention',
                    time: '2 days ago',
                  ),
                ],
              ),
            ),

            // ✅ Logout area at the bottom
            _buildSection(
              context,
              title: 'Account',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();

                        if (!context.mounted) return;

                        // Go back to Get Started (WelcomePage)
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/welcome',
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    return [
      Expanded(
        child: _buildStatCard(
          context,
          icon: LucideIcons.folderOpen,
          value: '8',
          label: 'Active Projects',
          color: const Color(0xFF0EA5E9),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          context,
          icon: LucideIcons.users,
          value: '24',
          label: 'Total Students',
          color: const Color(0xFF10B981),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          context,
          icon: LucideIcons.clock,
          value: '3',
          label: 'Pending Reviews',
          color: const Color(0xFFF59E0B),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          context,
          icon: LucideIcons.circleCheck,
          value: '15',
          label: 'Completed',
          color: const Color(0xFF8B5CF6),
        ),
      ),
    ];
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
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

  Widget _buildProjectCard(
    BuildContext context, {
    required String title,
    required List<String> students,
    required int progress,
    required String category,
    required String lastUpdate,
  }) {
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
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(category, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Students: ${students.join(', ')}',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$progress% Complete', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text('Updated $lastUpdate', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required String student,
    required String type,
    required String priority,
    required String date,
  }) {
    const redColor = Color(0xFFEF4444);
    const orangeColor = Color(0xFFF59E0B);
    const greenColor = Color(0xFF10B981);

    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = redColor;
        break;
      case 'Medium':
        priorityColor = orangeColor;
        break;
      default:
        priorityColor = greenColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('From: $student'),
            Text('Type: $type • $date'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            priority,
            style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(
    BuildContext context, {
    required String title,
    required List<String> students,
    required String dateTime,
    required String location,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('With: ${students.join(', ')}'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(dateTime),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
