// lib/services/arbeitspreis_alt_service.dart

import '../models/index_data.dart';
import '../models/arbeitspreis_alt_data.dart';

/// Service für alte Arbeitspreis-Berechnung (2024-2027)
///
/// Formel: AP = AP₀ × (0,40 × G/G₀ + 0,35 × GI/GI₀ + 0,25 × Z/Z₀)
/// Plus Emissionspreis: EP = (1 - Z) × Em × KCO₂ × F
class ArbeitspreisAltService {

  /// Berechne Arbeitspreis für ein Jahr
  /// Berechne Arbeitspreis für ein Jahr
  Future<ArbeitspreisAlt> berechneJahresArbeitspreis({
    required int jahr,
    required List<IndexData> gData,
    required List<IndexData> giData,
    required List<IndexData> zData,
    required List<IndexData> kco2Data,
  }) async {
    print('📊 [ARBEITSPREIS_ALT] === Berechne Jahr $jahr ===');

    final gJahr = _filterJahr(gData, jahr);
    final giJahr = _filterJahr(giData, jahr);
    final zJahr = _filterJahr(zData, jahr);
    final kco2Jahr = _filterJahr(kco2Data, jahr);

    // 🚨 WICHTIG: Prüfe ob überhaupt IRGENDWELCHE Daten für dieses Jahr existieren
    if (gJahr.isEmpty && giJahr.isEmpty && zJahr.isEmpty) {
      throw Exception('Keine Daten für Jahr $jahr verfügbar - Jahr wird übersprungen');
    }

    // Erstelle Monatsberechnungen - IMMER alle 12 Monate!
    final List<MonatsberechnungAlt> monate = [];

    // 🆕 Tracking für Vollständigkeit
    int vollstaendigeMonate = 0;
    int geschaetzteMonate = 0;

    print('📊 [ARBEITSPREIS_ALT] Prüfe Monate 1-12:');

    for (int monat = 1; monat <= 12; monat++) {
      // Versuche offizielle Werte zu finden
      final gWertOffiziell = _findeWert(gJahr, monat);
      final giWertOffiziell = _findeWert(giJahr, monat);
      final zWertOffiziell = _findeWert(zJahr, monat);
      final kco2WertOffiziell = _findeWert(kco2Jahr, monat);

      // ✅ KRITISCH: Prüfe ob dieser Monat vollständig ist
      final istMonatVollstaendig = gWertOffiziell != null &&
          giWertOffiziell != null &&
          zWertOffiziell != null;

      if (istMonatVollstaendig) {
        vollstaendigeMonate++;

        // ✅ Verwende offizielle Werte
        monate.add(MonatsberechnungAlt(
          monat: DateTime(jahr, monat),
          gWert: gWertOffiziell,
          giWert: giWertOffiziell,
          zWert: zWertOffiziell,
          promille: ArbeitspreisAltKonstanten.getPromille(monat),
          kco2Wert: kco2WertOffiziell,
        ));

        print('   ✓ Monat $monat: G=${gWertOffiziell!.toStringAsFixed(1)}, '
            'GI=${giWertOffiziell!.toStringAsFixed(1)}, '
            'Z=${zWertOffiziell!.toStringAsFixed(1)} - OFFIZIELL');

      } else {
        geschaetzteMonate++;

        // ⚠️ SCHÄTZUNG: Fülle mit letztem bekannten Wert
        final gWert = gWertOffiziell ?? _findeLetztenBekanntenWert(gJahr, monat) ?? 100.0;
        final giWert = giWertOffiziell ?? _findeLetztenBekanntenWert(giJahr, monat) ?? 100.0;
        final zWert = zWertOffiziell ?? _findeLetztenBekanntenWert(zJahr, monat) ?? 100.0;
        final kco2Wert = kco2WertOffiziell ?? _findeLetztenBekanntenWert(kco2Jahr, monat) ?? 70.0;

        // ⚠️ Wichtig: Setze offizielle Werte auf NULL damit erkennbar ist, dass geschätzt!
        monate.add(MonatsberechnungAlt(
          monat: DateTime(jahr, monat),
          gWert: gWertOffiziell,  // NULL wenn nicht vorhanden!
          giWert: giWertOffiziell, // NULL wenn nicht vorhanden!
          zWert: zWertOffiziell,   // NULL wenn nicht vorhanden!
          promille: ArbeitspreisAltKonstanten.getPromille(monat),
          kco2Wert: kco2WertOffiziell,
        ));

        print('   ⚠️ Monat $monat: GESCHÄTZT (G=${gWert.toStringAsFixed(1)}, '
            'GI=${giWert.toStringAsFixed(1)}, Z=${zWert.toStringAsFixed(1)})');
      }
    }

    // ✅ NACH der Schleife: Prüfe ob wir 12 Monate haben
    if (monate.length != 12) {
      throw Exception('FEHLER: Nur ${monate.length} Monate für $jahr - es müssen 12 sein!');
    }

    print('📊 [ARBEITSPREIS_ALT] $vollstaendigeMonate vollständige, $geschaetzteMonate geschätzte Monate');

    // ⚠️ Berechnung MIT geschätzten Werten
    double gSummeRoh = 0;
    double giSummeRoh = 0;
    double zSummeRoh = 0;

    for (int i = 0; i < monate.length; i++) {
      final monat = monate[i];
      final monatNr = i + 1;

      // Hole Werte: offiziell ODER geschätzt
      final gWert = monat.gWert ?? _findeLetztenBekanntenWert(gJahr, monatNr) ?? 100.0;
      final giWert = monat.giWert ?? _findeLetztenBekanntenWert(giJahr, monatNr) ?? 100.0;
      final zWert = monat.zWert ?? _findeLetztenBekanntenWert(zJahr, monatNr) ?? 100.0;

      gSummeRoh += gWert * monat.promille;
      giSummeRoh += giWert * monat.promille;
      zSummeRoh += zWert * monat.promille;
    }

    print('📊 [ARBEITSPREIS_ALT] Summen VOR Division:');
    print('   G:  ${gSummeRoh.toStringAsFixed(3)}');
    print('   GI: ${giSummeRoh.toStringAsFixed(3)}');
    print('   Z:  ${zSummeRoh.toStringAsFixed(3)}');

    // ========================================
    // Rest der Berechnung bleibt gleich...
    // ========================================

    final gSumme = ArbeitspreisAltKonstanten.runde1(gSummeRoh / 1000);
    final giSumme = ArbeitspreisAltKonstanten.runde1(giSummeRoh / 1000);
    final zSumme = ArbeitspreisAltKonstanten.runde1(zSummeRoh / 1000);

    print('📊 [ARBEITSPREIS_ALT] Summen NACH Division (auf 1 NK gerundet):');
    print('   G:  ${gSumme.toStringAsFixed(1)}');
    print('   GI: ${giSumme.toStringAsFixed(1)}');
    print('   Z:  ${zSumme.toStringAsFixed(1)}');

    final gFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtG * (gSumme / ArbeitspreisAltKonstanten.g0)
    );
    final giFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtGI * (giSumme / ArbeitspreisAltKonstanten.gi0)
    );
    final zFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtZ * (zSumme / ArbeitspreisAltKonstanten.z0)
    );

    print('📊 [ARBEITSPREIS_ALT] Gewichtete Faktoren (auf 4 NK gerundet):');
    print('   0,40 × (${gSumme.toStringAsFixed(1)} / ${ArbeitspreisAltKonstanten.g0}) = ${gFaktor.toStringAsFixed(4)}');
    print('   0,35 × (${giSumme.toStringAsFixed(1)} / ${ArbeitspreisAltKonstanten.gi0}) = ${giFaktor.toStringAsFixed(4)}');
    print('   0,25 × (${zSumme.toStringAsFixed(1)} / ${ArbeitspreisAltKonstanten.z0}) = ${zFaktor.toStringAsFixed(4)}');

    final aenderungsfaktor = gFaktor + giFaktor + zFaktor;

    print('📊 [ARBEITSPREIS_ALT] Änderungsfaktor:');
    print('   ${gFaktor.toStringAsFixed(4)} + ${giFaktor.toStringAsFixed(4)} + ${zFaktor.toStringAsFixed(4)} = ${aenderungsfaktor.toStringAsFixed(4)}');

    final arbeitspreisOhneEmission = ArbeitspreisAltKonstanten.ap0 * aenderungsfaktor;

    print('📊 [ARBEITSPREIS_ALT] Arbeitspreis (ohne Emission):');
    print('   ${ArbeitspreisAltKonstanten.ap0.toStringAsFixed(4)} × ${aenderungsfaktor.toStringAsFixed(4)} = ${arbeitspreisOhneEmission.toStringAsFixed(4)} ct/kWh');

    // Emissionspreis
    double emissionspreis = 0;
    final List<double> kco2Werte = [];

    for (int i = 0; i < monate.length; i++) {
      final monat = monate[i];
      final monatNr = i + 1;
      final kco2Wert = monat.kco2Wert ?? _findeLetztenBekanntenWert(kco2Jahr, monatNr) ?? 70.0;
      kco2Werte.add(kco2Wert);
    }

    if (kco2Werte.isNotEmpty) {
      final kco2Mittel = kco2Werte.fold<double>(0, (sum, w) => sum + w) / kco2Werte.length;

      emissionspreis = ArbeitspreisAltKonstanten.berechneEmissionspreis(
        jahr: jahr,
        kco2Mittelwert: kco2Mittel,
      );

      print('📊 [ARBEITSPREIS_ALT] Emissionspreis:');
      print('   ECarbiX Ø: ${kco2Mittel.toStringAsFixed(2)} €/t');
      print('   Z (Abschmelzung): ${ArbeitspreisAltKonstanten.getAbschmelzungsfaktor(jahr)}');
      print('   EP: ${emissionspreis.toStringAsFixed(4)} ct/kWh');
    }

    final arbeitspreisGesamt = arbeitspreisOhneEmission + emissionspreis;

    // 🆕 Bestimme ob Daten vollständig sind
    final hatVollstaendigeDaten = geschaetzteMonate == 0;

    if (!hatVollstaendigeDaten) {
      print('⚠️ [ARBEITSPREIS_ALT] WARNUNG: $geschaetzteMonate Monate wurden geschätzt!');
      print('⚠️ [ARBEITSPREIS_ALT] Dieser Wert ist NICHT OFFIZIELL!');
    }

    print('📊 [ARBEITSPREIS_ALT] Arbeitspreis GESAMT:');
    print('   ${arbeitspreisOhneEmission.toStringAsFixed(4)} + ${emissionspreis.toStringAsFixed(4)} = ${arbeitspreisGesamt.toStringAsFixed(4)} ct/kWh');
    print('📊 [ARBEITSPREIS_ALT] === Ende $jahr ===\n');

    return ArbeitspreisAlt(
      jahr: jahr,
      arbeitspreisOhneEmission: arbeitspreisOhneEmission,
      emissionspreis: emissionspreis,
      arbeitspreisGesamt: arbeitspreisGesamt,
      monate: monate,
      gFaktor: gFaktor,
      giFaktor: giFaktor,
      zFaktor: zFaktor,
      gSumme: gSumme,
      giSumme: giSumme,
      zSumme: zSumme,
      aenderungsfaktor: aenderungsfaktor,
      hatVollstaendigeDaten: hatVollstaendigeDaten,
      vollstaendigeMonate: vollstaendigeMonate,
      geschaetzteMonate: geschaetzteMonate,
    );
  }

  /// 🆕 Finde letzten bekannten Wert für einen Index
  double? _findeLetztenBekanntenWert(List<IndexData> data, int aktuellerMonat) {
    // Suche rückwärts nach letztem bekannten Monat
    for (int m = aktuellerMonat - 1; m >= 1; m--) {
      final wert = _findeWert(data, m);
      if (wert != null) {
        return wert;
      }
    }

    // Falls nichts gefunden: Nehme ersten verfügbaren Wert
    if (data.isNotEmpty) {
      return data.first.value;
    }

    return null;
  }

  /// Berechne alle Jahre (2024-2027)
  Future<List<ArbeitspreisAlt>> berechneAlleJahre({
    required List<IndexData> gData,
    required List<IndexData> giData,
    required List<IndexData> zData,
    required List<IndexData> kco2Data,
  }) async {
    print('📊 [ARBEITSPREIS_ALT] Berechne alle Jahre 2024-2027\n');

    final List<ArbeitspreisAlt> jahre = [];

    for (int jahr = 2024; jahr <= 2027; jahr++) {
      try {
        final jahresPreis = await berechneJahresArbeitspreis(
          jahr: jahr,
          gData: gData,
          giData: giData,
          zData: zData,
          kco2Data: kco2Data,
        );
        jahre.add(jahresPreis);
      } catch (e) {
        print('⚠️ [ARBEITSPREIS_ALT] Jahr $jahr: $e\n');
      }
    }

    print('📊 [ARBEITSPREIS_ALT] ${jahre.length} Jahre berechnet\n');
    return jahre;
  }

  /// Erstelle Übersicht
  List<JahresUebersichtAlt> erstelleUebersicht(List<ArbeitspreisAlt> jahre) {
    final List<JahresUebersichtAlt> uebersicht = [];

    for (int i = 0; i < jahre.length; i++) {
      final jahr = jahre[i];

      double? aenderungProzent;
      double? aenderungAbsolut;

      if (i > 0) {
        final vorjahr = jahre[i - 1];
        aenderungAbsolut = jahr.arbeitspreisGesamt - vorjahr.arbeitspreisGesamt;
        aenderungProzent = (aenderungAbsolut / vorjahr.arbeitspreisGesamt) * 100;
      }

      uebersicht.add(JahresUebersichtAlt(
        jahr: jahr.jahr,
        arbeitspreisOhneEmission: jahr.arbeitspreisOhneEmission,
        emissionspreis: jahr.emissionspreis,
        arbeitspreisGesamt: jahr.arbeitspreisGesamt,
        gSumme: jahr.gSumme,
        giSumme: jahr.giSumme,
        zSumme: jahr.zSumme,
        gFaktor: jahr.gFaktor,
        giFaktor: jahr.giFaktor,
        zFaktor: jahr.zFaktor,
        aenderungsfaktor: jahr.aenderungsfaktor,
        aenderungProzent: aenderungProzent,
        aenderungAbsolut: aenderungAbsolut,
        hatVollstaendigeDaten: jahr.hatVollstaendigeDaten, // 🆕
      ));
    }

    return uebersicht;
  }

  List<IndexData> _filterJahr(List<IndexData> data, int jahr) {
    return data.where((d) => d.date.year == jahr).toList();
  }

  double? _findeWert(List<IndexData> data, int monat) {
    try {
      return data.firstWhere((d) => d.date.month == monat).value;
    } catch (e) {
      return null;
    }
  }
}