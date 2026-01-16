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
      final classAvg = _gradeService.calculateClassAverage(students);

      setState(() {
        _fileName = result.files.single.name;
        _isLoading = false;
      });

      // Call callback
      widget.onFileImported(students, classAvg);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${students.length} étudiants importés avec succès !'),
            backgroundColor: const Color(0xFF4ADE80),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Optional: auto pop or let user see success
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Import - ${widget.selectedLevel}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                 border: Border.all(color: Colors.grey.withOpacity(0.1), width: 2),
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF10B981).withOpacity(0.05),
                     blurRadius: 30,
                     offset: const Offset(0, 10),
                   )
                 ]
              ),
              child: Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: const Color(0xFF06B6D4).withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       Icons.cloud_upload_rounded,
                       size: 64,
                       color: const Color(0xFF06B6D4),
                     ),
                   ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                   
                   const SizedBox(height: 32),
                   
                   Text(
                     'Sélectionnez un fichier',
                     style: GoogleFonts.outfit(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: const Color(0xFF1E293B),
                     ),
                   ),
                   const SizedBox(height: 12),
                   Text(
                     'Formats supportés: .CSV, .Excel',
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(
                       fontSize: 16,
                       color: const Color(0xFF1E293B).withOpacity(0.5),
                     ),
                   ),
                   
                   const SizedBox(height: 48),
                   
                   if (_isLoading)
                     const CircularProgressIndicator(color: Color(0xFF10B981))
                   else
                     SizedBox(
                       width: double.infinity,
                       height: 56,
                       child: ElevatedButton.icon(
                         onPressed: _pickFile,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF10B981),
                           foregroundColor: Colors.white,
                           elevation: 8,
                           shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                         ),
                         icon: const Icon(Icons.folder_open_rounded),
                         label: const Text(
                           'PARCOURIR',
                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                         ),
                       ),
                     ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
            
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'Fichier importé: $_fileName',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}
