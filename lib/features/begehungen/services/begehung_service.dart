import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/begehung_model.dart';
import '../models/mangel_model.dart';

class BegehungService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'europe-west1');

  CollectionReference<Map<String, dynamic>> get _begehungenRef =>
      _firestore.collection('begehungen');

  /// Manuellen SmapOne-Sync auslösen (Callable Function)
  Future<SyncResult> syncFromSmapOne() async {
    try {
      final callable = _functions.httpsCallable('syncBegehungen');
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;

      return SyncResult(
        success: data['success'] ?? false,
        imported: data['imported'] ?? 0,
        skipped: data['skipped'] ?? 0,
        errors: data['errors'] ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      return SyncResult(
        success: false,
        imported: 0,
        skipped: 0,
        errors: 1,
        errorMessage: e.message,
      );
    }
  }

  /// Echtzeit-Stream aller Begehungen (optional gefiltert)
  Stream<List<Begehung>> watchBegehungen({
    String? abteilung,
    String? standort,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
    _begehungenRef.orderBy('datum', descending: true);

    if (abteilung != null && abteilung.isNotEmpty) {
      query = query.where('abteilung', isEqualTo: abteilung);
    }
    if (standort != null && standort.isNotEmpty) {
      query = query.where('standort', isEqualTo: standort);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Begehung.fromFirestore(doc)).toList());
  }

  /// Einzelne Begehung laden
  Future<Begehung?> getBegehung(String id) async {
    final doc = await _begehungenRef.doc(id).get();
    if (!doc.exists) return null;
    return Begehung.fromFirestore(doc);
  }

  /// Echtzeit-Stream einer einzelnen Begehung
  Stream<Begehung?> watchBegehung(String id) {
    return _begehungenRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Begehung.fromFirestore(doc);
    });
  }

  /// Alle Mängel einer Begehung als Echtzeit-Stream
  Stream<List<Mangel>> watchMaengel(String begehungId) {
    return _begehungenRef
        .doc(begehungId)
        .collection('maengel')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Mangel.fromFirestore(doc)).toList());
  }

  /// Begehungen eines bestimmten Jahres zählen
  Future<int> countBegehungenImJahr(int jahr, {String? abteilung}) async {
    final start = DateTime(jahr);
    final end = DateTime(jahr + 1);

    Query<Map<String, dynamic>> query = _begehungenRef
        .where('datum', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('datum', isLessThan: Timestamp.fromDate(end));

    if (abteilung != null && abteilung.isNotEmpty) {
      query = query.where('abteilung', isEqualTo: abteilung);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}

/// Ergebnis eines SmapOne-Sync-Vorgangs
class SyncResult {
  final bool success;
  final int imported;
  final int skipped;
  final int errors;
  final String? errorMessage;

  SyncResult({
    required this.success,
    required this.imported,
    required this.skipped,
    required this.errors,
    this.errorMessage,
  });

  String get statusText {
    if (!success) return 'Sync fehlgeschlagen: ${errorMessage ?? "Unbekannter Fehler"}';
    if (imported == 0 && skipped == 0) return 'Keine neuen Begehungen gefunden.';
    return '$imported neue Begehung(en) importiert.';
  }
}