import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moyenne_auto/models/student_grade.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({
    super.key,
    required this.selectedLevel,
    required this.classGrades,
    required this.subjects,
    required this.onStudentsUpdated,
  });

  final String selectedLevel;
  final List<StudentGrade> classGrades;
  final List<String> subjects;
  final ValueChanged<List<StudentGrade>> onStudentsUpdated;

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  // Each row: { 'name': Ctrl, 'notes': Map<String, Ctrl>, 'average': double? }
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _initializeRows();
  }

  @override
  void dispose() {
    for (var row in _rows) {
      (row['name'] as TextEditingController).dispose();
      final notes = row['notes'] as Map<String, TextEditingController>;
      for (var ctrl in notes.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _initializeRows() {
    if (widget.classGrades.isNotEmpty) {
      for (var student in widget.classGrades) {
        _addRow(
          name: student.name,
          grades: student.grades,
        );
      }
    } else {
      _addEmptyRow();
    }
  }
  
  void _addEmptyRow() {
    _addRow();
  }

  void _addMultipleRows(int count) {
    for (int i = 0; i < count; i++) {
      _addRow();
    }
  }

  void _addRow({String name = '', Map<String, double> grades = const {}}) {
    final nameCtrl = TextEditingController(text: name);
    final Map<String, TextEditingController> noteControllers = {};
    
    for (var subject in widget.subjects) {
      noteControllers[subject] = TextEditingController(
        text: grades[subject]?.toString() ?? '',
      );
    }
    
    final row = {
      'name': nameCtrl,
      'notes': noteControllers,
      'average': 0.0,
      'mention': '',
    };

    // Add listeners
    void updateListener() {
      setState(() {
        final avg = _calculateRowAverage(noteControllers);
        row['average'] = avg ?? 0.0;
        row['mention'] = _calculateMention(row['average'] as double);
      });
    }

    for (var ctrl in noteControllers.values) {
      ctrl.addListener(updateListener);
    }

    // Initial calculation
    final initialAvg = _calculateRowAverage(noteControllers);
    row['average'] = initialAvg ?? 0.0;
    row['mention'] = _calculateMention(row['average'] as double);

    setState(() {
      _rows.add(row);
    });
  }
  
  double? _calculateRowAverage(Map<String, TextEditingController> controllers) {
    List<double> values = [];
    for (var ctrl in controllers.values) {
      final v = double.tryParse(ctrl.text.replaceAll(',', '.').trim());
      if (v != null) values.add(v);
    }
    
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _calculateMention(double average) {
    if (average >= 18) return 'Excellent';
    if (average >= 16) return 'Très Bien';
    if (average >= 14) return 'Bien';
    if (average >= 12) return 'Assez Bien';
    if (average >= 10) return 'Passable';
    return 'Insuffisant';
  }
  
  Color _getMentionColor(String? mention) {
    switch (mention) {
      case 'Excellent':
      case 'Très Bien':
        return const Color(0xFF10B981); // Green
      case 'Bien':
      case 'Assez Bien':
        return const Color(0xFF3B82F6); // Blue
      case 'Passable':
        return const Color(0xFFF59E0B); // Orange
      case 'Insuffisant':
      default:
        return Colors.redAccent;
    }
  }

  void _saveChanges() {
    List<StudentGrade> newGrades = [];
    
    for (var row in _rows) {
      final name = (row['name'] as TextEditingController).text.trim();
      if (name.isEmpty) continue;
      
      final Map<String, double> grades = {};
      final controllers = row['notes'] as Map<String, TextEditingController>;
      
      for (var entry in controllers.entries) {
        final val = double.tryParse(entry.value.text.replaceAll(',', '.').trim());
        if (val != null) {
          grades[entry.key] = val;
        }
      }
      
      final student = StudentGrade(name: name, grades: grades);
      student.average = row['average'];
      student.mention = row['mention'];
      newGrades.add(student);
    }
    
    widget.onStudentsUpdated(newGrades);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifications enregistrées !'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Tableur : ${widget.selectedLevel}', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
            label: const Text('+10 LIGNES', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () => _addMultipleRows(10),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Color(0xFF10B981), size: 24),
            onPressed: _saveChanges,
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmptyRow,
        mini: true,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return _buildMobileView();
          } else {
            return _buildDesktopView();
          }
        },
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        final controllers = row['notes'] as Map<String, TextEditingController>;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ),
            title: TextField(
              controller: row['name'],
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: 'Nom de l\'élève', border: InputBorder.none),
            ),
            subtitle: Text(
              'Moyenne: ${row['average'].toStringAsFixed(2)} - ${row['mention']}',
              style: TextStyle(color: _getMentionColor(row['mention']), fontWeight: FontWeight.w500),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.subjects.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(s, style: const TextStyle(fontSize: 13))),
                          Expanded(
                            child: TextField(
                              controller: controllers[s],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _rows.removeAt(index)),
                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopView() {
    final theme = Theme.of(context);
    
    // Calculate total width: Name(250) + Avg(100) + Mention(120) + Subjects(N * 120) + Number(50) + Action(50)
    final double tableWidth = 50 + 250 + (widget.subjects.length * 120) + 100 + 120 + 50;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Excel Letters Header (A, B, C...)
                      _buildExcelLettersHeader(),
                      // Real Headers
                      _buildExcelTableHeaders(),
                      // Data
                      Expanded(
                        child: ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (context, index) => _buildExcelRow(index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conseil : Utilisez TAB pour passer rapidement d\'une matière à l\'autre.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
              ),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save_rounded),
                label: const Text('ENREGISTRER LES NOTES'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcelLettersHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String getAlpha(int index) {
      const alphas = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      if (index < alphas.length) return alphas[index];
      return '${alphas[(index / alphas.length).floor() - 1]}${alphas[index % alphas.length]}';
    }
    
    return Container(
      height: 25,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[200],
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          _gridHeader('', width: 50),
          _gridHeader('A', width: 250),
          ...List.generate(widget.subjects.length, (i) => _gridHeader(getAlpha(i + 1), width: 120)),
          _gridHeader(getAlpha(widget.subjects.length + 1), width: 100),
          _gridHeader(getAlpha(widget.subjects.length + 2), width: 120),
          _gridHeader('', width: 50),
        ],
      ),
    );
  }

  Widget _buildExcelTableHeaders() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          _gridHeader('#', width: 50),
          _gridHeader('NOM ET PRÉNOMS', width: 250),
          ...widget.subjects.map((s) => _gridHeader(s.toUpperCase(), width: 120)),
          _gridHeader('MOYENNE', width: 100),
          _gridHeader('MENTION', width: 120),
          _gridHeader('', width: 50),
        ],
      ),
    );
  }

  Widget _buildExcelRow(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final row = _rows[index];
    final controllers = row['notes'] as Map<String, TextEditingController>;
    final avg = row['average'] as double;

    return Container(
      height: 45,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50]),
      ),
      child: Row(
        children: [
          // Row marker
          Container(
            width: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey[100],
              border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          // Student Name
          _buildTextCell(row['name'], width: 250, hint: 'Nom élève', bold: true),
          // Subjects
          ...widget.subjects.map((s) => _buildInputCell(controllers[s]!, width: 120)),
          // Stats
          _buildStaticCell(avg.toStringAsFixed(2), width: 100, color: avg >= 10 ? const Color(0xFF10B981) : Colors.redAccent),
          _buildStaticCell(row['mention'], width: 120, fontSize: 12),
          // Actions
          Container(
            width: 50,
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: () => setState(() => _rows.removeAt(index)),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridHeader(String text, {required double width}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTextCell(TextEditingController ctrl, {required double width, String? hint, bool bold = false}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildInputCell(TextEditingController ctrl, {required double width}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.outfit(fontSize: 13),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12), hintText: '0.0'),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  Widget _buildStaticCell(String text, {required double width, Color? color, double fontSize = 13}) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: fontSize, fontWeight: FontWeight.bold, color: color ?? theme.textTheme.bodyLarge?.color),
      ),
    );
  }
}
