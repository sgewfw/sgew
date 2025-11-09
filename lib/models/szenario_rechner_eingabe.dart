// lib/models/szenario_rechner_eingabe.dart

import 'package:flutter/foundation.dart';

/// Benutzereingaben für den Szenario-Rechner
class SzenarioRechnerEingabe {
  // Basisdaten (immer erforderlich)
  final double waermebedarf; // kWh/a

  // Wärmepumpen-spezifisch
  final double? jahresarbeitszahl; // JAZ (2.5 - 4.0)
  final double? stromarbeitspreisCtKWh; // ct/kWh
  final double? stromGrundpreisEuroMonat; // €/Monat

  // Wärmenetz-spezifisch
  final double? anteilWaermeAusStrom; // 0.0 - 1.0 (z.B. 0.30 = 30%)

  // Investitionskosten
  final bool eigenInvestitionskostenNutzen;
  final double? investitionskostenAnpassungProzent; // -20 bis +20

  // Förderung
  final bool foerderungBeruecksichtigen;

  // Berechnete Werte (aus waermebedarf)
  final double beheizteFlaeche; // Wird aus Stammdaten übernommen
  final double spezHeizenergiebedarf; // Wird aus Stammdaten übernommen

  const SzenarioRechnerEingabe({
    required this.waermebedarf,
    this.jahresarbeitszahl,
    this.stromarbeitspreisCtKWh,
    this.stromGrundpreisEuroMonat,
    this.anteilWaermeAusStrom,
    this.eigenInvestitionskostenNutzen = false,
    this.investitionskostenAnpassungProzent,
    this.foerderungBeruecksichtigen = true,
    required this.beheizteFlaeche,
    required this.spezHeizenergiebedarf,
  });

  /// Standard-Eingabe aus Stammdaten erstellen
  factory SzenarioRechnerEingabe.vonStammdaten({
    required double waermebedarf,
    required double beheizteFlaeche,
    required double spezHeizenergiebedarf,
    double? defaultJAZ,
    double? defaultStrompreis,
    double? defaultStromGrundpreis,
    double? defaultAnteilWaermeAusStrom,
  }) {
    return SzenarioRechnerEingabe(
      waermebedarf: waermebedarf,
      beheizteFlaeche: beheizteFlaeche,
      spezHeizenergiebedarf: spezHeizenergiebedarf,
      jahresarbeitszahl: defaultJAZ,
      stromarbeitspreisCtKWh: defaultStrompreis,
      stromGrundpreisEuroMonat: defaultStromGrundpreis,
      anteilWaermeAusStrom: defaultAnteilWaermeAusStrom,
      eigenInvestitionskostenNutzen: false,
      investitionskostenAnpassungProzent: 0,
      foerderungBeruecksichtigen: true,
    );
  }

  SzenarioRechnerEingabe copyWith({
    double? waermebedarf,
    double? jahresarbeitszahl,
    double? stromarbeitspreisCtKWh,
    double? stromGrundpreisEuroMonat,
    double? anteilWaermeAusStrom,
    bool? eigenInvestitionskostenNutzen,
    double? investitionskostenAnpassungProzent,
    bool? foerderungBeruecksichtigen,
    double? beheizteFlaeche,
    double? spezHeizenergiebedarf,
  }) {
    return SzenarioRechnerEingabe(
      waermebedarf: waermebedarf ?? this.waermebedarf,
      jahresarbeitszahl: jahresarbeitszahl ?? this.jahresarbeitszahl,
      stromarbeitspreisCtKWh: stromarbeitspreisCtKWh ?? this.stromarbeitspreisCtKWh,
      stromGrundpreisEuroMonat: stromGrundpreisEuroMonat ?? this.stromGrundpreisEuroMonat,
      anteilWaermeAusStrom: anteilWaermeAusStrom ?? this.anteilWaermeAusStrom,
      eigenInvestitionskostenNutzen: eigenInvestitionskostenNutzen ?? this.eigenInvestitionskostenNutzen,
      investitionskostenAnpassungProzent: investitionskostenAnpassungProzent ?? this.investitionskostenAnpassungProzent,
      foerderungBeruecksichtigen: foerderungBeruecksichtigen ?? this.foerderungBeruecksichtigen,
      beheizteFlaeche: beheizteFlaeche ?? this.beheizteFlaeche,
      spezHeizenergiebedarf: spezHeizenergiebedarf ?? this.spezHeizenergiebedarf,
    );
  }

  /// Validierung der Eingaben
  List<String> validiere() {
    final fehler = <String>[];

    // Wärmebedarf
    if (waermebedarf < 5000 || waermebedarf > 20000) {
      fehler.add('Wärmebedarf muss zwischen 5.000 und 20.000 kWh/a liegen');
    }

    // JAZ (falls gesetzt)
    if (jahresarbeitszahl != null) {
      if (jahresarbeitszahl! < 2.5 || jahresarbeitszahl! > 4.0) {
        fehler.add('Jahresarbeitszahl muss zwischen 2,5 und 4,0 liegen');
      }
    }

    // Strompreis (falls gesetzt)
    if (stromarbeitspreisCtKWh != null) {
      if (stromarbeitspreisCtKWh! < 10 || stromarbeitspreisCtKWh! > 50) {
        fehler.add('Stromarbeitspreis muss zwischen 10 und 50 ct/kWh liegen');
      }
    }

    // Strom-Grundpreis (falls gesetzt)
    if (stromGrundpreisEuroMonat != null) {
      if (stromGrundpreisEuroMonat! < 0 || stromGrundpreisEuroMonat! > 50) {
        fehler.add('Stromgrundpreis muss zwischen 0 und 50 €/Monat liegen');
      }
    }

    // Anteil Wärme aus Strom (falls gesetzt)
    if (anteilWaermeAusStrom != null) {
      if (anteilWaermeAusStrom! < 0 || anteilWaermeAusStrom! > 1) {
        fehler.add('Anteil Wärme aus Strom muss zwischen 0% und 100% liegen');
      }
    }

    // Investitionskosten-Anpassung (falls gesetzt)
    if (investitionskostenAnpassungProzent != null) {
      if (investitionskostenAnpassungProzent! < -20 ||
          investitionskostenAnpassungProzent! > 20) {
        fehler.add('Investitionskosten-Anpassung muss zwischen -20% und +20% liegen');
      }
    }

    return fehler;
  }

  /// Ist gültig?
  bool get istGueltig => validiere().isEmpty;
}

/// Einstellungen für Slider/Input-Bereiche
class SzenarioRechnerGrenzen {
  // Wärmebedarf
  static const double waermebedarfMin = 5000; // kWh/a
  static const double waermebedarfMax = 20000; // kWh/a
  static const double waermebedarfDefault = 11500; // kWh/a
  static const double waermebedarfSchritt = 500; // kWh/a

  // JAZ
  static const double jazMin = 2.5;
  static const double jazMax = 4.0;
  static const double jazDefault = 3.0;
  static const double jazSchritt = 0.1;

  // Strompreis
  static const double strompreisMin = 10; // ct/kWh
  static const double strompreisMax = 50; // ct/kWh
  static const double strompreisDefault = 16.52; // ct/kWh
  static const double strompreisSchritt = 0.5; // ct/kWh

  // Strom-Grundpreis
  static const double stromGrundpreisMin = 0; // €/Monat
  static const double stromGrundpreisMax = 50; // €/Monat
  static const double stromGrundpreisDefault = 9.0; // €/Monat
  static const double stromGrundpreisSchritt = 1.0; // €/Monat

  // Anteil Wärme aus Strom
  static const double anteilStromMin = 0.0; // 0%
  static const double anteilStromMax = 1.0; // 100%
  static const double anteilStromDefault = 0.30; // 30%
  static const double anteilStromSchritt = 0.01; // 1%

  // Investitionskosten-Anpassung
  static const double investAnpassungMin = -20; // %
  static const double investAnpassungMax = 20; // %
  static const double investAnpassungDefault = 0; // %
  static const double investAnpassungSchritt = 1; // %
}

/// Konfiguration für einen Eingabe-Parameter
class EingabeParameter {
  final String id;
  final String bezeichnung;
  final String beschreibung;
  final String einheit;
  final double minWert;
  final double maxWert;
  final double defaultWert;
  final double schrittweite;
  final int nachkommastellen;
  final bool istProzent;
  final ParameterTyp typ;

  // Für welche Szenarien relevant?
  final List<String> relevantFuerSzenarien;

  const EingabeParameter({
    required this.id,
    required this.bezeichnung,
    required this.beschreibung,
    required this.einheit,
    required this.minWert,
    required this.maxWert,
    required this.defaultWert,
    required this.schrittweite,
    required this.nachkommastellen,
    this.istProzent = false,
    required this.typ,
    required this.relevantFuerSzenarien,
  });

  /// Vordefinierte Parameter
  static final List<EingabeParameter> alleParameter = [
    // Wärmebedarf (alle Szenarien)
    EingabeParameter(
      id: 'waermebedarf',
      bezeichnung: 'Wärmebedarf',
      beschreibung: 'Jährlicher Wärmebedarf des Gebäudes',
      einheit: 'kWh/a',
      minWert: SzenarioRechnerGrenzen.waermebedarfMin,
      maxWert: SzenarioRechnerGrenzen.waermebedarfMax,
      defaultWert: SzenarioRechnerGrenzen.waermebedarfDefault,
      schrittweite: SzenarioRechnerGrenzen.waermebedarfSchritt,
      nachkommastellen: 0,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['alle'],
    ),

    // JAZ (nur Wärmepumpe)
    EingabeParameter(
      id: 'jahresarbeitszahl',
      bezeichnung: 'Jahresarbeitszahl (JAZ)',
      beschreibung: 'Verhältnis zwischen abgegebener Wärmeenergie und aufgenommener elektrischer Energie',
      einheit: '',
      minWert: SzenarioRechnerGrenzen.jazMin,
      maxWert: SzenarioRechnerGrenzen.jazMax,
      defaultWert: SzenarioRechnerGrenzen.jazDefault,
      schrittweite: SzenarioRechnerGrenzen.jazSchritt,
      nachkommastellen: 1,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['waermepumpe'],
    ),

    // Strompreis (Wärmepumpe + Wärmenetz)
    EingabeParameter(
      id: 'stromarbeitspreis',
      bezeichnung: 'Stromarbeitspreis',
      beschreibung: 'Arbeitspreis für Strom (netto)',
      einheit: 'ct/kWh',
      minWert: SzenarioRechnerGrenzen.strompreisMin,
      maxWert: SzenarioRechnerGrenzen.strompreisMax,
      defaultWert: SzenarioRechnerGrenzen.strompreisDefault,
      schrittweite: SzenarioRechnerGrenzen.strompreisSchritt,
      nachkommastellen: 2,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['waermepumpe', 'waermenetzKunde', 'waermenetzSuewag'],
    ),

    // Strom-Grundpreis (nur Wärmepumpe)
    EingabeParameter(
      id: 'stromgrundpreis',
      bezeichnung: 'Strom-Grundpreis',
      beschreibung: 'Monatlicher Grundpreis für Stromtarif',
      einheit: '€/Monat',
      minWert: SzenarioRechnerGrenzen.stromGrundpreisMin,
      maxWert: SzenarioRechnerGrenzen.stromGrundpreisMax,
      defaultWert: SzenarioRechnerGrenzen.stromGrundpreisDefault,
      schrittweite: SzenarioRechnerGrenzen.stromGrundpreisSchritt,
      nachkommastellen: 2,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['waermepumpe'],
    ),

    // Anteil Wärme aus Strom (nur Wärmenetz)
    EingabeParameter(
      id: 'anteilWaermeAusStrom',
      bezeichnung: 'Anteil Wärme aus Strom',
      beschreibung: 'Anteil der aus Strom erzeugten Wärme im Wärmenetz',
      einheit: '%',
      minWert: SzenarioRechnerGrenzen.anteilStromMin,
      maxWert: SzenarioRechnerGrenzen.anteilStromMax,
      defaultWert: SzenarioRechnerGrenzen.anteilStromDefault,
      schrittweite: SzenarioRechnerGrenzen.anteilStromSchritt,
      nachkommastellen: 1,
      istProzent: true,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['waermenetzKunde', 'waermenetzSuewag'],
    ),

    // Investitionskosten-Anpassung (alle Szenarien)
    EingabeParameter(
      id: 'investAnpassung',
      bezeichnung: 'Investitionskosten-Anpassung',
      beschreibung: 'Anpassung der Investitionskosten (±20%)',
      einheit: '%',
      minWert: SzenarioRechnerGrenzen.investAnpassungMin,
      maxWert: SzenarioRechnerGrenzen.investAnpassungMax,
      defaultWert: SzenarioRechnerGrenzen.investAnpassungDefault,
      schrittweite: SzenarioRechnerGrenzen.investAnpassungSchritt,
      nachkommastellen: 0,
      istProzent: true,
      typ: ParameterTyp.slider,
      relevantFuerSzenarien: ['alle'],
    ),
  ];

  /// Hole Parameter nach ID
  static EingabeParameter? byId(String id) {
    try {
      return alleParameter.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Parameter für ein bestimmtes Szenario
  static List<EingabeParameter> fuerSzenario(String szenarioId) {
    return alleParameter.where((p) {
      return p.relevantFuerSzenarien.contains('alle') ||
          p.relevantFuerSzenarien.contains(szenarioId);
    }).toList();
  }
}

enum ParameterTyp {
  slider,    // Slider mit Wert-Anzeige
  textfeld,  // Numerisches Textfeld
  toggle,    // An/Aus Schalter
}

/// Formatierung für Anzeige
extension EingabeParameterFormatierung on EingabeParameter {
  String formatiereWert(double wert) {
    if (istProzent) {
      return '${(wert * 100).toStringAsFixed(nachkommastellen)} $einheit';
    } else {
      return '${wert.toStringAsFixed(nachkommastellen)} $einheit';
    }
  }

  double parseWert(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d,.-]'), '').replaceAll(',', '.');
    final parsed = double.tryParse(cleaned) ?? defaultWert;

    if (istProzent) {
      return parsed / 100; // Von % zu 0-1
    }
    return parsed;
  }
}

/// Vergleich zwischen Stammdaten und User-Eingabe
class EingabeVergleich {
  final String parameterId;
  final String bezeichnung;
  final double stammdatenWert;
  final double benutzerWert;
  final double abweichungProzent;
  final bool istAbweichend;

  const EingabeVergleich({
    required this.parameterId,
    required this.bezeichnung,
    required this.stammdatenWert,
    required this.benutzerWert,
    required this.abweichungProzent,
    required this.istAbweichend,
  });

  factory EingabeVergleich.berechne({
    required String parameterId,
    required String bezeichnung,
    required double stammdatenWert,
    required double benutzerWert,
    double schwellwertProzent = 5.0, // Ab 5% Abweichung markieren
  }) {
    final abweichung = ((benutzerWert - stammdatenWert) / stammdatenWert) * 100;
    final istAbweichend = abweichung.abs() >= schwellwertProzent;

    return EingabeVergleich(
      parameterId: parameterId,
      bezeichnung: bezeichnung,
      stammdatenWert: stammdatenWert,
      benutzerWert: benutzerWert,
      abweichungProzent: abweichung,
      istAbweichend: istAbweichend,
    );
  }
}