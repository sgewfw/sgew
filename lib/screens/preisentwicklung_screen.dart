// lib/screens/preisentwicklung_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/index_data.dart';
import '../services/energie_index_service.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../constants/destatis_constants.dart';
import '../widgets/index_chart_widget.dart';
import '../widgets/loading_widget.dart' as custom;
import '../widgets/logo_widget.dart';

/// Hauptseite: Preisentwicklung
///
/// Zeigt alle 4 Energie-Indizes in einem Chart mit Toggle-Buttons
class PreisentwicklungScreen extends StatefulWidget {
  const PreisentwicklungScreen({Key? key}) : super(key: key);

  @override
  State<PreisentwicklungScreen> createState() => _PreisentwicklungScreenState();
}

class _PreisentwicklungScreenState extends State<PreisentwicklungScreen> {
  final EnergieIndexService _service = EnergieIndexService();

  // Daten-State
  Map<String, List<IndexData>> _allIndexData = {};
  Map<String, DateTime?> _lastUpdateMap = {};

  bool _isLoading = true;
  String? _error;
  bool _isRefreshing = false;

  // Sichtbare Indizes (alle 4 initial sichtbar)
  Set<String> _visibleIndizes = {
    DestatisConstants.erdgasGewerbeCode,
    DestatisConstants.stromGewerbeCode,
    DestatisConstants.stromHaushalteCode,
    DestatisConstants.waermepreisCode,
  };

  // View Mode: 'chart' oder 'table'
  String _viewMode = 'chart';
  String _preisformelFilter = 'ALLE'; // 'ALLE', 'BIS_2027', 'AB_2028'
  bool _showCO2Tab = false; // Separater Tab für CO₂
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Widget _buildPreisformelFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: SuewagColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Preisformel: ',
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),

          // Alle
          ChoiceChip(
            label: const Text('Alle'),
            selected: _preisformelFilter == 'ALLE',
            onSelected: (_) {
              setState(() {
                _preisformelFilter = 'ALLE';
                _updateVisibleIndizes(); // 🆕
              });
            },
            selectedColor: SuewagColors.primary,
            labelStyle: TextStyle(
              color: _preisformelFilter == 'ALLE' ? Colors.white : SuewagColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),

          // Bis Ende 2027
          ChoiceChip(
            label: const Text('Bis Ende 2027'),
            selected: _preisformelFilter == 'BIS_2027',
            onSelected: (_) {
              setState(() {
                _preisformelFilter = 'BIS_2027';
                _updateVisibleIndizes(); // 🆕
              });
            },
            selectedColor: SuewagColors.indiablau,
            labelStyle: TextStyle(
              color: _preisformelFilter == 'BIS_2027' ? Colors.white : SuewagColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),

          // Ab 2028
          ChoiceChip(
            label: const Text('Ab 2028'),
            selected: _preisformelFilter == 'AB_2028',
            onSelected: (_) {
              setState(() {
                _preisformelFilter = 'AB_2028';
                _updateVisibleIndizes(); // 🆕
              });
            },
            selectedColor: SuewagColors.leuchtendgruen,
            labelStyle: TextStyle(
              color: _preisformelFilter == 'AB_2028' ? Colors.white : SuewagColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Aktualisiere sichtbare Indizes basierend auf Preisformel-Filter
  void _updateVisibleIndizes() {
    final filteredIndizes = DestatisConstants.getFilteredIndizes(_preisformelFilter);

    // Entferne CO₂ aus sichtbaren Indizes
    final validIndizes = filteredIndizes
        .where((code) => code != DestatisConstants.ecarbixCode)
        .toSet();

    // Setze nur die Indizes die auch Daten haben
    _visibleIndizes = validIndizes.where((code) {
      return _allIndexData[code]?.isNotEmpty ?? false;
    }).toSet();

    // Mindestens ein Index muss sichtbar sein
    if (_visibleIndizes.isEmpty && validIndizes.isNotEmpty) {
      _visibleIndizes = {validIndizes.first};
    }
  }

  /// Lade alle Index-Daten
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, List<IndexData>> dataMap = {};
      final Map<String, DateTime?> updateMap = {};

      // Lade alle 4 Indizes
      for (var indexCode in DestatisConstants.verfuegbareIndizes.keys) {
        try {
          final data = await _service.getIndexData(indexCode: indexCode);
          dataMap[indexCode] = data;

          final lastUpdate = await _service.getLastUpdate(indexCode);
          updateMap[indexCode] = lastUpdate;

          print('✅ Loaded ${data.length} data points for $indexCode');
        } catch (e) {
          print('⚠️ Error loading $indexCode: $e');
          dataMap[indexCode] = [];
        }
      }

      if (mounted) {
        setState(() {
          _allIndexData = dataMap;
          _lastUpdateMap = updateMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden der Daten: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh alle Daten
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh alle Indizes parallel
      await Future.wait(
        DestatisConstants.verfuegbareIndizes.keys.map((indexCode) {
          return _service.refreshIndexData(
            indexCode: indexCode,
            months: DestatisConstants.standardZeitraumMonate,
          );
        }),
      );

      // Lade Daten neu
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle Daten erfolgreich aktualisiert'),
            backgroundColor: SuewagColors.leuchtendgruen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: SuewagColors.erdbeerrot,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Toggle Index Sichtbarkeit
  void _toggleIndex(String indexCode) {
    setState(() {
      if (_visibleIndizes.contains(indexCode)) {
        // Mindestens ein Index muss sichtbar bleiben
        if (_visibleIndizes.length > 1) {
          _visibleIndizes.remove(indexCode);
        }
      } else {
        _visibleIndizes.add(indexCode);
      }
    });
  }

  /// Hole Farbe für Index
  Color _getIndexColor(String indexCode) {
    switch (indexCode) {
      case DestatisConstants.erdgasGewerbeCode:
        return SuewagColors.erdgas;
      case DestatisConstants.stromGewerbeCode:
        return SuewagColors.chartGewerbe;
      case DestatisConstants.stromHaushalteCode:
        return SuewagColors.chartHaushalte;
      case DestatisConstants.waermepreisCode:
        return SuewagColors.waerme;
      default:
        return SuewagColors.primary;
    }
  }

  /// Hole Icon für Index
  IconData _getIndexIcon(String indexCode) {
    switch (indexCode) {
      case DestatisConstants.erdgasGewerbeCode:
        return Icons.local_fire_department;
      case DestatisConstants.stromGewerbeCode:
        return Icons.bolt;
      case DestatisConstants.stromHaushalteCode:
        return Icons.electric_bolt;
      case DestatisConstants.waermepreisCode:
        return Icons.thermostat;
      default:
        return Icons.show_chart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Lade Indexdaten...')
          : _error != null
          ? custom.ErrorWidget(
        message: _error!,
        onRetry: _loadData,
      )
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Indizes',
            style: SuewagTextStyles.headline2,
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _viewMode == 'chart' ? Icons.table_chart : Icons.show_chart,
                ),
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == 'chart' ? 'table' : 'chart';
                  });
                },
                tooltip: _viewMode == 'chart'
                    ? 'Zur Tabellen-Ansicht'
                    : 'Zur Chart-Ansicht',
              ),

              // // Refresh Button
              // IconButton(
              //   icon: _isRefreshing
              //       ? const SizedBox(
              //     width: 20,
              //     height: 20,
              //     child: CircularProgressIndicator(
              //       strokeWidth: 2,
              //       valueColor:
              //       AlwaysStoppedAnimation<Color>(Colors.white),
              //     ),
              //   )
              //       : const Icon(Icons.refresh),
              //   onPressed: _isRefreshing ? null : _refreshData,
              //   tooltip: 'Daten aktualisieren',
              // ),

              const SizedBox(width: 12),

              const AppLogo(height: 32),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: SuewagColors.quartzgrau100,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // 🆕 Preisformel-Filter oben
        _buildPreisformelFilter(),

        // 🆕 Tab-Buttons für Indizes vs CO₂
        _buildTabSelector(),

        // Toggle Buttons für Indizes (nur wenn nicht CO₂-Tab)
        if (!_showCO2Tab)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1800),
              child: _buildIndexToggles(),
            ),
          ),

        // Content
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1800),
              child: _showCO2Tab
                  ? _buildCO2View()
                  : (_viewMode == 'chart' ? _buildChartView() : _buildTableView()),
            ),
          ),
        ),
      ],
    );
  }
  /// 🆕 Tab-Selector (Indizes vs CO₂)
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: SuewagColors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indizes Tab
          InkWell(
            onTap: () => setState(() => _showCO2Tab = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !_showCO2Tab ? SuewagColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                'Energie-Indizes',
                style: SuewagTextStyles.headline4.copyWith(
                  color: !_showCO2Tab ? SuewagColors.primary : SuewagColors.textSecondary,
                  fontWeight: !_showCO2Tab ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // CO₂ Tab
          InkWell(
            onTap: () => setState(() => _showCO2Tab = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _showCO2Tab ? SuewagColors.verkehrsorange : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.co2,
                    size: 20,
                    color: _showCO2Tab ? SuewagColors.verkehrsorange : SuewagColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CO₂-Preis (€/Tonne)',
                    style: SuewagTextStyles.headline4.copyWith(
                      color: _showCO2Tab ? SuewagColors.verkehrsorange : SuewagColors.textSecondary,
                      fontWeight: _showCO2Tab ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// 🆕 Separate View für CO₂-Preis
  Widget _buildCO2View() {
    final co2Data = _allIndexData[DestatisConstants.ecarbixCode] ?? [];

    if (co2Data.isEmpty) {
      return const custom.EmptyStateWidget(
        title: 'Keine CO₂-Daten verfügbar',
        description: 'CO₂-Preisdaten werden automatisch von EEX geladen',
        icon: Icons.co2,
      );
    }

    final colorMap = {
      DestatisConstants.ecarbixCode: SuewagColors.verkehrsorange,
    };

    // 🆕 Chart oder Tabelle basierend auf _viewMode
    return _viewMode == 'chart'
        ? _buildCO2ChartView(co2Data, colorMap)
        : _buildCO2TableView(co2Data);
  }

  /// 🆕 CO₂ Chart View
  Widget _buildCO2ChartView(List<IndexData> co2Data, Map<String, Color> colorMap) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info-Box mit Quelle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SuewagColors.verkehrsorange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuewagColors.verkehrsorange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: SuewagColors.verkehrsorange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CO₂-Preise in €/Tonne',
                        style: SuewagTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Quelle
                Row(
                  children: [
                    Icon(Icons.link, color: SuewagColors.verkehrsorange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quelle: ',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openEEXLink(),
                        child: Text(
                          'EEX - European Energy Exchange',
                          style: SuewagTextStyles.bodySmall.copyWith(
                            color: SuewagColors.verkehrsorange,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      onPressed: () => _openEEXLink(),
                      tooltip: 'EEX-Quelle öffnen',
                      color: SuewagColors.verkehrsorange,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 500,
            child: IndexChartWidget(
              indexDataMap: {DestatisConstants.ecarbixCode: co2Data},
              indexColors: colorMap,
              showBaseline: false,
              chartType: 'line',
            ),
          ),

          const SizedBox(height: 24),

          // Stats Card
          _buildCO2StatsCard(co2Data),
        ],
      ),
    );
  }

  /// 🆕 CO₂ Tabellen View
  Widget _buildCO2TableView(List<IndexData> co2Data) {
    // Sortiere nach Datum (neueste zuerst)
    final sortedData = List<IndexData>.from(co2Data)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info-Box mit Quelle (gleich wie Chart)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SuewagColors.verkehrsorange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuewagColors.verkehrsorange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: SuewagColors.verkehrsorange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CO₂-Preis  in €/Tonne',
                        style: SuewagTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.link, color: SuewagColors.verkehrsorange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quelle: ',
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openEEXLink(),
                        child: Text(
                          'EEX - European Energy Exchange',
                          style: SuewagTextStyles.bodySmall.copyWith(
                            color: SuewagColors.verkehrsorange,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      onPressed: () => _openEEXLink(),
                      tooltip: 'EEX-Quelle öffnen',
                      color: SuewagColors.verkehrsorange,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tabelle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SuewagColors.divider),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SuewagColors.verkehrsorange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Monat',
                          style: SuewagTextStyles.tableHeader.withColor(
                            SuewagColors.verkehrsorange,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Preis (€/Tonne)',
                          style: SuewagTextStyles.tableHeader.withColor(
                            SuewagColors.verkehrsorange,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 48), // Für Link-Button
                    ],
                  ),
                ),

                // Rows
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedData.length,
                  itemBuilder: (context, index) {
                    final data = sortedData[index];
                    final backgroundColor = index.isEven
                        ? SuewagColors.quartzgrau10
                        : Colors.white;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border(
                          bottom: BorderSide(
                            color: SuewagColors.divider,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Monat
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_getMonthNameShort(data.date.month)} \'${data.date.year.toString().substring(2)}',
                              style: SuewagTextStyles.tableCell,
                            ),
                          ),
                          // Preis
                          // Preis
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_formatGermanNumber(data.value, 2)} €/t', // 🔥 Komma + €/t
                              style: SuewagTextStyles.tableNumber.withColor(
                                SuewagColors.verkehrsorange,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // Link Button
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              icon: const Icon(Icons.open_in_new, size: 16),
                              onPressed: () => _openEEXLink(),
                              tooltip: 'EEX-Quelle',
                              color: SuewagColors.verkehrsorange,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// Öffne EEX-Link
  Future<void> _openEEXLink() async {
    const eexUrl = 'https://www.eex.com/de/customised-solutions/agfw';

    try {
      final uri = Uri.parse(eexUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Konnte URL nicht öffnen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen: $e'),
            backgroundColor: SuewagColors.erdbeerrot,
          ),
        );
      }
    }
  }
  /// Stats Card für CO₂
  Widget _buildCO2StatsCard(List<IndexData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final current = data.last;
    final previous = data.length > 1 ? data[data.length - 2] : null;
    final monthlyChange = previous != null
        ? IndexData.calculateChange(previous, current)
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SuewagColors.verkehrsorange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SuewagColors.verkehrsorange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.co2,
                    color: SuewagColors.verkehrsorange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ECarbiX',
                        style: SuewagTextStyles.headline3,
                      ),
                      Text(
                        '${_getMonthNameShort(current.date.month)} ${current.date.year}',
                        style: SuewagTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${current.value.toStringAsFixed(2)} €',
                      style: SuewagTextStyles.numberLarge.withColor(
                        SuewagColors.verkehrsorange,
                      ),
                    ),
                    Text(
                      'pro Tonne CO₂',
                      style: SuewagTextStyles.caption,
                    ),
                    if (monthlyChange != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            monthlyChange >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: monthlyChange >= 0
                                ? SuewagColors.erdbeerrot
                                : SuewagColors.leuchtendgruen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${monthlyChange >= 0 ? '+' : ''}${monthlyChange.toStringAsFixed(1)}%',
                            style: SuewagTextStyles.caption.withColor(
                              monthlyChange >= 0
                                  ? SuewagColors.erdbeerrot
                                  : SuewagColors.leuchtendgruen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// Toggle Buttons für jeden Index
  /// Toggle Buttons für jeden Index
  Widget _buildIndexToggles() {
    // 🆕 Filtere Indizes basierend auf Preisformel-Filter
    final filteredIndizes = DestatisConstants.getFilteredIndizes(_preisformelFilter);

    // 🆕 CO₂ niemals in Index-Toggles zeigen
    final displayIndizes = filteredIndizes
        .where((code) => code != DestatisConstants.ecarbixCode)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile: 2 Buttons pro Zeile, gleich groß
            final buttonWidth = (constraints.maxWidth - 40) / 2;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayIndizes.map((indexCode) {
                final indexName = DestatisConstants.verfuegbareIndizes[indexCode]!;
                final isVisible = _visibleIndizes.contains(indexCode);
                final color = _getIndexColor(indexCode);
                final icon = _getIndexIcon(indexCode);
                final hasData = _allIndexData[indexCode]?.isNotEmpty ?? false;
                final label = DestatisConstants.mobileLabels[indexCode] ?? indexName;

                return SizedBox(
                  width: buttonWidth,
                  height: 40, // Feste Höhe für alle Buttons
                  child: FilterChip(
                    selected: isVisible,
                    onSelected: hasData ? (_) => _toggleIndex(indexCode) : null,
                    label: SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isVisible ? Colors.white : color,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isVisible ? Colors.white : color,
                                fontWeight: isVisible ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!hasData)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: isVisible ? Colors.white : SuewagColors.verkehrsorange,
                              ),
                            ),
                        ],
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: color, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                );
              }).toList(),
            );
          } else {
            // Desktop: Alle in einer Reihe mit langen Labels
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: displayIndizes.map((indexCode) {
                final indexName = DestatisConstants.verfuegbareIndizes[indexCode]!;
                final isVisible = _visibleIndizes.contains(indexCode);
                final color = _getIndexColor(indexCode);
                final icon = _getIndexIcon(indexCode);
                final hasData = _allIndexData[indexCode]?.isNotEmpty ?? false;

                return FilterChip(
                  selected: isVisible,
                  onSelected: hasData ? (_) => _toggleIndex(indexCode) : null,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isVisible ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        indexName,
                        style: TextStyle(
                          color: isVisible ? Colors.white : color,
                          fontWeight: isVisible ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (!hasData) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: isVisible ? Colors.white : SuewagColors.verkehrsorange,
                        ),
                      ],
                    ],
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: color, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
  /// Chart Ansicht mit responsive Layout
  Widget _buildChartView() {
    // Filter nur sichtbare Indizes mit Daten
    final visibleData = Map.fromEntries(
      _allIndexData.entries
          .where((e) => _visibleIndizes.contains(e.key) && e.value.isNotEmpty),
    );

    if (visibleData.isEmpty) {
      return const custom.EmptyStateWidget(
        title: 'Keine Daten verfügbar',
        description: 'Bitte laden Sie die Daten über den Refresh-Button',
        icon: Icons.show_chart,
      );
    }

    final colorMap = Map.fromEntries(
      visibleData.keys.map((code) => MapEntry(code, _getIndexColor(code))),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;
        final isMobile = constraints.maxWidth < 600;

        if (isDesktop) {
          // Desktop: Info-Cards links, Chart rechts
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Cards - 2x2 Grid
                SizedBox(
                  width: 500,
                  child: _buildStatsGrid(visibleData),
                ),

                const SizedBox(width: 24),

                // Chart
                Expanded(
                  child: SizedBox(
                    height: 600,
                    child: IndexChartWidget(
                      indexDataMap: visibleData,
                      indexColors: colorMap,
                      showBaseline: true,
                      chartType: 'line',
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile/Tablet: Chart oben, Cards unten
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Haupt-Chart
                SizedBox(
                  height: isMobile ? 400 : 500,
                  child: IndexChartWidget(
                    indexDataMap: visibleData,
                    indexColors: colorMap,
                    showBaseline: true,
                    chartType: 'line',
                  ),
                ),

                const SizedBox(height: 24),

                // Statistik-Cards - einzeln für Mobile
                ...visibleData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMobileStatsCard(entry.key, entry.value),
                  );
                }).toList(),
              ],
            ),
          );
        }
      },
    );
  }
  /// Mobile Stats Card (kompakt, eine pro Zeile)
  /// Mobile Stats Card (kompakt, eine pro Zeile)
  /// Mobile Stats Card (kompakt, eine pro Zeile)
  Widget _buildMobileStatsCard(String indexCode, List<IndexData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final color = _getIndexColor(indexCode);
    final icon = _getIndexIcon(indexCode);
    final name = DestatisConstants.verfuegbareIndizes[indexCode] ?? indexCode;

    final current = data.last;
    final previous = data.length > 1 ? data[data.length - 2] : null;
    final monthlyChange =
    previous != null ? IndexData.calculateChange(previous, current) : null;

    // Berechne Monat
    final monthNames = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    final monthText = '${monthNames[current.date.month - 1]} ${current.date.year}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quartal Überschrift
            Text(
              monthText,
              style: SuewagTextStyles.caption.withColor(color).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 8),

            // Rest wie vorher
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),

                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Text(
                    name,
                    style: SuewagTextStyles.headline4.copyWith(fontSize: 14),
                  ),
                ),

                // Wert
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      current.value.toStringAsFixed(1),
                      style: SuewagTextStyles.numberMedium.withColor(color).copyWith(fontSize: 18),
                    ),
                    if (monthlyChange != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            monthlyChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 10,
                            color: monthlyChange >= 0
                                ? SuewagColors.erdbeerrot
                                : SuewagColors.leuchtendgruen,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${monthlyChange >= 0 ? '+' : '-'}${_formatGermanNumber(monthlyChange.abs(), 1)}%',
                            style: SuewagTextStyles.caption.withColor(
                              monthlyChange >= 0
                                  ? SuewagColors.erdbeerrot
                                  : SuewagColors.leuchtendgruen,
                            ).copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Link Button
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () => _openDestatisLink(indexCode),
                  tooltip: 'Quelle',
                  color: color,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// Stats Grid für Desktop (2x2)
  Widget _buildStatsGrid(Map<String, List<IndexData>> visibleData) {
    final entries = visibleData.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildCompactStatsCard(entry.key, entry.value);
      },
    );
  }

  /// Kompakte Stats Card für Grid
  Widget _buildCompactStatsCard(String indexCode, List<IndexData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final color = _getIndexColor(indexCode);
    final icon = _getIndexIcon(indexCode);
    final name = DestatisConstants.kurzNamen[indexCode] ??
        DestatisConstants.verfuegbareIndizes[indexCode] ??
        indexCode;
    final nummer = DestatisConstants.indexToClassifyingKey[indexCode] ??"";

    final current = data.last;
    final previous = data.length > 1 ? data[data.length - 2] : null;
    final monthlyChange =
    previous != null ? IndexData.calculateChange(previous, current) : null;

    final yearAgo = data.length > 12 ? data[data.length - 13] : null;
    final yearlyChange =
    yearAgo != null ? IndexData.calculateChange(yearAgo, current) : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Icon und Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: SuewagTextStyles.headline4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    nummer,
                    style: SuewagTextStyles.headline4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  onPressed: () => _openDestatisLink(indexCode),
                  tooltip: 'Destatis-Quelle öffnen',
                  color: color,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Aktueller Wert
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatGermanNumber(current.value, 1),
                  style: SuewagTextStyles.numberLarge.withColor(color),
                ),
                Text(
                  '${_getMonthNameShort(current.date.month)} \'${current.date.year.toString().substring(2)}',
                  style: SuewagTextStyles.caption,
                ),
              ],
            ),

            // Änderungen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Monatliche Änderung
                if (monthlyChange != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              monthlyChange >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: monthlyChange >= 0
                                  ? SuewagColors.erdbeerrot
                                  : SuewagColors.leuchtendgruen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${monthlyChange >= 0 ? '+' : '-'}${_formatGermanNumber(monthlyChange.abs(), 1)}%',
                              style: SuewagTextStyles.caption.withColor(
                                monthlyChange >= 0
                                    ? SuewagColors.erdbeerrot
                                    : SuewagColors.leuchtendgruen,
                              ).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        Text(
                          'Monat',
                          style: SuewagTextStyles.caption,
                        ),
                      ],
                    ),
                  ),

                // Jährliche Änderung
                if (yearlyChange != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              yearlyChange >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: yearlyChange >= 0
                                  ? SuewagColors.erdbeerrot
                                  : SuewagColors.leuchtendgruen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${yearlyChange >= 0 ? '+' : ''}${yearlyChange.toStringAsFixed(1)}%',
                              style: SuewagTextStyles.caption.withColor(
                                yearlyChange >= 0
                                    ? SuewagColors.erdbeerrot
                                    : SuewagColors.leuchtendgruen,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Jahr',
                          style: SuewagTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// Kurzer Monatsname (3 Buchstaben)
  String _getMonthNameShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
  /// Formatiere Zahl im deutschen Format (1.234,5)
  String _formatGermanNumber(double value, int decimals) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'de_DE');
    return formatter.format(value);
  }
  /// Tabellen Ansicht (Monatsscharf)
  Widget _buildTableView() {
    // Filter nur sichtbare Indizes mit Daten
    final visibleData = Map.fromEntries(
      _allIndexData.entries
          .where((e) => _visibleIndizes.contains(e.key) && e.value.isNotEmpty),
    );

    if (visibleData.isEmpty) {
      return const custom.EmptyStateWidget(
        title: 'Keine Daten verfügbar',
        description: 'Bitte laden Sie die Daten über den Refresh-Button',
        icon: Icons.table_chart,
      );
    }

    // Kombiniere alle Daten nach Datum
    final Map<DateTime, Map<String, double>> combinedData = {};

    for (var entry in visibleData.entries) {
      final indexCode = entry.key;
      for (var data in entry.value) {
        combinedData.putIfAbsent(data.date, () => {});
        combinedData[data.date]![indexCode] = data.value;
      }
    }

    // Sortiere nach Datum (neueste zuerst)
    final sortedDates = combinedData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SuewagColors.divider),
        ),
        child: Column(
          children: [
            // Tabellen-Header
            _buildMonthlyTableHeader(visibleData.keys.toList()),

            // Tabellen-Body
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final values = combinedData[date]!;
                return _buildMonthlyTableRow(
                  date,
                  values,
                  index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Monatliche Tabellen-Header
  Widget _buildMonthlyTableHeader(List<String> indexCodes) {
    return Container(
      decoration: BoxDecoration(
        color: SuewagColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Row(
            children: [
              // Datum Spalte
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Monat',
                    style: SuewagTextStyles.tableHeader.withColor(
                      SuewagColors.primary,
                    ),
                  ),
                ),
              ),

              // Index Spalten
              ...indexCodes.map((indexCode) {
                final color = _getIndexColor(indexCode);
                final name = isMobile
                    ? DestatisConstants.mobileLabels[indexCode]
                    : DestatisConstants.kurzNamen[indexCode];

                return Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: isMobile ? 8 : 12,
                    ),
                    child: isMobile
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vertikaler Text für Mobile
                        RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            name ?? indexCode,
                            style: SuewagTextStyles.tableHeader.withColor(color).copyWith(
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Link Button
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 12),
                          onPressed: () => _openDestatisLink(indexCode),
                          tooltip: 'Quelle',
                          color: color,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(maxWidth: 20, maxHeight: 20),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            name ?? indexCode,
                            style: SuewagTextStyles.tableHeader.withColor(color),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 14),
                          onPressed: () => _openDestatisLink(indexCode),
                          tooltip: 'Destatis-Quelle',
                          color: color,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  /// Öffne Destatis-Link
  Future<void> _openDestatisLink(String indexCode) async {
    try {
      final link = await _service.getIndexLink(indexCode);

      if (link == null || link.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein Destatis-Link verfügbar'),
              backgroundColor: SuewagColors.verkehrsorange,
            ),
          );
        }
        return;
      }

      // URL öffnen
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Konnte URL nicht öffnen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen: $e'),
            backgroundColor: SuewagColors.erdbeerrot,
          ),
        );
      }
    }
  }
  /// Monatliche Tabellen-Zeile
  Widget _buildMonthlyTableRow(
      DateTime date,
      Map<String, double> values,
      int index,
      ) {
    final backgroundColor =
    index.isEven ? SuewagColors.quartzgrau10 : Colors.white;

    // 🆕 Hole alle sichtbaren Index-Codes für Spalten-Reihenfolge
    final visibleData = Map.fromEntries(
      _allIndexData.entries
          .where((e) => _visibleIndizes.contains(e.key) && e.value.isNotEmpty),
    );
    final indexCodes = visibleData.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: SuewagColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Datum
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${_getMonthNameShort(date.month)} \'${date.year.toString().substring(2)}',
                style: SuewagTextStyles.tableCell,
              ),
            ),
          ),

          // Werte - in gleicher Reihenfolge wie Header
          ...indexCodes.map((indexCode) {
            final value = values[indexCode]; // 🔥 Kann null sein!
            final color = _getIndexColor(indexCode);

            return Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  value != null
                      ? _formatGermanNumber(value, 1)
                      : '-', // 🔥 Strich wenn kein Wert
                  style: SuewagTextStyles.tableNumber.withColor(
                    value != null ? color : SuewagColors.textDisabled,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Stats Card für Mobile (behalten für Kompatibilität)
  Widget _buildStatsCard(String indexCode, List<IndexData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final color = _getIndexColor(indexCode);
    final icon = _getIndexIcon(indexCode);
    final name = DestatisConstants.verfuegbareIndizes[indexCode] ?? indexCode;
    final lastUpdate = _lastUpdateMap[indexCode];

    final current = data.last;
    final previous = data.length > 1 ? data[data.length - 2] : null;
    final monthlyChange =
    previous != null ? IndexData.calculateChange(previous, current) : null;

    final yearAgo = data.length > 12 ? data[data.length - 13] : null;
    final yearlyChange =
    yearAgo != null ? IndexData.calculateChange(yearAgo, current) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),

            const SizedBox(width: 16),

            Row(
              children: [
                Expanded(
                  child: Text(name, style: SuewagTextStyles.headline4),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () => _openDestatisLink(indexCode),
                  tooltip: 'Destatis-Quelle öffnen',
                  color: color,
                ),
              ],
            ),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: SuewagTextStyles.headline4),
                  if (lastUpdate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Stand: ${_formatDateTime(lastUpdate)}',
                      style: SuewagTextStyles.caption,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${data.length} Datenpunkte',
                    style: SuewagTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Aktueller Wert
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  current.value.toStringAsFixed(1),
                  style: SuewagTextStyles.numberMedium.withColor(color),
                ),
                if (monthlyChange != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        monthlyChange >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: monthlyChange >= 0
                            ? SuewagColors.erdbeerrot
                            : SuewagColors.leuchtendgruen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${monthlyChange >= 0 ? '+' : '-'}${_formatGermanNumber(monthlyChange.abs(), 1)}%',
                        style: SuewagTextStyles.caption.withColor(
                          monthlyChange >= 0
                              ? SuewagColors.erdbeerrot
                              : SuewagColors.leuchtendgruen,
                        ).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  Text(
                    'Monat',
                    style: SuewagTextStyles.caption,
                  ),
                ],
                if (yearlyChange != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        yearlyChange >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: yearlyChange >= 0
                            ? SuewagColors.erdbeerrot
                            : SuewagColors.leuchtendgruen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${yearlyChange >= 0 ? '+' : ''}${yearlyChange.toStringAsFixed(1)}%',
                        style: SuewagTextStyles.caption.withColor(
                          yearlyChange >= 0
                              ? SuewagColors.erdbeerrot
                              : SuewagColors.leuchtendgruen,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Jahr',
                    style: SuewagTextStyles.caption,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format DateTime
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Monatsname
  String _getMonthName(int month) {
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    return months[month - 1];
  }
}