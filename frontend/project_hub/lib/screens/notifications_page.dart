import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bell,
                  size: 64,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Medipol Project Hub! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Stay Updated with Your Projects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                icon: LucideIcons.userPlus,
                title: 'Project Invitations',
                description:
                    'Get notified when someone invites you to join their project',
                color: const Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: LucideIcons.messageSquare,
                title: 'Message Alerts',
                description:
                    'Never miss a message from your team members or supervisors',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: LucideIcons.trendingUp,
                title: 'Project Updates',
                description:
                    'Stay informed about milestones, deadlines, and progress',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: LucideIcons.circleCheck,
                title: 'Task Completions',
                description:
                    'Get notified when team members complete their tasks',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.info,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive notifications here once you join or create projects',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}