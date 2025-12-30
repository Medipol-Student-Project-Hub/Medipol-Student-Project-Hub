import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/project_service.dart';

class JoinRequestsPage extends StatefulWidget {
  const JoinRequestsPage({super.key});

  @override
  State<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends State<JoinRequestsPage>
    with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService();
  late TabController _tabController;

  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _projectService.getJoinRequests();
      setState(() {
        _allRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _sentRequests {
    // Requests sent BY me (where is_sent_by_me is true)
    return _allRequests.where((r) {
      final isSentByMe = r['is_sent_by_me'] as bool? ?? false;
      return isSentByMe;
    }).toList();
  }

  List<Map<String, dynamic>> get _receivedRequests {
    // Requests TO my projects (where is_sent_by_me is false)
    return _allRequests.where((r) {
      final isSentByMe = r['is_sent_by_me'] as bool? ?? false;
      return !isSentByMe;
    }).toList();
  }

  Future<void> _approveRequest(int requestId) async {
    try {
      await _projectService.approveJoinRequest(requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await _projectService.rejectJoinRequest(requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF0EA5E9),
          tabs: const [
            Tab(text: 'My Requests'),
            Tab(text: 'Incoming Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circleAlert,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error loading requests',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_sentRequests, isSent: true),
                    _buildRequestsList(_receivedRequests, isSent: false),
                  ],
                ),
    );
  }

  Widget _buildRequestsList(List<Map<String, dynamic>> requests,
      {required bool isSent}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSent ? LucideIcons.send : LucideIcons.inbox,
              size: 64,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              isSent ? 'No requests sent yet' : 'No incoming requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isSent
                  ? 'Explore projects and send join requests'
                  : 'Requests to join your projects will appear here',
              style: const TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request, isSent: isSent);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, {required bool isSent}) {
    final projectInfo = request['project_info'] as Map<String, dynamic>?;
    final studentInfo = request['student_info'] as Map<String, dynamic>?;
    final status = request['status'] as String? ?? 'pending';
    final message = request['message'] as String? ?? '';
    final requestDate = request['request_date'] as String? ?? '';
    final requestId = request['id'] as int;

    final projectTitle = projectInfo?['title'] ?? 'Unknown Project';
    final projectOwner = projectInfo?['owner'] ?? '';
    final studentName = studentInfo?['user']?['name'] ?? 'Unknown Student';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = LucideIcons.circleCheck;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = LucideIcons.circleX;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = LucideIcons.clock;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0EA5E9),
                  child: Text(
                    isSent
                        ? (projectTitle.isNotEmpty ? projectTitle[0].toUpperCase() : '?')
                        : (studentName.isNotEmpty ? studentName[0].toUpperCase() : '?'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent ? projectTitle : studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isSent ? 'Owner: $projectOwner' : 'Wants to join: $projectTitle',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (requestDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Requested: ${_formatDate(requestDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
            ],
            // Show approve/reject buttons for incoming pending requests
            if (!isSent && status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectRequest(requestId),
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRequest(requestId),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
