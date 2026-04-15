import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache für die Admin-Prüfung (damit nicht bei jedem Aufruf gelesen wird)
  String? _cachedUid;
  bool _cachedIsAdmin = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Synchroner Check — nutzt den gecachten Wert.
  /// Beim ersten Aufruf oder nach Login muss vorher checkAdmin() aufgerufen werden.
  bool get isAdmin {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    if (uid == _cachedUid) return _cachedIsAdmin;
    // Cache ist veraltet — async Check nötig, gib erstmal false zurück
    checkAdmin();
    return false;
  }

  /// Prüft die Rolle aus Firestore und cached das Ergebnis
  Future<bool> checkAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _cachedUid = null;
      _cachedIsAdmin = false;
      return false;
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final rolle = doc.data()?['rolle'] as String? ?? '';
      _cachedUid = uid;
      _cachedIsAdmin = rolle == 'Admin';
      return _cachedIsAdmin;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] checkAdmin Fehler: $e');
      return false;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] Login Fehler: ${e.code}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] Login Fehler: $e');
      return null;
    }
  }

  bool isSuewagEmail(String email) => email.trim().toLowerCase().endsWith('@suewag.de');

  Future<User?> signInBegehung(String email, String password) async {
    if (!isSuewagEmail(email)) return null;
    return signInWithEmailAndPassword(email, password);
  }

  Future<void> signOut() async {
    _cachedUid = null;
    _cachedIsAdmin = false;
    try { await _auth.signOut(); } catch (e) { rethrow; }
  }

  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Kein Benutzer mit dieser E-Mail gefunden';
      case 'wrong-password': return 'Falsches Passwort';
      case 'invalid-email': return 'Ungültige E-Mail-Adresse';
      case 'user-disabled': return 'Dieser Account wurde deaktiviert';
      case 'too-many-requests': return 'Zu viele Anmeldeversuche. Bitte später erneut versuchen';
      case 'invalid-credential': return 'Ungültige Anmeldedaten';
      default: return 'Anmeldefehler: ${e.message}';
    }
  }
}