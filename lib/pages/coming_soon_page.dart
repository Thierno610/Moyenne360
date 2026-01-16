import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.construction_rounded, size: 80, color: Color(0xFF10B981)),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 32),
            
            Text(
              'Bientôt Disponible',
              style: GoogleFonts.outfit(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.bodyLarge?.color
              ),
            ).animate().fadeIn().moveY(begin: 20, end: 0),
            
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Cette fonctionnalité est en cours de développement. Revenez bientôt pour découvrir les nouveautés !',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.5
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

            const SizedBox(height: 48),

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: Text('Retour', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
