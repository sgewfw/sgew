// lib/screens/arbeitspreis_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/index_data.dart';
import '../models/arbeitspreis_data.dart';
import '../models/waermepreis_data.dart';
import '../services/energie_index_service.dart';
import '../services/arbeitspreis_service.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../constants/destatis_constants.dart';
import '../services/waermepreis_service.dart';
import '../widgets/waerme_tab_widget.dart';
import '../widgets/logo_widget.dart';
import '../widgets/loading_widget.dart' as custom;
import '../widgets/monatstabelle_widget.dart';
import '../widgets/formel_erklaerung_widget.dart';
import '../widgets/waermeanteil_admin_dialog.dart';

/// § 8 Arbeitspreis - Interaktive Visualisierung
/// Mit Quartals-Preisen und n-4 bis n-2 Berechnung
class ArbeitspreisScreen extends StatefulWidget {
  const ArbeitspreisScreen({Key? key}) : super(key: key);

  @override
  State<ArbeitspreisScreen> createState() => _ArbeitspreisScreenState();
}

class _ArbeitspreisScreenState extends State<ArbeitspreisScreen>
    with SingleTickerProviderStateMixin {
  final EnergieIndexService _indexService = EnergieIndexService();
  final ArbeitspreisService _preisService = ArbeitspreisService();
  final WaermepreisService _waermepreisService = WaermepreisService();
  List<QuartalsWaermepreis> _waermepreise = [];
  late TabController _tabController;

  // Daten
  Map<String, List<IndexData>> _indexData = {};
  List<QuartalsPreis> _gasPreise = [];
  List<QuartalsPreis> _stromPreise = [];

  bool _isLoading = true;
  String? _error;

  // Interaktion
  DateTime? _selectedQuartal;
  QuartalsBerechnungsdaten? _selectedBerechnungGas;
  QuartalsBerechnungsdaten? _selectedBerechnungStrom;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // UI aktualisieren wenn Tab wechselt
    });
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
      final Map<String, List<IndexData>> dataMap = {};

      print('📊 [ARBEITSPREIS] Lade Index-Daten...');

      for (var indexCode in [
        DestatisConstants.erdgasGewerbeCode,
        DestatisConstants.stromGewerbeCode,
        DestatisConstants.stromHaushalteCode,
        DestatisConstants.waermepreisCode,
      ]) {
        final data = await _indexService.getIndexData(indexCode: indexCode);
        dataMap[indexCode] = data;

        print('📊 [ARBEITSPREIS] $indexCode: ${data.length} Datenpunkte');
        if (data.isNotEmpty) {
          print('   Zeitraum: ${data.first.date} bis ${data.last.date}');
        }
      }

      print('📊 [ARBEITSPREIS] Berechne Gas-Quartalspreise...');
      final gasPreise = _preisService.berechneGasQuartalspreise(
        kGasData: dataMap[DestatisConstants.erdgasGewerbeCode]!,
        mGasData: dataMap[DestatisConstants.waermepreisCode]!,
      );
      print('📊 [ARBEITSPREIS] Gas: ${gasPreise.length} Quartale berechnet');

      print('📊 [ARBEITSPREIS] Berechne Strom-Quartalspreise...');
      final stromPreise = _preisService.berechneStromQuartalspreise(
        kStromData: dataMap[DestatisConstants.stromGewerbeCode]!,
        mStromData: dataMap[DestatisConstants.stromHaushalteCode]!,
      );
      print('📊 [ARBEITSPREIS] Strom: ${stromPreise.length} Quartale berechnet');
      // 🆕 NEU: Lade Wärmeanteile und berechne Wärmepreise
      print('📊 [ARBEITSPREIS] Lade Wärmeanteile...');
      final waermeanteile = await _waermepreisService.ladeWaermeanteile();
      print('📊 [ARBEITSPREIS] ${waermeanteile.length} Wärmeanteile geladen');

      print('📊 [ARBEITSPREIS] Berechne Wärmepreise...');
      final waermepreise = _waermepreisService.berechneWaermepreise(
        gasPreise: gasPreise,
        stromPreise: stromPreise,
        waermeanteile: waermeanteile,


      );
      print('📊 [ARBEITSPREIS] ${waermepreise.length} Wärmepreise berechnet');
// 🆕 DEBUG: Details ausgeben
      for (final wp in waermepreise) {
        print('   ${wp.bezeichnung}: ${wp.waermepreisGesamt.toStringAsFixed(2)} ct/kWh');
      }

      if (mounted) {
        setState(() {
          _indexData = dataMap;
          _gasPreise = gasPreise;
          _stromPreise = stromPreise;
          _waermepreise = waermepreise;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('🔴 [ARBEITSPREIS] Fehler: $e');
      print('🔴 [ARBEITSPREIS] StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden der Daten: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onChartPointTapped(DateTime quartal, String typ) {
    setState(() {
      _selectedQuartal = quartal;

      if (typ == 'gas') {
        final preis = _gasPreise.firstWhere(
              (p) => p.quartal == quartal,
          orElse: () => _gasPreise.first,
        );
        _selectedBerechnungGas = preis.berechnungsdaten;
      } else {
        final preis = _stromPreise.firstWhere(
              (p) => p.quartal == quartal,
          orElse: () => _stromPreise.first,
        );
        _selectedBerechnungStrom = preis.berechnungsdaten;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Berechne Quartalspreise...')
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
          const Text(
            'Arbeitspreis',
            style: SuewagTextStyles.headline2,
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
        indicator: BoxDecoration( // 🆕 Custom Indicator
          border: Border(
            bottom: BorderSide(
              color: SuewagColors.fasergruen,
              width: 3,
            ),
          ),
        ),
        onTap: (index) {
          setState(() {
            _selectedQuartal = null;
            _selectedBerechnungGas = null;
            _selectedBerechnungStrom = null;
          });
        },
        tabs: const [
          Tab(icon: Icon(Icons.thermostat), text: 'Wärmepreis'),
          Tab(icon: Icon(Icons.local_fire_department), text: 'Wärme aus Gas'),
          Tab(icon: Icon(Icons.bolt), text: 'Wärme aus Strom'),

        ],
      ),
    );
  }
  void _zeigeAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => WaermeanteilAdminDialog(
        onSaved: () {
          // Daten neu laden nach dem Speichern
          _loadData();
        },
      ),
    );
  }
  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildWaermeTab(),
        _buildGasTab(),
        _buildStromTab(),

      ],
    );
  }
  Widget _buildWaermeTab() {
    print('🔍 [WAERME TAB] Building mit ${_waermepreise.length} Preisen');

    // Zeige Loading solange keine Daten da sind
    if (_waermepreise.isEmpty && !_isLoading) {
      return Center(
        key: const ValueKey('waerme_loading'), // 🆕
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.thermostat_outlined,
              size: 64,
              color: SuewagColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Lade Wärmepreise...',
              style: SuewagTextStyles.headline3,
            ),
          ],
        ),
      );
    }

    return WaermeTabWidget(
      key: ValueKey('waerme_data_${_waermepreise.length}'), // 🆕
      waermepreise: _waermepreise,
    );
  }
  Widget _buildGasTab() {
    return _buildTabContent(
      typ: 'gas',
      preise: _gasPreise,
      kData: _indexData[DestatisConstants.erdgasGewerbeCode] ?? [],
      mData: _indexData[DestatisConstants.waermepreisCode] ?? [],
      berechnungsdaten: _selectedBerechnungGas,
      color: SuewagColors.erdgas,
      kLabel: 'K Gas',
      mLabel: 'M Gas',
      kColor: SuewagColors.erdgas,
      mColor: SuewagColors.waerme,
    );
  }

  Widget _buildStromTab() {
    return _buildTabContent(
      typ: 'strom',
      preise: _stromPreise,
      kData: _indexData[DestatisConstants.stromGewerbeCode] ?? [],
      mData: _indexData[DestatisConstants.stromHaushalteCode] ?? [],
      berechnungsdaten: _selectedBerechnungStrom,
      color: SuewagColors.chartGewerbe,
      kLabel: 'K Strom',
      mLabel: 'M Strom',
      kColor: SuewagColors.chartGewerbe,
      mColor: SuewagColors.chartHaushalte,
    );
  }

  Widget _buildTabContent({
    required String typ,
    required List<QuartalsPreis> preise,
    required List<IndexData> kData,
    required List<IndexData> mData,
    required QuartalsBerechnungsdaten? berechnungsdaten,
    required Color color,
    required String kLabel,
    required String mLabel,
    required Color kColor,
    required Color mColor,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // REIHE 1: Preisformel links + Chart rechts (40/60)
                if (isDesktop) ...[
                  SizedBox(
                    height: 400, // Feste Höhe für beide Spalten
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Links: Aktueller Preis + Preisformel (40%)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              if (preise.isNotEmpty)
                                AktuellerPreisWidget(
                                  typ: typ,
                                  aktuellerPreis: preise.last,
                                  vorherigerPreis: preise.length > 1 ? preise[preise.length - 2] : null,
                                ),
                              const SizedBox(height: 16),
                              Expanded(child: PreisformelWidget(typ: typ)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Rechts: Chart (60%)
                        Expanded(
                          flex: 6,
                          child: _buildChartCard(typ, preise, color),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Mobile: untereinander
                  if (preise.isNotEmpty)
                    AktuellerPreisWidget(
                      typ: typ,
                      aktuellerPreis: preise.last,
                      vorherigerPreis: preise.length > 1 ? preise[preise.length - 2] : null,
                    ),
                  const SizedBox(height: 16),
                  PreisformelWidget(typ: typ),
                  const SizedBox(height: 16),
                  _buildChartCard(typ, preise, color),
                ],

                const SizedBox(height: 24),

                // REIHE 2: Die 3 Berechnungsschritte (30/30/40)
                if (berechnungsdaten != null) ...[
                  if (isDesktop) ...[
                    // Desktop: alle 3 nebeneinander mit fester Höhe
                    SizedBox(
                      height: 190, // Feste Höhe für alle 3 Widgets
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: IndexBerechnungWidget(
                              typ: typ,
                              berechnungsdaten: berechnungsdaten,
                              indexTyp: 'k',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: IndexBerechnungWidget(
                              typ: typ,
                              berechnungsdaten: berechnungsdaten,
                              indexTyp: 'm',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: ArbeitspreisErgebnisWidget(
                              typ: typ,
                              berechnungsdaten: berechnungsdaten,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Mobile: untereinander
                    IndexBerechnungWidget(
                      typ: typ,
                      berechnungsdaten: berechnungsdaten,
                      indexTyp: 'k',
                    ),
                    const SizedBox(height: 16),
                    IndexBerechnungWidget(
                      typ: typ,
                      berechnungsdaten: berechnungsdaten,
                      indexTyp: 'm',
                    ),
                    const SizedBox(height: 16),
                    ArbeitspreisErgebnisWidget(
                      typ: typ,
                      berechnungsdaten: berechnungsdaten,
                    ),
                  ],
                ] else ...[
                  _buildPlaceholder(),
                ],

                const SizedBox(height: 24),

                // Tabellen mit Tabs
                _buildTabellenMitTabs(
                  typ: typ,
                  kData: kData,
                  mData: mData,
                  preise: preise,
                  kLabel: kLabel,
                  mLabel: mLabel,
                  kColor: kColor,
                  mColor: mColor,
                  berechnungsdaten: berechnungsdaten,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: SuewagColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Wähle ein Quartal im Chart',
              style: SuewagTextStyles.headline4.copyWith(
                color: SuewagColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klicke auf einen Punkt im Diagramm',
              textAlign: TextAlign.center,
              style: SuewagTextStyles.bodySmall.copyWith(
                color: SuewagColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String typ, List<QuartalsPreis> preise, Color color) {
    // Finde ausgewählten Preis
    QuartalsPreis? selectedPreis;
    if (_selectedQuartal != null) {
      try {
        selectedPreis = preise.firstWhere(
              (p) => p.quartal.year == _selectedQuartal!.year &&
              p.quartalNummer == ArbeitspreisKonstanten.getQuartalNummer(_selectedQuartal!),
        );
      } catch (e) {
        // Kein Preis gefunden
      }
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Auswahl-Info
          if (selectedPreis != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.pin_drop, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ausgewähltes Quartal',
                          style: SuewagTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: SuewagColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              selectedPreis.bezeichnung,
                              style: SuewagTextStyles.headline4.copyWith(
                                fontSize: 15,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedPreis.preis.toStringAsFixed(2)} ct/kWh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedQuartal = null;
                        _selectedBerechnungGas = null;
                        _selectedBerechnungStrom = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Auswahl löschen',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Row(
              children: [
                Icon(Icons.show_chart, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quartalspreise',
                  style: SuewagTextStyles.headline4.copyWith(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Klicke auf einen Punkt',
                  style: SuewagTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _buildChart(typ, preise, color),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(String typ, List<QuartalsPreis> preise, Color color) {
    if (preise.isEmpty) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    final spots = <FlSpot>[];
    var xIndex = 0.0;

    for (final preis in preise) {
      spots.add(FlSpot(xIndex, preis.preis));
      spots.add(FlSpot(xIndex + 1, preis.preis));
      spots.add(FlSpot(xIndex + 2, preis.preis));
      xIndex += 3;
    }

    final maxPreis = preise.map((p) => p.preis).reduce((a, b) => a > b ? a : b);
    final maxY = (maxPreis * 1.5).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots != null) {
              final spot = response!.lineBarSpots!.first;
              final index = (spot.x / 3).floor();
              if (index >= 0 && index < preise.length) {
                _onChartPointTapped(preise[index].quartal, typ);
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = (spot.x / 3).floor();
                if (index >= 0 && index < preise.length) {
                  final preis = preise[index];
                  final b = preis.berechnungsdaten;

                  return LineTooltipItem(
                    '${preis.bezeichnung}\n'
                        '${preis.preis.toStringAsFixed(2)} ct/kWh\n\n'
                        'K Ø: ${b.kMittelwert.toStringAsFixed(2)}\n'
                        'M Ø: ${b.mMittelwert.toStringAsFixed(2)}\n\n'
                        '💡 Tippen für Details',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: SuewagColors.divider, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: SuewagColors.divider, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1).replaceAll('.', ',')}',
                  style: SuewagTextStyles.caption.copyWith(fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                final index = (value / 3).floor();
                final position = value % 3;
                if (index >= 0 && index < preise.length && position == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      preise[index].bezeichnung,
                      style: SuewagTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final quartalIndex = (spot.x / 3).floor();
                final isSelected = _selectedQuartal != null &&
                    quartalIndex < preise.length &&
                    preise[quartalIndex].quartal.year == _selectedQuartal!.year &&
                    preise[quartalIndex].quartalNummer ==
                        ArbeitspreisKonstanten.getQuartalNummer(_selectedQuartal!);

                return FlDotCirclePainter(
                  radius: isSelected ? 5 : 2.5,
                  color: color,
                  strokeWidth: isSelected ? 2.5 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabellenMitTabs({
    required String typ,
    required List<IndexData> kData,
    required List<IndexData> mData,
    required List<QuartalsPreis> preise,
    required String kLabel,
    required String mLabel,
    required Color kColor,
    required Color mColor,
    required QuartalsBerechnungsdaten? berechnungsdaten,
  }) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: 800,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SuewagColors.divider),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: SuewagColors.divider),
                ),
              ),
              child: TabBar(
                labelColor: SuewagColors.fasergruen,
                unselectedLabelColor: SuewagColors.textSecondary,
                indicatorColor: SuewagColors.primary,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, size: 18),
                        SizedBox(width: 8),
                        Text('Monatliche Indizes'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, size: 18),
                        SizedBox(width: 8),
                        Text('Quartals-Mittelwerte'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (berechnungsdaten != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SuewagColors.indiablau.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: SuewagColors.indiablau,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Hervorgehoben: ${_formatMonth(berechnungsdaten.monat1)}, '
                                        '${_formatMonth(berechnungsdaten.monat2)}, '
                                        '${_formatMonth(berechnungsdaten.monat3)}',
                                    style: SuewagTextStyles.caption.copyWith(
                                      color: SuewagColors.indiablau,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: MonatstabelleWidget(
                            kData: kData,
                            mData: mData,
                            kLabel: kLabel,
                            mLabel: mLabel,
                            kColor: kColor,
                            mColor: mColor,
                            selectedBerechnungsdaten: berechnungsdaten,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: QuartalstabelleWidget(
                      quartale: _preisService.erstelleQuartalsUebersicht(preise),
                      kLabel: kLabel,
                      mLabel: mLabel,
                      kColor: kColor,
                      mColor: mColor,
                      selectedQuartal: _selectedQuartal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}