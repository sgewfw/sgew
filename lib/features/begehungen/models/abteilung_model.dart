import 'package:cloud_firestore/cloud_firestore.dart';

import 'begehung_enums.dart';

class Abteilung {
  final String id;
  final String name;
  final String kuerzel;
  final String standort;
  final String beLevel;
  final int jahresZiel;
  final int begehungenDiesesJahr;
  final int offeneMaengel;

  Abteilung({
    required this.id,
    required this.name,
    required this.kuerzel,
    required this.standort,
    required this.beLevel,
    required this.jahresZiel,
    required this.begehungenDiesesJahr,
    required this.offeneMaengel,
  });

  factory Abteilung.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    return Abteilung(
      id: doc.id,
      name: name,
      kuerzel: data['kuerzel'] ?? name.substring(0, name.length >= 4 ? 4 : name.length).toUpperCase(),
      standort: data['standort'] ?? '',
      beLevel: data['beLevel'] ?? 'BE4',
      jahresZiel: (data['jahresZiel'] as num?)?.toInt() ?? 12,
      begehungenDiesesJahr: (data['begehungenDiesesJahr'] as num?)?.toInt() ?? 0,
      offeneMaengel: (data['offeneMaengel'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'kuerzel': kuerzel,
      'standort': standort,
      'beLevel': beLevel,
      'jahresZiel': jahresZiel,
      'begehungenDiesesJahr': begehungenDiesesJahr,
      'offeneMaengel': offeneMaengel,
    };
  }

  Abteilung copyWith({
    String? id,
    String? name,
    String? kuerzel,
    String? standort,
    String? beLevel,
    int? jahresZiel,
    int? begehungenDiesesJahr,
    int? offeneMaengel,
  }) {
    return Abteilung(
      id: id ?? this.id,
      name: name ?? this.name,
      kuerzel: kuerzel ?? this.kuerzel,
      standort: standort ?? this.standort,
      beLevel: beLevel ?? this.beLevel,
      jahresZiel: jahresZiel ?? this.jahresZiel,
      begehungenDiesesJahr: begehungenDiesesJahr ?? this.begehungenDiesesJahr,
      offeneMaengel: offeneMaengel ?? this.offeneMaengel,
    );
  }

  double get fortschrittProzent {
    if (jahresZiel == 0) return 0;
    return (begehungenDiesesJahr / jahresZiel).clamp(0.0, 1.0);
  }

  bool get hatOffeneMaengel => offeneMaengel > 0;

  bool get jahresZielErreicht => begehungenDiesesJahr >= jahresZiel;

  UserRolle get userRolle => UserRolle.fromString(beLevel);

  /// Seed-Daten für die initiale Abteilungsstruktur
  static List<Map<String, dynamic>> get seedData => [
    {'name': 'Fernwärme', 'kuerzel': 'RSGT-M-F', 'standort': 'Mitte/Nord', 'beLevel': 'BE4', 'jahresZiel': 12},
    {'name': 'Quartiere', 'kuerzel': 'RSGT-M-Q', 'standort': 'Mitte/Nord', 'beLevel': 'BE4', 'jahresZiel': 12},
    {'name': 'Dekarbonisierung', 'kuerzel': 'RSGT-M-B', 'standort': 'Mitte/Nord', 'beLevel': 'BE4', 'jahresZiel': 12},
    {'name': 'EE Erzeugung', 'kuerzel': 'RSGT-E', 'standort': 'Mitte/Nord', 'beLevel': 'BE3', 'jahresZiel': 12},
    {'name': 'Erzeugung Mitte/Nord', 'kuerzel': 'RSGT-M', 'standort': 'Mitte/Nord', 'beLevel': 'BE3', 'jahresZiel': 12},
    {'name': 'Betrieb Süd', 'kuerzel': 'RSGT-S-B', 'standort': 'Süd', 'beLevel': 'BE4', 'jahresZiel': 12},
    {'name': 'Erzeugung Süd', 'kuerzel': 'RSGT-S', 'standort': 'Süd', 'beLevel': 'BE3', 'jahresZiel': 12},
    {'name': 'Geschäftsführung', 'kuerzel': 'RSGT', 'standort': 'Konzern', 'beLevel': 'BE2', 'jahresZiel': 0},
  ];

  @override
  String toString() {
    return 'Abteilung(id: $id, kuerzel: $kuerzel, name: $name, standort: $standort, $begehungenDiesesJahr/$jahresZiel)';
  }
}