import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moyenne_auto/pages/profile_edit_page.dart'; // Ensure this is imported if used
import 'package:moyenne_auto/pages/about_page.dart';
import 'package:moyenne_auto/pages/contact_page.dart';
import 'package:moyenne_auto/services/theme_service.dart';
import 'package:moyenne_auto/services/auth_service.dart';


class SettingsPage extends StatefulWidget {
  final String username;
  const SettingsPage({super.key, required this.username});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _isBiometricHardwareAvailable = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkBiometricHardware();
    _loadBiometricPreference();
    _loadProfile();
  }

  Future<void> _checkBiometricHardware() async {
    final available = await _authService.isBiometricAvailable();
    if (mounted) {
      setState(() => _isBiometricHardwareAvailable = available);
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getUserProfile(widget.username);
    if (profile != null) {
      setState(() {
        _userData = profile;
      });
    }
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await _authService.getBiometricEnabled();
    setState(() => _biometricEnabled = enabled);
  }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Paramètres', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color, size: 20),
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
                  // Use AnimatedBuilder to listen to theme changes for the switch UI update
                  AnimatedBuilder(
                    animation: themeService,
                    builder: (context, child) {
                      return _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Mode Sombre',
                        subtitle: 'Thème foncé premium',
                        value: themeService.isDarkMode,
                        onChanged: (v) => themeService.toggleTheme(),
                      );
                    },
                  ),
                  if (_isBiometricHardwareAvailable) ...[
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.fingerprint,
                      title: 'Biométrie',
                      subtitle: 'Connexion rapide et sécurisée',
                      value: _biometricEnabled,
                      activeColor: const Color(0xFF3B82F6),
                      iconColor: _biometricEnabled ? const Color(0xFF3B82F6) : null,
                      onChanged: (v) async {
                        setState(() => _biometricEnabled = v);
                        await _authService.setBiometricEnabled(v);
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                  ],
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
                  _buildActionTile(Icons.mail_outline, 'Nous contacter', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactPage()));
                  }),
                  _buildDivider(),
                  _buildActionTile(Icons.info_outline, 'À propos', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
                  }),
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
          // Persist changes
          await _authService.saveUserProfile(widget.username, result);
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
                color: const Color(0xFF10B981).withValues(alpha:0.1),
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
                  Text(_userData['name']!, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 4),
                  Text('Modifier le profil', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color?.withValues(alpha:0.3), size: 16),
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
    Color activeColor = const Color(0xFF10B981),
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? theme.iconTheme.color?.withValues(alpha:0.7), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)),
                Text(subtitle, style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.6), fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.iconTheme.color?.withValues(alpha:0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color))),
            Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withValues(alpha:0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha:0.1));
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha:0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
