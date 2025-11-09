// lib/models/kostenvergleich_ergebnis.dart
import 'dart:ui';


import 'package:flutter/foundation.dart';

/// Ergebnis einer Kostenberechnung für ein Szenario
class KostenberechnungErgebnis {
  final String szenarioId;
  final String szenarioBezeichnung;

  // Eingangswerte (für Nachvollziehbarkeit)
  final double waermebedarf; // kWh/a
  final double beheizteFlaeche; // m²

  // Kostenkomponenten (€/Jahr)
  final KostenAufschluesselung kosten;

  // Ergebnisse
  final double jahreskosten; // €/a (netto)
  final double jahreskosten_brutto; // €/a (brutto inkl. MwSt)
  final double waermevollkostenpreisNetto; // €/MWh (netto)
  final double waermevollkostenpreisBrutto; // €/MWh (brutto)
  final double kostenProQuadratmeter; // €/m²a

  // Für Chart-Darstellung (anteilig am Vollkostenpreis)
  final PreisbestandteileChart preisbestandteile;

  const KostenberechnungErgebnis({
    required this.szenarioId,
    required this.szenarioBezeichnung,
    required this.waermebedarf,
    required this.beheizteFlaeche,
    required this.kosten,
    required this.jahreskosten,
    required this.jahreskosten_brutto,
    required this.waermevollkostenpreisNetto,
    required this.waermevollkostenpreisBrutto,
    required this.kostenProQuadratmeter,
    required this.preisbestandteile,
  });

  /// Erstellt aus Kostenaufschlüsselung
  factory KostenberechnungErgebnis.berechnen({
    required String szenarioId,
    required String szenarioBezeichnung,
    required double waermebedarf,
    required double beheizteFlaeche,
    required KostenAufschluesselung kosten,
  }) {
    // Jahreskosten = Summe aller Komponenten
    final jahreskosten = kosten.gesamtsumme;
    final jahreskosten_brutto = jahreskosten * 1.19; // 19% MwSt

    // Wärmevollkostenpreis = Jahreskosten / Wärmebedarf * 1000 (€/MWh)
    final waermevollkostenpreisNetto = (jahreskosten / waermebedarf) * 1000;
    final waermevollkostenpreisBrutto = (jahreskosten_brutto / waermebedarf) * 1000;

    // Kosten pro m²
    final kostenProQm = jahreskosten / beheizteFlaeche;

    // Preisbestandteile für Chart (ct/kWh)
    final preisbestandteile = PreisbestandteileChart.berechnen(
      kosten: kosten,
      waermebedarf: waermebedarf,
    );

    return KostenberechnungErgebnis(
      szenarioId: szenarioId,
      szenarioBezeichnung: szenarioBezeichnung,
      waermebedarf: waermebedarf,
      beheizteFlaeche: beheizteFlaeche,
      kosten: kosten,
      jahreskosten: jahreskosten,
      jahreskosten_brutto: jahreskosten_brutto,
      waermevollkostenpreisNetto: waermevollkostenpreisNetto,
      waermevollkostenpreisBrutto: waermevollkostenpreisBrutto,
      kostenProQuadratmeter: kostenProQm,
      preisbestandteile: preisbestandteile,
    );
  }
}

/// Detaillierte Kostenaufschlüsselung (€/Jahr)
class KostenAufschluesselung {
  // C. Wärmekosten
  final double arbeitspreis; // Strom oder Wärme
  final double grundUndMesspreis;

  // D. Nebenkosten
  final double betriebskosten; // Wartung + Zusatzkosten

  // Kapitaldienst
  final double kapitalkosten; // Mit Förderung
  final double kapitalkostenOhneFoerderung; // Ohne Förderung (für Chart)
  final double zusaetzlicheKapitalkostenOhneFoerderung; // Differenz (für Chart)

  // Zusätzlicher Grundpreis Übergabestation (nur Süwag)
  final double zusaetzlicherGrundpreisUebergabestation;

  const KostenAufschluesselung({
    required this.arbeitspreis,
    required this.grundUndMesspreis,
    required this.betriebskosten,
    required this.kapitalkosten,
    required this.kapitalkostenOhneFoerderung,
    required this.zusaetzlicheKapitalkostenOhneFoerderung,
    required this.zusaetzlicherGrundpreisUebergabestation,
  });

  double get gesamtsumme =>
      arbeitspreis +
          grundUndMesspreis +
          betriebskosten +
          kapitalkosten +
          zusaetzlicherGrundpreisUebergabestation;
}

/// Preisbestandteile für Chart-Darstellung (wie Excel, gestapelt)
/// Alle Werte in ct/kWh
class PreisbestandteileChart {
  final double arbeitspreis; // Dunkelgrün
  final double grundUndMesspreis; // Gelb
  final double zusaetzlicherGrundpreisUebergabestation; // Hellgrün (nur Süwag)
  final double kapitalkostenInklFoerderung; // Hellgrau
  final double zusaetzlicheKapitalkostenOhneFoerderung; // Hellblau (gestrichelt oben)
  final double betriebskosten; // Türkis

  // Summen für Anzeige
  final double summeOhneFoerderung; // Gesamthöhe mit gestricheltem Teil
  final double summeMitFoerderung; // Gesamthöhe ohne gestrichelten Teil

  const PreisbestandteileChart({
    required this.arbeitspreis,
    required this.grundUndMesspreis,
    required this.zusaetzlicherGrundpreisUebergabestation,
    required this.kapitalkostenInklFoerderung,
    required this.zusaetzlicheKapitalkostenOhneFoerderung,
    required this.betriebskosten,
    required this.summeOhneFoerderung,
    required this.summeMitFoerderung,
  });

  /// Berechnet aus Kostenaufschlüsselung
  factory PreisbestandteileChart.berechnen({
    required KostenAufschluesselung kosten,
    required double waermebedarf,
  }) {
    // Umrechnung von €/Jahr in ct/kWh
    double euroJahrZuCtKWh(double euroJahr) {
      return (euroJahr / waermebedarf) * 100;
    }

    final arbeitspreis = euroJahrZuCtKWh(kosten.arbeitspreis);
    final grundUndMesspreis = euroJahrZuCtKWh(kosten.grundUndMesspreis);
    final zusaetzlicherGrundpreis = euroJahrZuCtKWh(
        kosten.zusaetzlicherGrundpreisUebergabestation
    );
    final kapitalkosten = euroJahrZuCtKWh(kosten.kapitalkosten);
    final zusaetzlicheKapitalkosten = euroJahrZuCtKWh(
        kosten.zusaetzlicheKapitalkostenOhneFoerderung
    );
    final betriebskosten = euroJahrZuCtKWh(kosten.betriebskosten);

    final summeMitFoerderung =
        arbeitspreis +
            grundUndMesspreis +
            zusaetzlicherGrundpreis +
            kapitalkosten +
            betriebskosten;

    final summeOhneFoerderung = summeMitFoerderung + zusaetzlicheKapitalkosten;

    return PreisbestandteileChart(
      arbeitspreis: arbeitspreis,
      grundUndMesspreis: grundUndMesspreis,
      zusaetzlicherGrundpreisUebergabestation: zusaetzlicherGrundpreis,
      kapitalkostenInklFoerderung: kapitalkosten,
      zusaetzlicheKapitalkostenOhneFoerderung: zusaetzlicheKapitalkosten,
      betriebskosten: betriebskosten,
      summeOhneFoerderung: summeOhneFoerderung,
      summeMitFoerderung: summeMitFoerderung,
    );
  }

  /// Für gestapeltes Balkendiagramm - Reihenfolge von unten nach oben
  List<ChartSegment> get segmente => [
    ChartSegment(
      bezeichnung: 'Arbeitspreis',
      wert: arbeitspreis,
      farbe: ChartFarbe.arbeitspreis,
      typ: SegmentTyp.solid,
    ),
    ChartSegment(
      bezeichnung: 'Grund- und Messpreis',
      wert: grundUndMesspreis,
      farbe: ChartFarbe.grundpreis,
      typ: SegmentTyp.solid,
    ),
    if (zusaetzlicherGrundpreisUebergabestation > 0)
      ChartSegment(
        bezeichnung: 'zusätzl. Grundpreis ÜGS',
        wert: zusaetzlicherGrundpreisUebergabestation,
        farbe: ChartFarbe.zusatzGrundpreis,
        typ: SegmentTyp.solid,
      ),
    ChartSegment(
      bezeichnung: 'Betriebskosten',
      wert: betriebskosten,
      farbe: ChartFarbe.betriebskosten,
      typ: SegmentTyp.solid,
    ),
    ChartSegment(
      bezeichnung: 'Kapitalkosten inkl. Förderung',
      wert: kapitalkostenInklFoerderung,
      farbe: ChartFarbe.kapitalkostenMitFoerderung,
      typ: SegmentTyp.solid,
    ),
    if (zusaetzlicheKapitalkostenOhneFoerderung > 0)
      ChartSegment(
        bezeichnung: 'zusätzl. Kapitalkosten ohne Förderung',
        wert: zusaetzlicheKapitalkostenOhneFoerderung,
        farbe: ChartFarbe.kapitalkostenOhneFoerderung,
        typ: SegmentTyp.dashed, // Gestrichelt wie in Excel
      ),
  ];
}

/// Ein Segment im gestapelten Balkendiagramm
class ChartSegment {
  final String bezeichnung;
  final double wert; // ct/kWh
  final ChartFarbe farbe;
  final SegmentTyp typ;

  const ChartSegment({
    required this.bezeichnung,
    required this.wert,
    required this.farbe,
    required this.typ,
  });
}

enum SegmentTyp {
  solid,   // Durchgezogen
  dashed,  // Gestrichelt (für "ohne Förderung")
}

/// Farben für Chart-Segmente (entsprechend Excel)
enum ChartFarbe {
  arbeitspreis,                    // Dunkelgrün/Petrol
  grundpreis,                      // Gelb/Orange
  zusatzGrundpreis,                // Hellgrün
  betriebskosten,                  // Türkis
  kapitalkostenMitFoerderung,      // Hellgrau
  kapitalkostenOhneFoerderung,     // Hellblau (gestrichelt)
}

/// Extension für Flutter Colors
extension ChartFarbeColors on ChartFarbe {
  Color get color {
    switch (this) {
      case ChartFarbe.arbeitspreis:
        return const Color(0xFF006666); // Dunkel Petrol
      case ChartFarbe.grundpreis:
        return const Color(0xFFFFC000); // Orange/Gelb
      case ChartFarbe.zusatzGrundpreis:
        return const Color(0xFF92D050); // Hellgrün
      case ChartFarbe.betriebskosten:
        return const Color(0xFF00B0F0); // Türkis
      case ChartFarbe.kapitalkostenMitFoerderung:
        return const Color(0xFFBFBFBF); // Hellgrau
      case ChartFarbe.kapitalkostenOhneFoerderung:
        return const Color(0xFFD9E1F2); // Hellblau
    }
  }

  String get bezeichnung {
    switch (this) {
      case ChartFarbe.arbeitspreis:
        return 'Arbeitspreis';
      case ChartFarbe.grundpreis:
        return 'Grund- und Messpreis';
      case ChartFarbe.zusatzGrundpreis:
        return 'zusätzlicher Grundpreis Übergabestation';
      case ChartFarbe.betriebskosten:
        return 'Betriebskosten';
      case ChartFarbe.kapitalkostenMitFoerderung:
        return 'Kapitalkosten inkl. Förderung';
      case ChartFarbe.kapitalkostenOhneFoerderung:
        return 'zusätzliche Kapitalkosten ohne Förderung';
    }
  }
}

/// Vergleichsergebnis - alle 4 Szenarien zusammen
class KostenvergleichErgebnis {
  final int jahr;
  final List<KostenberechnungErgebnis> szenarien;

  // Für Vergleichstabelle
  final String guenstigstesSzenarioId;
  final double guenstigsterPreis; // €/MWh

  const KostenvergleichErgebnis({
    required this.jahr,
    required this.szenarien,
    required this.guenstigstesSzenarioId,
    required this.guenstigsterPreis,
  });

  /// Erstellt Vergleichsergebnis
  factory KostenvergleichErgebnis.erstellen({
    required int jahr,
    required List<KostenberechnungErgebnis> szenarien,
  }) {
    // Finde günstigstes Szenario (niedrigster Vollkostenpreis netto)
    var guenstigstesSzenario = szenarien.first;

    for (final szenario in szenarien) {
      if (szenario.waermevollkostenpreisNetto <
          guenstigstesSzenario.waermevollkostenpreisNetto) {
        guenstigstesSzenario = szenario;
      }
    }

    return KostenvergleichErgebnis(
      jahr: jahr,
      szenarien: szenarien,
      guenstigstesSzenarioId: guenstigstesSzenario.szenarioId,
      guenstigsterPreis: guenstigstesSzenario.waermevollkostenpreisNetto,
    );
  }

  /// Sortiert nach Vollkostenpreis (günstigstes zuerst)
  List<KostenberechnungErgebnis> get szenarienSortiertNachPreis {
    final sorted = List<KostenberechnungErgebnis>.from(szenarien);
    sorted.sort((a, b) => a.waermevollkostenpreisNetto
        .compareTo(b.waermevollkostenpreisNetto));
    return sorted;
  }

  /// Hole Szenario nach ID
  KostenberechnungErgebnis? getSzenario(String szenarioId) {
    try {
      return szenarien.firstWhere((s) => s.szenarioId == szenarioId);
    } catch (e) {
      return null;
    }
  }
}

/// Für Tabellenanzeige - eine Zeile
class VergleichsTabellenZeile {
  final String bezeichnung; // z.B. "Wärmevollkostenpreis netto"
  final String einheit; // z.B. "€/MWh"
  final Map<String, String> werte; // szenarioId → formatierter Wert
  final bool istHervorgehoben; // z.B. für Endergebnis

  const VergleichsTabellenZeile({
    required this.bezeichnung,
    required this.einheit,
    required this.werte,
    this.istHervorgehoben = false,
  });
}