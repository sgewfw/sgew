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

  /// Berechne alle Jahreskosten (Helper für Edit-Widget)
  List<KostenberechnungErgebnis> berechneAlleJahreskosten(KostenvergleichJahr stammdaten) {
    final ergebnisse = <KostenberechnungErgebnis>[];

    // Sortiere Szenarien nach sortierung
    final sortedSzenarien = stammdaten.szenarien.values.toList()
      ..sort((a, b) => a.sortierung.compareTo(b.sortierung));

    for (final szenario in sortedSzenarien) {
      final ergebnis = berechneSzenario(
        stammdaten: stammdaten,
        szenario: szenario,
      );
      ergebnisse.add(ergebnis);
    }

    return ergebnisse;
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
        : stammdaten.grunddaten.heizenergiebedarf.wert;

    final beheizteFlaeche = stammdaten.grunddaten.beheizteFlaeche.wert;

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
      zinssatz: stammdaten.finanzierung.zinssatz.wert,
      laufzeit: stammdaten.finanzierung.laufzeitJahre.wert,
    );

    final kapitaldienstOhneFoerderung = _berechneKapitaldienst(
      investition: investitionAngepasst,
      zinssatz: stammdaten.finanzierung.zinssatz.wert,
      laufzeit: stammdaten.finanzierung.laufzeitJahre.wert,
    );

    final zusaetzlicherKapitaldienst = kapitaldienstOhneFoerderung - kapitaldienst;

// Für "Netz Kunde" keine zusätzlichen Kapitalkosten anzeigen
// (Förderung ist Standard, daher nicht als "Extra" darstellen)
    final zusaetzlicherKapitaldienstAnzeige = (szenario.id == 'waermenetzKunde')
        ? 0.0
        : zusaetzlicherKapitaldienst;

// 6. Kostenaufschlüsselung erstellen
    final kostenAufschluesselung = KostenAufschluesselung(
      arbeitspreis: waermekosten['arbeitspreis']!,
      grundUndMesspreis: waermekosten['grundpreis']!,
      betriebskosten: nebenkosten['wartung']!,
      kapitalkosten: kapitaldienst,
      kapitalkostenOhneFoerderung: kapitaldienstOhneFoerderung,
      zusaetzlicheKapitalkostenOhneFoerderung: zusaetzlicherKapitaldienstAnzeige,
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
// In kostenvergleich_berechnung_service.dart - _berechneWaermekosten Methode

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
          szenario.waermekosten.jahresarbeitszahl?.wert ??
          3.0;

      // Stromverbrauch = Wärmebedarf / JAZ
      final stromverbrauch = waermebedarf / jaz;

      // Stromarbeitspreis
      final strompreisCtKWh = benutzerEingabe?.stromarbeitspreisCtKWh ??
          szenario.waermekosten.stromarbeitspreisCtKWh?.wert ??
          16.52;

      arbeitspreis = (stromverbrauch * strompreisCtKWh) / 100; // ct → €

      // Grundpreis
      final stromGrundpreisMonat = benutzerEingabe?.stromGrundpreisEuroMonat ??
          szenario.waermekosten.stromGrundpreisEuroMonat?.wert ??
          9.0;

      grundpreis = stromGrundpreisMonat * 12; // Monat → Jahr

    } else {
      // === WÄRMENETZ ===


      // Anteil Wärme aus Gas (aus Grunddaten oder Benutzer-Eingabe)
      final anteilStrom = benutzerEingabe?.anteilWaermeAusStrom ??
          (1.0 - (stammdaten.grunddaten.anteilGaswaerme?.wert ?? 0.7));
      final anteilGas = 1.0 - anteilStrom;

      // Verbrauch aufteilen
      final waermeGasKWh = waermebedarf * anteilGas;
      final waermeStromKWh = waermebedarf * anteilStrom;

      // Arbeitspreise
      // Arbeitspreise - NEU: Nutze Benutzer-Eingaben falls vorhanden
      final gasPreisCtKWh = benutzerEingabe?.waermeGasArbeitspreisCtKWh ??
          szenario.waermekosten.waermeGasArbeitspreisCtKWh?.wert ?? 0;
      final stromPreisCtKWh = benutzerEingabe?.waermeStromArbeitspreisCtKWh ??
          szenario.waermekosten.waermeStromArbeitspreisCtKWh?.wert ?? 0;
      arbeitspreis = ((waermeGasKWh * gasPreisCtKWh) +
          (waermeStromKWh * stromPreisCtKWh)) /
          100; // ct → €

      // Grund- und Messpreis - NEU: Verwende die drei Komponenten
      final waermeGrundpreis = szenario.waermekosten.waermeGrundpreisEuroJahr?.wert ?? 0;

      // Messpreise - neue Struktur
      final messpreisWasser = szenario.waermekosten.messpreisWasserzaehlerEuroJahr?.wert ?? 0;
      final messpreisWaerme = szenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0;
      final messpreisEich = szenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0;

      // Fallback auf altes Feld falls neue Felder nicht gesetzt
      final messpreisAlt = szenario.waermekosten.waermeMesspreisEuroJahr?.wert ?? 0;

      // Summiere neue Felder, oder nutze altes Feld als Fallback
      final messpreisGesamt = (messpreisWasser + messpreisWaerme + messpreisEich > 0)
          ? (messpreisWasser + messpreisWaerme + messpreisEich)
          : messpreisAlt;

      grundpreis = waermeGrundpreis + messpreisGesamt;
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
    final wartung = szenario.nebenkosten.wartungEuroJahr?.wert ?? 0.0;
    final grundpreisUGS =
        szenario.nebenkosten.grundpreisUebergabestationEuroJahr?.wert ?? 0.0;

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

    final annuitaetNachschuessig = investition * (qHochN * (q - 1)) / (qHochN - 1);

    // Umrechnung auf vorschüssig (Typ 1 = Zahlung am Jahresanfang)
    final annuitaetVorschuessig = annuitaetNachschuessig / q;

    return annuitaetVorschuessig;
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