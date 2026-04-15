import 'package:cloud_firestore/cloud_firestore.dart';

import 'begehung_enums.dart';

/// Einzelne Notiz zu einem Mangel (Timeline-Eintrag)
class MangelNotiz {
  final String autorUid;
  final String autorName;
  final String text;
  final DateTime erstelltAm;
  /// Optionaler Typ: 'notiz', 'status_aenderung', 'behoben'
  final String typ;

  MangelNotiz({
    required this.autorUid,
    required this.autorName,
    required this.text,
    required this.erstelltAm,
    this.typ = 'notiz',
  });

  factory MangelNotiz.fromMap(Map<String, dynamic> data) {
    return MangelNotiz(
      autorUid: data['autorUid'] as String? ?? '',
      autorName: data['autorName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      erstelltAm: data['erstelltAm'] is Timestamp
          ? (data['erstelltAm'] as Timestamp).toDate()
          : DateTime.now(),
      typ: data['typ'] as String? ?? 'notiz',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autorUid': autorUid,
      'autorName': autorName,
      'text': text,
      'erstelltAm': Timestamp.fromDate(erstelltAm),
      'typ': typ,
    };
  }
}

class Mangel {
  final String id;
  final String begehungId;
  final String beschreibung;
  final MangelKategorie kategorie;
  final MangelSchweregrad schweregrad;
  final String? fotoUrl;
  final String? fotoUrl2;
  final String? ortNotiz;
  final DateTime frist;
  final MangelStatus status;
  final String zustaendigUid;
  final String zustaendigName;
  final String zustaendigEmail;
  final String? behobenVonUid;
  final DateTime? behobenAm;
  final String? behobenKommentar;
  /// Notizen-Timeline: chronologische Liste aller Einträge
  final List<MangelNotiz> notizen;
  final bool erinnerungGesendet;
  final DateTime createdAt;

  Mangel({
    required this.id,
    required this.begehungId,
    required this.beschreibung,
    required this.kategorie,
    required this.schweregrad,
    this.fotoUrl,
    this.fotoUrl2,
    this.ortNotiz,
    required this.frist,
    required this.status,
    required this.zustaendigUid,
    required this.zustaendigName,
    this.zustaendigEmail = '',
    this.behobenVonUid,
    this.behobenAm,
    this.behobenKommentar,
    this.notizen = const [],
    required this.erinnerungGesendet,
    required this.createdAt,
  });

  factory Mangel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mangel(
      id: doc.id,
      begehungId: data['begehungId'] ?? '',
      beschreibung: data['beschreibung'] ?? '',
      kategorie: MangelKategorie.fromString(data['kategorie'] ?? 'sonstiges'),
      schweregrad:
      MangelSchweregrad.fromString(data['schweregrad'] ?? 'mittel'),
      fotoUrl: data['fotoUrl'],
      fotoUrl2: data['fotoUrl2'],
      ortNotiz: data['ortNotiz'],
      frist: (data['frist'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MangelStatus.fromString(data['status'] ?? 'offen'),
      zustaendigUid: data['zustaendig_uid'] ?? '',
      zustaendigName: data['zustaendig_name'] ?? '',
      zustaendigEmail: data['zustaendig_email'] ?? '',
      behobenVonUid: data['behoben_von_uid'],
      behobenAm: (data['behoben_am'] as Timestamp?)?.toDate(),
      behobenKommentar: data['behoben_kommentar'] as String?,
      notizen: (data['notizen'] as List<dynamic>?)
          ?.map((e) => MangelNotiz.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      erinnerungGesendet: data['erinnerung_gesendet'] ?? false,
      createdAt:
      (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'begehungId': begehungId,
      'beschreibung': beschreibung,
      'kategorie': kategorie.name,
      'schweregrad': schweregrad.name,
      'fotoUrl': fotoUrl,
      'fotoUrl2': fotoUrl2,
      'ortNotiz': ortNotiz,
      'frist': Timestamp.fromDate(frist),
      'status': status.firestoreValue,
      'zustaendig_uid': zustaendigUid,
      'zustaendig_name': zustaendigName,
      'zustaendig_email': zustaendigEmail,
      'behoben_von_uid': behobenVonUid,
      'behoben_am': behobenAm != null ? Timestamp.fromDate(behobenAm!) : null,
      'behoben_kommentar': behobenKommentar,
      'notizen': notizen.map((n) => n.toMap()).toList(),
      'erinnerung_gesendet': erinnerungGesendet,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Mangel copyWith({
    String? id,
    String? begehungId,
    String? beschreibung,
    MangelKategorie? kategorie,
    MangelSchweregrad? schweregrad,
    String? fotoUrl,
    String? fotoUrl2,
    String? ortNotiz,
    DateTime? frist,
    MangelStatus? status,
    String? zustaendigUid,
    String? zustaendigName,
    String? zustaendigEmail,
    String? behobenVonUid,
    DateTime? behobenAm,
    String? behobenKommentar,
    List<MangelNotiz>? notizen,
    bool? erinnerungGesendet,
    DateTime? createdAt,
  }) {
    return Mangel(
      id: id ?? this.id,
      begehungId: begehungId ?? this.begehungId,
      beschreibung: beschreibung ?? this.beschreibung,
      kategorie: kategorie ?? this.kategorie,
      schweregrad: schweregrad ?? this.schweregrad,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoUrl2: fotoUrl2 ?? this.fotoUrl2,
      ortNotiz: ortNotiz ?? this.ortNotiz,
      frist: frist ?? this.frist,
      status: status ?? this.status,
      zustaendigUid: zustaendigUid ?? this.zustaendigUid,
      zustaendigName: zustaendigName ?? this.zustaendigName,
      zustaendigEmail: zustaendigEmail ?? this.zustaendigEmail,
      behobenVonUid: behobenVonUid ?? this.behobenVonUid,
      behobenAm: behobenAm ?? this.behobenAm,
      behobenKommentar: behobenKommentar ?? this.behobenKommentar,
      notizen: notizen ?? this.notizen,
      erinnerungGesendet: erinnerungGesendet ?? this.erinnerungGesendet,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get istUeberfaellig =>
      status != MangelStatus.behoben && DateTime.now().isAfter(frist);

  bool get fristLaeuftBaldAb {
    if (status == MangelStatus.behoben) return false;
    final diff = frist.difference(DateTime.now());
    return diff.inHours > 0 && diff.inHours <= 48;
  }

  bool get hatZweitesFoto => fotoUrl2 != null && fotoUrl2!.isNotEmpty;
  bool get hatBehobenKommentar =>
      behobenKommentar != null && behobenKommentar!.isNotEmpty;
  bool get hatNotizen => notizen.isNotEmpty;
  int get anzahlNotizen => notizen.length;
  Duration get restzeit => frist.difference(DateTime.now());

  @override
  String toString() {
    return 'Mangel(id: $id, kategorie: ${kategorie.label}, '
        'schweregrad: ${schweregrad.label}, status: ${status.label}, '
        'notizen: ${notizen.length})';
  }
}