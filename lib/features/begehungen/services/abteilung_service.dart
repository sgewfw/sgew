import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/abteilung_model.dart';

class AbteilungService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _abteilungenRef =>
      _firestore.collection('abteilungen');

  /// Echtzeit-Stream aller Abteilungen
  Stream<List<Abteilung>> watchAbteilungen() {
    return _abteilungenRef.orderBy('standort').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Abteilung.fromFirestore(doc)).toList());
  }

  /// Einzelne Abteilung per Name suchen
  Future<Abteilung?> findByName(String name) async {
    final snapshot = await _abteilungenRef
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Abteilung.fromFirestore(snapshot.docs.first);
  }

  /// Initialdaten in Firestore anlegen (nur wenn Collection leer)
  Future<void> seedAbteilungen() async {
    final existing = await _abteilungenRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      print('⚠️ Abteilungen existieren bereits, Seed übersprungen');
      return;
    }

    final batch = _firestore.batch();
    for (final data in Abteilung.seedData) {
      final docRef = _abteilungenRef.doc();
      batch.set(docRef, {
        ...data,
        'begehungenDiesesJahr': 0,
        'offeneMaengel': 0,
      });
    }
    await batch.commit();
    print('✅ ${Abteilung.seedData.length} Abteilungen angelegt');
  }
}
