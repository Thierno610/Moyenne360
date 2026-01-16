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

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final platformFile = result.files.first;
      final path = platformFile.path;

      if (path == null) {
        throw Exception("Impossible d'accéder au fichier (chemin null).");
      }

      final file = File(path);
      final students = await _gradeService.parseFile(file);

      if (students.isEmpty) throw Exception('Aucun étudiant trouvé dans le fichier.');

      _gradeService.calculateAverages(students);
      _gradeService.rankStudents(students);

      setState(() {
        _fileName = platformFile.name;
        _previewStudents = students;
        _isReviewing = true;
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
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Modifier étudiant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nom complet',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
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
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isReviewing ? 'Vérification' : 'Import - ${widget.selectedLevel}',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (_isReviewing) {
              setState(() => _isReviewing = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: _isReviewing ? _buildReviewUI() : _buildUploadUI(),
          ),
        ],
      ),
      bottomNavigationBar: _isReviewing ? _buildBottomBar() : null,
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
        ),
      ),
      child: Stack(
        children: [
           Positioned(
             top: -100, left: -100,
             child: Container(
               width: 300, height: 300,
               decoration: BoxDecoration(
                 color: const Color(0xFF10B981).withOpacity(0.3),
                 shape: BoxShape.circle,
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF10B981).withOpacity(0.3),
                     blurRadius: 100,
                     spreadRadius: 20,
                   ),
                 ],
               ),
             ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 4.seconds),
           ),
           Positioned(
             bottom: -50, right: -50,
             child: Container(
               width: 250, height: 250,
               decoration: BoxDecoration(
                 color: Colors.blueAccent.withOpacity(0.2),
                 shape: BoxShape.circle,
                 boxShadow: [
                   BoxShadow(
                     color: Colors.blueAccent.withOpacity(0.2),
                     blurRadius: 100,
                     spreadRadius: 20,
                   ),
                 ],
               ),
             ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 50, duration: 5.seconds),
           ),
        ],
      ),
    );
  }

  Widget _buildUploadUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                   Container(
                     height: 120,
                     width: 120,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white.withOpacity(0.05),
                       border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 2),
                     ),
                     child: const Center(
                       child: Icon(Icons.cloud_upload_rounded, size: 50, color: Color(0xFF10B981)),
                     ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                   
                   const SizedBox(height: 32),
                   Text(
                     'Importer votre fichier',
                     style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     'Formats supportés: .CSV, .Excel',
                     style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5)),
                   ),
                   const SizedBox(height: 48),
                   if (_isLoading)
                     const CircularProgressIndicator(color: Color(0xFF10B981))
                   else
                     InkWell(
                       onTap: _pickFile,
                       borderRadius: BorderRadius.circular(16),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                         decoration: BoxDecoration(
                           gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                           borderRadius: BorderRadius.circular(16),
                           boxShadow: [
                             BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4))
                           ],
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.folder_open, color: Colors.white),
                             const SizedBox(width: 12),
                             Text('PARCOURIR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                           ],
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text('Vérifiez les données', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_previewStudents.length} élèves trouvés', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _previewStudents.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = _previewStudents[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                    child: Text(student.name.isNotEmpty ? student.name[0] : '?', style: const TextStyle(color: Color(0xFF10B981))),
                  ),
                  title: Text(student.name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Moy: ${student.average?.toStringAsFixed(2) ?? "--"}',
                    style: TextStyle(color: (student.average ?? 0) >= 10 ? const Color(0xFF10B981) : Colors.redAccent),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _editStudent(index)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteStudent(index)),
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
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _validateImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('VALIDER ET IMPORTER', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
