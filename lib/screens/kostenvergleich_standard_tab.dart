// lib/screens/kostenvergleich_standard_tab.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';
import '../widgets/kostenvergleich_chart_widget.dart';
import '../widgets/kostenvergleich_detail_table_mobile.dart';
import '../widgets/kostenvergleich_detail_table_widget.dart';

class KostenvergleichStandardTab extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final KostenvergleichErgebnis ergebnis;

  const KostenvergleichStandardTab({
    Key? key,
    required this.stammdaten,
    required this.ergebnis,
  }) : super(key: key);

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
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Banner
              _buildInfoBanner(isMobile),
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
                      // const SizedBox(width: 16),
                      // Expanded(
                      //   flex: 5,
                      //   child: _buildTabelleCard(isMobile),
                      // ),
                    ],
                  ),
                ),
              ] else ...[
                _buildChartCard(),
                // const SizedBox(height: 16),
                // _buildTabelleCard(isMobile),
              ],

              const SizedBox(height: 24),

              // 🆕 Detaillierte Tabelle
              if (isDesktop)
                KostenvergleichDetailTableWidget(
                  stammdaten: stammdaten,
                  ergebnisse: ergebnis.szenarien,
                )
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: KostenvergleichDetailTableMobile(
                    stammdaten: stammdaten,
                    ergebnisse: ergebnis.szenarien,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.indiablau),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: SuewagColors.indiablau,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kostenvergleich Wärmeversorgung Einfamilienhaus',
                  style: (isMobile
                      ? SuewagTextStyles.bodyMedium
                      : SuewagTextStyles.headline4
                  ).copyWith(
                    color: SuewagColors.indiablau,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  'Vergleich der Jahreskosten für verschiedene Wärmeversorgungssysteme bei einem Heizenergiebedarf von ${_formatiereDeutsch(stammdaten.grunddaten.heizenergiebedarf.wert, 0)} kWh/a',
                  style: isMobile
                      ? SuewagTextStyles.bodySmall.copyWith(fontSize: 11)
                      : SuewagTextStyles.bodyMedium,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasFixedHeight = constraints.maxHeight != double.infinity;

          if (hasFixedHeight) {
            return Column(
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
                      onTap: () => _zeigeChartInfoDialog(context),
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
                    ergebnisse: ergebnis.szenarien,
                  ),
                ),
              ],
            );
          } else {
            // ... gleiche Änderung für else-Teil
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: SuewagColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Preisbestandteile - Wärmevollkostenpreis netto in ct/kWh',
                        style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _zeigeChartInfoDialog(context),
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
                SizedBox(
                  height: 400,
                  child: KostenvergleichChartWidget(
                    ergebnisse: ergebnis.szenarien,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
  void _zeigeChartInfoDialog(BuildContext context) {
    final heizenergiebedarf = stammdaten.grunddaten.heizenergiebedarf.wert;

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
                      'Alle Preisbestandteile werden auf den angenommenen Heizenergiebedarf bezogen und in ct/kWh (Cent pro Kilowattstunde) dargestellt.',
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
                erklaerung: 'Mehrkosten wenn keine Förderung in Anspruch genommen wird (gestrichelt dargestellt)',
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

  Widget _buildAnnahmeZeile(String label, String wert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            wert,
            style: SuewagTextStyles.bodySmall.copyWith(
              color: SuewagColors.indiablau,
              fontWeight: FontWeight.bold,
            ),
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
  Widget _buildTabelleCard(bool isMobile) {
    if (isMobile) {
      // Mobile: Tab-basierte Ansicht
      return _buildTabelleMobile();
    }

    // Desktop: Normale Tabelle
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasFixedHeight = constraints.maxHeight != double.infinity;

          if (hasFixedHeight) {
            return Column(
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
                    child: _buildTabelle(isMobile),
                  ),
                ),
              ],
            );
          } else {
            return Column(
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
                SizedBox(
                  height: 400,
                  child: SingleChildScrollView(
                    child: _buildTabelle(isMobile),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTabelleMobile() {
    return _TabelleCardMobile(
      ergebnisse: ergebnis.szenarien,
      formatiereDeutsch: _formatiereDeutsch,
    );
  }

  Widget _buildTabelle(bool isMobile) {
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
            _buildTableCell('', isHeader: true, isMobile: isMobile),
            ...sortiert.map((e) => _buildTableCell(
              e.szenarioBezeichnung,
              isHeader: true,
              align: TextAlign.center,
              isMobile: isMobile,
            )),
          ],
        ),
        // Wärmevollkostenpreis netto
        _buildTableRow(
          'Wärmevollkostenpreis netto',
          sortiert.map((e) => '${_formatiereDeutsch(e.waermevollkostenpreisNetto, 2)} €/MWh').toList(),
          istHervorgehoben: true,
          isMobile: isMobile,
        ),
        // Wärmevollkostenpreis brutto
        _buildTableRow(
          'Wärmevollkostenpreis brutto',
          sortiert.map((e) => '${_formatiereDeutsch(e.waermevollkostenpreisBrutto, 2)} €/MWh').toList(),
          isMobile: isMobile,
        ),
        // Jahreskosten netto
        _buildTableRow(
          'Jahreskosten netto',
          sortiert.map((e) => '${_formatiereDeutsch(e.jahreskosten, 2)} €/a').toList(),
          isMobile: isMobile,
        ),
        // Jahreskosten brutto
        _buildTableRow(
          'Jahreskosten brutto',
          sortiert.map((e) => '${_formatiereDeutsch(e.jahreskosten_brutto, 2)} €/a').toList(),
          isMobile: isMobile,
        ),
        // Kosten pro m²
        _buildTableRow(
          'Kosten pro m²',
          sortiert.map((e) => '${_formatiereDeutsch(e.kostenProQuadratmeter, 2)} €/m²').toList(),
          isMobile: isMobile,
        ),
      ],
    );
  }

  TableRow _buildTableRow(
      String label,
      List<String> werte, {
        bool istHervorgehoben = false,
        required bool isMobile,
      }) {
    return TableRow(
      decoration: istHervorgehoben
          ? BoxDecoration(color: SuewagColors.fasergruen.withOpacity(0.1))
          : null,
      children: [
        _buildTableCell(
          label,
          istHervorgehoben: istHervorgehoben,
          isMobile: isMobile,
        ),
        ...werte.map((w) => _buildTableCell(
          w,
          align: TextAlign.right,
          istHervorgehoben: istHervorgehoben,
          isMobile: isMobile,
        )),
      ],
    );
  }

  Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        TextAlign align = TextAlign.left,
        bool istHervorgehoben = false,
        required bool isMobile,
      }) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      child: Text(
        text,
        textAlign: align,
        style: isHeader
            ? (isMobile
            ? SuewagTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10)
            : SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
        )
            : istHervorgehoben
            ? (isMobile
            ? SuewagTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: SuewagColors.fasergruen,
          fontSize: 10,
        )
            : SuewagTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: SuewagColors.fasergruen,
        )
        )
            : (isMobile
            ? SuewagTextStyles.bodySmall.copyWith(fontSize: 10)
            : SuewagTextStyles.bodyMedium
        ),
      ),
    );
  }
}

// Mobile Tab-basierte Tabelle
class _TabelleCardMobile extends StatefulWidget {
  final List<KostenberechnungErgebnis> ergebnisse;
  final String Function(double, int) formatiereDeutsch;

  const _TabelleCardMobile({
    required this.ergebnisse,
    required this.formatiereDeutsch,
  });

  @override
  State<_TabelleCardMobile> createState() => _TabelleCardMobileState();
}

class _TabelleCardMobileState extends State<_TabelleCardMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.ergebnisse.length, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getSzenarioKurz(String bezeichnung) {
    if (bezeichnung.contains('Wärmepumpe')) return 'Wärmepumpe';
    if (bezeichnung.contains('ohne')) return 'Netz ohne ÜGS';
    if (bezeichnung.contains('Kunde')) return 'Netz Kunde';
    if (bezeichnung.contains('Süwag')) return 'Netz Süwag';
    return bezeichnung;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: SuewagColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Kostenübersicht',
                  style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: SuewagColors.fasergruen,
            indicatorWeight: 3,
            labelColor: SuewagColors.quartzgrau100,
            unselectedLabelColor: SuewagColors.quartzgrau50,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),
            tabs: widget.ergebnisse.map((e) {
              return Tab(text: _getSzenarioKurz(e.szenarioBezeichnung));
            }).toList(),
          ),

          const SizedBox(height: 12),

          // PageView mit Szenario-Details
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              itemCount: widget.ergebnisse.length,
              itemBuilder: (context, index) {
                return _buildSzenarioCard(widget.ergebnisse[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSzenarioCard(KostenberechnungErgebnis ergebnis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildKennzahlZeile(
            'Wärmevollkostenpreis netto',
            widget.formatiereDeutsch(ergebnis.waermevollkostenpreisNetto, 2),
            '€/MWh',
            isHighlight: true,
          ),
          const Divider(height: 16),
          _buildKennzahlZeile(
            'Wärmevollkostenpreis brutto',
            widget.formatiereDeutsch(ergebnis.waermevollkostenpreisBrutto, 2),
            '€/MWh',
          ),
          const Divider(height: 16),
          _buildKennzahlZeile(
            'Jahreskosten netto',
            widget.formatiereDeutsch(ergebnis.jahreskosten, 2),
            '€/a',
          ),
          const Divider(height: 16),
          _buildKennzahlZeile(
            'Jahreskosten brutto',
            widget.formatiereDeutsch(ergebnis.jahreskosten_brutto, 2),
            '€/a',
          ),
          const Divider(height: 16),
          _buildKennzahlZeile(
            'Kosten pro m²',
            widget.formatiereDeutsch(ergebnis.kostenProQuadratmeter, 2),
            '€/m²',
          ),
        ],
      ),
    );
  }

  Widget _buildKennzahlZeile(
      String label,
      String wert,
      String einheit, {
        bool isHighlight = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? SuewagColors.fasergruen : SuewagColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$wert $einheit',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? SuewagColors.fasergruen : SuewagColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}