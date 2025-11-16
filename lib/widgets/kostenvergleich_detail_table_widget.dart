// lib/widgets/kostenvergleich_detail_table_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';

class KostenvergleichDetailTableWidget extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final List<KostenberechnungErgebnis> ergebnisse;

  const KostenvergleichDetailTableWidget({
    Key? key,
    required this.stammdaten,
    required this.ergebnisse,
  }) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          // Tabelle ohne äußeren SingleChildScrollView
          _buildTable(),
        ],
      ),
    );
  }
  String _formatiereDatum() {
    // Nutze das Jahr aus den Stammdaten und aktualisiereDatum falls vorhanden
    final jahr = stammdaten.jahr;

    // Prüfe ob ein aktualisierDatum in den Metadaten existiert
    // Falls ja, formatiere es schön
    // Falls nein, nutze das Jahr aus den Stammdaten

    return 'Jahr $jahr'; // Oder wenn du ein konkretes Datum hast: 'November $jahr'
  }
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jahreskostenvergleich - Wärmekosten Einfamilienhaus Bestand',
          style: SuewagTextStyles.headline3,
        ),
        const SizedBox(height: 8),
        Text(
          'Stand: ${_formatiereDatum()} - Kostenvergleich auf Basis folgender Kennzahlen des Vorjahres',
          style: SuewagTextStyles.caption.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        // NEU: Annahmen-Zeile
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _buildAnnahmeChip(
                    'Zinssatz: ${_formatiereDeutsch(stammdaten.finanzierung.zinssatz.wert, 2)} %',
                    stammdaten.finanzierung.zinssatz.quelle,
                  ),
                  _buildAnnahmeChip(
                    'Abwärmeanteil: ${_formatiereDeutsch((1 - stammdaten.grunddaten.anteilGaswaerme.wert) * 100, 0)} %',
                    stammdaten.grunddaten.anteilGaswaerme.quelle,
                  ),
                  _buildAnnahmeChip(
                    'Strompreis WP: ${_formatiereDeutsch(stammdaten.szenarien['waermepumpe']?.waermekosten.stromarbeitspreisCtKWh?.wert ?? 0, 2)} ct/kWh',
                    stammdaten.szenarien['waermepumpe']?.waermekosten.stromarbeitspreisCtKWh?.quelle ?? const QuellenInfo(titel: 'Strompreis', beschreibung: 'k.A.'),
                  ),
                  _buildAnnahmeChip(
                    'Wärmepreis Gas: ${_formatiereDeutsch(stammdaten.szenarien['waermenetzOhneUGS']?.waermekosten.waermeGasArbeitspreisCtKWh?.wert ?? 0, 4)} ct/kWh',
                    stammdaten.szenarien['waermenetzOhneUGS']?.waermekosten.waermeGasArbeitspreisCtKWh?.quelle ?? const QuellenInfo(titel: 'Wärmepreis Gas', beschreibung: 'k.A.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildAnnahmeChip(String text, QuellenInfo quelle) {
    return Builder(  // NEU: Builder um context zu bekommen
      builder: (context) => InkWell(
        onTap: () => _zeigeAnnahmeDialog(context, text, quelle),  // context übergeben
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: SuewagColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: SuewagColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: SuewagTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: SuewagColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 12,
                color: SuewagColors.primary.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _zeigeAnnahmeDialog(BuildContext context, String titel, QuellenInfo quelle) {  // context als Parameter
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titel.split(':')[0]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quelle.beschreibung),
              if (quelle.link != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(quelle.link!);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      print('Fehler beim Öffnen des Links: $e');
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: SuewagColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quelle.link!,
                          style: TextStyle(
                            color: SuewagColors.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  String _formatiereDeutsch(double wert, int nachkommastellen) {
    final parts = wert.toStringAsFixed(nachkommastellen).split('.');
    final vorkomma = parts[0];
    final nachkomma = nachkommastellen > 0 ? parts[1] : '';

    String formatted = '';
    int count = 0;
    for (int i = vorkomma.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = vorkomma[i] + formatted;
      count++;
    }

    if (nachkommastellen > 0) {
      formatted += ',$nachkomma';
    }

    return formatted;
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth, // Nutzt die verfügbare Breite
            ),
            child: Table(
              border: TableBorder.all(color: SuewagColors.divider, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(0.8),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
                5: FlexColumnWidth(2),
                6: FlexColumnWidth(2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildHeaderRow(),
                _buildSubHeaderRow(),
                ..._buildAbschnittA(),
                ..._buildAbschnittB(),
                ..._buildAbschnittC(),
                ..._buildAbschnittD(),
                ..._buildAbschnittE(),
              ],
            ),
          ),
        );
      },
    );
  }
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: SuewagColors.indiablau.withOpacity(0.1)),
      children: [
        const SizedBox.shrink(), // Pos.
        const SizedBox.shrink(), // Bezeichnung
        const SizedBox.shrink(), // Einheit
        Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Vergleichsszenario',
            style: SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox.shrink(), // Platzhalter für Spalte 2
        const SizedBox.shrink(), // Platzhalter für Spalte 3
        _buildHeaderCell('Informativ'),
      ],
    );
  }

  TableRow _buildSubHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: SuewagColors.background),
      children: [
        _buildHeaderCell('Pos.'),
        _buildHeaderCell('Bezeichnung'),
        _buildHeaderCell('Einheit'),
        _buildHeaderCell('Wärmepumpe\n\nLuft/Wasser-Wärmepumpe 10 kW\nTWW-Speicher\nVorlauf 55°C', fontSize: 11),
        _buildHeaderCell('Wärmenetz ohne ÜGS\n\nBestandsvertrag ohne\nAnpassungen,\nVorlauf 70°C', fontSize: 11),
        _buildHeaderCell('Wärmenetz - Station Kunde\n\nBEG Förderung\nStation Eigentum des Kunden\nÜbergabestation 10 kW TWW-\nSpeicher Vorlauf 70°C', fontSize: 10),
        _buildHeaderCell('Wärmenetz - Station Süwag\n\nBEW Förderung\nStation Eigentum der Süwag\nÜbergabestation 10 kW TWW-\nSpeicher Vorlauf 70°C', fontSize: 10),
      ],
    );
  }

  List<TableRow> _buildAbschnittA() {
    // Für Grunddaten: Wert gilt für alle 4 Szenarien
    final wertCellFlaeche = QuellenwertCell(
      wert: stammdaten.grunddaten.beheizteFlaeche.wert,
      nachkommastellen: 2,
      einheit: 'm²',
      quelle: stammdaten.grunddaten.beheizteFlaeche.quelle,
    );

    final wertCellSpez = QuellenwertCell(
      wert: stammdaten.grunddaten.spezHeizenergiebedarf.wert,
      nachkommastellen: 0,
      einheit: 'kWh/m²a',
      quelle: stammdaten.grunddaten.spezHeizenergiebedarf.quelle,
    );

    final wertCellGesamt = QuellenwertCell(
      wert: stammdaten.grunddaten.heizenergiebedarf.wert,
      nachkommastellen: 0,
      einheit: 'kWh/a',
      quelle: stammdaten.grunddaten.heizenergiebedarf.quelle,
    );

    return [
      _buildAbschnittHeader('A.', 'Grunddaten'),
      _buildDataRow(
        'A.1',
        'Gesamte beheizte Fläche EFH',
        'm²',
        [wertCellFlaeche, wertCellFlaeche, wertCellFlaeche, wertCellFlaeche],
      ),
      _buildDataRow(
        'A.2',
        'spez. Heizenergiebedarf (inkl. Warmwasser)',
        'kWh/m²a',
        [wertCellSpez, wertCellSpez, wertCellSpez, wertCellSpez],
      ),
      _buildDataRow(
        'A.3',
        'Heizenergiebedarf',
        'kWh/a',
        [wertCellGesamt, wertCellGesamt, wertCellGesamt, wertCellGesamt],
      ),
    ];
  }

  List<TableRow> _buildAbschnittB() {
    final rows = <TableRow>[
      _buildAbschnittHeader('B.', 'Investitionskosten (einmalige Kosten)'),
    ];

    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    // B.1: Wärmepumpe
    rows.add(_buildDataRow(
      'B.1',
      wpSzenario.investition.waermepumpe?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        wpSzenario.investition.waermepumpe != null
            ? QuellenwertCell(
          wert: wpSzenario.investition.waermepumpe!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: wpSzenario.investition.waermepumpe!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
        const EmptyCell(),
        const EmptyCell(),
      ],
    ));

    // B.2: Übergabestation
    rows.add(_buildDataRow(
      'B.2',
      kundeSzenario.investition.uebergabestation?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        const EmptyCell(),
        const EmptyCell(),
        kundeSzenario.investition.uebergabestation != null
            ? QuellenwertCell(
          wert: kundeSzenario.investition.uebergabestation!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: kundeSzenario.investition.uebergabestation!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
      ],
    ));

    // B.3: TWW-Speicher
    rows.add(_buildDataRow(
      'B.3',
      wpSzenario.investition.twwSpeicher?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        wpSzenario.investition.twwSpeicher != null
            ? QuellenwertCell(
          wert: wpSzenario.investition.twwSpeicher!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: wpSzenario.investition.twwSpeicher!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
        kundeSzenario.investition.twwSpeicher != null
            ? QuellenwertCell(
          wert: kundeSzenario.investition.twwSpeicher!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: kundeSzenario.investition.twwSpeicher!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
      ],
    ));

    // B.4: Hydraulik
    rows.add(_buildDataRow(
      'B.4',
      'Hydraulik inkl. Zubehör, Wärmedämmung, ELT + MSR',
      '€',
      const [
        TextCell(text: 'inkl.'),
        EmptyCell(),
        TextCell(text: 'inkl.'),
        EmptyCell(),
      ],
    ));

    // B.6: Heizlastberechnung
    rows.add(_buildDataRow(
      'B.6',
      kundeSzenario.investition.heizlastberechnung?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        const TextCell(text: 'inkl.'),
        const EmptyCell(),
        kundeSzenario.investition.heizlastberechnung != null
            ? QuellenwertCell(
          wert: kundeSzenario.investition.heizlastberechnung!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: kundeSzenario.investition.heizlastberechnung!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
      ],
    ));

    // B.7: Zählerschrank
    rows.add(_buildDataRow(
      'B.7',
      wpSzenario.investition.zaehlerschrank?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        wpSzenario.investition.zaehlerschrank != null
            ? QuellenwertCell(
          wert: wpSzenario.investition.zaehlerschrank!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: wpSzenario.investition.zaehlerschrank!.betrag.quelle,
        )
            : const EmptyCell(),
        const EmptyCell(),
        const EmptyCell(),
        const EmptyCell(),
      ],
    ));

    // B.8: BKZ
    rows.add(_buildDataRow(
      'B.8',
      suewagSzenario.investition.bkz?.bezeichnung ?? 'Platzhalter Überschrift',
      '€',
      [
        const EmptyCell(),
        const EmptyCell(),
        const EmptyCell(),
        suewagSzenario.investition.bkz != null
            ? QuellenwertCell(
          wert: suewagSzenario.investition.bkz!.betrag.wert,
          nachkommastellen: 0,
          einheit: '€',
          quelle: suewagSzenario.investition.bkz!.betrag.quelle,
        )
            : const EmptyCell(),
      ],
    ));

    // B.9: Förderung
    rows.add(_buildDataRow(
      'B.9',
      'Förderung BEG 30 %',
      '€',
      [
        wpSzenario,
        ohneSzenario,
        kundeSzenario,
        suewagSzenario,
      ].map((szenario) {
        if (szenario.investition.foerderbetrag > 0) {
          return QuellenwertCell(
            wert: -szenario.investition.foerderbetrag,
            nachkommastellen: 2,
            einheit: '€',
            farbe: Colors.red,
            quelle: QuellenInfo(
              titel: 'Förderung ${szenario.investition.foerderungsTyp == FoerderungsTyp.beg ? "BEG" : "BEW"}',
              beschreibung: 'Theoretische Annahme\n\n'
                  'Förderquote: ${(szenario.investition.foerderquote * 100).toStringAsFixed(0)} %\n'
                  'Investition brutto: ${szenario.investition.gesamtBrutto.toStringAsFixed(2).replaceAll('.', ',')} €\n'
                  'Förderbetrag: ${szenario.investition.foerderbetrag.toStringAsFixed(2).replaceAll('.', ',')} €',
              link: 'https://www.energiewechsel.de/KAENEF/Redaktion/DE/FAQ/FAQ-Uebersicht/Richtlinien/bundesfoerderung-fuer-effiziente-gebaeude-beg.html',
            ),
          );
        }
        return const EmptyCell();
      }).toList(),
    ));

    // B.10: Gesamt exkl. Förderung
    rows.add(_buildDataRow(
      'B.10',
      'Investitionskosten exkl. Förderung (netto, zzgl. MwSt.)',
      '€',
      [wpSzenario, ohneSzenario, kundeSzenario, suewagSzenario].map((szenario) {
        return QuellenwertCell(
          wert: szenario.investition.gesamtBrutto,
          nachkommastellen: 2,
          einheit: '€',
          isBold: true,
          quelle: QuellenInfo(
            titel: 'Investitionskosten gesamt',
            beschreibung: 'Summe aller Investitionspositionen (ohne Förderung)',
            link: 'https://www.kww-halle.de/service/infothek/detail/kww-technikkatalog-waermeplanung-begleitdokument',
          ),
        );
      }).toList(),
    ));

    // B.11: Gesamt inkl. Förderung
    rows.add(_buildDataRow(
      'B.11',
      'Investitionskosten inkl. Förderung (netto, zzgl. MwSt.)',
      '€',
      [wpSzenario, ohneSzenario, kundeSzenario, suewagSzenario].map((szenario) {
        return QuellenwertCell(
          wert: szenario.investition.nettoNachFoerderung,
          nachkommastellen: 2,
          einheit: '€',
          isBold: true,
          farbe: SuewagColors.fasergruen,
          quelle: QuellenInfo(
            titel: 'Investitionskosten mit Förderung',
            beschreibung: 'Investitionskosten nach Abzug der Förderung\n\n'
                'Brutto: ${szenario.investition.gesamtBrutto.toStringAsFixed(2).replaceAll('.', ',')} €\n'
                'Förderung: -${szenario.investition.foerderbetrag.toStringAsFixed(2).replaceAll('.', ',')} €\n'
                'Netto: ${szenario.investition.nettoNachFoerderung.toStringAsFixed(2).replaceAll('.', ',')} €',
          ),
        );
      }).toList(),
    ));

    return rows;
  }

  List<TableRow> _buildAbschnittC() {
    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    return [
      _buildAbschnittHeader('C.', 'Wärmekosten (laufende Kosten)'),

      // C.1: Stromverbrauch WP
      _buildDataRow(
        'C.1',
        'zu beziehender Verbrauch Strom',
        'kWh/a',
        [
          wpSzenario.waermekosten.stromverbrauchKWh != null
              ? QuellenwertCell(
            wert: wpSzenario.waermekosten.stromverbrauchKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: wpSzenario.waermekosten.stromverbrauchKWh!.quelle,
          )
              : const EmptyCell(),
          const EmptyCell(),
          const EmptyCell(),
          const EmptyCell(),
        ],
      ),

      // C.2: Verbrauch Gas
      _buildDataRow(
        'C.2',
        'zu bezahlender Verbrauch (Wärme aus Gas)',
        'kWh/a',
        [
          const EmptyCell(),
          ohneSzenario.waermekosten.waermeVerbrauchGasKWh != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeVerbrauchGasKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: ohneSzenario.waermekosten.waermeVerbrauchGasKWh!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeVerbrauchGasKWh != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeVerbrauchGasKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: kundeSzenario.waermekosten.waermeVerbrauchGasKWh!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeVerbrauchGasKWh != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeVerbrauchGasKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: suewagSzenario.waermekosten.waermeVerbrauchGasKWh!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.3: Verbrauch Strom (Wärmenetz)
      _buildDataRow(
        'C.3',
        'zu bezahlender Verbrauch (Wärme aus Strom)',
        'kWh/a',
        [
          const EmptyCell(),
          ohneSzenario.waermekosten.waermeVerbrauchStromKWh != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeVerbrauchStromKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: ohneSzenario.waermekosten.waermeVerbrauchStromKWh!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeVerbrauchStromKWh != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeVerbrauchStromKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: kundeSzenario.waermekosten.waermeVerbrauchStromKWh!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeVerbrauchStromKWh != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeVerbrauchStromKWh!.wert,
            nachkommastellen: 0,
            einheit: 'kWh/a',
            quelle: suewagSzenario.waermekosten.waermeVerbrauchStromKWh!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.4: Arbeitspreis Strom/Gas
      _buildDataRow(
        'C.4',
        'Arbeitspreis Strom / o. "Wärme aus Gas"',
        'ct/kWh',
        [
          wpSzenario.waermekosten.stromarbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
          ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.5: Arbeitspreis Wärme aus Strom
      _buildDataRow(
        'C.5',
        'Arbeitspreis "Wärme aus Strom"',
        'ct/kWh',
        [
          const EmptyCell(),
          ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            einheit: 'ct/kWh',
            quelle: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.6: Grundpreis
      _buildDataRow(
        'C.6',
        'Grundpreis Strom / o. Wärme',
        '€/a',
        [
          wpSzenario.waermekosten.stromGrundpreisEuroMonat != null
              ? QuellenwertCell(
            wert: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.wert * 12,
            nachkommastellen: 0,
            einheit: '€/a',
            quelle: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.quelle,
          )
              : const EmptyCell(),
          ohneSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            einheit: '€/a',
            quelle: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            einheit: '€/a',
            quelle: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            einheit: '€/a',
            quelle: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.7: Messpreis
      _buildDataRow(
        'C.7',
        'Messpreis Wasser (Szenario ohne ÜGS), Wärme + Eichgebühren',
        '€/a',
        [
          const EmptyCell(),
          ohneSzenario.waermekosten.waermeMesspreisEuroJahr != null
              ? QuellenwertCell(
            wert: ohneSzenario.waermekosten.waermeMesspreisEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: ohneSzenario.waermekosten.waermeMesspreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.waermekosten.waermeMesspreisEuroJahr != null
              ? QuellenwertCell(
            wert: kundeSzenario.waermekosten.waermeMesspreisEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: kundeSzenario.waermekosten.waermeMesspreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.waermekosten.waermeMesspreisEuroJahr != null
              ? QuellenwertCell(
            wert: suewagSzenario.waermekosten.waermeMesspreisEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: suewagSzenario.waermekosten.waermeMesspreisEuroJahr!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      // C.8: Summe Wärmekosten
      _buildDataRow(
        'C.8',
        'Summe Wärmekosten, netto',
        '€/a',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.kosten.arbeitspreis + e.kosten.grundUndMesspreis,
            nachkommastellen: 2,
            einheit: '€/a',
            isBold: true,
            farbe: SuewagColors.fasergruen,
            quelle: QuellenInfo(
              titel: 'Summe Wärmekosten',
              beschreibung: 'Arbeitspreis + Grundpreis + Messpreis\n\n'
                  'Arbeitspreis: ${e.kosten.arbeitspreis.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Grund- und Messpreis: ${e.kosten.grundUndMesspreis.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Summe: ${(e.kosten.arbeitspreis + e.kosten.grundUndMesspreis).toStringAsFixed(2).replaceAll('.', ',')} €/a',
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<TableRow> _buildAbschnittD() {
    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    return [
      _buildAbschnittHeader('D.', 'Nebenkosten (laufende Kosten)'),

      _buildDataRow(
        'D.1',
        'Wartung & Instandhaltung',
        '€/a',
        [
          wpSzenario.nebenkosten.wartungEuroJahr != null
              ? QuellenwertCell(
            wert: wpSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: wpSzenario.nebenkosten.wartungEuroJahr!.quelle,
          )
              : const EmptyCell(),
          ohneSzenario.nebenkosten.wartungEuroJahr != null
              ? QuellenwertCell(
            wert: ohneSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: ohneSzenario.nebenkosten.wartungEuroJahr!.quelle,
          )
              : const EmptyCell(),
          kundeSzenario.nebenkosten.wartungEuroJahr != null
              ? QuellenwertCell(
            wert: kundeSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: kundeSzenario.nebenkosten.wartungEuroJahr!.quelle,
          )
              : const EmptyCell(),
          suewagSzenario.nebenkosten.wartungEuroJahr != null
              ? QuellenwertCell(
            wert: suewagSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: suewagSzenario.nebenkosten.wartungEuroJahr!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      _buildDataRow(
        'D.2',
        'Zusätzlicher Grundpreis Übergabestation',
        '€/a',
        [
          const EmptyCell(),
          const EmptyCell(),
          const EmptyCell(),
          suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr != null
              ? QuellenwertCell(
            wert: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.wert,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.quelle,
          )
              : const EmptyCell(),
        ],
      ),

      _buildDataRow(
        'D.3',
        'Kapitaldienst: Investition / BKZ inkl. Förderung',
        '€/a',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.kosten.kapitalkosten,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: QuellenInfo(
              titel: 'Kapitaldienst',
              beschreibung: 'Annuitätenmethode mit Förderung\n\n'
                  'Kapitaldienst: ${e.kosten.kapitalkosten.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Zinssatz: ${stammdaten.finanzierung.zinssatz.wert.toStringAsFixed(3).replaceAll('.', ',')} %\n'
                  'Laufzeit: ${stammdaten.finanzierung.laufzeitJahre.wert} Jahre\n\n'
                  'Zinsen: Effektivzinssätze Bundesbank:\n'
                  'Banken DE / Neugeschäft / Wohnungsbaukredite an private Haushalte,\n'
                  'anfängliche Zinsbindung über 10 Jahre / SUD119',
              link: 'https://www.bundesbank.de/de/statistiken',
            ),
          );
        }).toList(),
      ),

      _buildDataRow(
        'D.4',
        'Summe Nebenkosten, netto',
        '€/a',
        ergebnisse.map((e) {
          final summe = e.kosten.betriebskosten +
              e.kosten.kapitalkosten +
              e.kosten.zusaetzlicherGrundpreisUebergabestation;

          return QuellenwertCell(
            wert: summe,
            nachkommastellen: 2,
            einheit: '€/a',
            isBold: true,
            farbe: SuewagColors.fasergruen,
            quelle: QuellenInfo(
              titel: 'Summe Nebenkosten',
              beschreibung: 'Wartung + Kapitaldienst + Zusätzl. Grundpreis ÜGS\n\n'
                  'Wartung: ${e.kosten.betriebskosten.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Kapitaldienst: ${e.kosten.kapitalkosten.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Zusätzl. Grundpreis: ${e.kosten.zusaetzlicherGrundpreisUebergabestation.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Summe: ${summe.toStringAsFixed(2).replaceAll('.', ',')} €/a',
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<TableRow> _buildAbschnittE() {
    return [
      _buildAbschnittHeader('E.', 'Jahreskosten (Wärme- & Nebenkosten)'),

      _buildDataRow(
        'E.1',
        'Wärmevollkostenpreis netto (netto, inkl. MwSt.)',
        '€/MWh',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.waermevollkostenpreisNetto,
            nachkommastellen: 2,
            einheit: '€/MWh',
            isBold: true,
            farbe: SuewagColors.indiablau,
            quelle: QuellenInfo(
              titel: 'Wärmevollkostenpreis netto',
              beschreibung: 'Berechnet: Jahreskosten / Heizenergiebedarf × 1000\n\n'
                  'Jahreskosten: ${e.jahreskosten.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Heizenergiebedarf: ${e.waermebedarf.toStringAsFixed(0).replaceAll(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), r'$1.')} kWh/a\n'
                  'Wärmevollkostenpreis: ${e.waermevollkostenpreisNetto.toStringAsFixed(2).replaceAll('.', ',')} €/MWh',
            ),
          );
        }).toList(),
      ),

      _buildDataRow(
        'E.2',
        'Wärmevollkostenpreis spez. (brutto, inkl. MwSt.)',
        '€/MWh',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.waermevollkostenpreisBrutto,
            nachkommastellen: 2,
            einheit: '€/MWh',
            quelle: QuellenInfo(
              titel: 'Wärmevollkostenpreis brutto',
              beschreibung: 'Mit 19% MwSt.\n\n'
                  'Netto: ${e.waermevollkostenpreisNetto.toStringAsFixed(2).replaceAll('.', ',')} €/MWh\n'
                  'Brutto: ${e.waermevollkostenpreisBrutto.toStringAsFixed(2).replaceAll('.', ',')} €/MWh',
            ),
          );
        }).toList(),
      ),

      _buildDataRow(
        'E.3',
        'Jahreskosten (netto, zzgl. MwSt.)',
        '€/a',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.jahreskosten,
            nachkommastellen: 2,
            einheit: '€/a',
            isBold: true,
            farbe: SuewagColors.verkehrsorange,
            quelle: QuellenInfo(
              titel: 'Jahreskosten netto',
              beschreibung: 'Summe aus Wärmekosten + Nebenkosten\n\n'
                  'Wärmekosten: ${(e.kosten.arbeitspreis + e.kosten.grundUndMesspreis).toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Nebenkosten: ${(e.kosten.betriebskosten + e.kosten.kapitalkosten + e.kosten.zusaetzlicherGrundpreisUebergabestation).toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Gesamt: ${e.jahreskosten.toStringAsFixed(2).replaceAll('.', ',')} €/a',
            ),
          );
        }).toList(),
      ),

      _buildDataRow(
        'E.4',
        'Jahreskosten (brutto, inkl. MwSt.)',
        '€/a',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.jahreskosten_brutto,
            nachkommastellen: 2,
            einheit: '€/a',
            quelle: QuellenInfo(
              titel: 'Jahreskosten brutto',
              beschreibung: 'Mit 19% MwSt.\n\n'
                  'Netto: ${e.jahreskosten.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Brutto: ${e.jahreskosten_brutto.toStringAsFixed(2).replaceAll('.', ',')} €/a',
            ),
          );
        }).toList(),
      ),

      _buildDataRow(
        'E.5',
        'Kosten pro m² Wohnfläche (brutto, inkl. MwSt.)',
        '€/m²',
        ergebnisse.map((e) {
          return QuellenwertCell(
            wert: e.kostenProQuadratmeter * 1.19,
            nachkommastellen: 2,
            einheit: '€/m²',
            quelle: QuellenInfo(
              titel: 'Kosten pro m² Wohnfläche',
              beschreibung: 'Berechnet: Jahreskosten brutto / Beheizte Fläche\n\n'
                  'Jahreskosten brutto: ${e.jahreskosten_brutto.toStringAsFixed(2).replaceAll('.', ',')} €/a\n'
                  'Beheizte Fläche: ${e.beheizteFlaeche.toStringAsFixed(2).replaceAll('.', ',')} m²\n'
                  'Kosten pro m²: ${(e.kostenProQuadratmeter * 1.19).toStringAsFixed(2).replaceAll('.', ',')} €/m²',
            ),
          );
        }).toList(),
      ),
    ];
  }

  TableRow _buildAbschnittHeader(String pos, String titel) {
    return TableRow(
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.2),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            pos,
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: SuewagColors.indiablau,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            titel,
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: SuewagColors.indiablau,
            ),
          ),
        ),
        ...List.generate(5, (_) => const SizedBox.shrink()),
      ],
    );
  }

  TableRow _buildDataRow(
      String pos,
      String bezeichnung,
      String einheit,
      List<Widget> werte, {
        bool centerAll = false,
      }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            pos,
            style: SuewagTextStyles.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            bezeichnung,
            style: SuewagTextStyles.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            einheit,
            style: SuewagTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        ...werte,
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int colspan = 1, double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: SuewagTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Hilfsklassen für Tabellenzellen
class QuellenwertCell extends StatelessWidget {
  final double wert;
  final int nachkommastellen;
  final String? einheit;
  final bool isBold;
  final Color? farbe;
  final QuellenInfo quelle;

  const QuellenwertCell({
    Key? key,
    required this.wert,
    required this.nachkommastellen,
    this.einheit,
    this.isBold = false,
    this.farbe,
    required this.quelle,
  }) : super(key: key);

  String _formatiereDeutsch(double wert, int nachkommastellen) {
    // Deutsche Zahlenformatierung: 1.000,00
    final parts = wert.toStringAsFixed(nachkommastellen).split('.');
    final vorkomma = parts[0];
    final nachkomma = nachkommastellen > 0 ? parts[1] : '';

    // Tausender-Punkte einfügen
    String formatted = '';
    int count = 0;
    for (int i = vorkomma.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = vorkomma[i] + formatted;
      count++;
    }

    if (nachkommastellen > 0) {
      formatted += ',$nachkomma';
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${_formatiereDeutsch(wert, nachkommastellen)} ${einheit ?? ''}',
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: farbe,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _zeigeQuelle(context),
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: SuewagColors.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _zeigeQuelle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quelle.titel),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quelle.beschreibung),
              if (quelle.link != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(quelle.link!);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      print('Fehler beim Öffnen des Links: $e');
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: SuewagColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quelle.link!,
                          style: TextStyle(
                            color: SuewagColors.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

class EmptyCell extends StatelessWidget {
  const EmptyCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: SizedBox.shrink(),
    );
  }
}

class TextCell extends StatelessWidget {
  final String text;

  const TextCell({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: SuewagTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}