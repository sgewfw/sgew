// lib/models/arbeitspreis_data.dart

import 'package:flutter/foundation.dart';

/// Arbeitspreis für ein Quartal (konstant für 3 Monate)
class QuartalsPreis {
  final DateTime quartal; // Erstes Datum des Quartals
  final int quartalNummer; // 1, 2, 3, 4
  final int jahr;
  final double preis; // ct/kWh - konstant für das ganze Quartal
  final QuartalsBerechnungsdaten berechnungsdaten;

  const QuartalsPreis({
    required this.quartal,
    required this.quartalNummer,
    required this.jahr,
    required this.preis,
    required this.berechnungsdaten,
  });

  String get bezeichnung => 'Q$quartalNummer $jahr';
}

/// Berechnungsdaten für ein Quartal (n-4 bis n-2)
class QuartalsBerechnungsdaten {
  final String typ; // 'gas' oder 'strom'

  // Die 3 Monate die verwendet werden (n-4, n-3, n-2)
  final DateTime monat1;
  final DateTime monat2;
  final DateTime monat3;
  final String quartalBezeichnung;

  // Kostenelement (K)
  final double kWert1;
  final double kWert2;
  final double kWert3;
  final double kMittelwert;

  // Marktelement (M)
  final double mWert1;
  final double mWert2;
  final double mWert3;
  final double mMittelwert;

  // Basis-Werte
  final double kBasis;
  final double mBasis;

  const QuartalsBerechnungsdaten({
    required this.typ,
    required this.monat1,
    required this.monat2,
    required this.monat3,
    required this.quartalBezeichnung,
    required this.kWert1,
    required this.kWert2,
    required this.kWert3,
    required this.kMittelwert,
    required this.mWert1,
    required this.mWert2,
    required this.mWert3,
    required this.mMittelwert,
    required this.kBasis,
    required this.mBasis,
  });

  /// Prüfe ob ein Monat einer der Berechnungsmonate ist
  bool istBerechnungsmonat(DateTime monat) {
    return _vergleicheMonate(monat, monat1) ||
        _vergleicheMonate(monat, monat2) ||
        _vergleicheMonate(monat, monat3);
  }

  bool _vergleicheMonate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

/// Konstanten aus § 8
class ArbeitspreisKonstanten {
  // Startarbeitspreise (Q3 2025)
  static const double ap0Gas = 12.87; // ct/kWh
  static const double ap0Strom = 8.52; // ct/kWh

  // Basis-Indizes (Mittelwert März-Mai 2025)
  static const double kGasBasis = 186.2;
  static const double kStromBasis = 122.8;
  static const double mGasBasis = 166.3;
  static const double mStromBasis = 127.6;

  // Gewichtung Kostenelement x
  static const double x = 0.5;

  // Basisquartal
  static const int basisQuartal = 3;
  static const int basisJahr = 2025;

  // Index-Codes
  static const String codeKGas = 'GP19-352222';
  static const String codeKStrom = 'GP19-351113';
  static const String codeMGas = 'CC13-77';
  static const String codeMStrom = 'GP19-351112';

  /// Berechne Quartalsnummer aus Monat
  static int getQuartalNummer(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  /// Erstes Datum des Quartals
  static DateTime getQuartalStart(DateTime date) {
    final quartal = getQuartalNummer(date);
    final monat = (quartal - 1) * 3 + 1;
    return DateTime(date.year, monat, 1);
  }

  /// Berechne n-4 bis n-2 Monate für ein Quartal
  static List<DateTime> getBerechnungsmonate(DateTime quartalStart) {
    // Für Q3 (Juli): März, April, Mai (n-4, n-3, n-2)
    final erstesQuartalsMonat = quartalStart;

    final monat1 = DateTime(
      erstesQuartalsMonat.year,
      erstesQuartalsMonat.month - 4,
      1,
    );
    final monat2 = DateTime(
      erstesQuartalsMonat.year,
      erstesQuartalsMonat.month - 3,
      1,
    );
    final monat3 = DateTime(
      erstesQuartalsMonat.year,
      erstesQuartalsMonat.month - 2,
      1,
    );

    return [monat1, monat2, monat3];
  }
}

/// Quartals-Übersicht für Tabelle
class QuartalsUebersicht {
  final DateTime quartal;
  final int quartalNummer;
  final int jahr;
  final double kMittelwert;
  final double mMittelwert;
  final double preis;

  const QuartalsUebersicht({
    required this.quartal,
    required this.quartalNummer,
    required this.jahr,
    required this.kMittelwert,
    required this.mMittelwert,
    required this.preis,
  });

  String get bezeichnung => 'Q$quartalNummer $jahr';
}