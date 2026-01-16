import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSending = false);
    
    // Clear form
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message envoyé avec succès !'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Contactez-nous', style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color)),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Illustration/Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline_rounded, size: 48, color: Color(0xFF10B981)),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              Text(
                'Une question ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ).animate().fadeIn().moveY(begin: 10, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Remplissez le formulaire ci-dessous et notre équipe vous répondra dans les plus brefs délais.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),

              const SizedBox(height: 32),

              _buildTextField(label: 'Nom Complet', controller: _nameController, icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField(label: 'Message', controller: _messageController, icon: Icons.message_outlined, maxLines: 5),

              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                  ),
                  child: _isSending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Envoyer le message', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color),
        validator: (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: theme.iconTheme.color?.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    ).animate().fadeIn().moveX(begin: -10, end: 0);
  }
}
