import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatelessWidget {
  final String userName;
  final String userLevel;
  final VoidCallback onContinue;

  const LandingPage({
    super.key,
    required this.userName,
    required this.userLevel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
              ),
            ),
          ),

          // 2. Animated Background Orbs
          _buildOrb(
            top: -100,
            right: -100,
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            size: 400,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 5.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
              ),
          _buildOrb(
            bottom: -50,
            left: -50,
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            size: 300,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                begin: 0,
                end: 50,
                duration: 4.seconds,
              ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Section
                    _buildGlassCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 24),
                          Text(
                            'Ravi de vous revoir,',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          const SizedBox(height: 8),
                          Text(
                            userName,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.headlineLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Info Section
                    _buildGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoChip(
                            icon: Icons.school_outlined,
                            label: userLevel,
                          ),
                          const SizedBox(width: 16),
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(),
                          ),
                        ],
                      ),
                    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 48),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Accéder au Tableau de Bord',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ).animate(delay: 1000.ms).fadeIn().scale(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 100,
              spreadRadius: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
