import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    // Mock or use package_info_plus if available, but for now mostly static or mock since we just added shared_prefs
    // If package_info_plus isn't added, we can just hardcode or wrap in try-catch if the user adds it later.
    // Given the prompt didn't ask to add package_info_plus, I'll stick to a hardcoded logic with a comment.
    // Or simpler:
    setState(() {
      _version = '1.0.0 (Beta)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('À Propos', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo Animation
            Hero(
              tag: 'app_logo',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset('assets/logo.png', errorBuilder: (c, o, s) => const Icon(Icons.school_rounded, size: 60, color: Color(0xFF10B981))),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text(
              'Moyenne360',
              style: GoogleFonts.outfit(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: 1.2
              ),
            ).animate().fadeIn().moveY(begin: 10, end: 0),

            Text(
              'Version $_version',
              style: GoogleFonts.outfit(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 48),

            _buildInfoCard(
              context,
              title: 'Description',
              content: 'Moyenne360 est l\'outil ultime pour les enseignants et les élèves. Calculez vos moyennes, gérez vos classes et visualisez vos progrès avec une interface moderne et intuitive.',
              icon: Icons.info_outline_rounded,
            ),

            const SizedBox(height: 16),

            _buildInfoCard(
              context,
              title: 'Développeur',
              content: 'Conçu avec passion par l\'équipe Moyenne360.\n© 2026 Tous droits réservés.',
              icon: Icons.code_rounded,
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              context,
              title: 'Politique de Confidentialité',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
             const SizedBox(height: 16),
             _buildActionCard(
              context,
              title: 'Conditions d\'utilisation',
              icon: Icons.description_outlined,
              onTap: () {},
            ),

            const SizedBox(height: 48),
            
            Text(
              'Made with Flutter 💙',
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String content, required IconData icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
         border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5)),
        ],
      ),
    ).animate().fadeIn().moveX(begin: 10, end: 0);
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color))),
            Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    ).animate().fadeIn().moveX(begin: 10, end: 0);
  }
}
