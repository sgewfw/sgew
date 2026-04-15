// lib/features/begehung/screens/begehung_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';

class BegehungRegistrationScreen extends StatefulWidget {
  const BegehungRegistrationScreen({super.key});
  @override
  State<BegehungRegistrationScreen> createState() => _BegehungRegistrationScreenState();
}

class _BegehungRegistrationScreenState extends State<BegehungRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nameFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose(); _passwordController.dispose(); _nameController.dispose();
    _emailFocus.dispose(); _passwordFocus.dispose(); _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(), password: _passwordController.text);
      final user = credential.user;
      if (user == null) throw Exception('User konnte nicht erstellt werden');

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid, 'email': user.email, 'name': _nameController.text.trim(),
        'rolle': 'Mitarbeiter', 'abteilung': '', 'standort': '',
        'status': 'ausstehend', 'darkMode': true, 'begehungenDiesesJahr': 0,
        'offeneMaengel': 0, 'behobeneMaengel': 0, 'createdAt': FieldValue.serverTimestamp(),
      });

      // FIX: Sofort ausloggen bevor Dashboard-Streams starten
      await _auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BegehungPendingApprovalScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = _getAuthErrorMessage(e); });
    } catch (e) {
      setState(() { _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten: $e'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Diese E-Mail-Adresse ist bereits registriert';
      case 'weak-password': return 'Das Passwort ist zu schwach (mindestens 6 Zeichen)';
      case 'invalid-email': return 'Ungültige E-Mail-Adresse';
      default: return 'Fehler: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(title: const Text('Registrierung'), backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/logo.png', height: 80, fit: BoxFit.contain, filterQuality: FilterQuality.high),
                    const SizedBox(height: 40),
                    Text('Neues Konto erstellen', style: SuewagTextStyles.headline2, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Nur für @suewag.de E-Mail-Adressen', style: SuewagTextStyles.bodyMedium.copyWith(color: SuewagColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: SuewagColors.verkehrsorange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: SuewagColors.verkehrsorange.withOpacity(0.3))),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: SuewagColors.verkehrsorange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Nach der Registrierung muss dein Konto von einem Administrator freigegeben werden.', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.verkehrsorange))),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(controller: _nameController, focusNode: _nameFocus, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Vollständiger Name', hintText: 'Max Mustermann', prefixIcon: Icon(Icons.person_outline, color: _nameFocus.hasFocus ? SuewagColors.primary : SuewagColors.textSecondary)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Namen eingeben' : null, onFieldSubmitted: (_) => _emailFocus.requestFocus()),
                    const SizedBox(height: 16),
                    TextFormField(controller: _emailController, focusNode: _emailFocus, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'E-Mail', hintText: 'vorname.nachname@suewag.de', prefixIcon: Icon(Icons.email_outlined, color: _emailFocus.hasFocus ? SuewagColors.primary : SuewagColors.textSecondary)),
                        validator: (v) { if (v == null || v.trim().isEmpty) return 'Bitte E-Mail eingeben'; if (!v.trim().toLowerCase().endsWith('@suewag.de')) return 'Nur @suewag.de E-Mail-Adressen erlaubt'; return null; },
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus()),
                    const SizedBox(height: 16),
                    TextFormField(controller: _passwordController, focusNode: _passwordFocus, obscureText: _obscurePassword, textInputAction: TextInputAction.done,
                        decoration: InputDecoration(labelText: 'Passwort', hintText: 'Mindestens 6 Zeichen', prefixIcon: Icon(Icons.lock_outlined, color: _passwordFocus.hasFocus ? SuewagColors.primary : SuewagColors.textSecondary),
                            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: SuewagColors.textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                        validator: (v) { if (v == null || v.isEmpty) return 'Bitte Passwort eingeben'; if (v.length < 6) return 'Passwort muss mindestens 6 Zeichen haben'; return null; },
                        onFieldSubmitted: (_) => _handleRegistration()),
                    if (_errorMessage != null) ...[const SizedBox(height: 16), _buildErrorBanner(_errorMessage!)],
                    const SizedBox(height: 28),
                    ElevatedButton(onPressed: _isLoading ? null : _handleRegistration,
                        style: ElevatedButton.styleFrom(backgroundColor: SuewagColors.verkehrsorange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.how_to_reg, size: 20), const SizedBox(width: 8), Text('Registrieren', style: SuewagTextStyles.buttonMedium)])),
                    const SizedBox(height: 20),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Bereits ein Konto? Anmelden', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.primary))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: SuewagColors.erdbeerrot.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: SuewagColors.erdbeerrot.withOpacity(0.3))),
      child: Row(children: [Icon(Icons.error_outline, color: SuewagColors.erdbeerrot, size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.erdbeerrot)))]),
    );
  }
}

class BegehungPendingApprovalScreen extends StatelessWidget {
  const BegehungPendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: SuewagColors.verkehrsorange.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.hourglass_empty_rounded, size: 64, color: SuewagColors.verkehrsorange)),
                  const SizedBox(height: 32),
                  Text('Registrierung eingegangen!', style: SuewagTextStyles.headline2, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Dein Konto wurde erstellt und wartet auf Freigabe durch einen Administrator.', style: SuewagTextStyles.bodyMedium.copyWith(color: SuewagColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  OutlinedButton.icon(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), icon: const Icon(Icons.arrow_back), label: const Text('Zurück zur Startseite')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}