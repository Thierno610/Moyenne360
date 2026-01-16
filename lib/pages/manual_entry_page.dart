import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moyenne_auto/models/student_grade.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({
    super.key,
    required this.selectedLevel,
    required this.classGrades,
    required this.onStudentsUpdated,
  });

  final String selectedLevel;
  final List<StudentGrade> classGrades;
  final ValueChanged<List<StudentGrade>> onStudentsUpdated;

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  // Each row: { 'name': Ctrl, 'note1': Ctrl, 'note2': Ctrl, 'note3': Ctrl, 'average': double? }
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
      (row['note1'] as TextEditingController).dispose();
      (row['note2'] as TextEditingController).dispose();
      (row['note3'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _initializeRows() {
    if (widget.classGrades.isNotEmpty) {
      for (var student in widget.classGrades) {
        final notesValues = student.grades.values.toList();
        _addRow(
          name: student.name,
          n1: notesValues.isNotEmpty ? notesValues[0].toString() : '',
          n2: notesValues.length > 1 ? notesValues[1].toString() : '',
          n3: notesValues.length > 2 ? notesValues[2].toString() : '',
        );
      }
    } else {
      _addEmptyRow();
    }
  }
  
  void _addEmptyRow() {
    _addRow();
  }

  void _addRow({String name = '', String n1 = '', String n2 = '', String n3 = ''}) {
    final note1Ctrl = TextEditingController(text: n1);
    final note2Ctrl = TextEditingController(text: n2);
    final note3Ctrl = TextEditingController(text: n3);
    
    final row = {
      'name': TextEditingController(text: name),
      'note1': note1Ctrl,
      'note2': note2Ctrl,
      'note3': note3Ctrl,
      'average': 0.0,
    };

    // Calculate initial average
    row['average'] = _calculateAverage(n1, n2, n3) ?? 0.0;

    // Add listeners
    void updateListener() {
      setState(() {
        row['average'] = _calculateAverage(note1Ctrl.text, note2Ctrl.text, note3Ctrl.text) ?? 0.0;
      });
    }

    note1Ctrl.addListener(updateListener);
    note2Ctrl.addListener(updateListener);
    note3Ctrl.addListener(updateListener);

    setState(() {
      _rows.add(row);
    });
  }
  
  double? _calculateAverage(String s1, String s2, String s3) {
    List<double> values = [];
    final v1 = double.tryParse(s1.replaceAll(',', '.').trim());
    final v2 = double.tryParse(s2.replaceAll(',', '.').trim());
    final v3 = double.tryParse(s3.replaceAll(',', '.').trim());
    
    if (v1 != null) values.add(v1);
    if (v2 != null) values.add(v2);
    if (v3 != null) values.add(v3);
    
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  void _saveChanges() {
    List<StudentGrade> newGrades = [];
    
    for (var row in _rows) {
      final name = (row['name'] as TextEditingController).text.trim();
      if (name.isEmpty) continue;
      
      final Map<String, double> grades = {};
      final n1 = double.tryParse((row['note1'] as TextEditingController).text.replaceAll(',', '.').trim());
      final n2 = double.tryParse((row['note2'] as TextEditingController).text.replaceAll(',', '.').trim());
      final n3 = double.tryParse((row['note3'] as TextEditingController).text.replaceAll(',', '.').trim());
      
      if (n1 != null) grades['Note 1'] = n1;
      if (n2 != null) grades['Note 2'] = n2;
      if (n3 != null) grades['Note 3'] = n3;
      
      newGrades.add(StudentGrade(name: name, grades: grades));
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
        title: Text('Saisie Notes (${widget.selectedLevel})', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFF10B981)),
            onPressed: _saveChanges,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmptyRow,
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return _buildMobileView();
          } else {
            return _buildDesktopView();
          }
        },
      ),
    );
  }

  Widget _buildMobileView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        final avg = row['average'] as double?;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                     width: 32, height: 32,
                     decoration: BoxDecoration(
                       color: const Color(0xFF10B981).withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Center(
                       child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: TextField(
                        controller: row['name'],
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'Nom de l\'élève',
                          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                     ),
                   ),
                   IconButton(
                     icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7)),
                     onPressed: () {
                        setState(() {
                          _rows.removeAt(index);
                        });
                     },
                   ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: _buildMobileNoteInput(row['note1'], 'Note 1')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMobileNoteInput(row['note2'], 'Note 2')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMobileNoteInput(row['note3'], 'Note 3')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: (avg != null && avg >= 10) 
                      ? const Color(0xFF10B981).withOpacity(0.1) 
                      : Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MOYENNE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                    Text(
                      avg?.toStringAsFixed(2) ?? '-',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (avg != null && avg >= 10) ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildMobileNoteInput(TextEditingController ctrl, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
             color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Center(
            child: TextField(
               controller: ctrl,
               keyboardType: const TextInputType.numberWithOptions(decimal: true),
               textAlign: TextAlign.center,
               style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
               decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopView() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('#', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                Expanded(flex: 3, child: Text('NOM & PRÉNOM', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))),
                Expanded(child: Center(child: Text('NOTE 1', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))),
                Expanded(child: Center(child: Text('NOTE 2', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))),
                Expanded(child: Center(child: Text('NOTE 3', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))),
                Expanded(child: Center(child: Text('MOYENNE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))),
                const SizedBox(width: 48), // Action space
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = _rows[index];
                final avg = row['average'] as double?;
                
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text('${index + 1}', style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)))),
                      Expanded(
                        flex: 3, 
                        child: TextField(
                           controller: row['name'],
                           style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                           decoration: InputDecoration(
                             border: InputBorder.none, 
                             hintText: 'Nom Élève',
                             hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3))
                           ),
                        ),
                      ),
                      _buildDesktopNoteCell(row['note1']),
                      _buildDesktopNoteCell(row['note2']),
                      _buildDesktopNoteCell(row['note3']),
                      // Average Cell
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: avg != null && avg >= 10 ? const Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              avg?.toStringAsFixed(2) ?? '-',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: avg != null && avg >= 10 ? const Color(0xFF10B981) : Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: theme.iconTheme.color?.withOpacity(0.3)),
                         onPressed: () {
                            setState(() {
                              _rows.removeAt(index);
                            });
                         },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (30 * index).ms).slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopNoteCell(TextEditingController ctrl) {
      final theme = Theme.of(context);
      return Expanded(
        child: Center(
          child: Container(
             width: 60,
             decoration: BoxDecoration(
               color: theme.canvasColor,
               borderRadius: BorderRadius.circular(8),
             ),
             child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color),
                decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
             ),
          ),
        ),
      );
  }
}
