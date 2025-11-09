// lib/models/kostenvergleich_data.dart

import 'package:flutter/foundation.dart';

/// Hauptdokument für ein Jahr
class KostenvergleichJahr {
  final String id; // z.B. "2025"
  final int jahr;
  final DateTime gueltigAb;
  final DateTime gueltigBis;
  final DateTime erstelltAm;
  final DateTime? aktualisiertAm;
  final bool istAktiv; // Nur ein Jahr kann aktiv sein
  final String status; // 'entwurf', 'aktiv', 'archiviert'

  // Allgemeine Daten
  final GrunddatenKostenvergleich grunddaten;
  final FinanzierungsDaten finanzierung;

  // Die 4 Szenarien
  final Map<String, SzenarioStammdaten> szenarien;

  const KostenvergleichJahr({
    required this.id,
    required this.jahr,
    required this.gueltigAb,
    required this.gueltigBis,
    required this.erstelltAm,
    this.aktualisiertAm,
    required this.istAktiv,
    required this.status,
    required this.grunddaten,
    required this.finanzierung,
    required this.szenarien,
  });

  factory KostenvergleichJahr.fromMap(Map<String, dynamic> map) {
    return KostenvergleichJahr(
      id: map['id'] as String,
      jahr: map['jahr'] as int,
      gueltigAb: DateTime.parse(map['gueltigAb'] as String),
      gueltigBis: DateTime.parse(map['gueltigBis'] as String),
      erstelltAm: DateTime.parse(map['erstelltAm'] as String),
      aktualisiertAm: map['aktualisiertAm'] != null
          ? DateTime.parse(map['aktualisiertAm'] as String)
          : null,
      istAktiv: map['istAktiv'] as bool,
      status: map['status'] as String,
      grunddaten: GrunddatenKostenvergleich.fromMap(
          map['grunddaten'] as Map<String, dynamic>
      ),
      finanzierung: FinanzierungsDaten.fromMap(
          map['finanzierung'] as Map<String, dynamic>
      ),
      szenarien: (map['szenarien'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
          key,
          SzenarioStammdaten.fromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jahr': jahr,
      'gueltigAb': gueltigAb.toIso8601String(),
      'gueltigBis': gueltigBis.toIso8601String(),
      'erstelltAm': erstelltAm.toIso8601String(),
      'aktualisiertAm': aktualisiertAm?.toIso8601String(),
      'istAktiv': istAktiv,
      'status': status,
      'grunddaten': grunddaten.toMap(),
      'finanzierung': finanzierung.toMap(),
      'szenarien': szenarien.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  KostenvergleichJahr copyWith({
    String? id,
    int? jahr,
    DateTime? gueltigAb,
    DateTime? gueltigBis,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
    bool? istAktiv,
    String? status,
    GrunddatenKostenvergleich? grunddaten,
    FinanzierungsDaten? finanzierung,
    Map<String, SzenarioStammdaten>? szenarien,
  }) {
    return KostenvergleichJahr(
      id: id ?? this.id,
      jahr: jahr ?? this.jahr,
      gueltigAb: gueltigAb ?? this.gueltigAb,
      gueltigBis: gueltigBis ?? this.gueltigBis,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
      istAktiv: istAktiv ?? this.istAktiv,
      status: status ?? this.status,
      grunddaten: grunddaten ?? this.grunddaten,
      finanzierung: finanzierung ?? this.finanzierung,
      szenarien: szenarien ?? this.szenarien,
    );
  }
}

/// Grunddaten (Abschnitt A in Excel)
class GrunddatenKostenvergleich {
  final double beheizteFlaeche; // m²
  final double spezHeizenergiebedarf; // kWh/m²a
  final double heizenergiebedarf; // kWh/a (berechnet: Fläche × spez. Bedarf)

  const GrunddatenKostenvergleich({
    required this.beheizteFlaeche,
    required this.spezHeizenergiebedarf,
    required this.heizenergiebedarf,
  });

  factory GrunddatenKostenvergleich.fromMap(Map<String, dynamic> map) {
    return GrunddatenKostenvergleich(
      beheizteFlaeche: (map['beheizteFlaeche'] as num).toDouble(),
      spezHeizenergiebedarf: (map['spezHeizenergiebedarf'] as num).toDouble(),
      heizenergiebedarf: (map['heizenergiebedarf'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'beheizteFlaeche': beheizteFlaeche,
      'spezHeizenergiebedarf': spezHeizenergiebedarf,
      'heizenergiebedarf': heizenergiebedarf,
    };
  }
}

/// Finanzierungsdaten (Zinsen, Förderung)
class FinanzierungsDaten {
  final double zinssatz; // % (z.B. 3.546)
  final int laufzeitJahre; // Jahre (z.B. 20)
  final double foerderungBEG; // Quote 0-1 (z.B. 0.30 = 30%)
  final double foerderungBEW; // Quote 0-1 (z.B. 0.30 = 30%)

  const FinanzierungsDaten({
    required this.zinssatz,
    required this.laufzeitJahre,
    required this.foerderungBEG,
    required this.foerderungBEW,
  });

  factory FinanzierungsDaten.fromMap(Map<String, dynamic> map) {
    return FinanzierungsDaten(
      zinssatz: (map['zinssatz'] as num).toDouble(),
      laufzeitJahre: map['laufzeitJahre'] as int,
      foerderungBEG: (map['foerderungBEG'] as num).toDouble(),
      foerderungBEW: (map['foerderungBEW'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zinssatz': zinssatz,
      'laufzeitJahre': laufzeitJahre,
      'foerderungBEG': foerderungBEG,
      'foerderungBEW': foerderungBEW,
    };
  }
}

/// Ein Szenario (z.B. Wärmepumpe, Wärmenetz, etc.)
class SzenarioStammdaten {
  final String id; // 'waermepumpe', 'waermenetzOhneUGS', etc.
  final String bezeichnung; // "Wärmepumpe"
  final String beschreibung; // "Luft/Wasser-Wärmepumpe 10 kW..."
  final SzenarioTyp typ;
  final int sortierung; // Für Reihenfolge in Darstellung

  // B. Investitionskosten
  final InvestitionskostenDaten investition;

  // C. Wärmekosten (laufend)
  final WaermekostenDaten waermekosten;

  // D. Nebenkosten (laufend)
  final NebenkostenDaten nebenkosten;

  const SzenarioStammdaten({
    required this.id,
    required this.bezeichnung,
    required this.beschreibung,
    required this.typ,
    required this.sortierung,
    required this.investition,
    required this.waermekosten,
    required this.nebenkosten,
  });

  factory SzenarioStammdaten.fromMap(Map<String, dynamic> map) {
    return SzenarioStammdaten(
      id: map['id'] as String,
      bezeichnung: map['bezeichnung'] as String,
      beschreibung: map['beschreibung'] as String,
      typ: SzenarioTyp.values.byName(map['typ'] as String),
      sortierung: map['sortierung'] as int,
      investition: InvestitionskostenDaten.fromMap(
          map['investition'] as Map<String, dynamic>
      ),
      waermekosten: WaermekostenDaten.fromMap(
          map['waermekosten'] as Map<String, dynamic>
      ),
      nebenkosten: NebenkostenDaten.fromMap(
          map['nebenkosten'] as Map<String, dynamic>
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bezeichnung': bezeichnung,
      'beschreibung': beschreibung,
      'typ': typ.name,
      'sortierung': sortierung,
      'investition': investition.toMap(),
      'waermekosten': waermekosten.toMap(),
      'nebenkosten': nebenkosten.toMap(),
    };
  }
}

enum SzenarioTyp {
  dezentral, // Wärmepumpe
  zentral,   // Wärmenetz-Varianten
}

/// Investitionskosten (Abschnitt B)
class InvestitionskostenDaten {
  final List<InvestitionsPosition> positionen; // Einzelpositionen
  final double gesamtBrutto; // Summe aller Positionen
  final FoerderungsTyp foerderungsTyp; // BEG, BEW, keine
  final double foerderquote; // 0-1
  final double foerderbetrag; // berechnet
  final double nettoNachFoerderung; // berechnet

  const InvestitionskostenDaten({
    required this.positionen,
    required this.gesamtBrutto,
    required this.foerderungsTyp,
    required this.foerderquote,
    required this.foerderbetrag,
    required this.nettoNachFoerderung,
  });

  factory InvestitionskostenDaten.fromMap(Map<String, dynamic> map) {
    return InvestitionskostenDaten(
      positionen: (map['positionen'] as List)
          .map((p) => InvestitionsPosition.fromMap(p as Map<String, dynamic>))
          .toList(),
      gesamtBrutto: (map['gesamtBrutto'] as num).toDouble(),
      foerderungsTyp: FoerderungsTyp.values.byName(map['foerderungsTyp'] as String),
      foerderquote: (map['foerderquote'] as num).toDouble(),
      foerderbetrag: (map['foerderbetrag'] as num).toDouble(),
      nettoNachFoerderung: (map['nettoNachFoerderung'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionen': positionen.map((p) => p.toMap()).toList(),
      'gesamtBrutto': gesamtBrutto,
      'foerderungsTyp': foerderungsTyp.name,
      'foerderquote': foerderquote,
      'foerderbetrag': foerderbetrag,
      'nettoNachFoerderung': nettoNachFoerderung,
    };
  }
}

class InvestitionsPosition {
  final String bezeichnung;
  final double betrag; // €
  final String? bemerkung;

  const InvestitionsPosition({
    required this.bezeichnung,
    required this.betrag,
    this.bemerkung,
  });

  factory InvestitionsPosition.fromMap(Map<String, dynamic> map) {
    return InvestitionsPosition(
      bezeichnung: map['bezeichnung'] as String,
      betrag: (map['betrag'] as num).toDouble(),
      bemerkung: map['bemerkung'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bezeichnung': bezeichnung,
      'betrag': betrag,
      if (bemerkung != null) 'bemerkung': bemerkung,
    };
  }
}

enum FoerderungsTyp {
  keine,
  beg, // BEG 30%
  bew, // BEW für Süwag
}

/// Wärmekosten (Abschnitt C)
class WaermekostenDaten {
  // Verbrauch
  final double? stromverbrauchKWh; // Nur Wärmepumpe
  final double? waermeVerbrauchGasKWh; // Wärmenetz aus Gas
  final double? waermeVerbrauchStromKWh; // Wärmenetz aus Strom

  // Arbeitspreise
  final double? stromarbeitspreisCtKWh; // ct/kWh
  final double? waermeGasArbeitspreisCtKWh; // ct/kWh
  final double? waermeStromArbeitspreisCtKWh; // ct/kWh

  // Grundpreise
  final double? stromGrundpreisEuroMonat; // €/Monat
  final double? waermeGrundpreisEuroJahr; // €/Jahr (o. Wärme)
  final double? waermeMesspreisEuroJahr; // €/Jahr

  // JAZ für Wärmepumpe
  final double? jahresarbeitszahl; // z.B. 3.0

  const WaermekostenDaten({
    this.stromverbrauchKWh,
    this.waermeVerbrauchGasKWh,
    this.waermeVerbrauchStromKWh,
    this.stromarbeitspreisCtKWh,
    this.waermeGasArbeitspreisCtKWh,
    this.waermeStromArbeitspreisCtKWh,
    this.stromGrundpreisEuroMonat,
    this.waermeGrundpreisEuroJahr,
    this.waermeMesspreisEuroJahr,
    this.jahresarbeitszahl,
  });

// Füge diese copyWith Methode hinzu:
  WaermekostenDaten copyWith({
    double? stromverbrauchKWh,
    double? waermeVerbrauchGasKWh,
    double? waermeVerbrauchStromKWh,
    double? stromarbeitspreisCtKWh,
    double? waermeGasArbeitspreisCtKWh,
    double? waermeStromArbeitspreisCtKWh,
    double? stromGrundpreisEuroMonat,
    double? waermeGrundpreisEuroJahr,
    double? waermeMesspreisEuroJahr,
    double? jahresarbeitszahl,
  }) {
    return WaermekostenDaten(
      stromverbrauchKWh: stromverbrauchKWh ?? this.stromverbrauchKWh,
      waermeVerbrauchGasKWh: waermeVerbrauchGasKWh ?? this.waermeVerbrauchGasKWh,
      waermeVerbrauchStromKWh: waermeVerbrauchStromKWh ?? this.waermeVerbrauchStromKWh,
      stromarbeitspreisCtKWh: stromarbeitspreisCtKWh ?? this.stromarbeitspreisCtKWh,
      waermeGasArbeitspreisCtKWh: waermeGasArbeitspreisCtKWh ?? this.waermeGasArbeitspreisCtKWh,
      waermeStromArbeitspreisCtKWh: waermeStromArbeitspreisCtKWh ?? this.waermeStromArbeitspreisCtKWh,
      stromGrundpreisEuroMonat: stromGrundpreisEuroMonat ?? this.stromGrundpreisEuroMonat,
      waermeGrundpreisEuroJahr: waermeGrundpreisEuroJahr ?? this.waermeGrundpreisEuroJahr,
      waermeMesspreisEuroJahr: waermeMesspreisEuroJahr ?? this.waermeMesspreisEuroJahr,
      jahresarbeitszahl: jahresarbeitszahl ?? this.jahresarbeitszahl,
    );
  }

  factory WaermekostenDaten.fromMap(Map<String, dynamic> map) {
    return WaermekostenDaten(
      stromverbrauchKWh: map['stromverbrauchKWh'] != null
          ? (map['stromverbrauchKWh'] as num).toDouble()
          : null,
      waermeVerbrauchGasKWh: map['waermeVerbrauchGasKWh'] != null
          ? (map['waermeVerbrauchGasKWh'] as num).toDouble()
          : null,
      waermeVerbrauchStromKWh: map['waermeVerbrauchStromKWh'] != null
          ? (map['waermeVerbrauchStromKWh'] as num).toDouble()
          : null,
      stromarbeitspreisCtKWh: map['stromarbeitspreisCtKWh'] != null
          ? (map['stromarbeitspreisCtKWh'] as num).toDouble()
          : null,
      waermeGasArbeitspreisCtKWh: map['waermeGasArbeitspreisCtKWh'] != null
          ? (map['waermeGasArbeitspreisCtKWh'] as num).toDouble()
          : null,
      waermeStromArbeitspreisCtKWh: map['waermeStromArbeitspreisCtKWh'] != null
          ? (map['waermeStromArbeitspreisCtKWh'] as num).toDouble()
          : null,
      stromGrundpreisEuroMonat: map['stromGrundpreisEuroMonat'] != null
          ? (map['stromGrundpreisEuroMonat'] as num).toDouble()
          : null,
      waermeGrundpreisEuroJahr: map['waermeGrundpreisEuroJahr'] != null
          ? (map['waermeGrundpreisEuroJahr'] as num).toDouble()
          : null,
      waermeMesspreisEuroJahr: map['waermeMesspreisEuroJahr'] != null
          ? (map['waermeMesspreisEuroJahr'] as num).toDouble()
          : null,
      jahresarbeitszahl: map['jahresarbeitszahl'] != null
          ? (map['jahresarbeitszahl'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (stromverbrauchKWh != null) 'stromverbrauchKWh': stromverbrauchKWh,
      if (waermeVerbrauchGasKWh != null) 'waermeVerbrauchGasKWh': waermeVerbrauchGasKWh,
      if (waermeVerbrauchStromKWh != null) 'waermeVerbrauchStromKWh': waermeVerbrauchStromKWh,
      if (stromarbeitspreisCtKWh != null) 'stromarbeitspreisCtKWh': stromarbeitspreisCtKWh,
      if (waermeGasArbeitspreisCtKWh != null) 'waermeGasArbeitspreisCtKWh': waermeGasArbeitspreisCtKWh,
      if (waermeStromArbeitspreisCtKWh != null) 'waermeStromArbeitspreisCtKWh': waermeStromArbeitspreisCtKWh,
      if (stromGrundpreisEuroMonat != null) 'stromGrundpreisEuroMonat': stromGrundpreisEuroMonat,
      if (waermeGrundpreisEuroJahr != null) 'waermeGrundpreisEuroJahr': waermeGrundpreisEuroJahr,
      if (waermeMesspreisEuroJahr != null) 'waermeMesspreisEuroJahr': waermeMesspreisEuroJahr,
      if (jahresarbeitszahl != null) 'jahresarbeitszahl': jahresarbeitszahl,
    };
  }
}

/// Nebenkosten (Abschnitt D)
class NebenkostenDaten {
  final double? wartungEuroJahr; // €/Jahr
  final double? grundpreisUebergabestationEuroJahr; // €/Jahr (nur Süwag)

  const NebenkostenDaten({
    this.wartungEuroJahr,
    this.grundpreisUebergabestationEuroJahr,
  });

  factory NebenkostenDaten.fromMap(Map<String, dynamic> map) {
    return NebenkostenDaten(
      wartungEuroJahr: map['wartungEuroJahr'] != null
          ? (map['wartungEuroJahr'] as num).toDouble()
          : null,
      grundpreisUebergabestationEuroJahr: map['grundpreisUebergabestationEuroJahr'] != null
          ? (map['grundpreisUebergabestationEuroJahr'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (wartungEuroJahr != null) 'wartungEuroJahr': wartungEuroJahr,
      if (grundpreisUebergabestationEuroJahr != null)
        'grundpreisUebergabestationEuroJahr': grundpreisUebergabestationEuroJahr,
    };
  }
}