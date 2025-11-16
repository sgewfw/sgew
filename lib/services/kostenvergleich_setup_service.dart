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
        return false;
      }

      print('🔨 [SETUP] Keine Daten gefunden - erstelle Initial-Setup für 2025...');

      await _erstelle2025Daten();

      print('✅ [SETUP] Initial-Setup erfolgreich abgeschlossen!');
      return true;
    } catch (e) {
      print('❌ [SETUP] Fehler beim Setup: $e');
      return false;
    }
  }

  Future<void> _erstelle2025Daten() async {
    print("hlloo");
    final jahr2025 = KostenvergleichJahr(
      id: '2025',
      jahr: 2025,
      gueltigAb: DateTime(2025, 1, 1),
      gueltigBis: DateTime(2025, 12, 31),
      erstelltAm: DateTime.now(),
      istAktiv: true,
      status: 'aktiv',
      grunddaten: _erstelleGrunddaten(),
      finanzierung: _erstelleFinanzierung(),
      szenarien: {
        'waermepumpe': _erstelleWaermepumpeSzenario(),
        'waermenetzOhneUGS': _erstelleWaermenetzOhneUGS(),
        'waermenetzKunde': _erstelleWaermenetzKunde(),
        'waermenetzSuewag': _erstelleWaermenetzSuewag(),
      },
    );

    await _firebaseService.speichereStammdaten(jahr2025);
    await _firebaseService.setzeAktivesJahr(2025);

    print('✅ [SETUP] Jahr 2025 erstellt und aktiviert');
  }

  // ========================================
  // GRUNDDATEN
  // ========================================

  GrunddatenKostenvergleich _erstelleGrunddaten() {
    return GrunddatenKostenvergleich(
      beheizteFlaeche: WertMitQuelle(
        wert: 119.24,
        quelle: QuellenInfo(
          titel: 'Beheizte Fläche',
          beschreibung: 'Standardhaus Schwalbach',
          link: '',
        ),
      ),
      spezHeizenergiebedarf: WertMitQuelle(
        wert: 96.0,
        quelle: QuellenInfo(
          titel: 'Spezifischer Heizenergiebedarf',
          beschreibung: 'Technikkatalog Bund 10.2025, Tabelle 50, Gebäude EFH, Baujahr \'69-\'78, 96 kWh/m²',
          link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
        ),
      ),
      heizenergiebedarf: WertMitQuelle(
        wert: 11500.0,
        quelle: QuellenInfo(
          titel: 'Heizenergiebedarf',
          beschreibung: 'Berechnet: Beheizte Fläche × spez. Heizenergiebedarf\n= 119,24 m² × 96 kWh/m²a\n= 11.447 kWh/a (gerundet 11.500)',
        ),
      ),
     anteilGaswaerme: WertMitQuelle(
        wert: 0,
        quelle: QuellenInfo(
          titel: 'Anteil Gaswärme',
          beschreibung: 'Anteil Wärme aus Gas',
        ),
      ),
    );
  }

  // ========================================
  // FINANZIERUNG
  // ========================================

  FinanzierungsDaten _erstelleFinanzierung() {
    return FinanzierungsDaten(
      zinssatz: WertMitQuelle(
        wert: 3.546,
        quelle: QuellenInfo(
          titel: 'Zinssatz',
          beschreibung: 'Effektivzinssätze Bundesbank:\nBanken DE / Neugeschäft / Wohnungsbaukredite an private Haushalte,\nanfängliche Zinsbindung über 10 Jahre / SUD119',
          link: 'https://www.bundesbank.de/de/statistiken',
        ),
      ),
      laufzeitJahre: WertMitQuelle(
        wert: 20,
        quelle: QuellenInfo(
          titel: 'Laufzeit',
          beschreibung: 'Übliche Laufzeit für Wohnungsbaukredite',
        ),
      ),
      foerderungBEG: WertMitQuelle(
        wert: 0.30,
        quelle: QuellenInfo(
          titel: 'BEG Förderung',
          beschreibung: 'Theoretische Annahme, keine Förderung gemäß 3.1 BEG Richtlinie\nFörderquote: 30 %\nFür Wärmepumpe und Wärmenetz Station Kunde',
          link: 'https://www.energiewechsel.de/KAENEF/Redaktion/DE/FAQ/FAQ-Uebersicht/Richtlinien/bundesfoerderung-fuer-effiziente-gebaeude-beg.html',
        ),
      ),
      foerderungBEW: WertMitQuelle(
        wert: 0.30,
        quelle: QuellenInfo(
          titel: 'BEW Förderung',
          beschreibung: 'Förderquote: 30 %\nFür Wärmenetz Station Süwag (bereits im Preis berücksichtigt)',
          link: 'https://www.bafa.de/DE/Energie/Energieeffizienz/Waermenetze/waermenetze_node.html',
        ),
      ),
    );
  }

  // ========================================
  // WÄRMEPUMPE
  // ========================================

  SzenarioStammdaten _erstelleWaermepumpeSzenario() {
    const gesamtBrutto = 29200.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote;
    const netto = gesamtBrutto - foerderbetrag;

    return SzenarioStammdaten(
      id: 'waermepumpe',
      bezeichnung: 'Wärmepumpe',
      beschreibung: 'Luft/Wasser-Wärmepumpe 10 kW mit TWW-Speicher, Vorlauf 55°C',
      typ: SzenarioTyp.dezentral,
      sortierung: 1,
      investition: InvestitionskostenDaten(
        waermepumpe: InvestitionsPosition(
          bezeichnung: 'Luft-Wasser-Wärmepumpe, JAZ 3, Q = 10 kW, 55/45°C',
          betrag: WertMitQuelle(
            wert: 29200.0,
            quelle: QuellenInfo(
              titel: 'Wärmepumpe',
              beschreibung: 'Technikkatalog Bund 10.2025, Tabelle 10, L-/W-Wärmepumpe 10 kW, Anmerkung AP',
              link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
            ),
          ),
        ),
        twwSpeicher: InvestitionsPosition(
          bezeichnung: 'TWW-Speicher inkl. Puffer',
          betrag: WertMitQuelle(
            wert: 3900.0,
            quelle: QuellenInfo(
              titel: 'TWW-Speicher',
              beschreibung: 'Technikkatalog Bund 10.2025 - Tabelle 45 Speicher',
              link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
            ),
          ),
        ),
        hydraulik: InvestitionsPositionText(
          bezeichnung: 'Hydraulik inkl. Zubehör, Wärmedämmung, ELT + MSR',
          text: WertMitQuelle(
            wert: 'inkl.',
            quelle: QuellenInfo(
              titel: 'Hydraulik',
              beschreibung: 'Im Preis der Wärmepumpe enthalten',
            ),
          ),
        ),
        zaehlerschrank: InvestitionsPosition(
          bezeichnung: 'Umbau Zählerschrank & Rundsteuerdempfänger',
          betrag: WertMitQuelle(
            wert: 1950.0,
            quelle: QuellenInfo(
              titel: 'Elektrische Installation',
              beschreibung: 'Annahme Süwag, Gebäudeabhängig',
            ),
          ),
        ),
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.beg,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: WaermekostenDaten(
        jahresarbeitszahl: WertMitQuelle(
          wert: 3.0,
          quelle: QuellenInfo(
            titel: 'Jahresarbeitszahl (JAZ)',
            beschreibung: 'Verhältnis Wärmeenergie / elektrische Energie\nTypischer Wert für Luft-Wasser-Wärmepumpe',
            link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
          ),
        ),
        stromverbrauchKWh: WertMitQuelle(
          wert: 3833.0,
          quelle: QuellenInfo(
            titel: 'Stromverbrauch Wärmepumpe',
            beschreibung: 'Berechnet: Heizenergiebedarf / JAZ\n= 11.500 kWh/a / 3,0\n= 3.833 kWh/a',
          ),
        ),
        stromarbeitspreisCtKWh: WertMitQuelle(
          wert: 16.52,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Stromtarif',
            beschreibung: 'Arbeitspreis Stromtarif mit abschaltbarer Last\n\n Durchschnittlicher Strompreis für Wärmepumpen pro Kilowattstunde des Vorjahres',
            link: 'https://www.verivox.de/heizstrom/waermepumpenstrom-preisentwicklung/',
          ),
        ),
        stromGrundpreisEuroMonat: WertMitQuelle(
          wert: 9.0,
          quelle: QuellenInfo(
            titel: 'Grundpreis Stromtarif',
            beschreibung: 'Abschätzungm übliche Grundpreise für Stromtarife',
            link: 'https://www.verivox.de/',
          ),
        ),
      ),
      nebenkosten: NebenkostenDaten(
        wartungEuroJahr: WertMitQuelle(
          wert: 490.0,
          quelle: QuellenInfo(
            titel: 'Wartung & Instandhaltung',
            beschreibung: 'Deutsche Energie-Agentur GmbH (Hrsg.) (dena, 2025) KWW-Technikkatalog Wärmeplanung.\n\nJährliche Fixkosten O & M, Tabelle 10',
            link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
          ),
        ),
      ),
    );
  }

  // ========================================
  // WÄRMENETZ OHNE ÜGS
  // ========================================

  SzenarioStammdaten _erstelleWaermenetzOhneUGS() {
    return SzenarioStammdaten(
      id: 'waermenetzOhneUGS',
      bezeichnung: 'Wärmenetz ohne Übergabestation',
      beschreibung: 'Bestandsvertrag ohne Anpassungen, Vorlauf 70°C',
      typ: SzenarioTyp.zentral,
      sortierung: 2,
      investition: const InvestitionskostenDaten(
        gesamtBrutto: 0.0,
        foerderungsTyp: FoerderungsTyp.keine,
        foerderquote: 0.0,
        foerderbetrag: 0.0,
        nettoNachFoerderung: 0.0,
      ),
      waermekosten: WaermekostenDaten(
        waermeVerbrauchGasKWh: WertMitQuelle(
          wert: 8050.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Gas',
            beschreibung: 'Berechnet: Heizenergiebedarf × (1 - Anteil Abwärme)\n\n= 11.500 kWh/a × 0,7\n= 8.050 kWh/a',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeVerbrauchStromKWh: WertMitQuelle(
          wert: 3450.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Strom (Abwärme)',
            beschreibung: 'Berechnet: Heizenergiebedarf × Anteil Abwärme\n\n= 11.500 kWh/a × 0,3\n= 3.450 kWh/a\n\nAnteil Abwärme (Eingabebereich 30 - 100 %)',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGasArbeitspreisCtKWh: WertMitQuelle(
          wert: 11.68,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Gas',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024\n\nAbschätzung Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeStromArbeitspreisCtKWh: WertMitQuelle(
          wert: 8.52,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Strom',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024\n\nAbschätzung Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGrundpreisEuroJahr: WertMitQuelle(
          wert: 471.0,
          quelle: QuellenInfo(
            titel: 'Grundpreis Wärme',
            beschreibung: 'Grundpreis "Sockelbetrag" - Szenario ohne ÜGS\n3,95 € / m²\n= 3,95 × 119,24 m²\n= 471 €/Jahr',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeMesspreisEuroJahr: WertMitQuelle(
          wert: 109.55,
          quelle: QuellenInfo(
            titel: 'Messpreis',
            beschreibung: 'Messpreis Wasser (Szenario ohne ÜGS), Wärme + Eichgebühren\n\nPreisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
      ),
      nebenkosten: NebenkostenDaten(
        wartungEuroJahr: WertMitQuelle(
          wert: 50.0,
          quelle: QuellenInfo(
            titel: 'Wartung & Instandhaltung',
            beschreibung: 'Minimale Wartungskosten bei Bestandsvertrag ohne Übergabestation',
          ),
        ),
      ),
    );
  }

  // ========================================
  // WÄRMENETZ KUNDE
  // ========================================

  SzenarioStammdaten _erstelleWaermenetzKunde() {
    const gesamtBrutto = 10950.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote;
    const netto = gesamtBrutto - foerderbetrag;

    return SzenarioStammdaten(
      id: 'waermenetzKunde',
      bezeichnung: 'Wärmenetz - Station Kunde',
      beschreibung: 'Übergabestation 10 kW TWW-Speicher, Vorlauf 70°C, BEG Förderung',
      typ: SzenarioTyp.zentral,
      sortierung: 3,
      investition: InvestitionskostenDaten(
        uebergabestation: InvestitionsPosition(
          bezeichnung: 'Übergabestation EFH',
          betrag: WertMitQuelle(
            wert: 10950.0,
            quelle: QuellenInfo(
              titel: 'Übergabestation',
              beschreibung: 'Technikkatalog Bund 10.2025 - Hausstationen 15 kW, Tabelle 37',
              link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
            ),
          ),
        ),
        twwSpeicher: InvestitionsPosition(
          bezeichnung: 'TWW-Speicher / FW exkl. Puffer',
          betrag: WertMitQuelle(
            wert: 2055.0,
            quelle: QuellenInfo(
              titel: 'Pufferspeicher',
              beschreibung: 'Technikkatalog Bund 10.2025 - Tabelle 45 Speicher',
              link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
            ),
          ),
        ),
        hydraulik: InvestitionsPositionText(
          bezeichnung: 'Hydraulik inkl. Zubehör, Wärmedämmung, ELT + MSR',
          text: WertMitQuelle(
            wert: 'inkl.',
            quelle: QuellenInfo(
              titel: 'Hydraulik',
              beschreibung: 'Im Preis der Übergabestation enthalten',
            ),
          ),
        ),
        heizlastberechnung: InvestitionsPosition(
          bezeichnung: 'Heizlastberechnung + Hydr. Abgleich',
          betrag: WertMitQuelle(
            wert: 1520.0,
            quelle: QuellenInfo(
              titel: 'Heizlastberechnung',
              beschreibung: 'Annahme Süwag, Gebäudeabhängig',
            ),
          ),
        ),
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.beg,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: WaermekostenDaten(
        waermeVerbrauchGasKWh: WertMitQuelle(
          wert: 8050.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Gas',
            beschreibung: 'Berechnet: Heizenergiebedarf × (1 - Anteil Abwärme)\n= 11.500 kWh/a × 0,7\n= 8.050 kWh/a',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeVerbrauchStromKWh: WertMitQuelle(
          wert: 3450.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Strom (Abwärme)',
            beschreibung: 'Berechnet: Heizenergiebedarf × Anteil Abwärme\n= 11.500 kWh/a × 0,3\n= 3.450 kWh/a',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGasArbeitspreisCtKWh: WertMitQuelle(
          wert: 11.68,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Gas',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeStromArbeitspreisCtKWh: WertMitQuelle(
          wert: 8.52,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Strom',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGrundpreisEuroJahr: WertMitQuelle(
          wert: 396.0,
          quelle: QuellenInfo(
            titel: 'Grundpreis Wärme',
            beschreibung: 'Grundpreis "Sockelbetrag 10 kW" (Szenario Übergabestation)',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeMesspreisEuroJahr: WertMitQuelle(
          wert: 64.20,
          quelle: QuellenInfo(
            titel: 'Messpreis',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
      ),
      nebenkosten: NebenkostenDaten(
        wartungEuroJahr: WertMitQuelle(
          wert: 100.0,
          quelle: QuellenInfo(
            titel: 'Wartung & Instandhaltung',
            beschreibung: 'Deutsche Energie-Agentur GmbH (Hrsg.) (dena, 2025) KWW-Technikkatalog Wärmeplanung.\n\nJährliche Fixkosten O & M, Tabelle 37',
            link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
          ),
        ),
      ),
    );
  }

  // ========================================
  // WÄRMENETZ SÜWAG
  // ========================================

  SzenarioStammdaten _erstelleWaermenetzSuewag() {
    const gesamtBrutto = 8900.0;
    const foerderquote = 0.30;
    const foerderbetrag = gesamtBrutto * foerderquote;
    const netto = gesamtBrutto - foerderbetrag;

    return SzenarioStammdaten(
      id: 'waermenetzSuewag',
      bezeichnung: 'Wärmenetz - Station Süwag',
      beschreibung: 'Übergabestation 10 kW TWW-Speicher, Vorlauf 70°C,, BEW Förderung',
      typ: SzenarioTyp.zentral,
      sortierung: 4,
      investition: InvestitionskostenDaten(
        bkz: InvestitionsPosition(
          bezeichnung: 'Baukostenzuschuss (BKZ)',
          betrag: WertMitQuelle(
            wert: 8900.0,
            quelle: QuellenInfo(
              titel: 'Baukostenzuschuss',
              beschreibung: 'Angebot Süwag - Süwag stellt Übergabestation',
            ),
          ),
          bemerkung: 'Süwag stellt Übergabestation',
        ),
        gesamtBrutto: gesamtBrutto,
        foerderungsTyp: FoerderungsTyp.bew,
        foerderquote: foerderquote,
        foerderbetrag: foerderbetrag,
        nettoNachFoerderung: netto,
      ),
      waermekosten: WaermekostenDaten(
        waermeVerbrauchGasKWh: WertMitQuelle(
          wert: 8050.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Gas',
            beschreibung: 'Berechnet: Heizenergiebedarf × (1 - Anteil Abwärme)\n= 11.500 kWh/a × 0,7\n= 8.050 kWh/a',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeVerbrauchStromKWh: WertMitQuelle(
          wert: 3450.0,
          quelle: QuellenInfo(
            titel: 'Wärmeverbrauch aus Strom (Abwärme)',
            beschreibung: 'Berechnet: Heizenergiebedarf × Anteil Abwärme\n= 11.500 kWh/a × 0,3\n= 3.450 kWh/a',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGasArbeitspreisCtKWh: WertMitQuelle(
          wert: 11.68,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Gas',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeStromArbeitspreisCtKWh: WertMitQuelle(
          wert: 8.52,
          quelle: QuellenInfo(
            titel: 'Arbeitspreis Wärme aus Strom',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeGrundpreisEuroJahr: WertMitQuelle(
          wert: 396.0,
          quelle: QuellenInfo(
            titel: 'Grundpreis Wärme',
            beschreibung: 'Grundpreis "Sockelbetrag 10 kW"',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
        waermeMesspreisEuroJahr: WertMitQuelle(
          wert: 64.20,
          quelle: QuellenInfo(
            titel: 'Messpreis',
            beschreibung: 'Preisblatt Fernwärme Schwalbach - Preisstand 2024',
            link: 'https://www.suewag.com/erzeugung/ihre-versorgung/fernwaermeversorgung',
          ),
        ),
      ),
      nebenkosten: NebenkostenDaten(
        wartungEuroJahr: WertMitQuelle(
          wert: 0.0,
          quelle: QuellenInfo(
            titel: 'Wartung & Instandhaltung',
            beschreibung: 'Keine Wartung - Süwag übernimmt Wartung der Übergabestation',
          ),
        ),
        grundpreisUebergabestationEuroJahr: WertMitQuelle(
          wert: 150.0,
          quelle: QuellenInfo(
            titel: 'Zusätzlicher Grundpreis Übergabestation',
            beschreibung: 'Angebot Süwag - Zusätzlicher jährlicher Grundpreis für Übergabestation im Eigentum der Süwag',
          ),
        ),
      ),
    );
  }
}