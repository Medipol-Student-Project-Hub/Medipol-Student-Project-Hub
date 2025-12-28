import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Profile editing will be connected to the backend.\n\n'
          'For demo: this page proves navigation works.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
