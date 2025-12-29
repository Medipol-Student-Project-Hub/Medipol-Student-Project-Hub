import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF0EA5E9),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user is Student)
                    Text(
                      'Student ID: ${user.studentId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  if (user is Faculty)
                    Text(
                      user.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Information Cards
            if (user is Student) ..._buildStudentInfo(context, user),
            if (user is Faculty) ..._buildFacultyInfo(context, user),

            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  authProvider.logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentInfo(BuildContext context, Student student) {
    return [
      _buildInfoCard(
        context,
        title: 'Contact Information',
        items: [
          _buildInfoRow(context, 'Email', student.email),
          _buildInfoRow(context, 'Department', student.department),
          _buildInfoRow(context, 'Faculty', student.faculty),
          _buildInfoRow(context, 'Year', student.year),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        context,
        title: 'Skills',
        items: [
          if (student.skills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No skills added yet. Tap edit to add skills.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: student.skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: const Color.fromRGBO(14, 165, 233, 0.1),
                        labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                      ))
                  .toList(),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildFacultyInfo(BuildContext context, Faculty faculty) {
    return [
      _buildInfoCard(
        context,
        title: 'Contact Information',
        items: [
          _buildInfoRow(context, 'Email', faculty.email),
          _buildInfoRow(context, 'Department', faculty.department),
          _buildInfoRow(context, 'Faculty', faculty.faculty),
          _buildInfoRow(context, 'Office', faculty.officeLocation),
          _buildInfoRow(context, 'Experience', '${faculty.yearsOfExperience} years'),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoCard(
        context,
        title: 'Specialization',
        items: [
          if (faculty.specialization.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No specializations added yet. Tap edit to add.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: faculty.specialization
                  .map((spec) => Chip(
                        label: Text(spec),
                        backgroundColor: const Color.fromRGBO(14, 165, 233, 0.1),
                        labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                      ))
                  .toList(),
            ),
        ],
      ),
    ];
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}