import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moyenne_auto/pages/onboarding_page.dart';
import 'package:moyenne_auto/main.dart'; // For EntryShell
import 'package:moyenne_auto/services/theme_service.dart';
import 'package:moyenne_auto/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Minimum Splash Display Time
    final minDelay = Future.delayed(const Duration(seconds: 3));

    // 2. Initialize Services (Parallel)
    await Future.wait([
      themeService.loadTheme(),
      DatabaseService().database, // Ensure DB is ready
      // Add other async inits here
    ]);

    // 3. Check Onboarding Status
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    await minDelay; // Wait for animation

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => seenOnboarding 
              ? const EntryShell() 
              : const OnboardingPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animation
            Image.asset(
              'assets/images/logo.png',
              height: 120,
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .then(delay: 500.ms)
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha:0.5))
            .then(delay: 500.ms), // Loop effect handled by re-render or just single pass

            const SizedBox(height: 24),

            // Text Animation
            Text(
              'Moyennes360',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineLarge?.color ?? const Color(0xFF1E293B),
                letterSpacing: 1.5,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 8),

            Text(
              'L\'excellence à portée de main',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7) ?? const Color(0xFF64748B),
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
