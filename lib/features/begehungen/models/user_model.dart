import 'package:cloud_firestore/cloud_firestore.dart';

import 'begehung_enums.dart';

class BegehungUser {
  final String uid;
  final String email;
  final String name;
  final UserRolle rolle;
  final UserStatus status;
  final String abteilung;
  final String standort;
  final int begehungenDiesesJahr;
  final int offeneMaengel;
  final int behobeneMaengel;
  final DateTime createdAt;
  final bool darkMode;

  BegehungUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.rolle,
    this.status = UserStatus.aktiv,
    required this.abteilung,
    required this.standort,
    required this.begehungenDiesesJahr,
    required this.offeneMaengel,
    required this.behobeneMaengel,
    required this.createdAt,
    this.darkMode = true,
  });

  factory BegehungUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BegehungUser(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      rolle: UserRolle.fromString(data['rolle'] ?? 'Mitarbeiter'),
      status: UserStatus.fromString(data['status'] as String?),
      abteilung: data['abteilung'] ?? '',
      standort: data['standort'] ?? '',
      begehungenDiesesJahr:
      (data['begehungenDiesesJahr'] as num?)?.toInt() ?? 0,
      offeneMaengel: (data['offeneMaengel'] as num?)?.toInt() ?? 0,
      behobeneMaengel: (data['behobeneMaengel'] as num?)?.toInt() ?? 0,
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      darkMode: data['darkMode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'rolle': rolle.label,
      'status': status.firestoreValue,
      'abteilung': abteilung,
      'standort': standort,
      'begehungenDiesesJahr': begehungenDiesesJahr,
      'offeneMaengel': offeneMaengel,
      'behobeneMaengel': behobeneMaengel,
      'createdAt': Timestamp.fromDate(createdAt),
      'darkMode': darkMode,
    };
  }

  BegehungUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRolle? rolle,
    UserStatus? status,
    String? abteilung,
    String? standort,
    int? begehungenDiesesJahr,
    int? offeneMaengel,
    int? behobeneMaengel,
    DateTime? createdAt,
    bool? darkMode,
  }) {
    return BegehungUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      rolle: rolle ?? this.rolle,
      status: status ?? this.status,
      abteilung: abteilung ?? this.abteilung,
      standort: standort ?? this.standort,
      begehungenDiesesJahr: begehungenDiesesJahr ?? this.begehungenDiesesJahr,
      offeneMaengel: offeneMaengel ?? this.offeneMaengel,
      behobeneMaengel: behobeneMaengel ?? this.behobeneMaengel,
      createdAt: createdAt ?? this.createdAt,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  bool get istFuehrungskraft => rolle.istFuehrungskraft;
  bool get istAktiv => status.istAktiv;

  double get fortschrittProzent {
    const jahresZiel = 12;
    if (jahresZiel == 0) return 0;
    return (begehungenDiesesJahr / jahresZiel).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'BegehungUser(uid: $uid, name: $name, rolle: ${rolle.label}, '
        'status: ${status.label}, abteilung: $abteilung)';
  }
}