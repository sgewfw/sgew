// lib/screens/admin/admin_login_screen.dart
//
// ÄNDERUNGEN gegenüber Originalversion:
//  - signInWithEmailAndPassword → signInBegehung (@suewag.de Check)
//  - Nach Login: status-Prüfung in Firestore
//    • "ausstehend" → BegehungPendingApprovalScreen
//    • "gesperrt"   → Fehlermeldung, kein Pop(true)
//    • "aktiv"      → Navigator.pop(true) wie bisher
//  - Links zu Registrierung + Passwort vergessen
//  - getOrCreateUser wird hier aufgerufen (behebt das currentUser=null Problem)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../features/begehungen/screens/begehung_forgot_password_screen.dart';
import '../../features/begehungen/screens/begehung_registration_screen.dart';
import '../../services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Login via signInBegehung → prüft @suewag.de
      final user = await _authService.signInBegehung(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _errorMessage =
          'Anmeldung fehlgeschlagen. Nur @suewag.de E-Mail-Adressen sind erlaubt.';
        });
        return;
      }

      // 2. Firestore-Dokument holen oder erstellen
      //    FIX: Das ist der Grund warum currentUser vorher null war!
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Erstelle minimales Dokument falls noch keines existiert
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ??
              user.email?.split('@').first ?? '',
          'rolle': 'Mitarbeiter',
          'abteilung': '',
          'standort': '',
          'status': 'aktiv', // manuell erstellte User direkt aktiv
          'darkMode': true,
          'begehungenDiesesJahr': 0,
          'offeneMaengel': 0,
          'behobeneMaengel': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Status prüfen
      final freshDoc = await docRef.get();
      final status =
          (freshDoc.data() as Map<String, dynamic>?)?['status'] as String? ??
              'aktiv';

      if (!mounted) return;

      switch (status) {
        case 'ausstehend':
        // Zur Warteseite weiterleiten
          await _authService.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const BegehungPendingApprovalScreen(),
            ),
          );
          break;

        case 'gesperrt':
        case 'abgelehnt':
          await _authService.signOut();
          setState(() {
            _errorMessage =
            'Dein Konto wurde deaktiviert. Bitte wende dich an einen Administrator.';
          });
          break;

        default: // 'aktiv'
          Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = AuthService.getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten';
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
        title: const Text('Anmeldung'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                    const SizedBox(height: 48),

                    Text(
                      'Mission Zero',
                      style: SuewagTextStyles.headline2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bitte melden Sie sich an',
                      style: SuewagTextStyles.bodyMedium.copyWith(
                        color: SuewagColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // E-Mail
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte E-Mail eingeben';
                        }
                        if (!value.contains('@')) {
                          return 'Ungültige E-Mail-Adresse';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 16),

                    // Passwort
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        hintText: '••••••••',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: _passwordFocus.hasFocus
                              ? SuewagColors.primary
                              : SuewagColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: SuewagColors.textSecondary,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Passwort eingeben';
                        }
                        if (value.length < 6) {
                          return 'Passwort muss mindestens 6 Zeichen haben';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    // Passwort vergessen
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const BegehungForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(
                          'Passwort vergessen?',
                          style: SuewagTextStyles.bodySmall
                              .copyWith(color: SuewagColors.primary),
                        ),
                      ),
                    ),

                    // Fehlermeldung
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                          SuewagColors.erdbeerrot.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SuewagColors.erdbeerrot
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: SuewagColors.erdbeerrot,
                                size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: SuewagTextStyles.bodySmall
                                    .copyWith(
                                    color: SuewagColors.erdbeerrot),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 20),
                          const SizedBox(width: 8),
                          Text('Anmelden',
                              style:
                              SuewagTextStyles.buttonMedium),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: SuewagColors.quartzgrau25)),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('oder',
                              style: SuewagTextStyles.bodySmall.copyWith(
                                  color: SuewagColors.textSecondary)),
                        ),
                        Expanded(
                            child: Divider(
                                color: SuewagColors.quartzgrau25)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Registrieren Button
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const BegehungRegistrationScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Neues Konto erstellen'),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: SuewagColors.primary,
                        side: BorderSide(
                            color: SuewagColors.primary.withOpacity(0.4)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SuewagColors.quartzgrau10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18,
                              color: SuewagColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nur für Mitarbeiter mit @suewag.de E-Mail-Adresse',
                              style: SuewagTextStyles.bodySmall.copyWith(
                                  color: SuewagColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}