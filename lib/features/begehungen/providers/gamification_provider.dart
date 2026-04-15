import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_providers.dart';

enum BadgeTyp {
  ersteBegehung,
  aufKurs,
  jahreszielErreicht,
  maengelChampion,
  schnellreakter,
  missionZeroHeld;

  String get label {
    switch (this) {
      case BadgeTyp.ersteBegehung:
        return 'Erste Begehung';
      case BadgeTyp.aufKurs:
        return 'Auf Kurs';
      case BadgeTyp.jahreszielErreicht:
        return 'Jahresziel erreicht';
      case BadgeTyp.maengelChampion:
        return 'Mängel-Champion';
      case BadgeTyp.schnellreakter:
        return 'Schnellreakter';
      case BadgeTyp.missionZeroHeld:
        return 'Mission Zero Held';
    }
  }

  String get beschreibung {
    switch (this) {
      case BadgeTyp.ersteBegehung:
        return '1. Begehung des Jahres durchgeführt';
      case BadgeTyp.aufKurs:
        return '6 von 12 Begehungen erreicht';
      case BadgeTyp.jahreszielErreicht:
        return '12 Begehungen abgeschlossen';
      case BadgeTyp.maengelChampion:
        return '10 Mängel behoben';
      case BadgeTyp.schnellreakter:
        return 'Kritischen Mangel binnen 24h behoben';
      case BadgeTyp.missionZeroHeld:
        return 'Ganzes Jahr ohne offene Mängel';
    }
  }

  IconData get icon {
    switch (this) {
      case BadgeTyp.ersteBegehung:
        return Icons.emoji_events;
      case BadgeTyp.aufKurs:
        return Icons.local_fire_department;
      case BadgeTyp.jahreszielErreicht:
        return Icons.star;
      case BadgeTyp.maengelChampion:
        return Icons.build;
      case BadgeTyp.schnellreakter:
        return Icons.bolt;
      case BadgeTyp.missionZeroHeld:
        return Icons.workspace_premium;
    }
  }
}

class BegehungBadge {
  final BadgeTyp typ;
  final bool earned;

  const BegehungBadge({required this.typ, required this.earned});
}

/// Berechnet Badges basierend auf User-Daten
List<BegehungBadge> berechneBadges(BegehungUser user) {
  return [
    BegehungBadge(
      typ: BadgeTyp.ersteBegehung,
      earned: user.begehungenDiesesJahr >= 1,
    ),
    BegehungBadge(
      typ: BadgeTyp.aufKurs,
      earned: user.begehungenDiesesJahr >= 6,
    ),
    BegehungBadge(
      typ: BadgeTyp.jahreszielErreicht,
      earned: user.begehungenDiesesJahr >= 12,
    ),
    BegehungBadge(
      typ: BadgeTyp.maengelChampion,
      earned: user.behobeneMaengel >= 10,
    ),
    // Schnellreakter und MissionZeroHeld brauchen zusätzliche Daten
    // die nicht im User-Model gespeichert sind. Werden vorerst
    // über einfache Heuristik ausgewertet.
    BegehungBadge(
      typ: BadgeTyp.schnellreakter,
      earned: false, // TODO: Cloud Function setzt Flag im User-Doc
    ),
    BegehungBadge(
      typ: BadgeTyp.missionZeroHeld,
      earned: user.begehungenDiesesJahr >= 12 && user.offeneMaengel == 0,
    ),
  ];
}

/// Provider für die Badges des aktuellen Users
final userBadgesProvider = Provider<List<BegehungBadge>>((ref) {
  final userAsync = ref.watch(currentBegehungUserProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return [];
  return berechneBadges(user);
});

/// Anzahl der verdienten Badges
final earnedBadgesCountProvider = Provider<int>((ref) {
  return ref.watch(userBadgesProvider).where((b) => b.earned).length;
});
