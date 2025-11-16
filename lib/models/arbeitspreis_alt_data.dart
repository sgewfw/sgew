// lib/models/arbeitspreis_alt_data.dart

import 'package:flutter/foundation.dart';

/// Monatsdaten für alte Preisformel (2024-2027)
class MonatsberechnungAlt {
  final DateTime monat;
  final double? gWert;      // Börse (Index G) - kann null sein!
  final double? giWert;     // Gewerbe (Index GI) - kann null sein!
  final double? zWert;      // Wärme (Index Z) - kann null sein!
  final double promille;   // Gewichtung aus VDI-Tabelle
  final double? kco2Wert;  // 🆕 CO₂-Preis in €/Tonne (ECarbiX)

  const MonatsberechnungAlt({
    required this.monat,
    required this.gWert,
    required this.giWert,
    required this.zWert,
    required this.promille,
    this.kco2Wert,
  });

  /// Gewichtete Monatsindizes für die Berechnung
  double get gGewichtet => (gWert ?? 0) * promille;
  double get giGewichtet => (giWert ?? 0) * promille;
  double get zGewichtet => (zWert ?? 0) * promille;

  /// Prüfe ob ein Wert vorhanden ist
  bool get hatG => gWert != null;
  bool get hatGI => giWert != null;
  bool get hatZ => zWert != null;
  bool get istVollstaendig => hatG && hatGI && hatZ;
}

/// Jahresberechnung alte Formel
/// Jahresberechnung alte Formel
class ArbeitspreisAlt {
  final int jahr;
  final double arbeitspreisOhneEmission; // AP ohne CO₂
  final double emissionspreis;           // EP (CO₂-Preis)
  final double arbeitspreisGesamt;       // AP + EP
  final List<MonatsberechnungAlt> monate;

  // Faktoren für die Formel (auf 4 Nachkommastellen gerundet)
  final double gFaktor;    // G/G₀
  final double giFaktor;   // GI/GI₀
  final double zFaktor;    // Z/Z₀

  // Summen der gewichteten Indizes (auf 1 Nachkommastelle gerundet)
  final double gSumme;
  final double giSumme;
  final double zSumme;

  // Änderungsfaktor (auf 4 Nachkommastellen gerundet)
  final double aenderungsfaktor;

  // 🆕 Vollständigkeits-Tracking
  final bool hatVollstaendigeDaten;
  final int vollstaendigeMonate;
  final int geschaetzteMonate;

  const ArbeitspreisAlt({
    required this.jahr,
    required this.arbeitspreisOhneEmission,
    required this.emissionspreis,
    required this.arbeitspreisGesamt,
    required this.monate,
    required this.gFaktor,
    required this.giFaktor,
    required this.zFaktor,
    required this.gSumme,
    required this.giSumme,
    required this.zSumme,
    required this.aenderungsfaktor,
    this.hatVollstaendigeDaten = true, // 🆕 Default: true
    this.vollstaendigeMonate = 12,     // 🆕 Default: 12
    this.geschaetzteMonate = 0,        // 🆕 Default: 0
  });
}


/// Konstanten für alte Formel (§5 & §6)
class ArbeitspreisAltKonstanten {
  // Basisarbeitspreis (Stand 2016)
  static const double ap0 = 4.9309; // ct/kWh

  // Basis-Indizes aus 2016 (Basis 2020=100)
  static const double g0 = 33.0;   // Börse Basis
  static const double gi0 = 93.6;  // Gewerbe Basis
  static const double z0 = 98.5;   // Wärme Basis

  // Gewichtungsfaktoren
  static const double gewichtG = 0.40;   // 40% Börse
  static const double gewichtGI = 0.35;  // 35% Gewerbe
  static const double gewichtZ = 0.25;   // 25% Wärme

  // Emissionspreis-Parameter (§6)
  static const double ep0 = 0.2926; // Basis-Emissionspreis 2020 (ct/kWh Wärme)
  static const double em = 170.28;  // Emissionsfaktor EU-Wärmebenchmark (g CO₂/kWh)
  static const double f = 0.0001;   // Umrechnungsfaktor EUR/MWh → ct/kWh

  // Abschmelzungsfaktoren Z (kostenlose Zuteilungen)
  static const Map<int, double> abschmelzungsfaktoren = {
    2021: 0.3000,
    2022: 0.2503,
    2023: 0.2437,
    2024: 0.2371,
    2025: 0.2305,
    2026: 0.2239, // Interpoliert
    2027: 0.2173, // Interpoliert
  };

  /// VDI-Promille-Gewichte für Monate (fix aus Tabelle 1*)
  static const Map<int, double> promilleGewichte = {
    1: 170.0,  // Januar
    2: 150.0,  // Februar
    3: 130.0,  // März
    4: 80.0,   // April
    5: 40.0,   // Mai
    6: 13.0,   // Juni
    7: 13.5,   // Juli
    8: 13.5,   // August
    9: 30.0,   // September
    10: 80.0,  // Oktober
    11: 120.0, // November
    12: 160.0, // Dezember
  };

  static const double promilleSumme = 1000.0;

  static double getPromille(int monat) {
    return promilleGewichte[monat] ?? 0.0;
  }

  static double getAbschmelzungsfaktor(int jahr) {
    return abschmelzungsfaktoren[jahr] ?? 0.2305; // Default
  }

  /// Runde auf 1 Nachkommastelle (für gewichtete Summen)
  static double runde1(double wert) {
    return (wert * 10).round() / 10;
  }

  /// Runde auf 4 Nachkommastellen (für Faktoren)
  static double runde4(double wert) {
    return (wert * 10000).round() / 10000;
  }

  /// Berechne Arbeitspreis aus Faktoren
  /// AP = AP₀ × (0,40 × G/G₀ + 0,35 × GI/GI₀ + 0,25 × Z/Z₀)
  static double berechneArbeitspreis({
    required double gFaktor,
    required double giFaktor,
    required double zFaktor,
  }) {
    // Erst Anteile berechnen, dann runden, dann summieren
    final anteilG = runde4(gewichtG * gFaktor);
    final anteilGI = runde4(gewichtGI * giFaktor);
    final anteilZ = runde4(gewichtZ * zFaktor);

    final aenderungsfaktor = anteilG + anteilGI + anteilZ;

    return ap0 * aenderungsfaktor;
  }

  /// Berechne Emissionspreis
  /// EP = (1 - Z) × Em × KCO2 × F
  static double berechneEmissionspreis({
    required int jahr,
    required double kco2Mittelwert, // ECarbiX Jahresmittel in €/Tonne
  }) {
    final z = getAbschmelzungsfaktor(jahr);
    return (1 - z) * em * kco2Mittelwert * f;
  }

  /// Index-Codes
  static const String gIndexCode = 'ERDGAS_BOERSE';
  static const String giIndexCode = 'ERDGAS_GEWERBE';
  static const String zIndexCode = 'WAERMEPREIS';
}

/// Übersicht für Tabelle
/// Übersicht für Tabelle
class JahresUebersichtAlt {
  final int jahr;
  final double arbeitspreisOhneEmission;
  final double emissionspreis;
  final double arbeitspreisGesamt;
  final double gSumme;
  final double giSumme;
  final double zSumme;
  final double gFaktor;
  final double giFaktor;
  final double zFaktor;
  final double aenderungsfaktor;
  final double? aenderungProzent;
  final double? aenderungAbsolut;
  final bool hatVollstaendigeDaten; // 🆕

  const JahresUebersichtAlt({
    required this.jahr,
    required this.arbeitspreisOhneEmission,
    required this.emissionspreis,
    required this.arbeitspreisGesamt,
    required this.gSumme,
    required this.giSumme,
    required this.zSumme,
    required this.gFaktor,
    required this.giFaktor,
    required this.zFaktor,
    required this.aenderungsfaktor,
    this.aenderungProzent,
    this.aenderungAbsolut,
    this.hatVollstaendigeDaten = true, // 🆕 Default: true
  });
}