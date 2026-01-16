import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moyenne_auto/pages/profile_edit_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _biometricsEnabled = false;

  // Mock User Data
  Map<String, String> _userData = {
    'name': 'Utilisateur Premium',
    'email': 'utilisateur@ecole.com',
    'phone': '+224 620 00 00 00',
    'role': 'Enseignant',
    'level': 'Lycée',
    'bio': 'Enseignant passionné par la technologie.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey
      appBar: AppBar(
        title: Text('Paramètres', style: GoogleFonts.outfit(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionHeader('Mon Profil'),
            const SizedBox(height: 12),
            _buildProfileCard(),
            const SizedBox(height: 32),

            // App Settings
            _buildSectionHeader('Application'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Alertes notes et devoirs',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Mode Sombre',
                    subtitle: 'Thème foncé',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: 'Biométrie',
                    subtitle: 'Connexion rapide',
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Support Section
            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
             Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _buildActionTile(Icons.help_outline, 'Aide & FAQ', () {}),
                  _buildDivider(),
                  _buildActionTile(Icons.mail_outline, 'Nous contacter', () {}),
                  _buildDivider(),
                  _buildActionTile(Icons.info_outline, 'À propos', () {}),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 2.1.0 (Premium)',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProfileCard() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileEditPage(currentData: _userData)),
        );

        if (result != null && result is Map<String, String>) {
          setState(() {
            _userData = result;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
                image: _userData['imagePath'] != null && _userData['imagePath']!.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(_userData['imagePath']!)),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: _userData['imagePath'] != null && _userData['imagePath']!.isNotEmpty 
                ? null 
                : Center(
                 child: Text(
                    _userData['name']!.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                 ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userData['name']!, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Modifier le profil', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500))),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.1));
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
