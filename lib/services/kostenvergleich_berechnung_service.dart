// lib/services/kostenvergleich_berechnung_service.dart

import 'dart:math' as math;
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';
import '../models/szenario_rechner_eingabe.dart';

class KostenvergleichBerechnungService {

  /// Berechne Kostenvergleich für alle Szenarien
  KostenvergleichErgebnis berechneVergleich({
    required KostenvergleichJahr stammdaten,
    SzenarioRechnerEingabe? benutzerEingabe,
  }) {
    final ergebnisse = <KostenberechnungErgebnis>[];

    // Sortiere Szenarien nach sortierung
    final sortedSzenarien = stammdaten.szenarien.values.toList()
      ..sort((a, b) => a.sortierung.compareTo(b.sortierung));

    for (final szenario in sortedSzenarien) {
      final ergebnis = berechneSzenario(
        stammdaten: stammdaten,
        szenario: szenario,
        benutzerEingabe: benutzerEingabe,
      );
      ergebnisse.add(ergebnis);
    }

    return KostenvergleichErgebnis.erstellen(
      jahr: stammdaten.jahr,
      szenarien: ergebnisse,
    );
  }

  /// Berechne ein einzelnes Szenario
  KostenberechnungErgebnis berechneSzenario({
    required KostenvergleichJahr stammdaten,
    required SzenarioStammdaten szenario,
    SzenarioRechnerEingabe? benutzerEingabe,
  }) {
    // Verwende User-Eingaben oder Stammdaten
    final useUserInput = benutzerEingabe != null;

    // 1. Wärmebedarf
    final waermebedarf = useUserInput
        ? benutzerEingabe.waermebedarf
        : stammdaten.grunddaten.heizenergiebedarf;

    final beheizteFlaeche = stammdaten.grunddaten.beheizteFlaeche;

    // 2. Berechne Wärmekosten (C)
    final waermekosten = _berechneWaermekosten(
      szenario: szenario,
      waermebedarf: waermebedarf,
      stammdaten: stammdaten,
      benutzerEingabe: benutzerEingabe,
    );

    // 3. Berechne Nebenkosten (D)
    final nebenkosten = _berechneNebenkosten(
      szenario: szenario,
      stammdaten: stammdaten,
    );

    // 4. Berechne Investitionskosten mit/ohne Förderung
    final investitionBrutto = szenario.investition.gesamtBrutto;

    // User-Anpassung der Investitionskosten?
    final investitionAngepasst = useUserInput &&
        benutzerEingabe.eigenInvestitionskostenNutzen &&
        benutzerEingabe.investitionskostenAnpassungProzent != null
        ? investitionBrutto *
        (1 + (benutzerEingabe.investitionskostenAnpassungProzent! / 100))
        : investitionBrutto;

    // Förderung berücksichtigen?
    final foerderungAktiv = !useUserInput || benutzerEingabe.foerderungBeruecksichtigen;

    final foerderbetrag = foerderungAktiv
        ? investitionAngepasst * szenario.investition.foerderquote
        : 0.0;

    final investitionNetto = investitionAngepasst - foerderbetrag;

    // 5. Kapitaldienst berechnen
    final kapitaldienst = _berechneKapitaldienst(
      investition: investitionNetto,
      zinssatz: stammdaten.finanzierung.zinssatz,
      laufzeit: stammdaten.finanzierung.laufzeitJahre,
    );

    final kapitaldienstOhneFoerderung = _berechneKapitaldienst(
      investition: investitionAngepasst,
      zinssatz: stammdaten.finanzierung.zinssatz,
      laufzeit: stammdaten.finanzierung.laufzeitJahre,
    );

    final zusaetzlicherKapitaldienst = kapitaldienstOhneFoerderung - kapitaldienst;

    // 6. Kostenaufschlüsselung erstellen
    final kostenAufschluesselung = KostenAufschluesselung(
      arbeitspreis: waermekosten['arbeitspreis']!,
      grundUndMesspreis: waermekosten['grundpreis']!,
      betriebskosten: nebenkosten['wartung']!,
      kapitalkosten: kapitaldienst,
      kapitalkostenOhneFoerderung: kapitaldienstOhneFoerderung,
      zusaetzlicheKapitalkostenOhneFoerderung: zusaetzlicherKapitaldienst,
      zusaetzlicherGrundpreisUebergabestation: nebenkosten['grundpreisUGS']!,
    );

    // 7. Ergebnis erstellen
    return KostenberechnungErgebnis.berechnen(
      szenarioId: szenario.id,
      szenarioBezeichnung: szenario.bezeichnung,
      waermebedarf: waermebedarf,
      beheizteFlaeche: beheizteFlaeche,
      kosten: kostenAufschluesselung,
    );
  }

  /// Berechne Wärmekosten (Abschnitt C)
  Map<String, double> _berechneWaermekosten({
    required SzenarioStammdaten szenario,
    required double waermebedarf,
    required KostenvergleichJahr stammdaten,
    SzenarioRechnerEingabe? benutzerEingabe,
  }) {
    double arbeitspreis = 0;
    double grundpreis = 0;

    if (szenario.id == 'waermepumpe') {
      // === WÄRMEPUMPE ===

      // JAZ
      final jaz = benutzerEingabe?.jahresarbeitszahl ??
          szenario.waermekosten.jahresarbeitszahl ??
          3.0;

      // Stromverbrauch = Wärmebedarf / JAZ
      final stromverbrauch = waermebedarf / jaz;

      // Stromarbeitspreis
      final strompreisCtKWh = benutzerEingabe?.stromarbeitspreisCtKWh ??
          szenario.waermekosten.stromarbeitspreisCtKWh ??
          16.52;

      arbeitspreis = (stromverbrauch * strompreisCtKWh) / 100; // ct → €

      // Grundpreis
      final stromGrundpreisMonat = benutzerEingabe?.stromGrundpreisEuroMonat ??
          szenario.waermekosten.stromGrundpreisEuroMonat ??
          9.0;

      grundpreis = stromGrundpreisMonat * 12; // Monat → Jahr

    } else {
      // === WÄRMENETZ ===

      // Anteil Wärme aus Strom
      final anteilStrom = benutzerEingabe?.anteilWaermeAusStrom ?? 0.30;
      final anteilGas = 1.0 - anteilStrom;

      // Verbrauch aufteilen
      final waermeGasKWh = waermebedarf * anteilGas;
      final waermeStromKWh = waermebedarf * anteilStrom;

      // Arbeitspreise
      final gasPreisCtKWh = szenario.waermekosten.waermeGasArbeitspreisCtKWh ?? 0;
      final stromPreisCtKWh = szenario.waermekosten.waermeStromArbeitspreisCtKWh ?? 0;

      arbeitspreis = ((waermeGasKWh * gasPreisCtKWh) +
          (waermeStromKWh * stromPreisCtKWh)) /
          100; // ct → €

      // Grund- und Messpreis
      final waermeGrundpreis = szenario.waermekosten.waermeGrundpreisEuroJahr ?? 0;
      final waermeMesspreis = szenario.waermekosten.waermeMesspreisEuroJahr ?? 0;

      grundpreis = waermeGrundpreis + waermeMesspreis;
    }

    return {
      'arbeitspreis': arbeitspreis,
      'grundpreis': grundpreis,
    };
  }

  /// Berechne Nebenkosten (Abschnitt D)
  Map<String, double> _berechneNebenkosten({
    required SzenarioStammdaten szenario,
    required KostenvergleichJahr stammdaten,
  }) {
    final wartung = szenario.nebenkosten.wartungEuroJahr ?? 0.0;
    final grundpreisUGS =
        szenario.nebenkosten.grundpreisUebergabestationEuroJahr ?? 0.0;

    return {
      'wartung': wartung,
      'grundpreisUGS': grundpreisUGS,
    };
  }

  /// Berechne Kapitaldienst (Annuitätenmethode)
  ///
  /// Formel: A = K × (q^n × (q-1)) / (q^n - 1)
  /// A = Annuität (jährlicher Kapitaldienst)
  /// K = Kapital (Investitionssumme)
  /// q = 1 + (Zinssatz / 100)
  /// n = Laufzeit in Jahren
  double _berechneKapitaldienst({
    required double investition,
    required double zinssatz,
    required int laufzeit,
  }) {
    if (investition <= 0) return 0.0;

    final q = 1 + (zinssatz / 100);
    final qHochN = math.pow(q, laufzeit);

    final annuitaet = investition * (qHochN * (q - 1)) / (qHochN - 1);

    return annuitaet;
  }

  /// Hilfsfunktion: Berechne Stromverbrauch für Wärmepumpe
  double berechneStromverbrauchWP({
    required double waermebedarf,
    required double jaz,
  }) {
    return waermebedarf / jaz;
  }

  /// Hilfsfunktion: Berechne benötigte Fläche für Wärmebedarf
  double berechneFlaecheAusWaermebedarf({
    required double waermebedarf,
    required double spezHeizenergiebedarf,
  }) {
    return waermebedarf / spezHeizenergiebedarf;
  }
}