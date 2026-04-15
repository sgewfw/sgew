import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/begehung_enums.dart';
import '../models/mangel_model.dart';

class MangelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _begehungenRef =>
      _firestore.collection('begehungen');

  CollectionReference<Map<String, dynamic>> _maengelRef(String begehungId) =>
      _begehungenRef.doc(begehungId).collection('maengel');

  Future<Mangel?> getMangel(String begehungId, String mangelId) async {
    final doc = await _maengelRef(begehungId).doc(mangelId).get();
    if (!doc.exists) return null;
    return Mangel.fromFirestore(doc);
  }

  /// Notiz zu einem Mangel hinzufügen
  Future<void> addNotiz(
      String begehungId,
      String mangelId, {
        required String autorUid,
        required String autorName,
        required String text,
        String typ = 'notiz',
      }) async {
    final notiz = MangelNotiz(
      autorUid: autorUid,
      autorName: autorName,
      text: text,
      erstelltAm: DateTime.now(),
      typ: typ,
    );

    await _maengelRef(begehungId).doc(mangelId).update({
      'notizen': FieldValue.arrayUnion([notiz.toMap()]),
    });
  }

  /// Mangel als "In Bearbeitung" setzen + automatische Notiz
  Future<void> setzeInBearbeitung(
      String begehungId,
      String mangelId, {
        required String bearbeiterUid,
        required String bearbeiterName,
        String? notizText,
      }) async {
    final notiz = MangelNotiz(
      autorUid: bearbeiterUid,
      autorName: bearbeiterName,
      text: notizText ?? 'Mangel in Bearbeitung genommen',
      erstelltAm: DateTime.now(),
      typ: 'status_aenderung',
    );

    await _maengelRef(begehungId).doc(mangelId).update({
      'status': MangelStatus.inBearbeitung.firestoreValue,
      'notizen': FieldValue.arrayUnion([notiz.toMap()]),
    });
  }

  /// Mangel als behoben markieren + Notiz + Counter-Updates
  Future<void> markiereAlsBehoben(
      String begehungId,
      String mangelId,
      String behobenVonUid, {
        String? kommentar,
        String? behobenVonName,
      }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final mangelRef = _maengelRef(begehungId).doc(mangelId);

    // 1. Mangel-Status + Kommentar
    final updateData = <String, dynamic>{
      'status': MangelStatus.behoben.firestoreValue,
      'behoben_von_uid': behobenVonUid,
      'behoben_am': Timestamp.fromDate(now),
    };
    if (kommentar != null && kommentar.isNotEmpty) {
      updateData['behoben_kommentar'] = kommentar;
    }
    batch.update(mangelRef, updateData);

    // 2. Begehung-Counter
    final begehungRef = _begehungenRef.doc(begehungId);
    batch.update(begehungRef, {
      'offeneMaengel': FieldValue.increment(-1),
      'behobeneMaengel': FieldValue.increment(1),
    });

    // 3. User + Abteilung Counter
    final mangelDoc = await mangelRef.get();
    if (mangelDoc.exists) {
      final mangel = Mangel.fromFirestore(mangelDoc);

      if (mangel.zustaendigUid.isNotEmpty) {
        final userRef =
        _firestore.collection('users').doc(mangel.zustaendigUid);
        batch.update(userRef, {
          'offeneMaengel': FieldValue.increment(-1),
          'behobeneMaengel': FieldValue.increment(1),
        });
      }

      final begehungDoc = await begehungRef.get();
      if (begehungDoc.exists) {
        final abteilungName = begehungDoc.data()?['abteilung'] as String?;
        if (abteilungName != null && abteilungName.isNotEmpty) {
          final abteilungSnapshot = await _firestore
              .collection('abteilungen')
              .where('name', isEqualTo: abteilungName)
              .limit(1)
              .get();
          if (abteilungSnapshot.docs.isNotEmpty) {
            batch.update(abteilungSnapshot.docs.first.reference, {
              'offeneMaengel': FieldValue.increment(-1),
            });
          }
        }
      }
    }

    await batch.commit();

    // Notiz hinzufügen (nach batch.commit, da arrayUnion in batch mit anderen Updates auf demselben Doc problematisch sein kann)
    final notizText = kommentar != null && kommentar.isNotEmpty
        ? 'Mangel behoben: $kommentar'
        : 'Mangel als behoben markiert';

    await addNotiz(
      begehungId,
      mangelId,
      autorUid: behobenVonUid,
      autorName: behobenVonName ?? '',
      text: notizText,
      typ: 'behoben',
    );
  }

  /// Mangel-Status ändern (ohne Counter, z.B. für Zurücksetzen)
  Future<void> updateStatus(
      String begehungId,
      String mangelId,
      MangelStatus neuerStatus,
      ) async {
    await _maengelRef(begehungId).doc(mangelId).update({
      'status': neuerStatus.firestoreValue,
    });
  }

  /// Alle offenen Mängel — kein Composite Index nötig,
  /// Filter + Sortierung im Client
  Stream<List<Mangel>> watchAlleOffenenMaengel() {
    return _firestore
        .collectionGroup('maengel')
        .snapshots()
        .map((snapshot) {
      final alle = snapshot.docs
          .map((doc) => Mangel.fromFirestore(doc))
          .where((m) =>
      m.status == MangelStatus.offen ||
          m.status == MangelStatus.inBearbeitung)
          .toList();
      alle.sort((a, b) => a.frist.compareTo(b.frist));
      return alle;
    });
  }

  /// Offene Mängel eines bestimmten Users — Filter im Client
  Stream<List<Mangel>> watchOffeneMaengelFuerUser(String uid) {
    return _firestore
        .collectionGroup('maengel')
        .snapshots()
        .map((snapshot) {
      final gefiltert = snapshot.docs
          .map((doc) => Mangel.fromFirestore(doc))
          .where((m) =>
      m.zustaendigUid == uid &&
          (m.status == MangelStatus.offen ||
              m.status == MangelStatus.inBearbeitung))
          .toList();
      gefiltert.sort((a, b) => a.frist.compareTo(b.frist));
      return gefiltert;
    });
  }
}