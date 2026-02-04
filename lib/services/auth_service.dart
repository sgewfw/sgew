// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

/// Minimaler Auth Service für Admin-Login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hardcoded Admin E-Mail
  static const String adminEmail = 'klemmerro@gmail.com';

  // Aktueller User Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktueller User
  User? get currentUser => _auth.currentUser;

  // Ist User eingeloggt?
  bool get isAuthenticated => _auth.currentUser != null;

  // Ist aktueller User Admin?
  bool get isAdmin => 
      _auth.currentUser != null && 
      _auth.currentUser!.email?.toLowerCase() == adminEmail.toLowerCase();

  /// Login mit Email & Passwort
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Fehler werden als null zurückgegeben
      // UI kann dann entsprechende Fehlermeldung anzeigen
      print('🔴 Login Fehler: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('🔴 Login Fehler: $e');
      return null;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Logout erfolgreich');
    } catch (e) {
      print('🔴 Logout Fehler: $e');
      rethrow;
    }
  }

  /// Fehlercode zu deutscher Nachricht
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser E-Mail gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      case 'user-disabled':
        return 'Dieser Account wurde deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Anmeldeversuche. Bitte später erneut versuchen';
      case 'invalid-credential':
        return 'Ungültige Anmeldedaten';
      default:
        return 'Anmeldefehler: ${e.message}';
    }
  }
}