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

      // Listeyi tek yerde birleştir
      final merged = <Map<String, dynamic>>[
        ...students.map((e) => {...e, '_type': 'student'}),
        ...faculty.map((e) => {...e, '_type': 'faculty'}),
      ];

      setState(() {
        _allUsers = merged;
        _filtered = merged;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
        final name = (u['name'] ?? u['user']?['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? u['user']?['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  String _displayName(Map<String, dynamic> u) {
    return (u['name'] ?? u['user']?['name'] ?? 'Unknown').toString();
  }

  String _displayEmail(Map<String, dynamic> u) {
    return (u['email'] ?? u['user']?['email'] ?? '').toString();
  }

  String _userId(Map<String, dynamic> u) {
    // Backend’te bazen profile objesi içinde user var, bazen direkt user id var.
    final id = u['id'] ?? u['user']?['id'];
    return id?.toString() ?? '';
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
                    child: Text(_error!, textAlign: TextAlign.center),
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
                          ? const Center(child: Text('No users found.'))
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final u = _filtered[index];
                                final name = _displayName(u);
                                final email = _displayEmail(u);
                                final id = _userId(u);

                                return ListTile(
                                  title: Text(name),
                                  subtitle: Text(email.isNotEmpty ? email : 'User ID: $id'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: id.isEmpty
                                      ? null
                                      : () async {
                                          final conv = await messageProvider.createConversation(
                                            participantIds: [id],
                                            isGroup: false,
                                            name: name, // backend ignore etse bile UI için güzel
                                          );

                                          if (!mounted) return;

                                          if (conv != null) {
                                            Navigator.pop(context, conv);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  messageProvider.error ?? 'Failed to create conversation',
                                                ),
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
