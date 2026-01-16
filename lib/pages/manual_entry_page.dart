import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // Dispose all controllers
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
          n1: notesValues.length > 0 ? notesValues[0].toString() : '',
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
    row['average'] = _calculateAverage(n1, n2, n3);

    // Add listeners
    void updateListener() {
      setState(() {
        row['average'] = _calculateAverage(note1Ctrl.text, note2Ctrl.text, note3Ctrl.text);
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Saisie Notes - ${widget.selectedLevel}'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
               border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green,
                     foregroundColor: Colors.white,
                   ),
                   onPressed: _addEmptyRow,
                   icon: const Icon(Icons.add),
                   label: const Text('Ajouter une ligne'),
                 ),
                 const Spacer(),
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF3B82F6),
                     foregroundColor: Colors.white,
                   ),
                   onPressed: _saveChanges,
                   icon: const Icon(Icons.save),
                   label: const Text('Enregistrer'),
                 ),
              ],
            ),
          ),
          
          // Grid Header
          Container(
            color: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Center(child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Padding(padding: EdgeInsets.only(left: 8), child: Text('NOM PRENOM', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('NOTE 1', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('NOTE 2', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('NOTE 3', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('MOYENNE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))))), // Added Moyenne Header
                SizedBox(width: 40),
              ],
            ),
          ),
          
          // Grid Rows
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                final avg = row['average'] as double?;
                
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Center(child: Text('${index + 1}'))),
                      Expanded(
                        flex: 3, 
                        child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 8),
                           child: TextField(
                             controller: row['name'],
                             decoration: const InputDecoration(border: InputBorder.none, hintText: 'Nom Élève'),
                           ),
                        ),
                      ),
                      _buildNoteCell(row['note1']),
                      _buildNoteCell(row['note2']),
                      _buildNoteCell(row['note3']),
                      // Average Cell
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: Colors.black12)),
                            color: Color(0xFFF1F5F9), // Slight gray background for read-only
                          ),
                          child: Center(
                            child: Text(
                              avg?.toStringAsFixed(2) ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: avg != null && avg >= 10 ? Colors.green : (avg != null ? Colors.red : Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40, 
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                          onPressed: () {
                             // clean up controllers
                             (row['name'] as TextEditingController).dispose();
                             (row['note1'] as TextEditingController).dispose();
                             (row['note2'] as TextEditingController).dispose();
                             (row['note3'] as TextEditingController).dispose();
                             setState(() => _rows.removeAt(index));
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoteCell(TextEditingController ctrl) {
      return Expanded(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Colors.black12)),
          ),
          child: Center(
            child: TextField(
               controller: ctrl,
               keyboardType: const TextInputType.numberWithOptions(decimal: true),
               textAlign: TextAlign.center,
               decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
            ),
          ),
        ),
      );
  }
}
