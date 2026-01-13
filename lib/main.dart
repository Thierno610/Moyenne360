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

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MoyenneApp());
}

class MoyenneApp extends StatelessWidget {
  const MoyenneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium "Deep Glass" Palette
    const primaryColor = Color(0xFF6366F1); // Indigo 500
    const secondaryColor = Color(0xFFEC4899); // Pink 500
    const tertiaryColor = Color(0xFF06B6D4); // Cyan 500
    const backgroundColor = Color(0xFF0F172A); // Slate 900

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moyennes Premium',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B), // Slate 800
          background: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
      ),
      home: const EntryShell(),
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

  void _onLogin(String email) {
    setState(() {
      _isLoggedIn = true;
      _userName = email.split('@').first.isNotEmpty
          ? email.split('@').first
          : 'Utilisateur';
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      child: _isLoggedIn
          ? MoyenneHomePage(
              key: const ValueKey('Home'),
              userName: _userName,
              onLogout: _onLogout,
            )
          : LoginPage(key: const ValueKey('Login'), onLogin: _onLogin),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final void Function(String email) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    widget.onLogin(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const _AnimatedBackground(),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 480,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_graph_rounded,
                          size: 64,
                          color: Colors.white,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                                curve: Curves.easeInOut)
                            .shimmer(
                                duration: 2.seconds,
                                color: Colors.white.withOpacity(0.5)),
                        const SizedBox(height: 24),
                        Text(
                          'Moyennes Premium',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        Text(
                          'Excellence académique',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
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
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(
                                      () => _showPassword = !_showPassword),
                                ),
                                validator: (v) => (v?.length ?? 0) < 4
                                    ? 'Trop court'
                                    : null,
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms)
                                  .slideX(begin: 0.2),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF6366F1).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _submit,
                                  child: const Text(
                                    'CONNEXION',
                                    style: TextStyle(
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
                              TextButton(
                                onPressed: () {
                                  _email.text = 'demo@campus.edu';
                                  _password.text = 'demo1234';
                                  _submit();
                                },
                                child: const Text(
                                  'Mode Démo',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ).animate().fadeIn(delay: 800.ms),
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
        ],
      ),
    );
  }
}

class MoyenneHomePage extends StatefulWidget {
  const MoyenneHomePage({
    super.key,
    required this.userName,
    required this.onLogout,
  });

  final String userName;
  final VoidCallback onLogout;

  @override
  State<MoyenneHomePage> createState() => _MoyenneHomePageState();
}

class _MoyenneHomePageState extends State<MoyenneHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _niveauController = TextEditingController();
  final _matiereController = TextEditingController();
  final List<NoteItem> _notes = [];
  String? _filtreNiveau;
  double? _moyenneGenerale;

  @override
  void dispose() {
    _niveauController.dispose();
    _matiereController.dispose();
    super.dispose();
  }

  List<String> get _niveauxDisponibles =>
      _notes.map((e) => e.niveau).toSet().toList()..sort();

  List<NoteItem> get _notesFiltrees => _filtreNiveau == null
      ? _notes
      : _notes.where((n) => n.niveau == _filtreNiveau).toList();

  void _recalculer() {
    for (var item in _notes) {
      item.recalculerMoyenne();
    }
    final allNotes = _notes.expand((n) => n.notes).toList();
    if (allNotes.isEmpty) {
      _moyenneGenerale = null;
    } else {
      final sum = allNotes.fold(0.0, (a, b) => a + b);
      _moyenneGenerale = double.parse((sum / allNotes.length).toStringAsFixed(2));
    }
    setState(() {});
  }

  void _ajouterNote() {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _notes.add(NoteItem(
        niveau: _niveauController.text.trim(),
        matiere: _matiereController.text.trim(),
        notes: [],
      ));
      _niveauController.clear();
      _matiereController.clear();
      _recalculer();
    });
  }

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
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Choisir le format', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.white70),
                title: const Text('CSV', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Compatible Excel', style: TextStyle(color: Colors.white30)),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.white70),
                title: const Text('JSON', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Format structuré', style: TextStyle(color: Colors.white30)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildAddForm(),
                  const SizedBox(height: 24),
                  _buildNotesList(),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _moyenneGenerale != null
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.star_rounded, color: Colors.white),
              label: Text(
                'Moyenne: ${_moyenneGenerale!.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ).animate().scale(delay: 500.ms, curve: Curves.elasticOut)
          : null,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, ${widget.userName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn().slideX(begin: -0.2),
        Text(
          'Voici vos performances académiques',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
      ],
    );
  }

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
      ],
    ).animate().fadeIn(delay: 400.ms);
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _ajouterNote,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une matière'),
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
                  size: 64, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'Aucune note pour le moment',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.niveau.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.matiere,
                    style: const TextStyle(
                      color: Colors.white,
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
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
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
                    backgroundColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.white),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  )),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
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
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ajouter une note',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ex: 15.5',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val >= 0 && val <= 20) {
                item.notes.add(val);
                onUpdate();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E1B4B), // Indigo 950
            Color(0xFF312E81), // Indigo 900
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .saturate(duration: 10.seconds, begin: 0.8, end: 1.2);
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
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
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
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
