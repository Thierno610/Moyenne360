import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Comment importer mes notes ?',
      'answer': 'Allez sur la page d\'accueil, cliquez sur "Importer Données". Vous pouvez sélectionner un fichier Excel (.xlsx) ou CSV. Assurez-vous que le fichier respecte le format demandé (Nom, Prénom, Notes...).'
    },
    {
      'question': 'Quel est le format du fichier Excel ?',
      'answer': 'Le fichier doit contenir les colonnes suivantes : "Nom", "Prénom", "Matière", "Note". Une note peut être séparée par des virgules si plusieurs notes sont dans la même cellule pour une matière.'
    },
    {
      'question': 'Comment sont calculées les moyennes ?',
      'answer': 'La moyenne est calculée en faisant la somme des notes divisée par le nombre de notes pour chaque matière. La moyenne générale est la moyenne de toutes les moyennes par matière.'
    },
    {
      'question': 'Puis-je modifier une note après import ?',
      'answer': 'Oui ! Allez dans "Saisie Manuelle" ou "Gestion de classe", sélectionnez l\'élève et modifiez ses notes directement. N\'oubliez pas de sauvegarder.'
    },
    {
      'question': 'L\'application fonctionne-t-elle hors ligne ?',
      'answer': 'Absolument. Toutes les données sont stockées localement sur votre appareil. Aucune connexion internet n\'est requise pour le fonctionnement de base.'
    },
    {
      'question': 'Comment activer le mode sombre ?',
      'answer': 'Allez dans "Paramètres" depuis le menu, puis activez l\'interrupteur "Mode Sombre". L\'application changera instantanément d\'apparence.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Aide & FAQ', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
               border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  faq['question']!,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color
                  ),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF10B981), size: 20),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text(
                      faq['answer']!,
                      style: GoogleFonts.outfit(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (100 * index).ms).moveX(begin: 10, end: 0);
        },
      ),
    );
  }
}
