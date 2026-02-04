// lib/screens/arbeitspreis_alt_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/index_data.dart';
import '../models/arbeitspreis_alt_data.dart';
import '../services/energie_index_service.dart';
import '../services/arbeitspreis_alt_service.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../constants/destatis_constants.dart';
import '../widgets/logo_widget.dart';
import '../widgets/loading_widget.dart' as custom;
import '../widgets/gewichtung_interactive_widget.dart';

/// Alte Arbeitspreis-Formel (2024-2027)
class ArbeitspreisAltScreen extends StatefulWidget {
  const ArbeitspreisAltScreen({Key? key}) : super(key: key);

  @override
  State<ArbeitspreisAltScreen> createState() => _ArbeitspreisAltScreenState();
}

class _ArbeitspreisAltScreenState extends State<ArbeitspreisAltScreen>
    with SingleTickerProviderStateMixin {

  final EnergieIndexService _indexService = EnergieIndexService();
  final ArbeitspreisAltService _preisService = ArbeitspreisAltService();

  late TabController _tabController;

  Map<String, List<IndexData>> _indexData = {};
  List<ArbeitspreisAlt> _jahresPreise = [];

  bool _isLoading = true;
  String? _error;

  int? _selectedJahr;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📊 [ARBEITSPREIS_ALT] Lade Index-Daten...');

      final Map<String, List<IndexData>> dataMap = {};

      dataMap['G'] = await _indexService.getIndexData(
        indexCode: ArbeitspreisAltKonstanten.gIndexCode,
      );
      dataMap['GI'] = await _indexService.getIndexData(
        indexCode: ArbeitspreisAltKonstanten.giIndexCode,
      );
      dataMap['Z'] = await _indexService.getIndexData(
        indexCode: ArbeitspreisAltKonstanten.zIndexCode,
      );
      dataMap['KCO2'] = await _indexService.getIndexData(
        indexCode: DestatisConstants.ecarbixCode,
      );

      final jahresPreise = await _preisService.berechneAlleJahre(
        gData: dataMap['G']!,
        giData: dataMap['GI']!,
        zData: dataMap['Z']!,
        kco2Data: dataMap['KCO2']!,
      );

      if (mounted) {
        setState(() {
          _indexData = dataMap;
          _jahresPreise = jahresPreise;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('🔴 [ARBEITSPREIS_ALT] Fehler: $e');
      print('🔴 [ARBEITSPREIS_ALT] StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Berechne Arbeitspreis...')
          : _error != null
          ? custom.ErrorWidget(message: _error!, onRetry: _loadData)
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Formel bis 2027',
              style: SuewagTextStyles.headline2,
            ),
          ),
          const SizedBox(width: 12),
          const AppLogo(height: 32),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: SuewagColors.quartzgrau100,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SuewagColors.quartzgrau100),
        onPressed: () => Navigator.of(context).pop(),
      ),
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: SuewagColors.fasergruen,
        indicatorWeight: 3,
        labelColor: SuewagColors.quartzgrau100,
        unselectedLabelColor: SuewagColors.quartzgrau50,
        onTap: (_) => setState(() => _selectedJahr = null),
        tabs: const [
          Tab(icon: Icon(Icons.bar_chart), text: 'Übersicht'),
          Tab(icon: Icon(Icons.calculate), text: 'Formel-Details'),

        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      key: ValueKey('tabview-${_selectedJahr ?? 'all'}'),
      controller: _tabController,
      children: [
        _buildUebersichtTab(),
        _buildGewichtungTab(),

      ],
    );
  }

  // ========================================
  // TAB 1: ÜBERSICHT
  // ========================================

  Widget _buildUebersichtTab() {
    if (_jahresPreise.isEmpty) {
      return _buildEmptyState();
    }

    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAktuellerPreisCard(),
                const SizedBox(height: 24),

                if (isDesktop) ...[
                  SizedBox(
                    height: 500,
                    child: Row(
                      children: [
                        Expanded(flex: 6, child: _buildChartCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildJahresTabelleCard()),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 350,
                    child: _buildChartCard(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,  // 40% der Bildschirmhöhe
                    child: _buildJahresTabelleCard(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

// 1. Erweitere _buildAktuellerPreisCard() - füge NACH dem Divider hinzu:

  Widget _buildAktuellerPreisCard() {
    final aktuellerPreis = _jahresPreise.last;

    double? aenderung;
    if (_jahresPreise.length > 1) {
      final vorjahr = _jahresPreise[_jahresPreise.length - 2];
      aenderung = aktuellerPreis.arbeitspreisGesamt - vorjahr.arbeitspreisGesamt;
    }

    final istGeschaetzt = !aktuellerPreis.hatVollstaendigeDaten;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuewagColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Arbeitspreis ${aktuellerPreis.jahr}',
                          style: SuewagTextStyles.bodyMedium.copyWith(
                            color: SuewagColors.textSecondary,
                          ),
                        ),
                        if (istGeschaetzt) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '${aktuellerPreis.geschaetzteMonate} von 12 Monaten noch nicht veröffentlicht',
                            child: Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade600,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatGermanNumber(aktuellerPreis.arbeitspreisGesamt, 4)} ct/kWh',
                      style: SuewagTextStyles.headline1.copyWith(
                        fontSize: 32,
                        color: SuewagColors.quartzgrau100,
                      ),
                    ),
                    if (istGeschaetzt) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'WERTE NOCH NICHT FINAL (${aktuellerPreis.geschaetzteMonate} ${aktuellerPreis.geschaetzteMonate == 1 ? "Monat" : "Monate"} fehlen)',

                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (aenderung != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: aenderung >= 0
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: aenderung >= 0
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aenderung >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: aenderung >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${aenderung >= 0 ? "+" : ""}${_formatGermanNumber(aenderung, 4)}',
                        style: TextStyle(
                          color: aenderung >= 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPreisComponentClean(
                  'Arbeitspreis',
                  aktuellerPreis.arbeitspreisOhneEmission,
                  SuewagColors.indiablau,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: SuewagColors.divider,
              ),
              Expanded(
                child: _buildPreisComponentClean(
                  'CO₂-Preis',
                  aktuellerPreis.emissionspreis,
                  SuewagColors.verkehrsorange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreisComponentClean(String label, double wert, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: SuewagTextStyles.bodySmall.copyWith(
            color: SuewagColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatGermanNumber(wert, 4),
          style: SuewagTextStyles.headline3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'ct/kWh',
          style: SuewagTextStyles.caption.copyWith(
            color: SuewagColors.textSecondary,
          ),
        ),
      ],
    );
  }

// 2. Ändere _buildJahresTabelleCard() - erweitere die Tabelle:

  Widget _buildJahresTabelleCard() {
    final uebersicht = _preisService.erstelleUebersicht(_jahresPreise);

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
              Icon(Icons.table_chart, color: SuewagColors.indiablau, size: 20),
              const SizedBox(width: 8),
              Text('Jahresübersicht', style: SuewagTextStyles.headline4),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(1), // 🆕 Neue Spalte
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: SuewagColors.divider),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: SuewagColors.quartzgrau10),
                    children: [
                      _buildTableHeader('Jahr'),
                      _buildTableHeader('AP'),
                      _buildTableHeader('CO₂'),
                      _buildTableHeader('Gesamt'),
                      _buildTableHeader('Status'), // 🆕
                    ],
                  ),
                  ...uebersicht.map((jahr) {
                    return TableRow(
                      decoration: BoxDecoration(
                        color: jahr.hatVollstaendigeDaten
                            ? null
                            : Colors.orange.withOpacity(0.05),
                      ),
                      children: [
                        _buildTableCell(jahr.jahr.toString(), false),
                        _buildTableCell('${_formatGermanNumber(jahr.arbeitspreisOhneEmission, 4)}', false),
                        _buildTableCell('${_formatGermanNumber(jahr.emissionspreis, 4)}', false),
                        _buildTableCell('${_formatGermanNumber(jahr.arbeitspreisGesamt, 4)}', true),
                        // 🆕 Status-Spalte
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: jahr.hatVollstaendigeDaten
                              ? Icon(Icons.check_circle, size: 16, color: SuewagColors.fasergruen)
                              : Tooltip(
                            message: 'Nicht alle Monate veröffentlicht',
                            child: Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreisComponent(String label, double wert, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            _formatGermanNumber(wert, 4),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'ct/kWh',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
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
              Icon(Icons.bar_chart, color: SuewagColors.fasergruen, size: 20),
              const SizedBox(width: 8),
              Text('Preisentwicklung', style: SuewagTextStyles.headline4),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_jahresPreise.isEmpty) return const SizedBox();

    final maxPreis = _jahresPreise
        .map((p) => p.arbeitspreisGesamt)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxPreis * 1.2).ceilToDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.white,
            tooltipBorder: BorderSide(color: SuewagColors.divider, width: 1),
            tooltipPadding: const EdgeInsets.all(12),
            tooltipMargin: 8,
            maxContentWidth: 200,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final preis = _jahresPreise[group.x.toInt()];
              return BarTooltipItem(
                '',
                const TextStyle(),
                children: [
                  TextSpan(
                    text: 'Jahr ${preis.jahr}\n\n',
                    style: SuewagTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SuewagColors.quartzgrau100,
                    ),
                  ),
                  TextSpan(
                    text: 'Arbeitspreis: ',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatGermanNumber(preis.arbeitspreisOhneEmission, 4)} ct/kWh\n',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.indiablau,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'CO₂-Preis: ',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatGermanNumber(preis.emissionspreis, 4)} ct/kWh\n',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.verkehrsorange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: 'Gesamt: ',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatGermanNumber(preis.arbeitspreisGesamt, 4)} ct/kWh',
                    style: SuewagTextStyles.bodyMedium.copyWith(
                      color: SuewagColors.quartzgrau100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              final index = response!.spot!.touchedBarGroupIndex;
              setState(() {
                _selectedJahr = _jahresPreise[index].jahr;
              });
            }
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _jahresPreise.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _jahresPreise[index].jahr.toString(),
                      style: SuewagTextStyles.caption,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              'Preis in ct/kWh',
              style: SuewagTextStyles.bodySmall.copyWith(
                color: SuewagColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            axisNameSize: 50,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatGermanNumber(value, 1),
                  style: SuewagTextStyles.caption.copyWith(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: SuewagColors.divider),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: SuewagColors.divider, strokeWidth: 1);
          },
        ),
        barGroups: _jahresPreise.asMap().entries.map((entry) {
          final index = entry.key;
          final preis = entry.value;
          final isSelected = preis.jahr == _selectedJahr;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: preis.arbeitspreisGesamt,
                color: isSelected ? SuewagColors.fasergruen : SuewagColors.indiablau,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    preis.arbeitspreisOhneEmission,
                    SuewagColors.indiablau,
                  ),
                  BarChartRodStackItem(
                    preis.arbeitspreisOhneEmission,
                    preis.arbeitspreisGesamt,
                    SuewagColors.verkehrsorange,
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }



  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: SuewagTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(String text, bool bold) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: SuewagTextStyles.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ========================================
  // TAB 2: GEWICHTUNG
  // ========================================

// ========================================
// TAB 2: GEWICHTUNG
// ========================================

  Widget _buildGewichtungTab() {
    if (_jahresPreise.isEmpty) {
      return _buildEmptyState();
    }

    // Zeige aktuellstes Jahr oder ausgewähltes Jahr
    final jahr = _selectedJahr ?? _jahresPreise.last.jahr;
    final jahresPreis = _jahresPreise.firstWhere(
          (p) => p.jahr == jahr,
      orElse: () => _jahresPreise.last,
    );

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Jahr-Auswahl
                if (_jahresPreise.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SuewagColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: SuewagColors.indiablau, size: 20),
                        const SizedBox(width: 12),
                        Text('Jahr auswählen:', style: SuewagTextStyles.bodyMedium),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: _jahresPreise.map((preis) {
                              final isSelected = jahr == preis.jahr;
                              return ChoiceChip(
                                label: Text(preis.jahr.toString()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedJahr = selected ? preis.jahr : null;
                                  });
                                },
                                selectedColor: SuewagColors.fasergruen,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : SuewagColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 🆕 Formeln-Erklärung VOR dem Widget
                _buildFormelnCard(),
                const SizedBox(height: 24),

                // Interaktives Gewichtungs-Widget
                GewichtungInteractiveWidget(
                  key: ValueKey('gewichtung-${jahresPreis.jahr}'),
                  jahresPreis: jahresPreis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// 🆕 Formeln-Card über dem Widget
  Widget _buildFormelnCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuewagColors.indiablau, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, color: SuewagColors.indiablau, size: 24),
              const SizedBox(width: 12),
              Text('Preisformeln 2024-2027', style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 20),

          // Arbeitspreis-Formel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SuewagColors.fasergruen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SuewagColors.fasergruen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '§5',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Arbeitspreis (ohne CO₂)',
                      style: SuewagTextStyles.headline4.copyWith(
                        color: SuewagColors.fasergruen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'AP = AP₀ × (0,40 × G/G₀ + 0,35 × GI/GI₀ + 0,25 × Z/Z₀)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AP₀ = 4,9309 ct/kWh (Basis 2016)',
                  style: SuewagTextStyles.bodySmall.copyWith(
                    color: SuewagColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emissionspreis-Formel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SuewagColors.verkehrsorange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SuewagColors.verkehrsorange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '§6',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Emissionspreis (CO₂)',
                      style: SuewagTextStyles.headline4.copyWith(
                        color: SuewagColors.verkehrsorange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'EP = (1 - Z) × Em × KCO₂ × F',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Em = 170,28 g CO₂/kWh  |  F = 0,0001  |  Z = Abschmelzungsfaktor',
                  style: SuewagTextStyles.bodySmall.copyWith(
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

  Widget _buildEmissionspreisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuewagColors.verkehrsorange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.co2, color: SuewagColors.verkehrsorange, size: 24),
              const SizedBox(width: 12),
              Text('Emissionspreis (§6)', style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SuewagColors.verkehrsorange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'EP = (1 - Z) × Em × KCO₂ × F',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Em = 170,28 g CO₂/kWh | F = 0,0001',
                  style: SuewagTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('Keine Daten', style: SuewagTextStyles.headline3),
    );
  }

  String _formatGermanNumber(double value, int decimals) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'de_DE');
    return formatter.format(value);
  }
}