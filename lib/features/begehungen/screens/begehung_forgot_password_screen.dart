// lib/features/begehung/screens/begehung_forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';

class BegehungForgotPasswordScreen extends StatefulWidget {
  const BegehungForgotPasswordScreen({super.key});

  @override
  State<BegehungForgotPasswordScreen> createState() =>
      _BegehungForgotPasswordScreenState();
}

class _BegehungForgotPasswordScreenState
    extends State<BegehungForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Kein Konto mit dieser E-Mail-Adresse gefunden';
            break;
          case 'invalid-email':
            _errorMessage = 'Ungültige E-Mail-Adresse';
            break;
          default:
            _errorMessage = 'Fehler: ${e.message}';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: const Text('Passwort zurücksetzen'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 80,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 40),

          Text(
            'Passwort vergessen?',
            style: SuewagTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Gib deine @suewag.de E-Mail-Adresse ein. Du erhältst einen Link zum Zurücksetzen.',
            style: SuewagTextStyles.bodyMedium
                .copyWith(color: SuewagColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'E-Mail',
              hintText: 'vorname.nachname@suewag.de',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _emailFocus.hasFocus
                    ? SuewagColors.primary
                    : SuewagColors.textSecondary,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Bitte E-Mail eingeben';
              }
              if (!v.trim().toLowerCase().endsWith('@suewag.de')) {
                return 'Nur @suewag.de E-Mail-Adressen';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleReset(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.erdbeerrot.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: SuewagColors.erdbeerrot.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: SuewagColors.erdbeerrot, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: SuewagTextStyles.bodySmall
                          .copyWith(color: SuewagColors.erdbeerrot),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleReset,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('Link senden',
                          style: SuewagTextStyles.buttonMedium),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zurück zur Anmeldung',
              style: SuewagTextStyles.bodySmall
                  .copyWith(color: SuewagColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SuewagColors.leuchtendgruen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: SuewagColors.leuchtendgruen,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'E-Mail gesendet!',
          style: SuewagTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Wir haben einen Link zum Zurücksetzen des Passworts an\n${_emailController.text.trim()}\ngesendet.',
          style: SuewagTextStyles.bodyMedium
              .copyWith(color: SuewagColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Bitte prüfe auch deinen Spam-Ordner.',
          style: SuewagTextStyles.bodySmall
              .copyWith(color: SuewagColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Zurück zur Anmeldung'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
            _emailController.clear();
          }),
          child: Text(
            'Andere E-Mail verwenden',
            style: SuewagTextStyles.bodySmall
                .copyWith(color: SuewagColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
