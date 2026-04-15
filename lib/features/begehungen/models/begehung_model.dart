import 'package:cloud_firestore/cloud_firestore.dart';

import 'begehung_enums.dart';

class Begehung {
  final String id;
  final BegehungTyp typ;
  final BegehungStatus status;
  final DateTime datum;
  final String ort;
  final String standort;
  final String standortBezeichnung;
  final String standortStrasse;
  final String standortPlz;
  final String abteilung;
  final String erstellerUid;
  final String erstellerName;
  final String erstellerEmail;
  final String berichtsText;
  final String berichtsKategorie;
  final int anzahlMaengel;
  final int offeneMaengel;
  final int behobeneMaengel;
  final String smaponeReportId;
  final String smaponeVersion;
  final List<String> teilnehmer;
  final DateTime createdAt;

  Begehung({
    required this.id,
    required this.typ,
    this.status = BegehungStatus.offen,
    required this.datum,
    required this.ort,
    required this.standort,
    this.standortBezeichnung = '',
    this.standortStrasse = '',
    this.standortPlz = '',
    required this.abteilung,
    required this.erstellerUid,
    required this.erstellerName,
    required this.erstellerEmail,
    required this.berichtsText,
    this.berichtsKategorie = '',
    required this.anzahlMaengel,
    required this.offeneMaengel,
    required this.behobeneMaengel,
    required this.smaponeReportId,
    this.smaponeVersion = '',
    this.teilnehmer = const [],
    required this.createdAt,
  });

  factory Begehung.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Begehung(
      id: doc.id,
      typ: BegehungTyp.fromString(data['typ'] ?? 'Standardbegehung'),
      status: BegehungStatus.fromString(data['status'] as String?),
      datum: (data['datum'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ort: data['ort'] ?? '',
      standort: data['standort'] ?? '',
      standortBezeichnung: data['standort_bezeichnung'] ?? '',
      standortStrasse: data['standort_strasse'] ?? '',
      standortPlz: data['standort_plz'] ?? '',
      abteilung: data['abteilung'] ?? '',
      erstellerUid: data['ersteller_uid'] ?? '',
      erstellerName: data['ersteller_name'] ?? '',
      erstellerEmail: data['ersteller_email'] ?? '',
      berichtsText: data['berichtsText'] ?? '',
      berichtsKategorie: data['berichtsKategorie'] ?? '',
      anzahlMaengel: (data['anzahlMaengel'] as num?)?.toInt() ?? 0,
      offeneMaengel: (data['offeneMaengel'] as num?)?.toInt() ?? 0,
      behobeneMaengel: (data['behobeneMaengel'] as num?)?.toInt() ?? 0,
      smaponeReportId: data['smapone_report_id'] ?? '',
      smaponeVersion: data['smapone_version'] ?? '',
      teilnehmer: (data['teilnehmer'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      createdAt:
      (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'typ': typ.label,
      'status': status.firestoreValue,
      'datum': Timestamp.fromDate(datum),
      'ort': ort,
      'standort': standort,
      'standort_bezeichnung': standortBezeichnung,
      'standort_strasse': standortStrasse,
      'standort_plz': standortPlz,
      'abteilung': abteilung,
      'ersteller_uid': erstellerUid,
      'ersteller_name': erstellerName,
      'ersteller_email': erstellerEmail,
      'berichtsText': berichtsText,
      'berichtsKategorie': berichtsKategorie,
      'anzahlMaengel': anzahlMaengel,
      'offeneMaengel': offeneMaengel,
      'behobeneMaengel': behobeneMaengel,
      'smapone_report_id': smaponeReportId,
      'smapone_version': smaponeVersion,
      'teilnehmer': teilnehmer,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Begehung copyWith({
    String? id,
    BegehungTyp? typ,
    BegehungStatus? status,
    DateTime? datum,
    String? ort,
    String? standort,
    String? standortBezeichnung,
    String? standortStrasse,
    String? standortPlz,
    String? abteilung,
    String? erstellerUid,
    String? erstellerName,
    String? erstellerEmail,
    String? berichtsText,
    String? berichtsKategorie,
    int? anzahlMaengel,
    int? offeneMaengel,
    int? behobeneMaengel,
    String? smaponeReportId,
    String? smaponeVersion,
    List<String>? teilnehmer,
    DateTime? createdAt,
  }) {
    return Begehung(
      id: id ?? this.id,
      typ: typ ?? this.typ,
      status: status ?? this.status,
      datum: datum ?? this.datum,
      ort: ort ?? this.ort,
      standort: standort ?? this.standort,
      standortBezeichnung: standortBezeichnung ?? this.standortBezeichnung,
      standortStrasse: standortStrasse ?? this.standortStrasse,
      standortPlz: standortPlz ?? this.standortPlz,
      abteilung: abteilung ?? this.abteilung,
      erstellerUid: erstellerUid ?? this.erstellerUid,
      erstellerName: erstellerName ?? this.erstellerName,
      erstellerEmail: erstellerEmail ?? this.erstellerEmail,
      berichtsText: berichtsText ?? this.berichtsText,
      berichtsKategorie: berichtsKategorie ?? this.berichtsKategorie,
      anzahlMaengel: anzahlMaengel ?? this.anzahlMaengel,
      offeneMaengel: offeneMaengel ?? this.offeneMaengel,
      behobeneMaengel: behobeneMaengel ?? this.behobeneMaengel,
      smaponeReportId: smaponeReportId ?? this.smaponeReportId,
      smaponeVersion: smaponeVersion ?? this.smaponeVersion,
      teilnehmer: teilnehmer ?? this.teilnehmer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get standortAdresse {
    final parts = <String>[];
    if (standortStrasse.isNotEmpty) parts.add(standortStrasse);
    if (standortPlz.isNotEmpty || ort.isNotEmpty) {
      parts.add('$standortPlz $ort'.trim());
    }
    return parts.join(', ');
  }

  bool get alleMaengelBehoben => anzahlMaengel > 0 && offeneMaengel == 0;
  bool get hatTeilnehmer => teilnehmer.isNotEmpty;

  @override
  String toString() {
    return 'Begehung(id: $id, typ: ${typ.label}, status: ${status.label}, '
        'ort: $ort, abteilung: $abteilung, teilnehmer: ${teilnehmer.length})';
  }
}