import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moyenne_auto/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onLogin});

  final void Function(String username, String role, String level) onLogin;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  
  bool _showPassword = false;
  bool _isLogin = true;
  String _selectedRole = 'Enseignant';
  String _selectedTeachingLevel = 'Primaire';
  bool _isLoading = false;

  final _authService = AuthService();
  bool _isBioAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await _authService.isBiometricAvailable();
    if (!available) {
      if (mounted) setState(() => _isBioAvailable = false);
      return;
    }
    final enabled = await _authService.getBiometricEnabled();
    if (mounted) setState(() => _isBioAvailable = enabled);
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _authService.authenticate();
    if (authenticated) {
      final credentials = await _authService.getUserCredentials();
      if (credentials != null && mounted) {
         widget.onLogin(credentials['username']!, credentials['role']!, credentials['level']!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun identifiant sauvegardé. Veuillez vous connecter manuellement.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentification biométrique échouée')),
        );
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(1.seconds); // Simulate network
    
    if (mounted) {
       final username = _username.text.trim();
       _authService.saveUserCredentials(username, _selectedRole, _selectedTeachingLevel);
       
       if (!_isLogin) {
         // Initialize profile for new registration
         await _authService.saveUserProfile(username, {
           'name': _name.text.trim(),
           'email': '', // Could add field in UI later
           'phone': '',
           'role': _selectedRole,
           'level': _selectedTeachingLevel,
           'bio': 'Enseignant passionné.',
           'imagePath': '',
         });
       }

       widget.onLogin(username, _selectedRole, _selectedTeachingLevel);
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                  : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
              ),
            ),
          ),
          
          // Animated Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha:0.1),
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha:0.2), blurRadius: 100, spreadRadius: 20)],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 5.seconds, begin: const Offset(1,1), end: const Offset(1.2,1.2)),
          ),
          
           Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha:0.1),
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha:0.2), blurRadius: 80, spreadRadius: 10)],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 50, duration: 4.seconds),
          ),

          // Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              
              if (isDesktop) {
                return Row(
                  children: [
                    // Left Brand Panel
                    Expanded(
                      flex: 5, // 50%
                      child: Container(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                             padding: const EdgeInsets.all(20),
                             decoration: BoxDecoration(
                               color: theme.colorScheme.surface.withValues(alpha:0.1),
                               borderRadius: BorderRadius.circular(30),
                               border: Border.all(color: Colors.white.withValues(alpha:0.1)),
                             ),
                             child: Image.asset('assets/images/logo.png', height: 120),
                            ).animate().fadeIn().scale(),
                            const SizedBox(height: 40),
                            Text(
                              'Excellence\nAcadémique',
                              style: GoogleFonts.outfit(
                                fontSize: 64,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideX(),
                            const SizedBox(height: 20),
                            Text(
                              'Gérez vos notes, visualisez vos performances et atteignez vos objectifs avec notre solution premium.',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7),
                                height: 1.5,
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideX(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Right Form Panel
                    Expanded(
                      flex: 4, 
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: _buildGlassCard(theme, isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile/Tablet View
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Image.asset('assets/images/logo.png', height: 100)
                             .animate().fadeIn().scale(),
                           const SizedBox(height: 32),
                           _buildGlassCard(theme, isDark),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(ThemeData theme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.cardTheme.color?.withValues(alpha:0.8) ?? Colors.white.withValues(alpha:0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha:isDark ? 0.05 : 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isLogin ? 'Bon retour !' : 'Créer un compte',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineMedium?.color,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Connectez-vous pour continuer' : 'Commencez votre voyage vers l\'excellence',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.6),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _username,
                      label: 'Nom d\'utilisateur',
                      icon: Icons.person_outline,
                      theme: theme,
                      validator: (v) => (v?.length ?? 0) < 3 ? 'Nom d\'utilisateur trop court' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _name,
                        label: 'Nom complet',
                        icon: Icons.badge_outlined,
                        theme: theme,
                        validator: (v) => (v?.length ?? 0) < 3 ? 'Nom trop court' : null,
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      
                      _buildDropdown(
                        value: _selectedRole,
                        items: ['Enseignant', 'Directeur de programme'],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                        icon: Icons.verified_user_outlined,
                        theme: theme,
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      
                      if (_selectedRole == 'Enseignant')
                        _buildDropdown(
                          value: _selectedTeachingLevel,
                          items: ['Primaire', 'Collège', 'Lycée'],
                          onChanged: (v) => setState(() => _selectedTeachingLevel = v!),
                          icon: Icons.school_outlined,
                          theme: theme,
                        ).animate().fadeIn().slideY(begin: 0.1),
                        if (_selectedRole == 'Enseignant') const SizedBox(height: 20),
                    ],

                    _buildTextField(
                      controller: _password,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      showPassword: _showPassword,
                      onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                      theme: theme,
                      validator: (v) => (v?.length ?? 0) < 6 ? 'Min. 6 caractères' : null,
                    ),
                    
                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPassword,
                        label: 'Confirmer',
                        icon: Icons.shield_outlined,
                        isPassword: true,
                        showPassword: _showPassword,
                        theme: theme,
                        validator: (v) => v != _password.text ? 'Mots de passe différents' : null,
                      ).animate().fadeIn().slideY(begin: 0.1),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF10B981).withValues(alpha:0.4),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Pas de compte ?' : 'Déjà un compte ?',
                    style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.6)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Créer un compte' : 'Connexion',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
              
              if (_isLogin) ...[
                 TextButton(
                    onPressed: () {
                      _username.text = 'demo_user';
                      _password.text = 'demo1234';
                      _submit();
                    },
                    child: Text('Mode Démo', style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5))),
                 ).animate().fadeIn(),
              ],
              
              if (_isBioAvailable) ...[
                 const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.all(8.0), child: Text("OU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Divider())]),
                ),
                 Center(
                   child: Container(
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF10B981).withValues(alpha:0.3),
                           blurRadius: 20,
                           spreadRadius: 2,
                         )
                       ],
                     ),
                     child: IconButton(
                       onPressed: _handleBiometricLogin, 
                       icon: const Icon(Icons.fingerprint, size: 44, color: Color(0xFF10B981)),
                       style: IconButton.styleFrom(
                         backgroundColor: const Color(0xFF10B981).withValues(alpha:0.15),
                         padding: const EdgeInsets.all(20),
                         side: const BorderSide(color: Color(0xFF10B981), width: 1),
                       ),
                     ),
                   ),
                 ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha:0.3))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), curve: Curves.easeInOut, duration: 1.seconds),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.iconTheme.color?.withValues(alpha:0.6)),
        suffixIcon: isPassword 
          ? IconButton(icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: theme.iconTheme.color), onPressed: onTogglePassword)
          : null,
        filled: true,
        fillColor: theme.cardTheme.color?.withValues(alpha:0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha:0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF10B981))),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha:0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color),
          dropdownColor: theme.cardTheme.color,
          style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Row(children: [Icon(icon, size: 18, color: const Color(0xFF10B981)), const SizedBox(width: 12), Text(e)]))).toList(),
        ),
      ),
    );
  }
}
