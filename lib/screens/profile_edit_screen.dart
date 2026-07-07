import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _loading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.user?.name ?? '');
    _phoneController = TextEditingController(text: auth.user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image. Try again.')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A8F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF1A3A8F), size: 32),
                          SizedBox(height: 8),
                          Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85C1A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library, color: Color(0xFFE85C1A), size: 32),
                          SizedBox(height: 8),
                          Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loading = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    const blue = Color(0xFF1A3A8F);
    const orange = Color(0xFFE85C1A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar with upload
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: blue.withOpacity(0.2), width: 2),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 100, height: 100,
                              ),
                            )
                          : Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: blue),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showImageOptions,
              child: const Text('Change Photo',
                  style: TextStyle(color: Color(0xFF1A3A8F), fontSize: 13)),
            ),
            const SizedBox(height: 24),

            // Name
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Full Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('Phone number cannot be changed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 20),

            // Role
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Account Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: blue, size: 20),
                  const SizedBox(width: 10),
                  Text(auth.user?.role ?? 'CUSTOMER',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}