import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  
  // For students
  TextEditingController? _studentIdController;
  List<String> _selectedSkills = [];
  
  // For faculty
  TextEditingController? _titleController;
  TextEditingController? _officeController;
  List<String> _selectedSpecializations = [];
  
  final List<String> _availableSkills = [
    'Flutter',
    'React',
    'Python',
    'Java',
    'JavaScript',
    'UI/UX Design',
    'Machine Learning',
    'Data Science',
    'Mobile Development',
    'Web Development',
    'Database Management',
    'DevOps',
    'C++',
    'C#',
    '.NET',
    'PHP',
    'Ruby',
    'Swift',
    'Kotlin',
  ];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _departmentController = TextEditingController(text: '');
    
    if (user is Student) {
      _studentIdController = TextEditingController(text: user.studentId);
      _departmentController.text = user.department;
      _selectedSkills = List.from(user.skills);
    } else if (user is Faculty) {
      _titleController = TextEditingController(text: user.title);
      _departmentController.text = user.department;
      _officeController = TextEditingController(text: user.officeLocation);
      _selectedSpecializations = List.from(user.specialization);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _studentIdController?.dispose();
    _titleController?.dispose();
    _officeController?.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Implement actual API call to update profile
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    final isStudent = user is Student;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
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
              // Profile Picture
              Center(
                child: Stack(
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0EA5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(LucideIcons.user),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(LucideIcons.mail),
                  border: OutlineInputBorder(),
                ),
                enabled: false,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              if (isStudent) ...[
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    prefixIcon: Icon(LucideIcons.hash),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
              ],

              if (!isStudent) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Academic Title',
                    prefixIcon: Icon(LucideIcons.graduationCap),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(LucideIcons.building),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (!isStudent) ...[
                TextFormField(
                  controller: _officeController,
                  decoration: const InputDecoration(
                    labelText: 'Office Location',
                    prefixIcon: Icon(LucideIcons.mapPin),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              if (isStudent) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Skills'),
                const SizedBox(height: 8),
                Text(
                  'Select your skills to help others find you',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSkills.add(skill);
                          } else {
                            _selectedSkills.remove(skill);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0EA5E9).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF0EA5E9),
                    );
                  }).toList(),
                ),
              ],

              if (!isStudent) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Specializations'),
                const SizedBox(height: 8),
                Text(
                  'Add your areas of expertise',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSpecializations.map((spec) {
                    return Chip(
                      label: Text(spec),
                      onDeleted: () {
                        setState(() => _selectedSpecializations.remove(spec));
                      },
                      backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                      labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Add Specialization',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.add),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && !_selectedSpecializations.contains(value.trim())) {
                      setState(() => _selectedSpecializations.add(value.trim()));
                    }
                  },
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
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
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}