import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moyenne_auto/models/student_grade.dart';
import 'package:moyenne_auto/services/grade_service.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({
    super.key,
    required this.selectedLevel,
    required this.onFileImported,
  });

  final String selectedLevel;
  final void Function(List<StudentGrade>, double?) onFileImported;

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  final _gradeService = GradeService();
  bool _isLoading = false;
  String? _fileName;
  
  // Review State
  bool _isReviewing = false;
  List<StudentGrade> _previewStudents = [];

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(result.files.single.path!);
      final students = await _gradeService.parseFile(file);

      if (students.isEmpty) throw Exception('Aucun étudiant trouvé');

      _gradeService.calculateAverages(students);
      _gradeService.rankStudents(students);

      setState(() {
        _fileName = result.files.single.name;
        _previewStudents = students;
        _isReviewing = true; // Switch to review mode
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
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

  void _validateImport() {
    final classAvg = _gradeService.calculateClassAverage(_previewStudents);
    widget.onFileImported(_previewStudents, classAvg);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_previewStudents.length} étudiants importés avec succès !'),
        backgroundColor: const Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _editStudent(int index) {
    final student = _previewStudents[index];
    final nameController = TextEditingController(text: student.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier étudiant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes: ${student.grades.length} détectées', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _previewStudents[index] = StudentGrade(
                  name: nameController.text,
                  grades: student.grades,
                  average: student.average,
                  rank: student.rank,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(int index) {
    setState(() {
      _previewStudents.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_isReviewing ? 'Vérification' : 'Import - ${widget.selectedLevel}'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () {
            if (_isReviewing) {
              setState(() => _isReviewing = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF1E293B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: _isReviewing ? _buildReviewUI() : _buildUploadUI(),
      ),
      bottomNavigationBar: _isReviewing ? _buildBottomBar() : null,
    );
  }

  Widget _buildUploadUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Upload Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF10B981).withOpacity(0.08),
                     blurRadius: 30,
                     offset: const Offset(0, 10),
                   )
                 ]
              ),
              child: Column(
                children: [
                   // Animated Icon BG
                   Container(
                     height: 120,
                     width: 120,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       gradient: LinearGradient(
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                         colors: [
                           const Color(0xFF10B981).withOpacity(0.2),
                           const Color(0xFF34D399).withOpacity(0.05),
                         ]
                       )
                     ),
                     child: const Center(
                       child: Icon(
                         Icons.cloud_upload_rounded,
                         size: 60,
                         color: Color(0xFF10B981),
                       ),
                     ),
                   ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds),
                   
                   const SizedBox(height: 32),
                   
                   Text(
                     'Importer votre fichier',
                     style: GoogleFonts.outfit(
                       fontSize: 24,
                       fontWeight: FontWeight.w800,
                       color: const Color(0xFF1E293B),
                     ),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     'Formats supportés: .CSV, .Excel\nAssurez-vous que le format est correct.',
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(
                       fontSize: 14,
                       color: Colors.grey[500],
                       height: 1.5
                     ),
                   ),
                   
                   const SizedBox(height: 48),
                   
                   if (_isLoading)
                     const CircularProgressIndicator(color: Color(0xFF10B981))
                   else
                     Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(16),
                         gradient: const LinearGradient(
                           colors: [Color(0xFF10B981), Color(0xFF059669)],
                         ),
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFF10B981).withOpacity(0.4),
                             blurRadius: 15,
                             offset: const Offset(0, 8),
                           )
                         ]
                       ),
                       child: Material(
                         color: Colors.transparent,
                         child: InkWell(
                           onTap: _pickFile,
                           borderRadius: BorderRadius.circular(16),
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(Icons.folder_open_rounded, color: Colors.white),
                                 const SizedBox(width: 12),
                                 Text(
                                   'PARCOURIR',
                                   style: GoogleFonts.outfit(
                                     fontSize: 16, 
                                     fontWeight: FontWeight.bold, 
                                     color: Colors.white,
                                     letterSpacing: 1
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                     ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewUI() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Column(
            children: [
              Text(
                'Vérifiez les données',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_previewStudents.length} élèves trouvés',
                style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _previewStudents.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = _previewStudents[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                  ]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48, 
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  title: Text(student.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.notes, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${student.grades.length} notes', 
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.analytics_outlined, size: 14, color: Colors.grey[400]),
                         const SizedBox(width: 4),
                        Text(
                          'Moy: ${student.average?.toStringAsFixed(2) ?? "--"}', 
                           style: GoogleFonts.outfit(
                             color: (student.average ?? 0) >= 10 ? const Color(0xFF10B981) : Colors.red,
                             fontWeight: FontWeight.bold,
                             fontSize: 13
                           )
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                        onPressed: () => _editStudent(index),
                        splashRadius: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteStudent(index),
                         splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ]
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _validateImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'VALIDER ET IMPORTER',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}
