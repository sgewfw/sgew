import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/begehung_enums.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool get _debug => kDebugMode;
  CollectionReference<Map<String, dynamic>> get _usersRef => _firestore.collection('users');

  void _log(String msg) { if (_debug) debugPrint('[UserService] $msg'); }
  void _logError(String msg, [Object? e]) { if (_debug) { debugPrint('[UserService] ERROR: $msg'); if (e != null) debugPrint('[UserService] $e'); } }
  void _logSuccess(String msg) { if (_debug) debugPrint('[UserService] OK: $msg'); }

  Future<void> debugCheckUserDoc(String uid) async {
    if (!_debug) return;
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) { _logError('User-Dokument existiert NICHT!'); return; }
      final data = doc.data()!;
      _logSuccess('User: status=${data['status']}, rolle=${data['rolle']}');
    } on FirebaseException catch (e) { _logError('Fehler', e); }
  }

  Future<void> runFullDiagnostic() async {
    if (!_debug) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) { _logError('Kein User.'); return; }
    await debugCheckUserDoc(u.uid);
    for (final c in ['users', 'begehungen', 'abteilungen']) { await testCollectionRead(c); }
  }

  Future<bool> testCollectionRead(String collection) async {
    try { await _firestore.collection(collection).limit(1).get(); _logSuccess('$collection: OK'); return true;
    } on FirebaseException catch (e) { _logError('$collection: DENIED', e); return false; }
  }

  Future<BegehungUser> getOrCreateUser(User firebaseUser) async {
    _log('getOrCreateUser()');
    try {
      final doc = await _usersRef.doc(firebaseUser.uid).get();
      if (doc.exists) { return BegehungUser.fromFirestore(doc); }
      final newUser = BegehungUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? '',
          rolle: UserRolle.mitarbeiter, status: UserStatus.aktiv, abteilung: '', standort: '',
          begehungenDiesesJahr: 0, offeneMaengel: 0, behobeneMaengel: 0, createdAt: DateTime.now());
      await _usersRef.doc(firebaseUser.uid).set(newUser.toFirestore());
      _logSuccess('Neuer User erstellt'); return newUser;
    } on FirebaseException catch (e) { _logError('getOrCreateUser FAILED', e); rethrow; }
  }

  Stream<BegehungUser?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BegehungUser.fromFirestore(doc);
    }).handleError((e) { _logError('watchUser($uid) FEHLER', e); });
  }

  Stream<List<BegehungUser>> watchUsers({String? abteilung, String? standort}) {
    Query<Map<String, dynamic>> query = _usersRef;
    if (abteilung != null && abteilung.isNotEmpty) query = query.where('abteilung', isEqualTo: abteilung);
    if (standort != null && standort.isNotEmpty) query = query.where('standort', isEqualTo: standort);
    return query.snapshots().map((s) => s.docs.map((d) => BegehungUser.fromFirestore(d)).toList())
        .handleError((e) { _logError('watchUsers FEHLER', e); });
  }

  Stream<List<BegehungUser>> watchPendingUsers() {
    return _usersRef.where('status', isEqualTo: UserStatus.ausstehend.firestoreValue)
        .orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => BegehungUser.fromFirestore(d)).toList())
        .handleError((e) { _logError('watchPendingUsers FEHLER', e); });
  }

  Stream<int> watchPendingCount() {
    return _usersRef.where('status', isEqualTo: UserStatus.ausstehend.firestoreValue)
        .snapshots().map((s) => s.docs.length).handleError((e) { _logError('watchPendingCount FEHLER', e); });
  }

  Stream<List<BegehungUser>> watchAllUsersSorted() {
    return _usersRef.orderBy('createdAt', descending: true).snapshots()
        .map((s) => s.docs.map((d) => BegehungUser.fromFirestore(d)).toList())
        .handleError((e) { _logError('watchAllUsersSorted FEHLER', e); });
  }

  Future<void> freigebenMitAbteilung(String uid, String abteilung, String standort) async {
    try { await _usersRef.doc(uid).update({'status': UserStatus.aktiv.firestoreValue, 'abteilung': abteilung, 'standort': standort, 'freigegebenAm': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) { _logError('freigebenMitAbteilung FAILED', e); rethrow; }
  }

  Future<void> ablehnen(String uid) async {
    try { await _usersRef.doc(uid).update({'status': UserStatus.abgelehnt.firestoreValue});
    } on FirebaseException catch (e) { _logError('ablehnen FAILED', e); rethrow; }
  }

  Future<void> updateRolle(String uid, UserRolle neueRolle) async {
    try { await _usersRef.doc(uid).update({'rolle': neueRolle.label});
    } on FirebaseException catch (e) { _logError('updateRolle FAILED', e); rethrow; }
  }

  Future<void> updateStatus(String uid, UserStatus status) async {
    try { await _usersRef.doc(uid).update({'status': status.firestoreValue});
    } on FirebaseException catch (e) { _logError('updateStatus FAILED', e); rethrow; }
  }

  Future<void> updateAbteilung(String uid, String abteilung, String standort) async {
    try { await _usersRef.doc(uid).update({'abteilung': abteilung, 'standort': standort});
    } on FirebaseException catch (e) { _logError('updateAbteilung FAILED', e); rethrow; }
  }

  Future<void> updateName(String uid, String name) async {
    try { await _usersRef.doc(uid).update({'name': name});
    } on FirebaseException catch (e) { _logError('updateName FAILED', e); rethrow; }
  }

  Future<void> updateDarkMode(String uid, bool darkMode) async {
    try { await _usersRef.doc(uid).update({'darkMode': darkMode});
    } on FirebaseException catch (e) { _logError('updateDarkMode FAILED', e); rethrow; }
  }
}