import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moyenne_auto/services/database_service.dart';
import 'package:moyenne_auto/pages/file_upload_page.dart';
import 'package:intl/intl.dart';

class ImportHistoryPage extends StatefulWidget {
  const ImportHistoryPage({super.key});

  @override
  State<ImportHistoryPage> createState() => _ImportHistoryPageState();
}

class _ImportHistoryPageState extends State<ImportHistoryPage> {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await _databaseService.getImportFiles();
    setState(() {
      _history = List.from(data);
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int id, int index) async {
    await _databaseService.deleteImportFile(id);
    setState(() {
      _history.removeAt(index);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier supprimé de l\'historique')),
      );
    }
  }

  void _reuseFile(Map<String, dynamic> item) {
    final path = item['path'] as String;
    final file = File(path);

    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le fichier n\'existe plus sur l\'appareil.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileUploadPage(
          selectedLevel: item['level'] as String? ?? 'Inconnu',
          initialFile: file,
          onFileImported: (students, avg) {
            // Callback handled in FileUploadPage
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Historique des Imports', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withValues(alpha:0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun historique d\'import',
                        style: GoogleFonts.outfit(color: Colors.grey.withValues(alpha:0.5), fontSize: 18),
                      ),
                    ],
                  ).animate().fadeIn(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final date = DateTime.tryParse(item['imported_at'] as String) ?? DateTime.now();
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
                    final name = item['name'] as String;
                    final count = item['student_count'] as int;
                    final level = item['level'] as String;

                    return Dismissible(
                      key: Key(item['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteItem(item['id'] as int, index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                          border: Border.all(color: theme.dividerColor.withValues(alpha:0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.description, color: Color(0xFF10B981)),
                          ),
                          title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(level, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('$count étudiants', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(dateStr, style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
                            tooltip: 'Réutiliser ce fichier',
                            onPressed: () => _reuseFile(item),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
                  },
                ),
    );
  }
}
