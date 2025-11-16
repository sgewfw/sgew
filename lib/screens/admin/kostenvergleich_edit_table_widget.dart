// lib/widgets/kostenvergleich_edit_table_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../models/kostenvergleich_data.dart';
import '../../models/kostenvergleich_ergebnis.dart';
import '../../services/kostenvergleich_berechnung_service.dart';
import '../../utils/numberFormatter.dart';
import '../../widgets/kostenvergleich_chart_widget.dart';
import '../../widgets/kostenvergleich_parameter_widget.dart';


class KostenvergleichEditTableWidget extends StatefulWidget {
  final KostenvergleichJahr initialStammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const KostenvergleichEditTableWidget({
    Key? key,
    required this.initialStammdaten,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<KostenvergleichEditTableWidget> createState() =>
      _KostenvergleichEditTableWidgetState();
}

class _KostenvergleichEditTableWidgetState
    extends State<KostenvergleichEditTableWidget> {
  late KostenvergleichJahr stammdaten;
  final _berechnungsService = KostenvergleichBerechnungService();

  @override
  void initState() {
    super.initState();
    stammdaten = widget.initialStammdaten;
  }

  void _updateStammdaten(KostenvergleichJahr neueStammdaten) {
    setState(() {
      stammdaten = neueStammdaten;
    });
    widget.onChanged(neueStammdaten);
  }
// Deutsche Zahlenformatierung
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




  @override
  Widget build(BuildContext context) {
    final ergebnisse = _berechnungsService.berechneAlleJahreskosten(stammdaten);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEU: Parameter-Widget oberhalb der Tabelle
        KostenvergleichParameterWidget(
          stammdaten: stammdaten,
          onChanged: (neueStammdaten) {
            setState(() {
              stammdaten = neueStammdaten;
            });
            widget.onChanged(neueStammdaten);
          },
        ),
        const SizedBox(height: 16),

        // 🆕 NEU: Grafik + Kostenübersicht
        if (isDesktop)
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildChartCard(ergebnisse),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _buildKostenuebersichtCard(ergebnisse),
                ),
              ],
            ),
          )
        else ...[
          _buildChartCard(ergebnisse),
          const SizedBox(height: 16),
          _buildKostenuebersichtCard(ergebnisse),
        ],

        const SizedBox(height: 16),
        // Bestehende Tabelle
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuewagColors.divider),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTable(ergebnisse),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
          'Jahr ${stammdaten.jahr} - Bearbeitungsmodus',
          style: SuewagTextStyles.caption.copyWith(
            fontStyle: FontStyle.italic,
            color: SuewagColors.verkehrsorange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  Widget _buildChartCard(List<KostenberechnungErgebnis> ergebnisse) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preisbestandteile - Wärmevollkostenpreis netto in ct/kWh',
                  style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
                ),
              ),
              // NEU: Info-Button
              InkWell(
                onTap: () => _zeigeChartInfoDialog(context, ergebnisse),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SuewagColors.indiablau.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: SuewagColors.indiablau.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: SuewagColors.indiablau,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Info',
                        style: SuewagTextStyles.caption.copyWith(
                          color: SuewagColors.indiablau,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: KostenvergleichChartWidget(
              ergebnisse: ergebnisse,
            ),
          ),
        ],
      ),
    );
  }
  void _zeigeChartInfoDialog(BuildContext context, List<KostenberechnungErgebnis> ergebnisse) {
    final heizenergiebedarf = ergebnisse.isNotEmpty
        ? ergebnisse.first.waermebedarf
        : stammdaten.grunddaten.heizenergiebedarf.wert;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: SuewagColors.primary, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Systematik des Kostenvergleichs'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Berechnungsgrundlage
              Text(
                'Berechnungsgrundlage',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.fasergruen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alle Preisbestandteile werden auf den angenommenen Heizenergiebedarf bezogen und in ct/kWh (Cent pro Kilowattstunde) netto dargestellt.',
                      style: SuewagTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Angenommener Heizenergiebedarf: ${_formatiereDeutsch(heizenergiebedarf, 0)} kWh/a',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SuewagColors.fasergruen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Erklärung der Balken
              Text(
                'Aufbau der Balken',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Jeder Balken zeigt die Gesamtkosten eines Szenarios, aufgeschlüsselt nach Kostenarten. Die Segmente werden von unten nach oben gestapelt:',
                style: SuewagTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),

              // Legende mit Erklärungen
              Text(
                'Preisbestandteile (Legende)',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildLegendeErklaerung(
                farbe: ChartFarbe.arbeitspreis.color,
                label: ChartFarbe.arbeitspreis.bezeichnung,
                erklaerung: 'Kosten für die verbrauchte Energie (Strom bei Wärmepumpe, Gas/Strom-Mix bei Wärmenetz)',
              ),
              _buildLegendeErklaerung(
                farbe: ChartFarbe.grundpreis.color,
                label: ChartFarbe.grundpreis.bezeichnung,
                erklaerung: 'Fixe jährliche Kosten unabhängig vom Verbrauch (inkl. Zählermiete, Messdienstleistungen)',
              ),
              _buildLegendeErklaerung(
                farbe: ChartFarbe.zusatzGrundpreis.color,
                label: ChartFarbe.zusatzGrundpreis.bezeichnung,
                erklaerung: 'Zusätzlicher Grundpreis für die Übergabestation (nur bei Variante "Netz Süwag")',
              ),
              _buildLegendeErklaerung(
                farbe: ChartFarbe.betriebskosten.color,
                label: ChartFarbe.betriebskosten.bezeichnung,
                erklaerung: 'Jährliche Kosten für Wartung und Betrieb der Anlagentechnik',
              ),
              _buildLegendeErklaerung(
                farbe: ChartFarbe.kapitalkostenMitFoerderung.color,
                label: ChartFarbe.kapitalkostenMitFoerderung.bezeichnung,
                erklaerung: 'Jährliche Zahlung zur Finanzierung der Investition nach Abzug der Förderung (Annuität)',
              ),
              _buildLegendeErklaerung(
                farbe: ChartFarbe.kapitalkostenOhneFoerderung.color,
                label: ChartFarbe.kapitalkostenOhneFoerderung.bezeichnung,
                erklaerung: 'zusätzliche Kapitalkosten, da gemäß BEG-Richtlinie keine Förderung im Wärmenetzgebiet in Anspruch genommen werden kann',
                isDashed: true,
              ),

              const SizedBox(height: 16),

              // Hinweis
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.indiablau.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SuewagColors.indiablau.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: SuewagColors.indiablau,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Die Höhe der Balken zeigt die spezifischen Wärmevollkosten in ct/kWh. Je niedriger der Balken, desto günstiger ist das Szenario pro verbrauchter Kilowattstunde.',
                        style: SuewagTextStyles.bodySmall.copyWith(
                          color: SuewagColors.indiablau,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildLegendeErklaerung({
    required Color farbe,
    required String label,
    required String erklaerung,
    bool isDashed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: farbe,
              border: isDashed ? Border.all(color: Colors.white, width: 2) : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SuewagTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  erklaerung,
                  style: SuewagTextStyles.caption.copyWith(
                    color: SuewagColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildKostenuebersichtCard(List<KostenberechnungErgebnis> ergebnisse) {
    final sortiert = List<KostenberechnungErgebnis>.from(ergebnisse)
      ..sort((a, b) => a.waermevollkostenpreisNetto.compareTo(b.waermevollkostenpreisNetto));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kostenübersicht',
                style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: SuewagColors.divider),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: SuewagColors.background),
                    children: [
                      _buildKostenTableCell('', isHeader: true),
                      ...sortiert.map((e) => _buildKostenTableCell(
                        e.szenarioBezeichnung,
                        isHeader: true,
                        align: TextAlign.center,
                      )),
                    ],
                  ),
                  // Wärmevollkostenpreis netto
                  _buildKostenTableRow(
                    'Wärmevollkostenpreis netto',
                    sortiert.map((e) => '${_formatiereDeutsch(e.waermevollkostenpreisNetto, 2)} €/MWh').toList(),
                    istHervorgehoben: true,
                  ),
                  // Wärmevollkostenpreis brutto
                  _buildKostenTableRow(
                    'Wärmevollkostenpreis brutto',
                    sortiert.map((e) => '${_formatiereDeutsch(e.waermevollkostenpreisBrutto, 2)} €/MWh').toList(),
                  ),
                  // Jahreskosten netto
                  _buildKostenTableRow(
                    'Jahreskosten netto',
                    sortiert.map((e) => '${_formatiereDeutsch(e.jahreskosten, 2)} €/a').toList(),
                  ),
                  // Jahreskosten brutto
                  _buildKostenTableRow(
                    'Jahreskosten brutto',
                    sortiert.map((e) => '${_formatiereDeutsch(e.jahreskosten_brutto, 2)} €/a').toList(),
                  ),
                  // Kosten pro m²
                  _buildKostenTableRow(
                    'Kosten pro m²',
                    sortiert.map((e) => '${_formatiereDeutsch(e.kostenProQuadratmeter * 1.19, 2)} €/m²').toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildKostenTableRow(
      String label,
      List<String> werte, {
        bool istHervorgehoben = false,
      }) {
    return TableRow(
      decoration: istHervorgehoben
          ? BoxDecoration(color: SuewagColors.fasergruen.withOpacity(0.1))
          : null,
      children: [
        _buildKostenTableCell(
          label,
          istHervorgehoben: istHervorgehoben,
        ),
        ...werte.map((w) => _buildKostenTableCell(
          w,
          align: TextAlign.right,
          istHervorgehoben: istHervorgehoben,
        )),
      ],
    );
  }

  Widget _buildKostenTableCell(
      String text, {
        bool isHeader = false,
        TextAlign align = TextAlign.left,
        bool istHervorgehoben = false,
      }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: align,
        style: isHeader
            ? SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 11)
            : istHervorgehoben
            ? SuewagTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: SuewagColors.fasergruen,
          fontSize: 11,
        )
            : SuewagTextStyles.bodyMedium.copyWith(fontSize: 11),
      ),
    );
  }
  Widget _buildTable(List<dynamic> ergebnisse) {
    return Table(
      border: TableBorder.all(color: SuewagColors.divider, width: 1),
      columnWidths: const {
        0: FixedColumnWidth(50),  // Pos.
        1: FixedColumnWidth(400), // Bezeichnung
        2: FixedColumnWidth(80),  // Einheit
        3: FixedColumnWidth(180), // Wärmepumpe
        4: FixedColumnWidth(180), // Netz ohne ÜGS
        5: FixedColumnWidth(180), // Netz Kunde
        6: FixedColumnWidth(180), // Netz Süwag
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeaderRow(),
        _buildSubHeaderRow(),
        ..._buildAbschnittA(),
        ..._buildAbschnittB(ergebnisse),
        ..._buildAbschnittC(ergebnisse),
        ..._buildAbschnittD(ergebnisse),
        ..._buildAbschnittE(ergebnisse),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: SuewagColors.indiablau.withOpacity(0.1)),
      children: [
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Vergleichsszenario',
            style: SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
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
        _buildHeaderCell('Wärmenetz - Station Kunde\n\nBEG Förderung\nStation Eigentum des Kunden\nÜbergabestation 10 kW TWW-\nSpeicher Vorlauf 70°C, 30 %\nAbwärme aus RZ', fontSize: 10),
        _buildHeaderCell('Wärmenetz - Station Süwag\n\nBEW Förderung\nStation Eigentum der Süwag\nÜbergabestation 10 kW TWW-\nSpeicher Vorlauf 70°C, 30 %\nAbwärme aus RZ', fontSize: 10),
      ],
    );
  }

  // ========== ABSCHNITT A: GRUNDDATEN ==========
  List<TableRow> _buildAbschnittA() {
    return [
      _buildAbschnittHeader('A.', 'Grunddaten'),

      // A.1: Beheizte Fläche
      _buildDataRow(
        'A.1',
        'Gesamte beheizte Fläche EFH',
        'm²',
        [
          _buildEditableCell(
            wert: stammdaten.grunddaten.beheizteFlaeche.wert,
            nachkommastellen: 2,
            quelle: stammdaten.grunddaten.beheizteFlaeche.quelle,
            quellenTitel: 'Beheizte Fläche',
            onChanged: (neuerWert) {
              final neueGrunddaten = GrunddatenKostenvergleich(
                beheizteFlaeche: WertMitQuelle(
                  wert: neuerWert,
                  quelle: stammdaten.grunddaten.beheizteFlaeche.quelle,
                ),
                spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
                heizenergiebedarf: WertMitQuelle(
                  wert: neuerWert * stammdaten.grunddaten.spezHeizenergiebedarf.wert,
                  quelle: stammdaten.grunddaten.heizenergiebedarf.quelle,
                ),
                anteilGaswaerme: stammdaten.grunddaten.anteilGaswaerme, // NEU
              );
              _updateStammdaten(stammdaten.copyWith(grunddaten: neueGrunddaten));
            },
            onQuelleChanged: (neueQuelle) {
              final neueGrunddaten = GrunddatenKostenvergleich(
                beheizteFlaeche: WertMitQuelle(
                  wert: stammdaten.grunddaten.beheizteFlaeche.wert,
                  quelle: neueQuelle,
                ),
                spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
                heizenergiebedarf: stammdaten.grunddaten.heizenergiebedarf,
                anteilGaswaerme: stammdaten.grunddaten.anteilGaswaerme, // NEU
              );
              _updateStammdaten(stammdaten.copyWith(grunddaten: neueGrunddaten));
            },
          ),
          _buildReadOnlyCell(stammdaten.grunddaten.beheizteFlaeche.wert, 2),
          _buildReadOnlyCell(stammdaten.grunddaten.beheizteFlaeche.wert, 2),
          _buildReadOnlyCell(stammdaten.grunddaten.beheizteFlaeche.wert, 2),
        ],
      ),

// A.2: Spez. Heizenergiebedarf
      _buildDataRow(
        'A.2',
        'spez. Heizenergiebedarf (inkl. Warmwasser)',
        'kWh/m²a',
        [
          _buildEditableCell(
            wert: stammdaten.grunddaten.spezHeizenergiebedarf.wert,
            nachkommastellen: 0,
            quelle: stammdaten.grunddaten.spezHeizenergiebedarf.quelle,
            quellenTitel: 'Spez. Heizenergiebedarf',
            onChanged: (neuerWert) {
              final neueGrunddaten = GrunddatenKostenvergleich(
                beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
                spezHeizenergiebedarf: WertMitQuelle(
                  wert: neuerWert,
                  quelle: stammdaten.grunddaten.spezHeizenergiebedarf.quelle,
                ),
                heizenergiebedarf: WertMitQuelle(
                  wert: stammdaten.grunddaten.beheizteFlaeche.wert * neuerWert,
                  quelle: stammdaten.grunddaten.heizenergiebedarf.quelle,
                ),
                anteilGaswaerme: stammdaten.grunddaten.anteilGaswaerme, // NEU
              );
              _updateStammdaten(stammdaten.copyWith(grunddaten: neueGrunddaten));
            },
            onQuelleChanged: (neueQuelle) {
              final neueGrunddaten = GrunddatenKostenvergleich(
                beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
                spezHeizenergiebedarf: WertMitQuelle(
                  wert: stammdaten.grunddaten.spezHeizenergiebedarf.wert,
                  quelle: neueQuelle,
                ),
                heizenergiebedarf: stammdaten.grunddaten.heizenergiebedarf,
                anteilGaswaerme: stammdaten.grunddaten.anteilGaswaerme, // NEU
              );
              _updateStammdaten(stammdaten.copyWith(grunddaten: neueGrunddaten));
            },
          ),
          _buildReadOnlyCell(stammdaten.grunddaten.spezHeizenergiebedarf.wert, 0),
          _buildReadOnlyCell(stammdaten.grunddaten.spezHeizenergiebedarf.wert, 0),
          _buildReadOnlyCell(stammdaten.grunddaten.spezHeizenergiebedarf.wert, 0),
        ],
      ),

      // A.3: Heizenergiebedarf (berechnet)
      _buildDataRow(
        'A.3',
        'Heizenergiebedarf',
        'kWh/a',
        [
          _buildReadOnlyCell(stammdaten.grunddaten.heizenergiebedarf.wert, 0, farbe: SuewagColors.fasergruen),
          _buildReadOnlyCell(stammdaten.grunddaten.heizenergiebedarf.wert, 0, farbe: SuewagColors.fasergruen),
          _buildReadOnlyCell(stammdaten.grunddaten.heizenergiebedarf.wert, 0, farbe: SuewagColors.fasergruen),
          _buildReadOnlyCell(stammdaten.grunddaten.heizenergiebedarf.wert, 0, farbe: SuewagColors.fasergruen),
        ],
      ),
    ];
  }

  // ========== ABSCHNITT B: INVESTITIONSKOSTEN ==========
  List<TableRow> _buildAbschnittB(List<dynamic> ergebnisse) {
    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    return [
      _buildAbschnittHeader('B.', 'Investitionskosten (einmalige Kosten)'),

      // B.1: Wärmepumpe
      _buildDataRow(
        'B.1',
        wpSzenario.investition.waermepumpe?.bezeichnung ?? 'Platzhalter Überschrift',
        '€',
        [
          wpSzenario.investition.waermepumpe != null
              ? _buildEditableCell(
            wert: wpSzenario.investition.waermepumpe!.betrag.wert,
            nachkommastellen: 0,
            quelle: wpSzenario.investition.waermepumpe!.betrag.quelle,
            quellenTitel: wpSzenario.investition.waermepumpe!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermepumpe', 'waermepumpe', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermepumpe', 'waermepumpe', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // B.2: Übergabestation
      _buildDataRow(
        'B.2',
        kundeSzenario.investition.uebergabestation?.bezeichnung ?? 'Platzhalter Überschrift',
        '€',
        [
          _buildEmptyCell(),
          _buildEmptyCell(),
          kundeSzenario.investition.uebergabestation != null
              ? _buildEditableCell(
            wert: kundeSzenario.investition.uebergabestation!.betrag.wert,
            nachkommastellen: 0,
            quelle: kundeSzenario.investition.uebergabestation!.betrag.quelle,
            quellenTitel: kundeSzenario.investition.uebergabestation!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermenetzKunde', 'uebergabestation', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermenetzKunde', 'uebergabestation', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // B.3: TWW-Speicher
      _buildDataRow(
        'B.3',
        'TWW-Speicher inkl. Puffer / FW exkl. Puffer',
        '€',
        [
          wpSzenario.investition.twwSpeicher != null
              ? _buildEditableCell(
            wert: wpSzenario.investition.twwSpeicher!.betrag.wert,
            nachkommastellen: 0,
            quelle: wpSzenario.investition.twwSpeicher!.betrag.quelle,
            quellenTitel: wpSzenario.investition.twwSpeicher!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermepumpe', 'twwSpeicher', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermepumpe', 'twwSpeicher', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
          kundeSzenario.investition.twwSpeicher != null
              ? _buildEditableCell(
            wert: kundeSzenario.investition.twwSpeicher!.betrag.wert,
            nachkommastellen: 0,
            quelle: kundeSzenario.investition.twwSpeicher!.betrag.quelle,
            quellenTitel: kundeSzenario.investition.twwSpeicher!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermenetzKunde', 'twwSpeicher', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermenetzKunde', 'twwSpeicher', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // B.4: Hydraulik (Text-Zelle)
      _buildDataRow(
        'B.4',
        'Hydraulik inkl. Zubehör, Wärmedämmung, ELT + MSR',
        '€',
        [
          _buildTextCell('inkl.'),
          _buildEmptyCell(),
          _buildTextCell('inkl.'),
          _buildEmptyCell(),
        ],
      ),

      // B.6: Heizlastberechnung
      _buildDataRow(
        'B.6',
        kundeSzenario.investition.heizlastberechnung?.bezeichnung ?? 'Platzhalter Überschrift',
        '€',
        [
          _buildTextCell('inkl.'),
          _buildEmptyCell(),
          kundeSzenario.investition.heizlastberechnung != null
              ? _buildEditableCell(
            wert: kundeSzenario.investition.heizlastberechnung!.betrag.wert,
            nachkommastellen: 0,
            quelle: kundeSzenario.investition.heizlastberechnung!.betrag.quelle,
            quellenTitel: kundeSzenario.investition.heizlastberechnung!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermenetzKunde', 'heizlastberechnung', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermenetzKunde', 'heizlastberechnung', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // B.7: Zählerschrank
      _buildDataRow(
        'B.7',
        wpSzenario.investition.zaehlerschrank?.bezeichnung ?? 'Platzhalter Überschrift',
        '€',
        [
          wpSzenario.investition.zaehlerschrank != null
              ? _buildEditableCell(
            wert: wpSzenario.investition.zaehlerschrank!.betrag.wert,
            nachkommastellen: 0,
            quelle: wpSzenario.investition.zaehlerschrank!.betrag.quelle,
            quellenTitel: wpSzenario.investition.zaehlerschrank!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermepumpe', 'zaehlerschrank', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermepumpe', 'zaehlerschrank', neueQuelle);
            },
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // B.8: BKZ
      _buildDataRow(
        'B.8',
        suewagSzenario.investition.bkz?.bezeichnung ?? 'Platzhalter Überschrift',
        '€',
        [
          _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
          suewagSzenario.investition.bkz != null
              ? _buildEditableCell(
            wert: suewagSzenario.investition.bkz!.betrag.wert,
            nachkommastellen: 0,
            quelle: suewagSzenario.investition.bkz!.betrag.quelle,
            quellenTitel: suewagSzenario.investition.bkz!.bezeichnung,
            onChanged: (neuerWert) {
              _updateInvestitionsposition('waermenetzSuewag', 'bkz', neuerWert);
            },
            onQuelleChanged: (neueQuelle) {
              _updateInvestitionspositionQuelle('waermenetzSuewag', 'bkz', neueQuelle);
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // B.9: Förderung (berechnet - negativ)
      _buildDataRow(
        'B.9',
        'Förderung BEG 30 %',
        '€',
        [
          _buildReadOnlyCell(-wpSzenario.investition.foerderbetrag, 2, farbe: Colors.red),
          _buildReadOnlyCell(-ohneSzenario.investition.foerderbetrag, 2, farbe: Colors.red),
          _buildReadOnlyCell(-kundeSzenario.investition.foerderbetrag, 2, farbe: Colors.red),
          // NEU: Für Süwag mit Hinweis, dass Förderung bereits in BKZ enthalten ist
          Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: SuewagColors.background,
                border: Border.all(color: SuewagColors.divider),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '0,00',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Förderung bereits in BKZ (B.8) enthalten',
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: SuewagColors.primary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // B.10: Gesamt exkl. Förderung (berechnet)
      _buildDataRow(
        'B.10',
        'Investitionskosten exkl. Förderung (netto, zzgl. MwSt.)',
        '€',
        [
          _buildReadOnlyCell(wpSzenario.investition.gesamtBrutto, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(ohneSzenario.investition.gesamtBrutto, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(kundeSzenario.investition.gesamtBrutto, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(suewagSzenario.investition.gesamtBrutto, 2, farbe: SuewagColors.fasergruen, bold: true),
        ],
      ),

      // B.11: Gesamt inkl. Förderung (berechnet)
      _buildDataRow(
        'B.11',
        'Investitionskosten inkl. Förderung (netto, zzgl. MwSt.)',
        '€',
        [
          _buildReadOnlyCell(wpSzenario.investition.nettoNachFoerderung, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(ohneSzenario.investition.nettoNachFoerderung, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(kundeSzenario.investition.nettoNachFoerderung, 2, farbe: SuewagColors.fasergruen, bold: true),
          _buildReadOnlyCell(suewagSzenario.investition.nettoNachFoerderung, 2, farbe: SuewagColors.fasergruen, bold: true),
        ],
      ),
    ];
  }

  // ========== ABSCHNITT C: WÄRMEKOSTEN ==========
  List<TableRow> _buildAbschnittC(List<dynamic> ergebnisse) {
    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    return [
      _buildAbschnittHeader('C.', 'Wärmekosten (laufende Kosten)'),

      // C.1: Stromverbrauch WP (teilweise berechnet)
      // In kostenvergleich_edit_table_widget.dart - _buildAbschnittC

// C.1: Stromverbrauch WP (JETZT BERECHNET: A.3 / JAZ)
      _buildDataRow(
        'C.1',
        'zu beziehender Verbrauch Strom',
        'kWh/a',
        [
          wpSzenario.waermekosten.jahresarbeitszahl != null
              ? _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert /
                wpSzenario.waermekosten.jahresarbeitszahl!.wert,
            0,
            farbe: SuewagColors.fasergruen,
          )
              : _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

      // In kostenvergleich_edit_table_widget.dart - _buildAbschnittC anpassen:

// C.2: Verbrauch Gas (BERECHNET aus Grunddaten)
      _buildDataRow(
        'C.2',
        'zu bezahlender Verbrauch (Wärme aus Gas)',
        'kWh/a',
        [
          _buildEmptyCell(),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * stammdaten.grunddaten.anteilGaswaerme.wert,
            0,
            farbe: SuewagColors.fasergruen,
          ),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * stammdaten.grunddaten.anteilGaswaerme.wert,
            0,
            farbe: SuewagColors.fasergruen,
          ),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * stammdaten.grunddaten.anteilGaswaerme.wert,
            0,
            farbe: SuewagColors.fasergruen,
          ),
        ],
      ),

// C.3: Verbrauch Strom (BERECHNET aus Grunddaten)
      _buildDataRow(
        'C.3',
        'zu bezahlender Verbrauch (Wärme aus Strom)',
        'kWh/a',
        [
          _buildEmptyCell(),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * (1 - stammdaten.grunddaten.anteilGaswaerme.wert),
            0,
            farbe: SuewagColors.fasergruen,
          ),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * (1 - stammdaten.grunddaten.anteilGaswaerme.wert),
            0,
            farbe: SuewagColors.fasergruen,
          ),
          _buildReadOnlyCell(
            stammdaten.grunddaten.heizenergiebedarf.wert * (1 - stammdaten.grunddaten.anteilGaswaerme.wert),
            0,
            farbe: SuewagColors.fasergruen,
          ),
        ],
      ),
      // C.4: Arbeitspreis Strom/Gas
      _buildDataRow(
        'C.4',
        'Arbeitspreis Strom / o. "Wärme aus Gas"',
        'ct/kWh',
        [
          wpSzenario.waermekosten.stromarbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            quelle: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Strom',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermepumpe',
                wpSzenario.waermekosten.copyWith(
                  stromarbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermepumpe',
                wpSzenario.waermekosten.copyWith(
                  stromarbeitspreisCtKWh: WertMitQuelle(
                    wert: wpSzenario.waermekosten.stromarbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 4,
            quelle: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Gas',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 4,
            quelle: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Gas',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: kundeSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
            nachkommastellen: 4,
            quelle: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Gas',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeGasArbeitspreisCtKWh: WertMitQuelle(
                    wert: suewagSzenario.waermekosten.waermeGasArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // C.5: AP Wärme aus Strom
      _buildDataRow(
        'C.5',
        'Arbeitspreis "Wärme aus Strom"',
        'ct/kWh',
        [
          _buildEmptyCell(),
          ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            quelle: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Strom',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            quelle: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Strom',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: kundeSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh != null
              ? _buildEditableCell(
            wert: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
            nachkommastellen: 2,
            quelle: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
            quellenTitel: 'AP Strom',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeStromArbeitspreisCtKWh: WertMitQuelle(
                    wert: suewagSzenario.waermekosten.waermeStromArbeitspreisCtKWh!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // C.6: Grundpreis
      _buildDataRow(
        'C.6',
        'Grundpreis Strom / o. Wärme',
        '€/a',
        [
          wpSzenario.waermekosten.stromGrundpreisEuroMonat != null
              ? _buildEditableCell(
            wert: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.wert * 12,
            nachkommastellen: 0,
            quelle: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.quelle,
            quellenTitel: 'Grundpreis Strom',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermepumpe',
                wpSzenario.waermekosten.copyWith(
                  stromGrundpreisEuroMonat: WertMitQuelle(
                    wert: neuerWert / 12,
                    quelle: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermepumpe',
                wpSzenario.waermekosten.copyWith(
                  stromGrundpreisEuroMonat: WertMitQuelle(
                    wert: wpSzenario.waermekosten.stromGrundpreisEuroMonat!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          ohneSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? _buildEditableCell(
            wert: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            quelle: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
            quellenTitel: 'Grundpreis Wärme',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          kundeSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? _buildEditableCell(
            wert: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            quelle: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
            quellenTitel: 'Grundpreis Wärme',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: kundeSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          suewagSzenario.waermekosten.waermeGrundpreisEuroJahr != null
              ? _buildEditableCell(
            wert: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
            nachkommastellen: 0,
            quelle: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
            quellenTitel: 'Grundpreis Wärme',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  waermeGrundpreisEuroJahr: WertMitQuelle(
                    wert: suewagSzenario.waermekosten.waermeGrundpreisEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // C.7: Messpreis
      // In _buildAbschnittC() - C.7 durch neue Struktur ersetzen:

// C.7A: Messpreis Wasserzähler (nur Variante 2)
      _buildDataRow(
        'C.7A',
        'Messpreis Wasserzähler',
        '€/a',
        [
          _buildEmptyCell(),
          _buildEditableCell(
            wert: ohneSzenario.waermekosten.messpreisWasserzaehlerEuroJahr?.wert ?? 0.0, // Fallback!
            nachkommastellen: 2,
            quelle: ohneSzenario.waermekosten.messpreisWasserzaehlerEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Messpreis Wasserzähler', beschreibung: 'Standardwert'),
            quellenTitel: 'Messpreis Wasserzähler',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisWasserzaehlerEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.messpreisWasserzaehlerEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Messpreis Wasserzähler', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisWasserzaehlerEuroJahr: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.messpreisWasserzaehlerEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
          _buildEmptyCell(),
          _buildEmptyCell(),
        ],
      ),

// C.7B: Messpreis Wärmezähler (Variante 2, 3, 4)
      _buildDataRow(
        'C.7B',
        'Messpreis Wärmezähler',
        '€/a',
        [
          _buildEmptyCell(),
          _buildEditableCell(
            wert: ohneSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: ohneSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Standardwert'),
            quellenTitel: 'Messpreis Wärmezähler',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
          _buildEditableCell(
            wert: kundeSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: kundeSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Standardwert'),
            quellenTitel: 'Messpreis Wärmezähler',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: kundeSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
          _buildEditableCell(
            wert: suewagSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: suewagSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Standardwert'),
            quellenTitel: 'Messpreis Wärmezähler',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Messpreis Wärmezähler', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  messpreisWaermezaehlerEuroJahr: WertMitQuelle(
                    wert: suewagSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
        ],
      ),

// C.7C: Eichgebühren (Variante 2, 3, 4)
      _buildDataRow(
        'C.7C',
        'Eichgebühren Wärmezähler',
        '€/a',
        [
          _buildEmptyCell(),
          _buildEditableCell(
            wert: ohneSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: ohneSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Standardwert'),
            quellenTitel: 'Eichgebühren',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzOhneUGS',
                ohneSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: ohneSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
          _buildEditableCell(
            wert: kundeSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: kundeSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Standardwert'),
            quellenTitel: 'Eichgebühren',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzKunde',
                kundeSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: kundeSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
          _buildEditableCell(
            wert: suewagSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
            nachkommastellen: 2,
            quelle: suewagSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Standardwert'),
            quellenTitel: 'Eichgebühren',
            onChanged: (neuerWert) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.quelle ??
                        const QuellenInfo(titel: 'Eichgebühren', beschreibung: 'Benutzer definiert'),
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateWaermekosten('waermenetzSuewag',
                suewagSzenario.waermekosten.copyWith(
                  messpreisEichgebuehrenEuroJahr: WertMitQuelle(
                    wert: suewagSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0.0,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    // C.7: Summe Messpreise (BERECHNET)
    _buildDataRow(
    'C.7',
    'Summe Messpreise (Wasser + Wärme + Eichgebühren)',
    '€/a',
    [
    _buildEmptyCell(),
    _buildReadOnlyCell(
    (ohneSzenario.waermekosten.messpreisWasserzaehlerEuroJahr?.wert ?? 0) +
    (ohneSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0) +
    (ohneSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0),
    2,
    farbe: SuewagColors.fasergruen,
    bold: true,
    ),
    _buildReadOnlyCell(
    (kundeSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0) +
    (kundeSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0),
    2,
    farbe: SuewagColors.fasergruen,
    bold: true,
    ),
    _buildReadOnlyCell(
    (suewagSzenario.waermekosten.messpreisWaermezaehlerEuroJahr?.wert ?? 0) +
    (suewagSzenario.waermekosten.messpreisEichgebuehrenEuroJahr?.wert ?? 0),
    2,
    farbe: SuewagColors.fasergruen,
    bold: true,
    ),
    ],
    ),
      // C.8: Summe Wärmekosten (berechnet)
      _buildDataRow(
        'C.8',
        'Summe Wärmekosten, netto',
        '€/a',
        ergebnisse.map<Widget>((e) {
          final summe = e.kosten.arbeitspreis + e.kosten.grundUndMesspreis;
          return _buildReadOnlyCell(summe, 2, farbe: SuewagColors.fasergruen, bold: true);
        }).toList(),
      ),
    ];
  }

  // ========== ABSCHNITT D: NEBENKOSTEN ==========
  List<TableRow> _buildAbschnittD(List<dynamic> ergebnisse) {
    final wpSzenario = stammdaten.szenarien['waermepumpe']!;
    final ohneSzenario = stammdaten.szenarien['waermenetzOhneUGS']!;
    final kundeSzenario = stammdaten.szenarien['waermenetzKunde']!;
    final suewagSzenario = stammdaten.szenarien['waermenetzSuewag']!;

    return [
      _buildAbschnittHeader('D.', 'Nebenkosten (laufende Kosten)'),

      // D.1: Wartung
      _buildDataRow(
        'D.1',
        'Wartung & Instandhaltung',
        '€/a',
        [
          wpSzenario.nebenkosten.wartungEuroJahr != null
              ? _buildEditableCell(
            wert: wpSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            quelle: wpSzenario.nebenkosten.wartungEuroJahr!.quelle,
            quellenTitel: 'Wartung',
            onChanged: (neuerWert) {
              _updateNebenkosten('waermepumpe',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: wpSzenario.nebenkosten.wartungEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateNebenkosten('waermepumpe',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: wpSzenario.nebenkosten.wartungEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          ohneSzenario.nebenkosten.wartungEuroJahr != null
              ? _buildEditableCell(
            wert: ohneSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            quelle: ohneSzenario.nebenkosten.wartungEuroJahr!.quelle,
            quellenTitel: 'Wartung',
            onChanged: (neuerWert) {
              _updateNebenkosten('waermenetzOhneUGS',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: ohneSzenario.nebenkosten.wartungEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateNebenkosten('waermenetzOhneUGS',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: ohneSzenario.nebenkosten.wartungEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          kundeSzenario.nebenkosten.wartungEuroJahr != null
              ? _buildEditableCell(
            wert: kundeSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            quelle: kundeSzenario.nebenkosten.wartungEuroJahr!.quelle,
            quellenTitel: 'Wartung',
            onChanged: (neuerWert) {
              _updateNebenkosten('waermenetzKunde',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: kundeSzenario.nebenkosten.wartungEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateNebenkosten('waermenetzKunde',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: kundeSzenario.nebenkosten.wartungEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
          suewagSzenario.nebenkosten.wartungEuroJahr != null
              ? _buildEditableCell(
            wert: suewagSzenario.nebenkosten.wartungEuroJahr!.wert,
            nachkommastellen: 2,
            quelle: suewagSzenario.nebenkosten.wartungEuroJahr!.quelle,
            quellenTitel: 'Wartung',
            onChanged: (neuerWert) {
              _updateNebenkosten('waermenetzSuewag',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.nebenkosten.wartungEuroJahr!.quelle,
                  ),
                  grundpreisUebergabestationEuroJahr: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr,
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateNebenkosten('waermenetzSuewag',
                NebenkostenDaten(
                  wartungEuroJahr: WertMitQuelle(
                    wert: suewagSzenario.nebenkosten.wartungEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                  grundpreisUebergabestationEuroJahr: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr,
                ),
              );
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // D.2: Zusätzlicher Grundpreis ÜGS
      _buildDataRow(
        'D.2',
        'Zusätzlicher Grundpreis Übergabestation',
        '€/a',
        [
          _buildEmptyCell(),
          _buildEmptyCell(),
          _buildEmptyCell(),
          suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr != null
              ? _buildEditableCell(
            wert: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.wert,
            nachkommastellen: 2,
            quelle: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.quelle,
            quellenTitel: 'Grundpreis ÜGS',
            onChanged: (neuerWert) {
              _updateNebenkosten('waermenetzSuewag',
                NebenkostenDaten(
                  wartungEuroJahr: suewagSzenario.nebenkosten.wartungEuroJahr,
                  grundpreisUebergabestationEuroJahr: WertMitQuelle(
                    wert: neuerWert,
                    quelle: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.quelle,
                  ),
                ),
              );
            },
            onQuelleChanged: (neueQuelle) {
              _updateNebenkosten('waermenetzSuewag',
                NebenkostenDaten(
                  wartungEuroJahr: suewagSzenario.nebenkosten.wartungEuroJahr,
                  grundpreisUebergabestationEuroJahr: WertMitQuelle(
                    wert: suewagSzenario.nebenkosten.grundpreisUebergabestationEuroJahr!.wert,
                    quelle: neueQuelle,
                  ),
                ),
              );
            },
          )
              : _buildEmptyCell(),
        ],
      ),

      // D.3: Kapitaldienst (berechnet)
      // D.3: Kapitaldienst mit Info-Button
      _buildKapitaldienstRow(ergebnisse),

      // D.4: Summe Nebenkosten (berechnet)
      _buildDataRow(
        'D.4',
        'Summe Nebenkosten, netto',
        '€/a',
        ergebnisse.map<Widget>((e) {
          final summe = e.kosten.betriebskosten +
              e.kosten.kapitalkosten +
              e.kosten.zusaetzlicherGrundpreisUebergabestation;
          return _buildReadOnlyCell(summe, 2, farbe: SuewagColors.fasergruen, bold: true);
        }).toList(),
      ),
    ];
  }
// In kostenvergleich_edit_table_widget.dart - bei D.3

// D.3: Kapitaldienst (berechnet) mit Info-Button
  TableRow _buildKapitaldienstRow(List<dynamic> ergebnisse) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('D.3', style: SuewagTextStyles.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kapitaldienst: Investition BKZ inkl. Förderung',
                  style: SuewagTextStyles.bodySmall,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _zeigeKapitaldienstInfoDialog(context),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: SuewagColors.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '€/a',
            style: SuewagTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        ...ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.kosten.kapitalkosten, 2, farbe: SuewagColors.fasergruen);
        }).toList(),
      ],
    );
  }

// Dialog mit Erklärung
  void _zeigeKapitaldienstInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calculate, color: SuewagColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Kapitaldienst - Berechnungsmethodik'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Was ist der Kapitaldienst?',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Der Kapitaldienst ist die jährliche Zahlung (Annuität), die zur Finanzierung der Investitionskosten aufgebracht werden muss. Er umfasst sowohl Zins- als auch Tilgungsanteil.',
                style: SuewagTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),

              Text(
                'Berechnungsgrundlage',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Der Kapitaldienst wird auf Basis der Investitionskosten NACH Förderung (Zeile B.11) berechnet.',
                style: SuewagTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),

              Text(
                'Berechnungsmethode',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Es wird die Annuitätenmethode mit vorschüssiger Zahlung verwendet (Zahlung am Jahresanfang).',
                style: SuewagTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SuewagColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formel:',
                      style: SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Annuität = Investition × [q^n × (q-1)] / [q^n - 1] / q',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wobei:',
                      style: SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildFormelZeile('q', '= 1 + Zinssatz'),
                    _buildFormelZeile('n', '= Laufzeit in Jahren'),
                    _buildFormelZeile('Division durch q', '= Umrechnung auf vorschüssige Zahlung'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Beispielrechnung',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.fasergruen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBeispielZeile('Investition nach Förderung:', '35.000 €'),
                    _buildBeispielZeile('Zinssatz:', '3,0 %'),
                    _buildBeispielZeile('Laufzeit:', '20 Jahre'),
                    const Divider(height: 16),
                    _buildBeispielZeile(
                      'Jährlicher Kapitaldienst:',
                      '≈ 2.084 €/a',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Excel-Äquivalent',
                style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.indiablau.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '=RMZ(Zinssatz; Laufzeit; -Investition; 0; 1)',
                  style: SuewagTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Der Parameter "1" am Ende steht für vorschüssige Zahlung (am Jahresanfang).',
                style: SuewagTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: SuewagColors.textSecondary,
                ),
              ),
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

  Widget _buildFormelZeile(String symbol, String beschreibung) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              symbol,
              style: SuewagTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              beschreibung,
              style: SuewagTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeispielZeile(String label, String wert, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            wert,
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  // ========== ABSCHNITT E: JAHRESKOSTEN ==========
  List<TableRow> _buildAbschnittE(List<dynamic> ergebnisse) {
    return [
      _buildAbschnittHeader('E.', 'Jahreskosten (Wärme- & Nebenkosten)'),

      // E.1: Wärmevollkostenpreis netto (berechnet)
      _buildDataRow(
        'E.1',
        'Wärmevollkostenpreis netto (netto, inkl. MwSt.)',
        '€/MWh',
        ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.waermevollkostenpreisNetto, 2, farbe: SuewagColors.indiablau, bold: true);
        }).toList(),
      ),

      // E.2: Wärmevollkostenpreis brutto (berechnet)
      _buildDataRow(
        'E.2',
        'Wärmevollkostenpreis spez. (brutto, inkl. MwSt.)',
        '€/MWh',
        ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.waermevollkostenpreisBrutto, 2, farbe: SuewagColors.indiablau);
        }).toList(),
      ),

      // E.3: Jahreskosten netto (berechnet)
      _buildDataRow(
        'E.3',
        'Jahreskosten (netto, zzgl. MwSt.)',
        '€/a',
        ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.jahreskosten, 2, farbe: SuewagColors.verkehrsorange, bold: true);
        }).toList(),
      ),

      // E.4: Jahreskosten brutto (berechnet)
      _buildDataRow(
        'E.4',
        'Jahreskosten (brutto, inkl. MwSt.)',
        '€/a',
        ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.jahreskosten_brutto, 2, farbe: SuewagColors.verkehrsorange);
        }).toList(),
      ),

      // E.5: Kosten pro m² (berechnet)
      _buildDataRow(
        'E.5',
        'Kosten pro m² Wohnfläche (brutto, inkl. MwSt.)',
        '€/m²',
        ergebnisse.map<Widget>((e) {
          return _buildReadOnlyCell(e.kostenProQuadratmeter * 1.19, 2, farbe: SuewagColors.verkehrsorange);
        }).toList(),
      ),
    ];
  }

  // ========== HELPER WIDGETS ==========

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
      List<Widget> werte,
      ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(pos, style: SuewagTextStyles.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(bezeichnung, style: SuewagTextStyles.bodySmall),
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

  Widget _buildHeaderCell(String text, {double fontSize = 12}) {
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

  Widget _buildEditableCell({
    required double wert,
    required int nachkommastellen,
    required QuellenInfo quelle,
    required String quellenTitel,
    required Function(double) onChanged,
    required Function(QuellenInfo) onQuelleChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: deutscheZahl(wert, nachkommastellen),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                GermanNumberInputFormatter(nachkommastellen: nachkommastellen),
              ],
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                final parsed = parseGermanNumber(text);
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _zeigeQuellenDialog(quellenTitel, quelle, onQuelleChanged),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: SuewagColors.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyCell(double wert, int nachkommastellen, {Color? farbe, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: SuewagColors.background,
          border: Border.all(color: SuewagColors.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          deutscheZahl(wert, nachkommastellen),
          style: TextStyle(
            fontSize: 12,
            color: farbe ?? Colors.black54,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: SizedBox.shrink(),
    );
  }

  Widget _buildTextCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: SuewagTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  // ========== UPDATE METHODEN ==========

  void _updateInvestitionsposition(String szenarioId, String positionKey, double neuerWert) {
    final szenario = stammdaten.szenarien[szenarioId]!;
    InvestitionsPosition? position;

    switch (positionKey) {
      case 'waermepumpe':
        position = szenario.investition.waermepumpe;
        break;
      case 'twwSpeicher':
        position = szenario.investition.twwSpeicher;
        break;
      case 'uebergabestation':
        position = szenario.investition.uebergabestation;
        break;
      case 'heizlastberechnung':
        position = szenario.investition.heizlastberechnung;
        break;
      case 'zaehlerschrank':
        position = szenario.investition.zaehlerschrank;
        break;
      case 'bkz':
        position = szenario.investition.bkz;
        break;
    }

    if (position == null) return;

    final neuePosition = InvestitionsPosition(
      bezeichnung: position.bezeichnung,
      betrag: WertMitQuelle(
        wert: neuerWert,
        quelle: position.betrag.quelle,
      ),
      bemerkung: position.bemerkung,
    );

    _neuberechnungInvestition(szenarioId, positionKey, neuePosition);
  }

  void _updateInvestitionspositionQuelle(String szenarioId, String positionKey, QuellenInfo neueQuelle) {
    final szenario = stammdaten.szenarien[szenarioId]!;
    InvestitionsPosition? position;

    switch (positionKey) {
      case 'waermepumpe':
        position = szenario.investition.waermepumpe;
        break;
      case 'twwSpeicher':
        position = szenario.investition.twwSpeicher;
        break;
      case 'uebergabestation':
        position = szenario.investition.uebergabestation;
        break;
      case 'heizlastberechnung':
        position = szenario.investition.heizlastberechnung;
        break;
      case 'zaehlerschrank':
        position = szenario.investition.zaehlerschrank;
        break;
      case 'bkz':
        position = szenario.investition.bkz;
        break;
    }

    if (position == null) return;

    final neuePosition = InvestitionsPosition(
      bezeichnung: position.bezeichnung,
      betrag: WertMitQuelle(
        wert: position.betrag.wert,
        quelle: neueQuelle,
      ),
      bemerkung: position.bemerkung,
    );

    _neuberechnungInvestition(szenarioId, positionKey, neuePosition);
  }

  void _neuberechnungInvestition(String szenarioId, String positionKey, InvestitionsPosition neuePosition) {
    final szenario = stammdaten.szenarien[szenarioId]!;

    // Alle Positionen sammeln
    InvestitionsPosition? waermepumpe = szenario.investition.waermepumpe;
    InvestitionsPosition? twwSpeicher = szenario.investition.twwSpeicher;
    InvestitionsPosition? uebergabestation = szenario.investition.uebergabestation;
    InvestitionsPosition? heizlastberechnung = szenario.investition.heizlastberechnung;
    InvestitionsPositionText? hydraulik = szenario.investition.hydraulik;
    InvestitionsPosition? zaehlerschrank = szenario.investition.zaehlerschrank;
    InvestitionsPosition? bkz = szenario.investition.bkz;

    // Die geänderte Position ersetzen
    switch (positionKey) {
      case 'waermepumpe':
        waermepumpe = neuePosition;
        break;
      case 'twwSpeicher':
        twwSpeicher = neuePosition;
        break;
      case 'uebergabestation':
        uebergabestation = neuePosition;
        break;
      case 'heizlastberechnung':
        heizlastberechnung = neuePosition;
        break;
      case 'zaehlerschrank':
        zaehlerschrank = neuePosition;
        break;
      case 'bkz':
        bkz = neuePosition;
        break;
    }

    // Gesamt neu berechnen
    // KORRIGIERT: Summe aus B.1 bis B.8 (alle Einzelpositionen)
    double gesamtBrutto = 0;
    if (waermepumpe != null) gesamtBrutto += waermepumpe.betrag.wert;        // B.1
    if (uebergabestation != null) gesamtBrutto += uebergabestation.betrag.wert; // B.2
    if (twwSpeicher != null) gesamtBrutto += twwSpeicher.betrag.wert;        // B.3
    // B.4 Hydraulik ist "inkl." - kein zusätzlicher Betrag
    // B.5 fehlt in der aktuellen Struktur
    if (heizlastberechnung != null) gesamtBrutto += heizlastberechnung.betrag.wert; // B.6
    if (zaehlerschrank != null) gesamtBrutto += zaehlerschrank.betrag.wert;  // B.7
    if (bkz != null) gesamtBrutto += bkz.betrag.wert;                        // B.8

    // Förderung berechnen
    double foerderquote = 0.0;
    FoerderungsTyp foerderungsTyp = FoerderungsTyp.keine;

    // NEU: Für waermenetzSuewag KEINE Förderung (bereits in BKZ enthalten)
    if (szenarioId == 'waermenetzSuewag') {
      foerderquote = 0.0;
      foerderungsTyp = FoerderungsTyp.keine; // Oder behalte FoerderungsTyp.bew als Info, dass es eigentlich BEW wäre
    } else if (szenarioId == 'waermepumpe' || szenarioId == 'waermenetzKunde') {
      foerderquote = stammdaten.finanzierung.foerderungBEG.wert;
      foerderungsTyp = FoerderungsTyp.beg;
    }

    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    // Neue Investition erstellen
    final neueInvestition = InvestitionskostenDaten(
      waermepumpe: waermepumpe,
      twwSpeicher: twwSpeicher,
      uebergabestation: uebergabestation,
      heizlastberechnung: heizlastberechnung,
      hydraulik: hydraulik,
      zaehlerschrank: zaehlerschrank,
      bkz: bkz,
      gesamtBrutto: gesamtBrutto,
      foerderungsTyp: foerderungsTyp,
      foerderquote: foerderquote,
      foerderbetrag: foerderbetrag,
      nettoNachFoerderung: netto,
    );

    // Szenario aktualisieren
    final neuesSzenario = SzenarioStammdaten(
      id: szenario.id,
      bezeichnung: szenario.bezeichnung,
      beschreibung: szenario.beschreibung,
      typ: szenario.typ,
      sortierung: szenario.sortierung,
      investition: neueInvestition,
      waermekosten: szenario.waermekosten,
      nebenkosten: szenario.nebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    _updateStammdaten(stammdaten.copyWith(szenarien: neueSzenarien));
  }
  void _updateWaermekosten(String szenarioId, WaermekostenDaten neueWaermekosten) {
    final szenario = stammdaten.szenarien[szenarioId]!;

    final neuesSzenario = SzenarioStammdaten(
      id: szenario.id,
      bezeichnung: szenario.bezeichnung,
      beschreibung: szenario.beschreibung,
      typ: szenario.typ,
      sortierung: szenario.sortierung,
      investition: szenario.investition,
      waermekosten: neueWaermekosten,
      nebenkosten: szenario.nebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    _updateStammdaten(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  void _updateNebenkosten(String szenarioId, NebenkostenDaten neueNebenkosten) {
    final szenario = stammdaten.szenarien[szenarioId]!;

    final neuesSzenario = SzenarioStammdaten(
      id: szenario.id,
      bezeichnung: szenario.bezeichnung,
      beschreibung: szenario.beschreibung,
      typ: szenario.typ,
      sortierung: szenario.sortierung,
      investition: szenario.investition,
      waermekosten: szenario.waermekosten,
      nebenkosten: neueNebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    _updateStammdaten(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  // ========== DIALOGE ==========

  void _zeigeQuellenDialog(
      String titel,
      QuellenInfo quelle,
      Function(QuellenInfo) onQuelleChanged,
      ) {
    final beschreibungController = TextEditingController(text: quelle.beschreibung);
    final linkController = TextEditingController(text: quelle.link ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quelle: $titel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final neueQuelle = QuellenInfo(
                titel:"",
                beschreibung: beschreibungController.text,
                link: linkController.text.isEmpty ? null : linkController.text,
              );
              onQuelleChanged(neueQuelle);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

// Helper extension for copyWith on WaermekostenDaten
extension WaermekostenDatenCopyWith on WaermekostenDaten {
  WaermekostenDaten copyWith({
    WertMitQuelle<double>? stromverbrauchKWh,
    WertMitQuelle<double>? waermeVerbrauchGasKWh,
    WertMitQuelle<double>? waermeVerbrauchStromKWh,
    WertMitQuelle<double>? stromarbeitspreisCtKWh,
    WertMitQuelle<double>? waermeGasArbeitspreisCtKWh,
    WertMitQuelle<double>? waermeStromArbeitspreisCtKWh,
    WertMitQuelle<double>? stromGrundpreisEuroMonat,
    WertMitQuelle<double>? waermeGrundpreisEuroJahr,
    WertMitQuelle<double>? waermeMesspreisEuroJahr,
    WertMitQuelle<double>? jahresarbeitszahl,
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
}