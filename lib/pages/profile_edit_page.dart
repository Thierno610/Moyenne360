import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, String> currentData;

  const ProfileEditPage({super.key, required this.currentData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _levelController;
  late TextEditingController _bioController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['name']);
    _emailController = TextEditingController(text: widget.currentData['email']);
    _phoneController = TextEditingController(text: widget.currentData['phone'] ?? '+224 600 00 00 00');
    _roleController = TextEditingController(text: widget.currentData['role']);
    _levelController = TextEditingController(text: widget.currentData['level']);
    _bioController = TextEditingController(text: widget.currentData['bio'] ?? 'Enseignant passionné.');
    _imagePath = widget.currentData['imagePath'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _levelController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    // Return updated data
    Navigator.pop(context, {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'role': _roleController.text,
      'level': _levelController.text,
      'bio': _bioController.text,
      'imagePath': _imagePath ?? '',
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mis à jour avec succès !'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imagePath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Modifier Profil', style: GoogleFonts.outfit(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Enregistrer', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                        image: _imagePath != null && _imagePath!.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: _imagePath == null || _imagePath!.isEmpty 
                        ? Center(
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text.substring(0, 1).toUpperCase() : 'U',
                             style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                          ),
                        )
                        : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
            ).animate().scale(),
            const SizedBox(height: 32),

            // Form
            _buildSectionHeader('Informations Personnelles'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _buildTextField(label: 'Nom Complet', controller: _nameController, icon: Icons.person_outline),
                  _buildDivider(),
                  _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined),
                  _buildDivider(),
                  _buildTextField(label: 'Téléphone', controller: _phoneController, icon: Icons.phone_outlined),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Rôle & Établissement'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _buildTextField(label: 'Rôle', controller: _roleController, icon: Icons.badge_outlined, readOnly: true), // Role often read-only
                  _buildDivider(),
                  _buildTextField(label: 'Niveau / Classe', controller: _levelController, icon: Icons.class_outlined),
                  _buildDivider(),
                  _buildTextField(label: 'Bio', controller: _bioController, icon: Icons.info_outline, maxLines: 3),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: readOnly ? Colors.grey : Colors.black87),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Entrez $label',
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
