import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/project_provider.dart';
import '../services/user_service.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamSizeController = TextEditingController();
  final _durationController = TextEditingController();

  final UserService _userService = UserService();

  // ✅ Backend expects VALUES, not labels
  final List<Map<String, String>> _categories = const [
    {'label': 'Engineering', 'value': 'engineering'},
    {'label': 'Design', 'value': 'design'},
    {'label': 'Health', 'value': 'health'},
    {'label': 'Business', 'value': 'business'},
    {'label': 'AI', 'value': 'ai'},
    {'label': 'Web', 'value': 'web'},
    {'label': 'Mobile', 'value': 'mobile'},
    {'label': 'Research', 'value': 'research'},
    {'label': 'Other', 'value': 'other'},
  ];

  String _selectedCategoryValue = 'engineering'; // ✅ Default value
  DateTime? _startDate;

  String? _selectedSupervisor; // id as string
  List<Map<String, dynamic>> _supervisors = [];
  bool _loadingSupervisors = false;

  final List<String> _roles = [];
  final List<String> _skills = [];
  final _roleController = TextEditingController();
  final _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    setState(() => _loadingSupervisors = true);
    try {
      final faculty = await _userService.getAllFaculty();
      if (mounted) {
        setState(() {
          _supervisors = faculty;
          _loadingSupervisors = false;

          // ✅ If previously selected supervisor is not in new list, reset to null
          if (_selectedSupervisor != null) {
            final exists = _supervisors.any((f) => f['id'].toString() == _selectedSupervisor);
            if (!exists) _selectedSupervisor = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSupervisors = false;
          _supervisors = [];
          _selectedSupervisor = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load supervisors: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDateOnly(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd'; // ✅ Django DateField friendly
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Safe dropdown value: empty string for "No supervisor", or actual ID
    final String safeSelectedSupervisor = (_selectedSupervisor != null &&
            _selectedSupervisor!.isNotEmpty &&
            _supervisors.any((f) => f['id'].toString() == _selectedSupervisor))
        ? _selectedSupervisor!
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        actions: [
          IconButton(
            tooltip: 'Refresh supervisors',
            onPressed: _loadingSupervisors ? null : _loadSupervisors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategoryValue,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['value'],
                        child: Text(c['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryValue = v!),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please select a category' : null,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Timeline'),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Date'),
                subtitle: Text(
                  _startDate == null
                      ? 'Select start date'
                      : _formatDateOnly(_startDate!),
                ),
                trailing: const Icon(LucideIcons.calendar),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g., 6 months',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Team Requirements'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _teamSizeController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Team Size',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),
              _buildChipInput(
                label: 'Looking For (Roles)',
                hint: 'e.g., Backend Developer',
                controller: _roleController,
                items: _roles,
                onAdd: () {
                  final t = _roleController.text.trim();
                  if (t.isNotEmpty) {
                    setState(() {
                      _roles.add(t);
                      _roleController.clear();
                    });
                  }
                },
                onRemove: (i) => setState(() => _roles.removeAt(i)),
              ),

              const SizedBox(height: 16),
              _buildChipInput(
                label: 'Required Skills',
                hint: 'e.g., Flutter, Python',
                controller: _skillController,
                items: _skills,
                onAdd: () {
                  final t = _skillController.text.trim();
                  if (t.isNotEmpty) {
                    setState(() {
                      _skills.add(t);
                      _skillController.clear();
                    });
                  }
                },
                onRemove: (i) => setState(() => _skills.removeAt(i)),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Supervisor (Optional)'),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: safeSelectedSupervisor, // ✅ Critical fix
                decoration: InputDecoration(
                  labelText: 'Select Supervisor',
                  border: const OutlineInputBorder(),
                  suffixIcon: _loadingSupervisors
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('No supervisor'),
                  ),
                  ..._supervisors.map((faculty) {
                    final id = faculty['id'].toString();
                    final name = (faculty['user']?['name'] ??
                            faculty['name'] ??
                            faculty['email'] ??
                            'Faculty')
                        .toString();
                    final title = (faculty['title'] ?? '').toString();
                    final displayName = title.isNotEmpty ? '$title $name' : name;

                    return DropdownMenuItem(
                      value: id,
                      child: Text(displayName, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: _loadingSupervisors
                    ? null
                    : (v) => setState(() => _selectedSupervisor = (v == '' ? null : v)),
                isExpanded: true,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Create Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChipInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(icon: const Icon(LucideIcons.plus), onPressed: onAdd),
          ),
          onSubmitted: (_) => onAdd(),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => onRemove(entry.key),
                backgroundColor: const Color.fromRGBO(14, 165, 233, 0.1),
                labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final success = await provider.createProject(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategoryValue,
      lookingFor: _roles,
      maxTeamSize: int.tryParse(_teamSizeController.text),
      startDate: _startDate == null ? null : _formatDateOnly(_startDate!),
      duration: _durationController.text.trim(),
      requirements: _skills,
      objectives: const [],
      supervisorId: _selectedSupervisor,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create project'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _teamSizeController.dispose();
    _durationController.dispose();
    _roleController.dispose();
    _skillController.dispose();
    super.dispose();
  }
}