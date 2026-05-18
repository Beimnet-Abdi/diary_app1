import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/glass_back_button.dart';
import 'landing_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  bool _isEditing = false;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _roleController.text = auth.role;
    _orgController.text = auth.organization;
    _localImagePath = auth.profileImagePath;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localImagePath = pickedFile.path;
      });
    }
  }

  void _saveProfile() {
    Provider.of<AuthProvider>(context, listen: false).updateProfile(
      imagePath: _localImagePath,
      role: _roleController.text,
      organization: _orgController.text,
    );
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _localImagePath != null && !kIsWeb
                        ? FileImage(File(_localImagePath!))
                        : (_localImagePath != null && kIsWeb
                            ? NetworkImage(_localImagePath!)
                            : null) as ImageProvider?,
                    child: _localImagePath == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Photo'),
                  ),
                const SizedBox(height: 30),
                if (_isEditing) ...[
                  TextField(
                    controller: _roleController,
                    autofillHints: const [AutofillHints.organizationTitle],
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _orgController,
                    autofillHints: const [AutofillHints.organizationName],
                    decoration: const InputDecoration(labelText: 'Organization', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Profile'),
                  ),
                ] else ...[
                  Text(
                    _roleController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_orgController.text, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
                const SizedBox(height: 40),
                OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingRegistrationScreen()),
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            child: const GlassBackButton(),
          ),
        ],
      ),
    );
  }
}
