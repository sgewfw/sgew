// lib/models/kostenvergleich_data.dart

import 'package:flutter/foundation.dart';

/// Quelleninformation für jeden Wert
class QuellenInfo {
  final String titel;
  final String beschreibung;
  final String? link;

  const QuellenInfo({
    required this.titel,
    required this.beschreibung,
    this.link,
  });

  factory QuellenInfo.fromMap(Map<String, dynamic> map) {
    return QuellenInfo(
      titel: map['titel'] as String,
      beschreibung: map['beschreibung'] as String,
      link: map['link'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titel': titel,
      'beschreibung': beschreibung,
      if (link != null) 'link': link,
    };
  }
}

/// Wrapper für Werte mit Quelle
class WertMitQuelle<T> {
  final T wert;
  final QuellenInfo quelle;

  const WertMitQuelle({
    required this.wert,
    required this.quelle,
  });

  factory WertMitQuelle.fromMap(
      Map<String, dynamic> map,
      T Function(dynamic) parseWert,
      ) {
    return WertMitQuelle(
      wert: parseWert(map['wert']),
      quelle: QuellenInfo.fromMap(map['quelle'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap(dynamic Function(T) serializeWert) {
    return {
      'wert': serializeWert(wert),
      'quelle': quelle.toMap(),
    };
  }
}

/// Hauptdokument für ein Jahr
class KostenvergleichJahr {
  final String id;
  final int jahr;
  final DateTime gueltigAb;
  final DateTime gueltigBis;
  final DateTime erstelltAm;
  final DateTime? aktualisiertAm;
  final bool istAktiv;
  final String status;

  final GrunddatenKostenvergleich grunddaten;
  final FinanzierungsDaten finanzierung;
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
        map['grunddaten'] as Map<String, dynamic>,
      ),
      finanzierung: FinanzierungsDaten.fromMap(
        map['finanzierung'] as Map<String, dynamic>,
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

// In lib/models/kostenvergleich_data.dart

/// Grunddaten mit Quellen
class GrunddatenKostenvergleich {
  final WertMitQuelle<double> beheizteFlaeche;
  final WertMitQuelle<double> spezHeizenergiebedarf;
  final WertMitQuelle<double> heizenergiebedarf;
  final WertMitQuelle<double> anteilGaswaerme; // NEU

  const GrunddatenKostenvergleich({
    required this.beheizteFlaeche,
    required this.spezHeizenergiebedarf,
    required this.heizenergiebedarf,
    required this.anteilGaswaerme, // NEU
  });

  factory GrunddatenKostenvergleich.fromMap(Map<String, dynamic> map) {
    return GrunddatenKostenvergleich(
      beheizteFlaeche: WertMitQuelle.fromMap(
        map['beheizteFlaeche'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      spezHeizenergiebedarf: WertMitQuelle.fromMap(
        map['spezHeizenergiebedarf'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      heizenergiebedarf: WertMitQuelle.fromMap(
        map['heizenergiebedarf'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      anteilGaswaerme: WertMitQuelle.fromMap( // NEU
        map['anteilGaswaerme'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'beheizteFlaeche': beheizteFlaeche.toMap((v) => v),
      'spezHeizenergiebedarf': spezHeizenergiebedarf.toMap((v) => v),
      'heizenergiebedarf': heizenergiebedarf.toMap((v) => v),
      'anteilGaswaerme': anteilGaswaerme.toMap((v) => v), // NEU
    };
  }
}
/// Finanzierungsdaten mit Quellen
class FinanzierungsDaten {
  final WertMitQuelle<double> zinssatz;
  final WertMitQuelle<int> laufzeitJahre;
  final WertMitQuelle<double> foerderungBEG;
  final WertMitQuelle<double> foerderungBEW;

  const FinanzierungsDaten({
    required this.zinssatz,
    required this.laufzeitJahre,
    required this.foerderungBEG,
    required this.foerderungBEW,
  });

  factory FinanzierungsDaten.fromMap(Map<String, dynamic> map) {
    return FinanzierungsDaten(
      zinssatz: WertMitQuelle.fromMap(
        map['zinssatz'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      laufzeitJahre: WertMitQuelle.fromMap(
        map['laufzeitJahre'] as Map<String, dynamic>,
            (v) => v as int,
      ),
      foerderungBEG: WertMitQuelle.fromMap(
        map['foerderungBEG'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      foerderungBEW: WertMitQuelle.fromMap(
        map['foerderungBEW'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zinssatz': zinssatz.toMap((v) => v),
      'laufzeitJahre': laufzeitJahre.toMap((v) => v),
      'foerderungBEG': foerderungBEG.toMap((v) => v),
      'foerderungBEW': foerderungBEW.toMap((v) => v),
    };
  }
}

/// Szenario
class SzenarioStammdaten {
  final String id;
  final String bezeichnung;
  final String beschreibung;
  final SzenarioTyp typ;
  final int sortierung;

  final InvestitionskostenDaten investition;
  final WaermekostenDaten waermekosten;
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
        map['investition'] as Map<String, dynamic>,
      ),
      waermekosten: WaermekostenDaten.fromMap(
        map['waermekosten'] as Map<String, dynamic>,
      ),
      nebenkosten: NebenkostenDaten.fromMap(
        map['nebenkosten'] as Map<String, dynamic>,
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
  dezentral,
  zentral,
}

/// Investitionskosten - FEST VORDEFINIERTE POSITIONEN
class InvestitionskostenDaten {
  // B.1 - Nur Wärmepumpe
  final InvestitionsPosition? waermepumpe;

  // B.2 - Nur WN Kunde
  final InvestitionsPosition? uebergabestation;

  // B.3 - WP und WN Kunde (unterschiedliche Beträge)
  final InvestitionsPosition? twwSpeicher;

  // B.4 - WP und WN Kunde ("inkl." Text)
  final InvestitionsPositionText? hydraulik;

  // B.6 - Nur WN Kunde
  final InvestitionsPosition? heizlastberechnung;

  // B.7 - Nur WP
  final InvestitionsPosition? zaehlerschrank;

  // B.8 - Nur WN Süwag
  final InvestitionsPosition? bkz;

  // Berechnete Werte
  final double gesamtBrutto;
  final FoerderungsTyp foerderungsTyp;
  final double foerderquote;
  final double foerderbetrag;
  final double nettoNachFoerderung;

  const InvestitionskostenDaten({
    this.waermepumpe,
    this.uebergabestation,
    this.twwSpeicher,
    this.hydraulik,
    this.heizlastberechnung,
    this.zaehlerschrank,
    this.bkz,
    required this.gesamtBrutto,
    required this.foerderungsTyp,
    required this.foerderquote,
    required this.foerderbetrag,
    required this.nettoNachFoerderung,
  });

  factory InvestitionskostenDaten.fromMap(Map<String, dynamic> map) {
    return InvestitionskostenDaten(
      waermepumpe: map['waermepumpe'] != null
          ? InvestitionsPosition.fromMap(map['waermepumpe'] as Map<String, dynamic>)
          : null,
      uebergabestation: map['uebergabestation'] != null
          ? InvestitionsPosition.fromMap(map['uebergabestation'] as Map<String, dynamic>)
          : null,
      twwSpeicher: map['twwSpeicher'] != null
          ? InvestitionsPosition.fromMap(map['twwSpeicher'] as Map<String, dynamic>)
          : null,
      hydraulik: map['hydraulik'] != null
          ? InvestitionsPositionText.fromMap(map['hydraulik'] as Map<String, dynamic>)
          : null,
      heizlastberechnung: map['heizlastberechnung'] != null
          ? InvestitionsPosition.fromMap(map['heizlastberechnung'] as Map<String, dynamic>)
          : null,
      zaehlerschrank: map['zaehlerschrank'] != null
          ? InvestitionsPosition.fromMap(map['zaehlerschrank'] as Map<String, dynamic>)
          : null,
      bkz: map['bkz'] != null
          ? InvestitionsPosition.fromMap(map['bkz'] as Map<String, dynamic>)
          : null,
      gesamtBrutto: (map['gesamtBrutto'] as num).toDouble(),
      foerderungsTyp: FoerderungsTyp.values.byName(map['foerderungsTyp'] as String),
      foerderquote: (map['foerderquote'] as num).toDouble(),
      foerderbetrag: (map['foerderbetrag'] as num).toDouble(),
      nettoNachFoerderung: (map['nettoNachFoerderung'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (waermepumpe != null) 'waermepumpe': waermepumpe!.toMap(),
      if (uebergabestation != null) 'uebergabestation': uebergabestation!.toMap(),
      if (twwSpeicher != null) 'twwSpeicher': twwSpeicher!.toMap(),
      if (hydraulik != null) 'hydraulik': hydraulik!.toMap(),
      if (heizlastberechnung != null) 'heizlastberechnung': heizlastberechnung!.toMap(),
      if (zaehlerschrank != null) 'zaehlerschrank': zaehlerschrank!.toMap(),
      if (bkz != null) 'bkz': bkz!.toMap(),
      'gesamtBrutto': gesamtBrutto,
      'foerderungsTyp': foerderungsTyp.name,
      'foerderquote': foerderquote,
      'foerderbetrag': foerderbetrag,
      'nettoNachFoerderung': nettoNachFoerderung,
    };
  }
}

/// Investitionsposition mit Betrag und Quelle
class InvestitionsPosition {
  final String bezeichnung;
  final WertMitQuelle<double> betrag;
  final String? bemerkung;

  const InvestitionsPosition({
    required this.bezeichnung,
    required this.betrag,
    this.bemerkung,
  });

  factory InvestitionsPosition.fromMap(Map<String, dynamic> map) {
    return InvestitionsPosition(
      bezeichnung: map['bezeichnung'] as String,
      betrag: WertMitQuelle.fromMap(
        map['betrag'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      ),
      bemerkung: map['bemerkung'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bezeichnung': bezeichnung,
      'betrag': betrag.toMap((v) => v),
      if (bemerkung != null) 'bemerkung': bemerkung,
    };
  }
}

/// Investitionsposition mit Text statt Betrag (z.B. "inkl.")
class InvestitionsPositionText {
  final String bezeichnung;
  final WertMitQuelle<String> text;

  const InvestitionsPositionText({
    required this.bezeichnung,
    required this.text,
  });

  factory InvestitionsPositionText.fromMap(Map<String, dynamic> map) {
    return InvestitionsPositionText(
      bezeichnung: map['bezeichnung'] as String,
      text: WertMitQuelle.fromMap(
        map['text'] as Map<String, dynamic>,
            (v) => v as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bezeichnung': bezeichnung,
      'text': text.toMap((v) => v),
    };
  }
}

enum FoerderungsTyp {
  keine,
  beg,
  bew,
}

// In lib/models/kostenvergleich_data.dart

/// Wärmekosten mit Quellen
class WaermekostenDaten {
  // Verbrauch
  final WertMitQuelle<double>? stromverbrauchKWh;
  final WertMitQuelle<double>? waermeVerbrauchGasKWh;
  final WertMitQuelle<double>? waermeVerbrauchStromKWh;

  // Arbeitspreise
  final WertMitQuelle<double>? stromarbeitspreisCtKWh;
  final WertMitQuelle<double>? waermeGasArbeitspreisCtKWh;
  final WertMitQuelle<double>? waermeStromArbeitspreisCtKWh;

  // Grundpreise
  final WertMitQuelle<double>? stromGrundpreisEuroMonat;
  final WertMitQuelle<double>? waermeGrundpreisEuroJahr;
  final WertMitQuelle<double>? waermeMesspreisEuroJahr;

  // NEU: Messpreis aufgeteilt in 3 Komponenten
  final WertMitQuelle<double>? messpreisWasserzaehlerEuroJahr;
  final WertMitQuelle<double>? messpreisWaermezaehlerEuroJahr;
  final WertMitQuelle<double>? messpreisEichgebuehrenEuroJahr;


  // JAZ
  final WertMitQuelle<double>? jahresarbeitszahl;

  // NEU: Anteil Gaswärme (0.0 bis 1.0)
  final WertMitQuelle<double>? anteilGaswaerme;

  const WaermekostenDaten({
    this.stromverbrauchKWh,
    this.waermeVerbrauchGasKWh,
    this.waermeVerbrauchStromKWh,
    this.stromarbeitspreisCtKWh,
    this.waermeGasArbeitspreisCtKWh,
    this.waermeStromArbeitspreisCtKWh,
    this.stromGrundpreisEuroMonat,
    this.waermeGrundpreisEuroJahr,
    this.messpreisWasserzaehlerEuroJahr, // NEU
    this.messpreisWaermezaehlerEuroJahr, // NEU
    this.messpreisEichgebuehrenEuroJahr, // NEU
    this.waermeMesspreisEuroJahr,
    this.jahresarbeitszahl,
    this.anteilGaswaerme, // NEU
  });

  WaermekostenDaten copyWith({
    WertMitQuelle<double>? stromverbrauchKWh,
    WertMitQuelle<double>? waermeVerbrauchGasKWh,
    WertMitQuelle<double>? waermeVerbrauchStromKWh,
    WertMitQuelle<double>? stromarbeitspreisCtKWh,
    WertMitQuelle<double>? waermeGasArbeitspreisCtKWh,
    WertMitQuelle<double>? waermeStromArbeitspreisCtKWh,
    WertMitQuelle<double>? stromGrundpreisEuroMonat,
    WertMitQuelle<double>? waermeGrundpreisEuroJahr,
    WertMitQuelle<double>? messpreisWasserzaehlerEuroJahr, // NEU
    WertMitQuelle<double>? messpreisWaermezaehlerEuroJahr, // NEU
    WertMitQuelle<double>? messpreisEichgebuehrenEuroJahr, // NEU
    WertMitQuelle<double>? waermeMesspreisEuroJahr,
    WertMitQuelle<double>? jahresarbeitszahl,
    WertMitQuelle<double>? anteilGaswaerme, // NEU
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
      messpreisWasserzaehlerEuroJahr: messpreisWasserzaehlerEuroJahr ?? this.messpreisWasserzaehlerEuroJahr, // NEU
      messpreisWaermezaehlerEuroJahr: messpreisWaermezaehlerEuroJahr ?? this.messpreisWaermezaehlerEuroJahr, // NEU
      messpreisEichgebuehrenEuroJahr: messpreisEichgebuehrenEuroJahr ?? this.messpreisEichgebuehrenEuroJahr, // NEU

      waermeMesspreisEuroJahr: waermeMesspreisEuroJahr ?? this.waermeMesspreisEuroJahr,
      jahresarbeitszahl: jahresarbeitszahl ?? this.jahresarbeitszahl,
      anteilGaswaerme: anteilGaswaerme ?? this.anteilGaswaerme, // NEU
    );
  }

  factory WaermekostenDaten.fromMap(Map<String, dynamic> map) {
    return WaermekostenDaten(
      stromverbrauchKWh: map['stromverbrauchKWh'] != null
          ? WertMitQuelle.fromMap(
        map['stromverbrauchKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeVerbrauchGasKWh: map['waermeVerbrauchGasKWh'] != null
          ? WertMitQuelle.fromMap(
        map['waermeVerbrauchGasKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeVerbrauchStromKWh: map['waermeVerbrauchStromKWh'] != null
          ? WertMitQuelle.fromMap(
        map['waermeVerbrauchStromKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      stromarbeitspreisCtKWh: map['stromarbeitspreisCtKWh'] != null
          ? WertMitQuelle.fromMap(
        map['stromarbeitspreisCtKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeGasArbeitspreisCtKWh: map['waermeGasArbeitspreisCtKWh'] != null
          ? WertMitQuelle.fromMap(
        map['waermeGasArbeitspreisCtKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeStromArbeitspreisCtKWh: map['waermeStromArbeitspreisCtKWh'] != null
          ? WertMitQuelle.fromMap(
        map['waermeStromArbeitspreisCtKWh'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      stromGrundpreisEuroMonat: map['stromGrundpreisEuroMonat'] != null
          ? WertMitQuelle.fromMap(
        map['stromGrundpreisEuroMonat'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeGrundpreisEuroJahr: map['waermeGrundpreisEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['waermeGrundpreisEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,

      messpreisWasserzaehlerEuroJahr: map['messpreisWasserzaehlerEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['messpreisWasserzaehlerEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      messpreisWaermezaehlerEuroJahr: map['messpreisWaermezaehlerEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['messpreisWaermezaehlerEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      messpreisEichgebuehrenEuroJahr: map['messpreisEichgebuehrenEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['messpreisEichgebuehrenEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      waermeMesspreisEuroJahr: map['waermeMesspreisEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['waermeMesspreisEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,

      jahresarbeitszahl: map['jahresarbeitszahl'] != null
          ? WertMitQuelle.fromMap(
        map['jahresarbeitszahl'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      anteilGaswaerme: map['anteilGaswaerme'] != null // NEU
          ? WertMitQuelle.fromMap(
        map['anteilGaswaerme'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (stromverbrauchKWh != null) 'stromverbrauchKWh': stromverbrauchKWh!.toMap((v) => v),
      if (waermeVerbrauchGasKWh != null) 'waermeVerbrauchGasKWh': waermeVerbrauchGasKWh!.toMap((v) => v),
      if (waermeVerbrauchStromKWh != null) 'waermeVerbrauchStromKWh': waermeVerbrauchStromKWh!.toMap((v) => v),
      if (stromarbeitspreisCtKWh != null) 'stromarbeitspreisCtKWh': stromarbeitspreisCtKWh!.toMap((v) => v),
      if (waermeGasArbeitspreisCtKWh != null) 'waermeGasArbeitspreisCtKWh': waermeGasArbeitspreisCtKWh!.toMap((v) => v),
      if (waermeStromArbeitspreisCtKWh != null) 'waermeStromArbeitspreisCtKWh': waermeStromArbeitspreisCtKWh!.toMap((v) => v),
      if (stromGrundpreisEuroMonat != null) 'stromGrundpreisEuroMonat': stromGrundpreisEuroMonat!.toMap((v) => v),
      if (waermeGrundpreisEuroJahr != null) 'waermeGrundpreisEuroJahr': waermeGrundpreisEuroJahr!.toMap((v) => v),

      if (messpreisWasserzaehlerEuroJahr != null)
        'messpreisWasserzaehlerEuroJahr': messpreisWasserzaehlerEuroJahr!.toMap((v) => v),
      if (messpreisWaermezaehlerEuroJahr != null)
        'messpreisWaermezaehlerEuroJahr': messpreisWaermezaehlerEuroJahr!.toMap((v) => v),
      if (messpreisEichgebuehrenEuroJahr != null)
        'messpreisEichgebuehrenEuroJahr': messpreisEichgebuehrenEuroJahr!.toMap((v) => v),
      if (waermeMesspreisEuroJahr != null)
        'waermeMesspreisEuroJahr': waermeMesspreisEuroJahr!.toMap((v) => v),
      if (jahresarbeitszahl != null) 'jahresarbeitszahl': jahresarbeitszahl!.toMap((v) => v),
      if (anteilGaswaerme != null) 'anteilGaswaerme': anteilGaswaerme!.toMap((v) => v), // NEU
    };
  }
}

/// Nebenkosten mit Quellen
class NebenkostenDaten {
  final WertMitQuelle<double>? wartungEuroJahr;
  final WertMitQuelle<double>? grundpreisUebergabestationEuroJahr;

  const NebenkostenDaten({
    this.wartungEuroJahr,
    this.grundpreisUebergabestationEuroJahr,
  });

  factory NebenkostenDaten.fromMap(Map<String, dynamic> map) {
    return NebenkostenDaten(
      wartungEuroJahr: map['wartungEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['wartungEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
      grundpreisUebergabestationEuroJahr: map['grundpreisUebergabestationEuroJahr'] != null
          ? WertMitQuelle.fromMap(
        map['grundpreisUebergabestationEuroJahr'] as Map<String, dynamic>,
            (v) => (v as num).toDouble(),
      )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (wartungEuroJahr != null) 'wartungEuroJahr': wartungEuroJahr!.toMap((v) => v),
      if (grundpreisUebergabestationEuroJahr != null)
        'grundpreisUebergabestationEuroJahr': grundpreisUebergabestationEuroJahr!.toMap((v) => v),
    };
  }
}