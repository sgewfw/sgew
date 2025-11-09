// lib/screens/kostenvergleich_standard_tab.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';
import '../widgets/kostenvergleich_chart_widget.dart';

class KostenvergleichStandardTab extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final KostenvergleichErgebnis ergebnis;

  const KostenvergleichStandardTab({
    Key? key,
    required this.stammdaten,
    required this.ergebnis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Banner
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // Chart + Tabelle
              if (isDesktop) ...[
                SizedBox(
                  height: 600,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildChartCard(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildTabelleCard(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildChartCard(),
                const SizedBox(height: 16),
                _buildTabelleCard(),
              ],

              const SizedBox(height: 24),

              // Günstigstes Szenario Highlight
              _buildGuenstigstesHighlight(),

              const SizedBox(height: 24),

              // Detaillierte Aufschlüsselung
              _buildDetailAufschluesselungCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.indiablau),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: SuewagColors.indiablau, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kostenvergleich Wärmeversorgung Einfamilienhaus',
                  style: SuewagTextStyles.headline4.copyWith(
                    color: SuewagColors.indiablau,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vergleich der Jahreskosten für verschiedene Wärmeversorgungssysteme bei einem Heizenergiebedarf von ${stammdaten.grunddaten.heizenergiebedarf.toStringAsFixed(0)} kWh/a',
                  style: SuewagTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
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
              Text(
                'Preisbestandteile - Wärmevollkostenpreis netto in ct/kWh',
                style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: KostenvergleichChartWidget(
              ergebnisse: ergebnis.szenarien,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelleCard() {
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
              child: _buildTabelle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelle() {
    final sortiert = ergebnis.szenarienSortiertNachPreis;

    return Table(
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
            _buildTableCell('', isHeader: true),
            ...sortiert.map((e) => _buildTableCell(
              e.szenarioBezeichnung,
              isHeader: true,
              align: TextAlign.center,
            )),
          ],
        ),
        // Wärmevollkostenpreis netto
        _buildTableRow(
          'Wärmevollkostenpreis netto',
          sortiert.map((e) => '${e.waermevollkostenpreisNetto.toStringAsFixed(2)} €/MWh').toList(),
          istHervorgehoben: true,
        ),
        // Wärmevollkostenpreis brutto
        _buildTableRow(
          'Wärmevollkostenpreis brutto',
          sortiert.map((e) => '${e.waermevollkostenpreisBrutto.toStringAsFixed(2)} €/MWh').toList(),
        ),
        // Jahreskosten netto
        _buildTableRow(
          'Jahreskosten netto',
          sortiert.map((e) => '${e.jahreskosten.toStringAsFixed(2)} €/a').toList(),
        ),
        // Jahreskosten brutto
        _buildTableRow(
          'Jahreskosten brutto',
          sortiert.map((e) => '${e.jahreskosten_brutto.toStringAsFixed(2)} €/a').toList(),
        ),
        // Kosten pro m²
        _buildTableRow(
          'Kosten pro m²',
          sortiert.map((e) => '${e.kostenProQuadratmeter.toStringAsFixed(2)} €/m²').toList(),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, List<String> werte, {bool istHervorgehoben = false}) {
    return TableRow(
      decoration: istHervorgehoben
          ? BoxDecoration(color: SuewagColors.fasergruen.withOpacity(0.1))
          : null,
      children: [
        _buildTableCell(label, istHervorgehoben: istHervorgehoben),
        ...werte.map((w) => _buildTableCell(
          w,
          align: TextAlign.right,
          istHervorgehoben: istHervorgehoben,
        )),
      ],
    );
  }

  Widget _buildTableCell(
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
            ? SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
            : istHervorgehoben
            ? SuewagTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: SuewagColors.fasergruen,
        )
            : SuewagTextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildGuenstigstesHighlight() {
    final guenstigste = ergebnis.getSzenario(ergebnis.guenstigstesSzenarioId);
    if (guenstigste == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.green, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günstigstes Szenario',
                  style: SuewagTextStyles.headline3.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  guenstigste.szenarioBezeichnung,
                  style: SuewagTextStyles.headline2.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  '${guenstigste.waermevollkostenpreisNetto.toStringAsFixed(2)} €/MWh',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailAufschluesselungCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.info_outline, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Detaillierte Kostenaufschlüsselung', style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 20),
          ...ergebnis.szenarien.map((e) => _buildSzenarioDetail(e)),
        ],
      ),
    );
  }

  Widget _buildSzenarioDetail(KostenberechnungErgebnis ergebnis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: SuewagColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ergebnis.szenarioBezeichnung,
            style: SuewagTextStyles.headline4,
          ),
          const Divider(),
          _buildKostenZeile('Arbeitspreis:', ergebnis.kosten.arbeitspreis),
          _buildKostenZeile('Grund- und Messpreis:', ergebnis.kosten.grundUndMesspreis),
          _buildKostenZeile('Betriebskosten:', ergebnis.kosten.betriebskosten),
          _buildKostenZeile('Kapitalkosten (inkl. Förderung):', ergebnis.kosten.kapitalkosten),
          if (ergebnis.kosten.zusaetzlicherGrundpreisUebergabestation > 0)
            _buildKostenZeile(
              'Zusätzl. Grundpreis ÜGS:',
              ergebnis.kosten.zusaetzlicherGrundpreisUebergabestation,
            ),
          const Divider(),
          _buildKostenZeile(
            'Gesamt:',
            ergebnis.jahreskosten,
            istGesamt: true,
          ),
        ],
      ),
    );
  }

  Widget _buildKostenZeile(String label, double betrag, {bool istGesamt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: istGesamt
                ? SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
                : SuewagTextStyles.bodyMedium,
          ),
          Text(
            '${betrag.toStringAsFixed(2)} €/a',
            style: istGesamt
                ? SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
                : SuewagTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}