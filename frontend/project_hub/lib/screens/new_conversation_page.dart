import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/message_provider.dart';
import '../services/user_service.dart';

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_applyFilter);
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final students = await _userService.getAllStudents();
      final faculty = await _userService.getAllFaculty();

      // Merge lists
      final merged = <Map<String, dynamic>>[
        ...students.map((e) => {...e, '_type': 'student'}),
        ...faculty.map((e) => {...e, '_type': 'faculty'}),
      ];

      if (mounted) {
        setState(() {
          _allUsers = merged;
          _filtered = merged;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _allUsers);
      return;
    }

    setState(() {
      _filtered = _allUsers.where((u) {
        final name = _displayName(u).toLowerCase();
        final email = _displayEmail(u).toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  String _displayName(Map<String, dynamic> u) {
    // Try multiple possible name locations
    String name = '';
    
    // Check nested user object first
    if (u['user'] is Map) {
      name = (u['user']['name'] ?? '').toString().trim();
    }
    
    // If still empty, check direct name field
    if (name.isEmpty) {
      name = (u['name'] ?? '').toString().trim();
    }
    
    // If still empty, try email
    if (name.isEmpty) {
      name = _displayEmail(u);
    }
    
    // Last resort
    if (name.isEmpty) {
      name = 'User ${u['id'] ?? 'Unknown'}';
    }
    
    return name;
  }

  String _displayEmail(Map<String, dynamic> u) {
    // Check nested user object first
    if (u['user'] is Map) {
      final email = (u['user']['email'] ?? '').toString().trim();
      if (email.isNotEmpty) return email;
    }
    
    // Check direct email field
    return (u['email'] ?? '').toString().trim();
  }

  String _userId(Map<String, dynamic> u) {
    // Backend sometimes has nested user object, sometimes direct id
    // For conversation creation, we need the actual user ID
    
    // Check if there's a nested user object with ID
    if (u['user'] is Map && u['user']['id'] != null) {
      return u['user']['id'].toString();
    }
    
    // Otherwise use the profile ID (which should link to user)
    final id = u['id'];
    return id?.toString() ?? '';
  }

  String _userType(Map<String, dynamic> u) {
    return (u['_type'] ?? 'student').toString();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.read<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load users',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by name or email...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_search, size: 48),
                                  const SizedBox(height: 16),
                                  const Text('No users found'),
                                  if (_searchCtrl.text.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _applyFilter();
                                      },
                                      child: const Text('Clear search'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final u = _filtered[index];
                                final name = _displayName(u);
                                final email = _displayEmail(u);
                                final id = _userId(u);
                                final type = _userType(u);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: type == 'faculty'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF0EA5E9),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      Text(
                                        type == 'faculty' ? 'Faculty' : 'Student',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: type == 'faculty'
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF0EA5E9),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: id.isEmpty
                                      ? null
                                      : () async {
                                          // Capture context before async gap
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(context);
                                          
                                          // Show loading
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );

                                          final conv = await messageProvider
                                              .createConversation(
                                            participantIds: [id],
                                            isGroup: false,
                                            name: name,
                                          );

                                          if (!mounted) return;

                                          // Close loading dialog
                                          navigator.pop();

                                          if (conv != null) {
                                            navigator.pop(conv);
                                          } else {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  messageProvider.error ??
                                                      'Failed to create conversation',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}