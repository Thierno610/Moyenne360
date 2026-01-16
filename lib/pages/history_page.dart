import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [
    {
      'title': 'Importation réussie',
      'description': 'Classe 3ème A - Mathématiques',
      'date': 'Aujourd\'hui, 15:30',
      'type': 'import',
    },
    {
      'title': 'Modification de notes',
      'description': 'Élève: Jean Dupont',
      'date': 'Aujourd\'hui, 14:15',
      'type': 'edit',
    },
    {
      'title': 'Exportation PDF',
      'description': 'Bulletin de notes global',
      'date': 'Hier, 09:45',
      'type': 'export',
    },
    {
      'title': 'Sauvegarde Database',
      'description': 'Sauvegarde automatique',
      'date': 'Hier, 09:40',
      'type': 'system',
    },
    {
      'title': 'Nouvelle classe ajoutée',
      'description': 'Terminale S2',
      'date': '14 Janv. 2026',
      'type': 'add',
    },
  ];

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique effacé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Historique', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.iconTheme.color),
            onPressed: _history.isEmpty ? null : _clearHistory,
          )
        ],
      ),
      body: _history.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.withOpacity(0.3)),
                   const SizedBox(height: 16),
                   Text('Aucun historique', style: GoogleFonts.outfit(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _history.length,
              separatorBuilder: (c, i) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final item = _history[index];
                return _buildHistoryItem(context, item, index);
              },
            ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color iconColor;
    IconData iconData;
    Color bgColor;

    switch (item['type']) {
      case 'import':
        iconColor = Colors.blue;
        iconData = Icons.file_upload_outlined;
        bgColor = Colors.blue.withOpacity(0.1);
        break;
      case 'export':
        iconColor = Colors.orange;
        iconData = Icons.file_download_outlined;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'edit':
        iconColor = const Color(0xFF10B981);
        iconData = Icons.edit_outlined;
        bgColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'add':
        iconColor = Colors.purple;
        iconData = Icons.add_circle_outline;
        bgColor = Colors.purple.withOpacity(0.1);
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.info_outline;
        bgColor = Colors.grey.withOpacity(0.1);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            if (index != _history.length - 1)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.only(top: 8),
                color: theme.dividerColor.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['title'],
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      item['date'],
                      style: GoogleFonts.outfit(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'],
                  style: GoogleFonts.outfit(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
  }
}
