// lib/services/kostenvergleich_setup_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kostenvergleich_data.dart';
import 'kostenvergleich_firebase_service.dart';

class KostenvergleichSetupService {
  final KostenvergleichFirebaseService _firebaseService =
  KostenvergleichFirebaseService();

  /// Prüfe ob Setup nötig ist und führe es aus
  Future<bool> pruefeUndErstelleInitialDaten() async {
    try {
      print('📊 [SETUP] Prüfe ob Kostenvergleich-Daten vorhanden...');

      // Prüfe ob schon Jahre vorhanden
      final verfuegbareJahre = await _firebaseService.ladeVerfuegbareJahre();

      if (verfuegbareJahre.isNotEmpty) {
        print('✅ [SETUP] Daten bereits vorhanden (${verfuegbareJahre.length} Jahre)');
        return false; // Kein Setup nötig
      }

      print('📝 [SETUP] Keine Daten gefunden - erstelle Initial-Setup für 2025...');

      // Erstelle 2025 Daten
      await _erstelle2025Daten();

      print('✅ [SETUP] Initial-Setup erfolgreich abgeschlossen!');
      return true;
    } catch (e) {
      print('❌ [SETUP] Fehler beim Setup: $e');
      return false;
    }
  }

  Future<void> _erstelle2025Daten() async {
    final jahr2025 = KostenvergleichJahr(
      id: '2025',
      jahr: 2025,
      gueltigAb: DateTime(2025, 1, 1),
      gueltigBis: DateTime(2025, 12, 31),
      erstelltAm: DateTime.now(),
      istAktiv: true,
      status: 'aktiv',
      grunddaten: const GrunddatenKostenvergleich(
        beheizteFlaeche: 119.24,
        spezHeizenergiebedarf: 96.0,
        heizenergiebedarf: 11500.0,
      ),
      finanzierung: const FinanzierungsDaten(
        zinssatz: 3.546,
        laufzeitJahre: 20,
        foerderungBEG: 0.30, // 30%
        foerderungBEW: 0.30, // 30%
      ),
      szenarien: {
        'waermepumpe': _erstelleWaermepumpeSzenario(),
        'waermenetzOhneUGS': _erstelleWaermenetzOhneUGS(),
        'waermenetzKunde': _erstelleWaermenetzKunde(),
        'waermenetzSuewag': _erstelleWaermenetzSuewag(),
      },
    );

    // Speichere in Firebase
    await _firebaseService.speichereStammdaten(jahr2025);

    // Setze als aktives Jahr
    await _firebaseService.setzeAktivesJahr(2025);

    print('✅ [SETUP] Jahr 2025 erstellt und aktiviert');
  }

  /// Wärmepumpe Szenario
  SzenarioStammdaten _erstelleWaermepumpeSzenario() {
    const gesamtBrutto = 29200.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote; // 8760 €
    const netto = gesamtBrutto - foerderbetrag; // 20440 €

    return SzenarioStammdaten(
      id: 'waermepumpe',
      bezeichnung: 'Wärmepumpe',
      beschreibung: 'Luft/Wasser-Wärmepumpe 10 kW mit TWW-Speicher, Vorlauf 55°C',
      typ: SzenarioTyp.dezentral,
      sortierung: 1,
      investition: InvestitionskostenDaten(
        positionen: const [
          InvestitionsPosition(
            bezeichnung: 'Luft-Wasser-Wärmepumpe, JAZ 3, Q = 10 kW, 55/45°C',
            betrag: 29200.0,
          ),
        ],
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.beg,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: const WaermekostenDaten(
        stromverbrauchKWh: 3833.0, // 11500 / 3.0 JAZ
        jahresarbeitszahl: 3.0,
        stromarbeitspreisCtKWh: 16.52,
        stromGrundpreisEuroMonat: 9.0,
      ),
      nebenkosten: const NebenkostenDaten(
        wartungEuroJahr: 490.0,
      ),
    );
  }

  /// Wärmenetz ohne Übergabestation
  SzenarioStammdaten _erstelleWaermenetzOhneUGS() {
    return const SzenarioStammdaten(
      id: 'waermenetzOhneUGS',
      bezeichnung: 'Wärmenetz ohne Übergabestation',
      beschreibung: 'Bestandsvertrag ohne Anpassungen, Vorlauf 70°C',
      typ: SzenarioTyp.zentral,
      sortierung: 2,
      investition: InvestitionskostenDaten(
        positionen: [],
        gesamtBrutto: 0.0,
        foerderungsTyp: FoerderungsTyp.keine,
        foerderquote: 0.0,
        foerderbetrag: 0.0,
        nettoNachFoerderung: 0.0,
      ),
      waermekosten: WaermekostenDaten(
        waermeVerbrauchGasKWh: 8050.0, // 70% aus Gas
        waermeVerbrauchStromKWh: 3450.0, // 30% aus Strom
        waermeGasArbeitspreisCtKWh: 11.68,
        waermeStromArbeitspreisCtKWh: 8.52,
        waermeGrundpreisEuroJahr: 471.0,
        waermeMesspreisEuroJahr: 109.55,
      ),
      nebenkosten: NebenkostenDaten(
        wartungEuroJahr: 50.0,
      ),
    );
  }

  /// Wärmenetz Station Kunde
  SzenarioStammdaten _erstelleWaermenetzKunde() {
    const gesamtBrutto = 10950.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote; // 3285 €
    const netto = gesamtBrutto - foerderbetrag; // 7665 €

    return SzenarioStammdaten(
      id: 'waermenetzKunde',
      bezeichnung: 'Wärmenetz - Station Kunde',
      beschreibung:
      'Übergabestation 10 kW TWW-Speicher, Vorlauf 70°C, 30% Abwärme aus RZ, BEG Förderung',
      typ: SzenarioTyp.zentral,
      sortierung: 3,
      investition: InvestitionskostenDaten(
        positionen: const [
          InvestitionsPosition(
            bezeichnung: 'Übergabestation EFH',
            betrag: 10950.0,
          ),
        ],
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.beg,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: const WaermekostenDaten(
        waermeVerbrauchGasKWh: 8050.0,
        waermeVerbrauchStromKWh: 3450.0,
        waermeGasArbeitspreisCtKWh: 11.68,
        waermeStromArbeitspreisCtKWh: 8.52,
        waermeGrundpreisEuroJahr: 396.0,
        waermeMesspreisEuroJahr: 64.20,
      ),
      nebenkosten: const NebenkostenDaten(
        wartungEuroJahr: 100.0,
      ),
    );
  }

  /// Wärmenetz Station Süwag
  SzenarioStammdaten _erstelleWaermenetzSuewag() {
    const gesamtBrutto = 8900.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote; // 2670 €
    const netto = gesamtBrutto - foerderbetrag; // 6230 €

    return SzenarioStammdaten(
      id: 'waermenetzSuewag',
      bezeichnung: 'Wärmenetz - Station Süwag',
      beschreibung:
      'Übergabestation 10 kW TWW-Speicher, Vorlauf 70°C, 30% Abwärme aus RZ, BEW Förderung',
      typ: SzenarioTyp.zentral,
      sortierung: 4,
      investition: InvestitionskostenDaten(
        positionen: const [
          InvestitionsPosition(
            bezeichnung: 'Übergabestation EFH (Süwag)',
            betrag: 8900.0,
            bemerkung: 'Süwag stellt Übergabestation',
          ),
        ],
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.bew,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: const WaermekostenDaten(
        waermeVerbrauchGasKWh: 8050.0,
        waermeVerbrauchStromKWh: 3450.0,
        waermeGasArbeitspreisCtKWh: 11.68,
        waermeStromArbeitspreisCtKWh: 8.52,
        waermeGrundpreisEuroJahr: 396.0,
        waermeMesspreisEuroJahr: 64.20,
      ),
      nebenkosten: const NebenkostenDaten(
        wartungEuroJahr: 0.0, // Keine Wartung - Süwag übernimmt
        grundpreisUebergabestationEuroJahr: 150.0, // Zusätzlicher Grundpreis
      ),
    );
  }
}