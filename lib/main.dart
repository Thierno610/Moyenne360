import 'dart:ui';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moyenne_auto/models/student_grade.dart';
import 'package:moyenne_auto/services/grade_service.dart';
import 'package:moyenne_auto/pages/manual_entry_page.dart';
import 'package:moyenne_auto/pages/file_upload_page.dart';
import 'package:moyenne_auto/services/auth_service.dart';
import 'package:moyenne_auto/services/export_service.dart';
import 'package:moyenne_auto/services/database_service.dart';
import 'package:moyenne_auto/pages/settings_page.dart';

import 'package:moyenne_auto/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeService.loadTheme();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MoyenneApp());
}

enum _EntryMode { manual, upload }

class MoyenneApp extends StatelessWidget {
  const MoyenneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Colors
    const primaryColor = Color(0xFF10B981); // Emerald 500
    
    // Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
        background: const Color(0xFFF8FAFC), // Slate 50
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)), // Slate 800
        titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
      ),
    );

    // Dark Theme (Deep Glass / Premium Slate)
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B), // Slate 800
        background: const Color(0xFF0F172A), // Slate 900
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B), // Slate 800
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155), // Slate 700
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Moyennes360',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeService.themeMode,
          home: const EntryShell(),
        );
      },
    );
  }
}



class EntryShell extends StatefulWidget {
  const EntryShell({super.key});

  @override
  State<EntryShell> createState() => _EntryShellState();
}

class _EntryShellState extends State<EntryShell> {
  bool _isLoggedIn = false;
  String _userName = 'Invité';
  String _userRole = 'Enseignant'; // Default
  String _userLevel = 'Primaire'; // Default for teacher

  void _onLogin(String email, String role, String level) {
    setState(() {
      _isLoggedIn = true;
      _userName = email.split('@')[0];
      _userRole = role;
      _userLevel = level;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
      _userName = 'Invité';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return MoyenneHomePage(
        userName: _userName, 
        userRole: _userRole,
        userLevel: _userLevel,
        onLogout: _onLogout
      );
    }
    return LoginPage(onLogin: _onLogin);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final void Function(String email, String role, String level) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _showPassword = false;
  bool _isLogin = true;
  String _selectedRole = 'Enseignant';
  String _selectedTeachingLevel = 'Primaire';

  final _authService = AuthService();
  bool _isBioAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _authService.isBiometricAvailable();
    setState(() => _isBioAvailable = available);
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _authService.authenticate();
    if (authenticated) {
      if (mounted) {
         // Assuming a default role and level for biometric login if not stored
         widget.onLogin('biometric@user.com', 'Enseignant', 'Primaire');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentification biométrique échouée')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    // Pass selected role and level (only relevant if role is teacher)
    widget.onLogin(_email.text.trim(), _selectedRole, _selectedTeachingLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const _AnimatedBackground(),
          
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // Allow scroll if really needed, but FittedBox below tries to avoid it.
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48, // Ensure it takes height if needed
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: 420, // Check explicit width for scaling
                              padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 150,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.05, 1.05),
                                duration: 2.seconds,
                                curve: Curves.easeInOut)
                            .shimmer(
                                duration: 2.seconds,
                                color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 24),
                        Text(
                          'Moyennes Premium',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        Text(
                          'Excellence académique',
                          style: TextStyle(
                              color: const Color(0xFF0F172A).withOpacity(0.65),
                              fontSize: 16),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                        const SizedBox(height: 40),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _GlassTextField(
                                controller: _email,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                validator: (v) => v?.contains('@') == true
                                    ? null
                                    : 'Email invalide',
                              )
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .slideX(begin: -0.2),
                              const SizedBox(height: 20),
                              if (!_isLogin) ...[
                                _GlassTextField(
                                  controller: _name,
                                  label: 'Nom complet',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v?.length ?? 0) < 3
                                      ? 'Nom trop court'
                                      : null,
                                )
                                    .animate()
                                    .fadeIn(delay: 450.ms)
                                    .slideX(begin: -0.2),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRole,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF1E293B),
                                        fontSize: 16,
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedRole = newValue!;
                                        });
                                      },
                                      items: <String>['Enseignant', 'Directeur de programme']
                                          .map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Row(
                                            children: [
                                              Icon(
                                                value == 'Enseignant' ? Icons.school : Icons.admin_panel_settings,
                                                color: const Color(0xFF10B981),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(value),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 480.ms).slideX(begin: -0.2),
                                const SizedBox(height: 20),
                                if (_selectedRole == 'Enseignant') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedTeachingLevel,
                                          isExpanded: true,
                                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E293B)),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 16,
                                          ),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _selectedTeachingLevel = newValue!;
                                            });
                                          },
                                          items: <String>['Primaire', 'Collège', 'Lycée']
                                              .map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.class_,
                                                    color: const Color(0xFF10B981),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(value),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 490.ms).slideX(begin: -0.2),
                                    const SizedBox(height: 20),
                                ],
                              ],
                              _GlassTextField(
                                controller: _password,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline,
                                obscureText: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.black45,
                                  ),
                                  onPressed: () => setState(
                                      () => _showPassword = !_showPassword),
                                ),
                                validator: (v) => (v?.length ?? 0) < 6
                                    ? 'Minimum 6 caractères'
                                    : null,
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms)
                                  .slideX(begin: 0.2),
                              if (!_isLogin) ...[
                                const SizedBox(height: 20),
                                _GlassTextField(
                                  controller: _confirmPassword,
                                  label: 'Confirmer',
                                  icon: Icons.verified_user_outlined,
                                  obscureText: !_showPassword,
                                  validator: (v) => v != _password.text
                                      ? 'Mots de passe différents'
                                      : null,
                                )
                                    .animate()
                                    .fadeIn(delay: 550.ms)
                                    .slideX(begin: 0.2),
                              ],
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF10B981).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _submit,
                                  child: Text(
                                    _isLogin ? 'CONNEXION' : 'S\'INSCRIRE',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 600.ms)
                                  .scale(begin: const Offset(0.8, 0.8)),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _isLogin
                                        ? 'Pas encore de compte ?'
                                        : 'Déjà inscrit ?',
                                    style: TextStyle(
                                        color: const Color(0xFF0F172A).withOpacity(0.6)),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _isLogin = !_isLogin),
                                    child: Text(
                                      _isLogin ? 'Créer un compte' : 'Connexion',
                                      style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 700.ms),
                              if (_isLogin)
                                TextButton(
                                  onPressed: () {
                                    _email.text = 'demo@campus.edu';
                                    _password.text = 'demo1234';
                                    _submit();
                                  },
                                  child: const Text(
                                    'Mode Démo',
                                    style: TextStyle(color: Color(0xFF0F172A)),
                                  ),
                                ).animate().fadeIn(delay: 800.ms),

                              if (_isBioAvailable) ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OU',
                                        style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                IconButton(
                                  onPressed: _handleBiometricLogin,
                                  icon: const Icon(Icons.fingerprint, color: Color(0xFF10B981), size: 42),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.2)),
                                    )
                                  ),
                                ).animate().scale(delay: 500.ms),
                                const SizedBox(height: 8),
                                Text(
                                  'Connexion biométrique',
                                  style: GoogleFonts.outfit(color: Colors.grey.withOpacity(0.7), fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                    ),
                  ),
                ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}

class MoyenneHomePage extends StatefulWidget {
  const MoyenneHomePage({
    super.key,
    required this.userName,
    this.userRole = 'Enseignant',
    this.userLevel = 'Primaire',
    required this.onLogout,
  });

  final String userName;
  final String userRole;
  final String userLevel;
  final VoidCallback onLogout;

  @override
  State<MoyenneHomePage> createState() => _MoyenneHomePageState();
}

class _MoyenneHomePageState extends State<MoyenneHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _gradeService = GradeService();
  final _databaseService = DatabaseService();
  List<StudentGrade> _classGrades = [];
  double? _classAverage;
  String? _selectedLevel;
  int? _currentClassId; // ID de la classe actuelle dans la base
  bool _isLoading = false;

  /// Mode de saisie choisi après la sélection du niveau.
  /// - manual: l'utilisateur saisit les élèves/notes dans l'app
  /// - upload: l'utilisateur importe un fichier CSV/Excel
  _EntryMode? _entryMode;
  
  final _niveauController = TextEditingController();
  final _matiereController = TextEditingController();
  final List<NoteItem> _notes = [];
  String? _filtreNiveau;

  double? _moyenneGenerale;

  // Search & Filter State
  String _searchQuery = '';
  String _filterOption = 'Tous'; // 'Tous', 'Admis', 'Échec'

  @override
  void dispose() {
    _niveauController.dispose();
    _matiereController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  /// Initialise la base de données avec les niveaux et matières par défaut
  Future<void> _initializeDatabase() async {
    try {
      // Initialiser la base de données
      await _databaseService.database;
      
      // Vérifier et créer les niveaux par défaut
      final existingLevels = await _databaseService.getAllLevels();
      if (existingLevels.isEmpty) {
        await _databaseService.insertLevel('Primaire');
        await _databaseService.insertLevel('Collège');
        await _databaseService.insertLevel('Lycée');
      }

      // Créer les matières par défaut pour chaque niveau
      final levels = await _databaseService.getAllLevels();
      for (var level in levels) {
        final levelId = level['id'] as int;
        final levelName = level['name'] as String;
        final existingSubjects = await _databaseService.getSubjectsByLevel(levelId);
        
        if (existingSubjects.isEmpty) {
          // Matières par défaut selon le niveau
          if (levelName == 'Primaire') {
            await _databaseService.insertSubject('Mathématiques', levelId);
            await _databaseService.insertSubject('Français', levelId);
            await _databaseService.insertSubject('Sciences', levelId);
            await _databaseService.insertSubject('Histoire-Géographie', levelId);
          } else if (levelName == 'Collège') {
            await _databaseService.insertSubject('Mathématiques', levelId);
            await _databaseService.insertSubject('Français', levelId);
            await _databaseService.insertSubject('Sciences', levelId);
            await _databaseService.insertSubject('Histoire-Géographie', levelId);
            await _databaseService.insertSubject('Anglais', levelId);
          } else if (levelName == 'Lycée') {
            await _databaseService.insertSubject('Mathématiques', levelId);
            await _databaseService.insertSubject('Français', levelId);
            await _databaseService.insertSubject('Physique-Chimie', levelId);
            await _databaseService.insertSubject('SVT', levelId);
            await _databaseService.insertSubject('Histoire-Géographie', levelId);
            await _databaseService.insertSubject('Anglais', levelId);
          }
        }
      }

      // Si un niveau est sélectionné, charger les classes
      if (widget.userLevel.isNotEmpty) {
        await _loadClassesForLevel(widget.userLevel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur initialisation base: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charge les classes pour un niveau donné
  Future<void> _loadClassesForLevel(String levelName) async {
    try {
      final levels = await _databaseService.getAllLevels();
      final level = levels.firstWhere(
        (l) => l['name'] == levelName,
        orElse: () => {},
      );
      
      if (level.isNotEmpty) {
        final levelId = level['id'] as int;
        final classes = await _databaseService.getClassesByLevel(levelId);
        
        // Si aucune classe n'existe, en créer une par défaut
        if (classes.isEmpty && _selectedLevel != null) {
          final classId = await _databaseService.insertClass(
            '${_selectedLevel} - Classe 1',
            levelId,
            academicYear: DateTime.now().year.toString(),
          );
          _currentClassId = classId;
        } else if (classes.isNotEmpty) {
          _currentClassId = classes.first['id'] as int;
          await _loadClassData(_currentClassId!);
        }
      }
    } catch (e) {
      print('Erreur chargement classes: $e');
    }
  }

  /// Charge les données d'une classe depuis la base
  Future<void> _loadClassData(int classId) async {
    setState(() => _isLoading = true);
    try {
      final students = await _databaseService.getStudentsWithAverages(classId);
      final classAvg = await _databaseService.getClassAverage(classId);
      
      setState(() {
        _classGrades = students;
        _classAverage = classAvg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sauvegarde les étudiants dans la base de données
  Future<void> _saveClassToDatabase(List<StudentGrade> students) async {
    if (_currentClassId == null) {
      // Créer une nouvelle classe si nécessaire
      final levels = await _databaseService.getAllLevels();
      final levelName = _selectedLevel ?? widget.userLevel;
      final level = levels.firstWhere(
        (l) => l['name'] == levelName,
        orElse: () => {},
      );
      
      if (level.isEmpty) return;
      
      final levelId = level['id'] as int;
      _currentClassId = await _databaseService.insertClass(
        '${levelName} - ${DateTime.now().toString().split(' ').first}',
        levelId,
        academicYear: DateTime.now().year.toString(),
      );
    }

    // Extraire les matières des notes des étudiants
    final allSubjects = <String>{};
    for (var student in students) {
      allSubjects.addAll(student.grades.keys);
    }

    // S'assurer que toutes les matières existent dans la base
    final levels = await _databaseService.getAllLevels();
    final levelName = _selectedLevel ?? widget.userLevel;
    final level = levels.firstWhere(
      (l) => l['name'] == levelName,
      orElse: () => {},
    );
    
    if (level.isNotEmpty) {
      final levelId = level['id'] as int;
      final existingSubjects = await _databaseService.getSubjectsByLevel(levelId);
      final existingSubjectNames = existingSubjects.map((s) => s['name'] as String).toSet();
      
      for (var subjectName in allSubjects) {
        if (!existingSubjectNames.contains(subjectName)) {
          await _databaseService.insertSubject(subjectName, levelId);
        }
      }
    }

    // Sauvegarder les étudiants et leurs notes
    await _databaseService.saveClassGrades(_currentClassId!, students);
    
    // Recharger les données
    await _loadClassData(_currentClassId!);
  }

  // Ancien thème dynamique (non utilisé dans le nouveau dashboard).

  List<String> get _niveauxDisponibles {
    final levels = _notes.map((e) => e.niveau).toSet().toList();
    if (_selectedLevel == 'Primaire') {
      return levels.where((n) => ['CP', 'CE1', 'CE2', 'CM1', 'CM2'].contains(n)).toList()..sort();
    } else if (_selectedLevel == 'Collège') {
      return levels.where((n) => ['7ème', '8ème', '9ème', '10ème'].contains(n)).toList()..sort();
    } else if (_selectedLevel == 'Lycée') {
      return levels.where((n) => ['2nde', '1ère', 'Terminale'].contains(n)).toList()..sort();
    }
    return levels..sort();
  }

  List<NoteItem> get _notesFiltrees {
    var filtered = _notes;
    
    // Filter by Level Context
    if (_selectedLevel == 'Primaire') {
      filtered = filtered.where((n) => ['CP', 'CE1', 'CE2', 'CM1', 'CM2'].contains(n.niveau)).toList();
    } else if (_selectedLevel == 'Collège') {
      filtered = filtered.where((n) => ['6ème', '5ème', '4ème', '3ème'].contains(n.niveau)).toList();
    } else if (_selectedLevel == 'Lycée') {
      filtered = filtered.where((n) => ['2nde', '1ère', 'Terminale'].contains(n.niveau)).toList();
    }

    // Filter by Chip Selection
    if (_filtreNiveau != null) {
      filtered = filtered.where((n) => n.niveau == _filtreNiveau).toList();
    }
    
    return filtered;
  }

  void _recalculer() {
    for (var item in _notes) {
      item.recalculerMoyenne();
    }
    final allNotes = _notesFiltrees.expand((n) => n.notes).toList();
    if (allNotes.isEmpty) {
      _moyenneGenerale = null;
    } else {
      final sum = allNotes.fold(0.0, (a, b) => a + b);
      _moyenneGenerale = double.parse((sum / allNotes.length).toStringAsFixed(2));
    }
    setState(() {});
  }

  // Ancien ajout direct (non utilisé: la saisie se fait via le dialogue).

  void _ajouterExemple() {
    setState(() {
      _notes.clear();
      _notes.addAll([
        NoteItem(niveau: '3ème', matiere: 'Maths', notes: [14.5, 16, 12]),
        NoteItem(niveau: '3ème', matiere: 'Physique', notes: [15, 13.5, 17]),
        NoteItem(niveau: 'Terminale', matiere: 'Philo', notes: [11, 13]),
      ]);
      _recalculer();
    });
  }

  Future<void> _exporterFiches() async {
    if (_notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucune donnée à exporter.'),
          backgroundColor: Colors.orange.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Choisir le format', style: TextStyle(color: Color(0xFF0F172A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.black54),
                title: const Text('CSV', style: TextStyle(color: Color(0xFF0F172A))),
                subtitle: const Text('Compatible Excel', style: TextStyle(color: Colors.black45)),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.black54),
                title: const Text('JSON', style: TextStyle(color: Color(0xFF0F172A))),
                subtitle: const Text('Format structuré', style: TextStyle(color: Colors.black45)),
                onTap: () => Navigator.pop(context, 'json'),
              ),
            ],
          ),
        ),
      );

      if (format == null) return;

      String contenu;
      String extension;

      if (format == 'csv') {
        final rows = <List<dynamic>>[['Niveau', 'Matière', 'Notes', 'Moyenne']];
        for (final item in _notes) {
          rows.add([
            item.niveau,
            item.matiere,
            item.notes.join('; '),
            item.moyenne?.toStringAsFixed(2) ?? '0.00',
          ]);
        }
        contenu = const ListToCsvConverter().convert(rows);
        extension = 'csv';
      } else {
        final data = {
          'exportDate': DateTime.now().toIso8601String(),
          'notes': _notes.map((item) => {
                'niveau': item.niveau,
                'matiere': item.matiere,
                'notes': item.notes,
                'moyenne': item.moyenne,
              }).toList(),
          'moyenneGenerale': _moyenneGenerale,
        };
        contenu = const JsonEncoder.withIndent('  ').convert(data);
        extension = 'json';
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/moyennes_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await file.writeAsString(contenu);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Export des moyennes',
        subject: 'Moyennes - ${DateTime.now().toString().split(' ').first}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export réussi en format ${extension.toUpperCase()} !'),
            backgroundColor: const Color(0xFF4ADE80),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFF87171),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importerFiches() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final contenu = await file.readAsString();
      final extension = result.files.single.extension?.toLowerCase();
      List<NoteItem> nouvellesNotes = [];

      if (extension == 'csv') {
        final rows = const CsvToListConverter().convert(contenu);
        if (rows.length < 2) throw Exception('Fichier CSV vide');
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 3) continue;
          final notes = row[2].toString().split(RegExp(r'[;,\s]+'))
              .map((s) => double.tryParse(s.trim()))
              .where((n) => n != null).cast<double>().toList();
          nouvellesNotes.add(NoteItem(
            niveau: row[0].toString(),
            matiere: row[1].toString(),
            notes: notes,
          ));
        }
      } else if (extension == 'json') {
        final data = jsonDecode(contenu);
        final list = data['notes'] as List;
        for (var item in list) {
          final notes = (item['notes'] as List).map((e) => double.parse(e.toString())).toList();
          nouvellesNotes.add(NoteItem(
            niveau: item['niveau'],
            matiere: item['matiere'],
            notes: notes,
          ));
        }
      }

      if (nouvellesNotes.isEmpty) return;

      if (mounted) {
        setState(() {
          _notes.addAll(nouvellesNotes);
          _recalculer();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import réussi !'),
            backgroundColor: Color(0xFF4ADE80),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur import: $e'),
            backgroundColor: const Color(0xFFF87171),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importClassFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final students = await _gradeService.parseFile(file);

      if (students.isEmpty) throw Exception('Aucun étudiant trouvé');

      _gradeService.calculateAverages(students);
      _gradeService.rankStudents(students);
      final classAvg = _gradeService.calculateClassAverage(students);

      // Sauvegarder dans la base de données
      await _saveClassToDatabase(students);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${students.length} étudiants importés et sauvegardés !'),
            backgroundColor: const Color(0xFF4ADE80),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur import classe: $e'),
            backgroundColor: const Color(0xFFF87171),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      drawer: _buildDrawer(), // Added Drawer
      body: SafeArea(
        child: _selectedLevel == null
            ? Stack(children: [const _AnimatedBackground(), _buildLevelSelection()])
            : Column(
                children: [
                   _buildAdminHeader(),
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.all(24),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           _buildAdminActions(),
                           const SizedBox(height: 24),
                           Expanded(child: _buildSplitView()),
                         ],
                       ),
                     ),
                   ),
                   _buildAdminFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            accountName: Text(
              widget.userName, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              '${widget.userRole} - ${widget.userLevel}',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  text: 'Tableau de bord',
                  isActive: true,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.swap_horiz,
                  text: 'Changer de niveau',
                  onTap: () {
                     Navigator.pop(context); // Close Drawer
                     setState(() => _selectedLevel = null);
                  },
                ),
                if (widget.userRole == 'Enseignant') ...[
                   const Divider(indent: 20, endIndent: 20),
                   Padding(
                     padding: const EdgeInsets.only(left: 20, top: 10, bottom: 5),
                     child: Text('MA CLASSE (${widget.userLevel})', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                   ),
                   _DrawerItem(
                     icon: Icons.class_outlined,
                     text: 'Gestion de classe',
                     onTap: () => Navigator.pop(context),
                   ),
                   _DrawerItem(
                     icon: Icons.edit_note,
                     text: 'Saisie des notes',
                     onTap: () => Navigator.pop(context),
                   ),
                ] else if (widget.userRole == 'Directeur de programme') ...[
                   const Divider(indent: 20, endIndent: 20),
                   const Padding(
                     padding: EdgeInsets.only(left: 20, top: 10, bottom: 5),
                     child: Text('ADMINISTRATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                   ),
                   _DrawerItem(
                     icon: Icons.analytics_outlined,
                     text: 'Vue Globale',
                     onTap: () => Navigator.pop(context),
                   ),
                   _DrawerItem(
                     icon: Icons.people_outline,
                     text: 'Gestion Enseignants',
                     onTap: () => Navigator.pop(context),
                   ),
                ],
                const Divider(indent: 20, endIndent: 20),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  text: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
             padding: const EdgeInsets.all(20),
             child: InkWell(
               onTap: widget.onLogout,
               borderRadius: BorderRadius.circular(12),
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.red.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.logout_rounded, color: Colors.red[400]),
                     const SizedBox(width: 12),
                     Text('Déconnexion', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF10B981), // Green Header
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'CALCUL MOYENNE CLASSE',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                _showExportOptions(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                    if (MediaQuery.of(context).size.width > 600) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Exporter',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final children = [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _buildActionButton(
              title: 'Saisie Manuelle',
              subtitle: 'Ajouter notes & élèves',
              icon: Icons.edit_note_rounded,
              color: const Color(0xFF10B981),
              isFilled: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ManualEntryPage(
                      selectedLevel: _selectedLevel ?? '',
                      classGrades: _classGrades,
                      onStudentsUpdated: (students) async {
                        _gradeService.calculateAverages(students);
                        _gradeService.rankStudents(students);
                        await _saveClassToDatabase(students);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Données sauvegardées avec succès !'),
                              backgroundColor: Color(0xFF4ADE80),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: _buildActionButton(
              title: 'Importer Données',
              subtitle: 'Fichiers Excel ou CSV',
              icon: Icons.upload_file_rounded,
              color: Colors.blue,
              isFilled: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => FileUploadPage(
                      selectedLevel: _selectedLevel ?? '',
                      onFileImported: (students, classAvg) async {
                        await _saveClassToDatabase(students);
                        setState(() {
                          _entryMode = _EntryMode.upload;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fichier importé et sauvegardé !'),
                              backgroundColor: Color(0xFF4ADE80),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Column(
                    children: children
                        .map((e) => SizedBox(width: double.infinity, child: e))
                        .toList())
                : Row(children: children),
            const SizedBox(height: 16),
            // Existing small badges
            Row(
              children: [
                _buildBadge('ÉLÈVE INDIVIDUEL', Colors.blueGrey, false),
                const SizedBox(width: 8),
                _buildBadge('CLASSE ENTIÈRE', const Color(0xFF10B981), true),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isFilled ? null : Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isFilled ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFilled ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isFilled ? Colors.white : color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                      color: isFilled ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                      color: isFilled ? Colors.white.withOpacity(0.8) : Colors.grey,
                      fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: isFilled ? Colors.white.withOpacity(0.8) : Colors.grey[400], size: 16),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }

  Widget _buildBadge(String text, Color color, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: filled ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: filled ? Colors.white : color,
            fontSize: 12),
      ),
    );
  }

  Widget _buildSplitView() {
    if (_classGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée pour les statistiques',
              style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // Mobile/Tablet View
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildGlobalStats(),
                const SizedBox(height: 24),
                _buildDistributionChart(),
                const SizedBox(height: 24),
                SizedBox(height: 300, child: _buildChart()),
                const SizedBox(height: 24),
                _buildStudentsTable(),
              ],
            ),
          );
        } else {
          // Desktop View
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlobalStats(),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildStudentsTable()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildDistributionChart(),
                          const SizedBox(height: 24),
                          _buildChart(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildGlobalStats() {
    if (_classGrades.isEmpty) return const SizedBox.shrink();

    double max = 0;
    double min = 20;
    int passCount = 0;

    for (var s in _classGrades) {
      final avg = s.average ?? 0;
      if (avg > max) max = avg;
      if (avg < min) min = avg;
      if (avg >= 10) passCount++;
    }
    if (_classGrades.isEmpty) min = 0;

    double successRate = (passCount / _classGrades.length) * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.4 : 1.8,
          children: [
            _buildStatCard('Moyenne', _classAverage?.toStringAsFixed(2) ?? '--', Icons.show_chart, const Color(0xFF10B981)),
            _buildStatCard('Réussite', '${successRate.toStringAsFixed(0)}%', Icons.check_circle_outline, Colors.blue),
            _buildStatCard('Max', max.toStringAsFixed(2), Icons.arrow_upward, Colors.green),
            _buildStatCard('Min', min.toStringAsFixed(2), Icons.arrow_downward, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistributionChart() {
    int range0_10 = 0;
    int range10_12 = 0;
    int range12_14 = 0;
    int range14_16 = 0;
    int range16_20 = 0;

    for (var s in _classGrades) {
      final avg = s.average ?? 0;
      if (avg < 10) range0_10++;
      else if (avg < 12) range10_12++;
      else if (avg < 14) range12_14++;
      else if (avg < 16) range14_16++;
      else range16_20++;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          const Text('Distribution des Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  if (range0_10 > 0) _buildPieSection(range0_10, '< 10', Colors.redAccent),
                  if (range10_12 > 0) _buildPieSection(range10_12, '10-12', Colors.orangeAccent),
                  if (range12_14 > 0) _buildPieSection(range12_14, '12-14', Colors.yellow),
                  if (range14_16 > 0) _buildPieSection(range14_16, '14-16', Colors.lightGreen),
                  if (range16_20 > 0) _buildPieSection(range16_20, '16-20', const Color(0xFF10B981)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10,
            children: [
               _LegendItem(color: Colors.redAccent, text: '<10'),
               _LegendItem(color: Colors.orangeAccent, text: '10-12'),
               _LegendItem(color: Colors.yellow, text: '12-14'),
               _LegendItem(color: Colors.lightGreen, text: '14-16'),
               _LegendItem(color: Color(0xFF10B981), text: '16+'),
            ],
          )
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(int value, String title, Color color) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '$value',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Exporter les résultats', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Choisissez le format de fichier souhaité.', style: GoogleFonts.outfit(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildExportOption(
              context: context,
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              title: 'Format PDF',
              subtitle: 'Idéal pour l\'impression et le partage',
              onTap: () {
                Navigator.pop(context);
                final service = ExportService();
                service.exportToPdf(_classGrades, _selectedLevel ?? 'Classe', _classAverage);
              },
            ),
            const SizedBox(height: 16),
             _buildExportOption(
              context: context,
              icon: Icons.table_view,
              color: const Color(0xFF10B981),
              title: 'Format Excel',
              subtitle: 'Idéal pour le traitement de données',
              onTap: () {
                Navigator.pop(context);
                final service = ExportService();
                service.exportToExcel(_classGrades, _selectedLevel ?? 'Classe', _classAverage);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTable() {
    // 1. Filtering Logic
    List<StudentGrade> filteredList = _classGrades.where((s) {
      // 1.1 Search
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // 1.2 Filter Option
      bool matchesFilter = true;
      double avg = s.average ?? 0;
      if (_filterOption == 'Admis') {
        matchesFilter = avg >= 10;
      } else if (_filterOption == 'Échec') {
        matchesFilter = avg < 10;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Search & Filter Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un élève...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              Row(
                children: [
                  const Text('Filtre:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  _buildFilterChip('Tous'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Admis', color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Échec', color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 3. Data Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFF10B981)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  columns: const [
                     DataColumn(label: Text('NOM')),
                     DataColumn(label: Text('NBR NOTES')),
                     DataColumn(label: Text('MOYENNE')),
                     DataColumn(label: Text('RANG')),
                     DataColumn(label: Text('DÉTAILS')),
                  ],
                  rows: filteredList.map((student) {
                     return DataRow(cells: [
                       DataCell(Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                       DataCell(Text(student.grades.length.toString())),
                       DataCell(
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: (student.average ?? 0) >= 10 
                                 ? const Color(0xFF10B981).withOpacity(0.1) 
                                 : Colors.red.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Text(
                             student.average?.toStringAsFixed(2) ?? '--',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               color: (student.average ?? 0) >= 10 
                                   ? const Color(0xFF10B981) 
                                   : Colors.red,
                             ),
                           ),
                         )
                       ),
                       DataCell(Text('#${student.rank}')),
                       DataCell(
                         IconButton(
                           icon: const Icon(Icons.visibility_outlined, color: Colors.grey),
                           onPressed: () => _showStudentDetails(student),
                         ),
                       ),
                     ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {Color? color}) {
    final isSelected = _filterOption == label;
    final activeColor = color ?? Colors.blue;
    return InkWell(
      onTap: () => setState(() => _filterOption = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700], 
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(StudentGrade student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              child: Text(student.name[0], style: const TextStyle(color: Color(0xFF10B981))),
            ),
            const SizedBox(width: 12),
            Text(student.name),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Moyenne Générale'),
                trailing: Text(
                  student.average?.toStringAsFixed(2) ?? '--',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft, 
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Notes par matière:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: student.grades.entries.map((e) {
                     return ListTile(
                       dense: true,
                       title: Text(e.key),
                       trailing: Text(e.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                     );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_classGrades.isEmpty) {
       return Container(
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(12),
         ),
         child: const Center(child: Text('Aucune donnée')),
       );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value.toInt() >= 0 && value.toInt() < _classGrades.length) {
                      // Only show initials to avoid clutter
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _classGrades[value.toInt()].name.substring(0, 1), 
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                   }
                   return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: _classGrades.asMap().entries.map((e) {
             return BarChartGroupData(
               x: e.key,
               barRods: [
                 BarChartRodData(
                   toY: e.value.average ?? 0,
                   color: const Color(0xFF10B981),
                   width: 16,
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                 )
               ],
             );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdminFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Center(
        child: Text(
          'MOYENNE GÉNÉRALE CLASSE: ${_classAverage?.toStringAsFixed(2) ?? '--'}',
          style: const TextStyle(
             color: Color(0xFF10B981),
             fontSize: 18,
             fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelection() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.school, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue, ${widget.userName}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    
                    if (widget.userName.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez votre niveau',
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Text(
                      'Sélectionnez votre espace de travail',
                      style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              
              const SizedBox(height: 48),
              
              Text(
                'NIVEAUX ACADÉMIQUES',
                style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              _LevelCard(
                title: 'PRIMAIRE',
                subtitle: 'Classes CP à CM2',
                icon: Icons.backpack_outlined,
                color: Colors.orangeAccent,
                onTap: () => _onLevelSelected('Primaire'),
              ).animate().fadeIn(delay: 300.ms).slideX(),
              
              const SizedBox(height: 16),
              
              _LevelCard(
                title: 'COLLÈGE',
                subtitle: 'Classes 6ème à 3ème',
                icon: Icons.menu_book_rounded,
                color: Colors.blueAccent,
                onTap: () => _onLevelSelected('Collège'),
              ).animate().fadeIn(delay: 400.ms).slideX(),
              
              const SizedBox(height: 16),
              
              _LevelCard(
                title: 'LYCÉE',
                subtitle: 'Seconde à Terminale',
                icon: Icons.architecture_rounded,
                color: Colors.purpleAccent,
                onTap: () => _onLevelSelected('Lycée'),
              ).animate().fadeIn(delay: 500.ms).slideX(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, ${widget.userName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn().slideX(begin: -0.2),
        Text(
          'Voici vos performances académiques',
          style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.7), fontSize: 16),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildDashboardBanner() {
    final modeLabel = switch (_entryMode) {
      _EntryMode.manual => 'Saisie manuelle',
      _EntryMode.upload => 'Téléversement (fichier)',
      null => 'Non défini',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord — ${_selectedLevel ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mode: $modeLabel',
                  style: TextStyle(
                    color: const Color(0xFF1E293B).withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _showDataEntryChoice,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardActions() {
    return Column(
      children: [
        // Boutons principaux pour les méthodes de saisie
        Row(
          children: [
            Expanded(
              child: _PremiumActionCard(
                icon: Icons.edit_note_rounded,
                title: 'Saisie manuelle',
                subtitle: 'Ajouter les élèves et notes',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ManualEntryPage(
                        selectedLevel: _selectedLevel ?? '',
                        classGrades: _classGrades,
                        onStudentsUpdated: (students) async {
                          _gradeService.calculateAverages(students);
                          _gradeService.rankStudents(students);
                          await _saveClassToDatabase(students);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Données sauvegardées avec succès !'),
                                backgroundColor: Color(0xFF4ADE80),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PremiumActionCard(
                icon: Icons.cloud_upload_rounded,
                title: 'Téléverser fichier',
                subtitle: 'CSV ou Excel',
                color: const Color(0xFF06B6D4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => FileUploadPage(
                        selectedLevel: _selectedLevel ?? '',
                        onFileImported: (students, classAvg) {
                          setState(() {
                            _classGrades = students;
                            _classAverage = classAvg;
                            _entryMode = _EntryMode.upload;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Boutons secondaires
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                icon: Icons.person_add,
                label: 'Ajouter un élève',
                onTap: _showAddStudentDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassButton(
                icon: Icons.refresh_rounded,
                label: 'Actualiser',
                onTap: () {
                  setState(() {
                    _gradeService.calculateAverages(_classGrades);
                    _gradeService.rankStudents(_classGrades);
                    _classAverage = _gradeService.calculateClassAverage(_classGrades);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  /// Appelé après le choix d'un niveau (Primaire / Collège / Lycée)
  /// pour demander à l'utilisateur s'il veut saisir les notes manuellement
  /// ou téléverser un fichier de classe.
  Future<void> _onLevelSelected(String level) async {
    setState(() {
      _selectedLevel = level;
      _entryMode = null;
    });
    // Charger les classes pour ce niveau depuis la base de données
    await _loadClassesForLevel(level);
    // _showDataEntryChoice(); // Removed to use new Dashboard buttons
  }

  // ---- Ancien dashboard "Perso" (désactivé) ----
  /*
  Widget _buildStatsGrid() {
    final count = _notes.length;
    final best = _notes.expand((e) => e.notes).isEmpty
        ? 0.0
        : _notes.expand((e) => e.notes).reduce((a, b) => a > b ? a : b);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Matières',
          value: '$count',
          icon: Icons.book,
          color: const Color(0xFF38BDF8),
        ),
        _StatCard(
          title: 'Meilleure Note',
          value: best.toStringAsFixed(2),
          icon: Icons.emoji_events,
          color: const Color(0xFFF472B6),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                icon: Icons.person,
                label: 'Perso',
                 isActive: _currentViewIndex == 0,
                onTap: () => setState(() => _currentViewIndex = 0),
              ),
            ),
             const SizedBox(width: 12),
            Expanded(
              child: _GlassButton(
                icon: Icons.groups,
                label: 'Classe',
                isActive: _currentViewIndex == 1,
                onTap: _showClassInputChoice,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_currentViewIndex == 0) ...[
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                icon: Icons.add_chart,
                label: 'Exemple',
                onTap: _ajouterExemple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassButton(
                icon: Icons.delete_sweep,
                label: 'Reset',
                onTap: () => setState(() {
                  _notes.clear();
                  _recalculer();
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                icon: Icons.upload_file,
                label: 'Importer',
                onTap: _importerFiches,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassButton(
                icon: Icons.download,
                label: 'Exporter',
                onTap: _exporterFiches,
              ),
            ),
          ],
        ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _GlassButton(
                  icon: Icons.person_add,
                  label: 'Ajouter un élève',
                  onTap: _showAddStudentDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassButton(
                  icon: Icons.upload_file,
                  label: 'Importer Classe (CSV/Excel)',
                  onTap: _importClassFile,
                ),
              ),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
  */

  Widget _buildClassStats() {
    if (_classGrades.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
         _StatCard(
          title: 'Effectif',
          value: '${_classGrades.length}',
          icon: Icons.groups,
          color: const Color(0xFF38BDF8),
        ),
        _StatCard(
          title: 'Moyenne Classe',
          value: _classAverage?.toStringAsFixed(2) ?? '--',
          icon: Icons.insights,
          color: const Color(0xFFF472B6),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildClassList() {
    if (_classGrades.isEmpty) {
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.upload_file,
                  size: 64, color: const Color(0xFF1E293B).withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'Importez un fichier CSV/Excel',
                style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ).animate().fadeIn();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _classGrades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = _classGrades[index];
        final isTop3 = index < 3;
        final rank = student.rank;
        
        Color rankColor = Colors.white;
        if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
        if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
        if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTop3 ? rankColor.withOpacity(0.5) : Colors.grey.withOpacity(0.1),
               width: isTop3 ? 2 : 1,
            ),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: rankColor.withOpacity(0.2),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor == Colors.white ? const Color(0xFF1E293B) : rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.average?.toStringAsFixed(2) ?? '--',
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX();
      },
    );
  }

  /// Dialogue affiché juste après la sélection du niveau
  /// pour choisir entre saisie manuelle et import de fichier.
  void _showDataEntryChoice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Comment voulez-vous saisir les données ?',
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: Color(0xFF1E293B)),
              title: const Text(
                'Saisir les notes manuellement',
                style: TextStyle(color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Ajouter vos matières et notes directement dans le tableau de bord',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _entryMode = _EntryMode.manual;
                });
              },
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF1E293B)),
              title: const Text(
                'Téléverser un fichier (CSV/Excel)',
                style: TextStyle(color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Importer directement les élèves et leurs notes',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _entryMode = _EntryMode.upload;
                });
                _importClassFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Demande à l'utilisateur comment il veut renseigner la classe :
  /// - saisie manuelle des élèves
  /// - import d'un fichier CSV/Excel
  void _showClassInputChoice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Comment renseigner la classe ?',
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.keyboard, color: Color(0xFF1E293B)),
              title: const Text(
                'Saisir moi-même les élèves',
                style: TextStyle(color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Ajouter les noms et notes directement dans l’application',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _entryMode = _EntryMode.manual;
                });
              },
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF1E293B)),
              title: const Text(
                'J’ai déjà un fichier (CSV/Excel)',
                style: TextStyle(color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Importer directement la liste des élèves',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _entryMode = _EntryMode.upload;
                });
                _importClassFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Petit formulaire pour ajouter rapidement un élève manuellement.
  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final gradeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Ajouter un élève',
            style: TextStyle(color: Color(0xFF1E293B)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’élève',
                  hintText: 'Ex: Diallo Mamadou',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Matière (optionnel)',
                  hintText: 'Ex: Maths',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gradeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  hintText: 'Ex: 15.5',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }

                final subject = subjectController.text.trim();
                final gradeText = gradeController.text.trim();
                final Map<String, double> grades = {};

                if (subject.isNotEmpty && gradeText.isNotEmpty) {
                  final parsed =
                      double.tryParse(gradeText.replaceAll(',', '.').trim());
                  if (parsed != null) {
                    grades[subject] = parsed;
                  }
                }

                setState(() {
                  _classGrades.add(StudentGrade(name: name, grades: grades));
                  _gradeService.calculateAverages(_classGrades);
                  _gradeService.rankStudents(_classGrades);
                  _classAverage =
                      _gradeService.calculateClassAverage(_classGrades);
                });

                Navigator.of(ctx).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    if (_niveauxDisponibles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Tous',
            selected: _filtreNiveau == null,
            onTap: () => setState(() => _filtreNiveau = null),
          ),
          ..._niveauxDisponibles.map((n) => _FilterChip(
                label: n,
                selected: _filtreNiveau == n,
                onTap: () => setState(() => _filtreNiveau = n),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _GlassTextField(
                    controller: _niveauController,
                    label: 'Niveau',
                    icon: Icons.school,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GlassTextField(
                    controller: _matiereController,
                    label: 'Matière',
                    icon: Icons.subject,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => _AddNoteDialog(
                    selectedLevel: _selectedLevel,
                    onAdd: (n, m, score) {
                       setState(() {
                         final existent = _notes.firstWhere((x) => x.niveau == n && x.matiere == m, orElse: () {
                           final newItem = NoteItem(niveau: n, matiere: m, notes: []);
                           _notes.add(newItem);
                           return newItem;
                         });
                         existent.notes.add(score);
                         _recalculer();
                       });
                    },
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une matière/note'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildNotesList() {
    if (_notesFiltrees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.note_alt_outlined,
                  size: 64, color: const Color(0xFF1E293B).withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'Aucune note pour le moment',
                style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ).animate().fadeIn();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notesFiltrees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _notesFiltrees[index];
        return _NoteCard(
          item: item,
          onDelete: () => setState(() {
            _notes.remove(item);
            _recalculer();
          }),
          onUpdate: _recalculer,
        )
            .animate(delay: (100 * index).ms)
            .fadeIn()
            .slideX(begin: 0.2, curve: Curves.easeOutQuad);
      },
    );
  }

}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
  });

  final NoteItem item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.niveau.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.matiere,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    )
                  ],
                ),
                child: Text(
                  item.moyenne?.toStringAsFixed(2) ?? '--',
                  style: TextStyle(
                    color: _getScoreColor(item.moyenne),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...item.notes.map((n) => Chip(
                    label: Text(n.toStringAsFixed(1)),
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(color: Color(0xFF1E293B)),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    padding: EdgeInsets.zero,
                  )),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  foregroundColor: const Color(0xFF6366F1),
                ),
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showAddNoteDialog(context),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.withOpacity(0.7)),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 16) return const Color(0xFF4ADE80); // Green
    if (score >= 12) return const Color(0xFF6366F1); // Indigo
    if (score >= 10) return const Color(0xFFFACC15); // Yellow
    return const Color(0xFFF87171); // Red
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddNoteDialog(
        onAdd: (val) {
          item.notes.add(val);
          onUpdate();
        },
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog({
    this.selectedLevel,
    required this.onAdd,
  });

  final String? selectedLevel;
  // `onAdd` can be either `ValueChanged<double>` (adds a single note)
  // or `void Function(String niveau, String matiere, double score)`
  // (adds/creates a note with niveau + matiere + score).
  final dynamic onAdd;

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _controller = TextEditingController();
  final _niveauController = TextEditingController();
  final _matiereController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _niveauController.dispose();
    _matiereController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Ajouter une note', style: TextStyle(color: Color(0xFF1E293B))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If the caller expects a full add (niveau/matiere/score), show the fields.
          if (widget.onAdd is! ValueChanged<double>) ...[
            TextField(
              controller: _niveauController
                ..text = widget.selectedLevel ?? _niveauController.text,
              decoration: InputDecoration(labelText: 'Niveau', hintText: 'Ex: Collège'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _matiereController,
              decoration: InputDecoration(labelText: 'Matière', hintText: 'Ex: Maths'),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Ex: 15.5',
              hintStyle: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.3)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF1E293B).withOpacity(0.2))),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final val = double.tryParse(_controller.text.replaceAll(',', '.'));
            if (val == null || val < 0 || val > 20) return;

            // If `onAdd` is a single-value callback, call it directly.
            if (widget.onAdd is ValueChanged<double>) {
              (widget.onAdd as ValueChanged<double>)(val);
              Navigator.pop(context);
              return;
            }

            // Otherwise assume it's the full signature: (String niveau, String matiere, double score)
            final niveau = _niveauController.text.trim().isNotEmpty
                ? _niveauController.text.trim()
                : (widget.selectedLevel ?? '');
            final matiere = _matiereController.text.trim();
            if (niveau.isEmpty || matiere.isEmpty) return;

            try {
              (widget.onAdd as void Function(String, String, double))(niveau, matiere, val);
              Navigator.pop(context);
            } catch (_) {}
          },
          child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class NoteItem {
  NoteItem({
    required this.niveau,
    required this.matiere,
    required this.notes,
  }) {
    recalculerMoyenne();
  }

  final String niveau;
  final String matiere;
  final List<double> notes;
  double? moyenne;

  void recalculerMoyenne() {
    if (notes.isEmpty) {
      moyenne = null;
    } else {
      final sum = notes.fold(0.0, (a, b) => a + b);
      moyenne = double.parse((sum / notes.length).toStringAsFixed(2));
    }
  }
}

// --- Reusable Components ---

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC), // Slate 50 (White-ish)
      child: Stack(
        children: [
          // Moving Blobs (Pastel/Lighter for white bg)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2), // Lighter Indigo
                    Colors.transparent
                  ],
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 6.seconds)
              .rotate(begin: 0, end: 0.2, duration: 7.seconds),

          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.2), // Lighter Pink
                    Colors.transparent
                  ],
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slide(
                  begin: const Offset(0, 0.2),
                  end: const Offset(0.2, -0.2),
                  duration: 8.seconds)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),

          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.15), // Lighter Cyan
                    Colors.transparent
                  ],
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideX(begin: 0.1, end: -0.1, duration: 10.seconds)
              .rotate(begin: 0, end: -0.1),

          // Glass Overlay (Blur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.white.withOpacity(0.1), // Very light overlay
            ),
          ),
          
           // Mesh Noise (Optional subtle texture - Darker noise for white bg)
           Container(
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [
                   Colors.black.withOpacity(0.01),
                   Colors.transparent,
                   Colors.black.withOpacity(0.01),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF1E293B)), // Dark Text
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF1E293B).withOpacity(0.6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5), // Lighter fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1E293B).withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Solid white card for pop
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
     this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B).withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
            color: isActive ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white.withOpacity(0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B).withOpacity(0.7)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B).withOpacity(0.7), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6366F1)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFF1E293B).withOpacity(0.1),
            ),
             boxShadow: selected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1E293B).withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFF1E293B).withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF1E293B).withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumActionCard extends StatelessWidget {
  const _PremiumActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isActive ? const Color(0xFF10B981) : Colors.grey[600]),
      title: Text(
        text,
        style: TextStyle(
          color: isActive ? const Color(0xFF10B981) : Colors.grey[800],
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      selected: isActive,
      selectedTileColor: const Color(0xFF10B981).withOpacity(0.1),
    );
  }
}
