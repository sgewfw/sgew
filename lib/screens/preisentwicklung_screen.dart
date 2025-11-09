// lib/screens/preisentwicklung_screen.dart

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
            'Preisentwicklung',
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

              // Refresh Button
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.refresh),
                onPressed: _isRefreshing ? null : _refreshData,
                tooltip: 'Daten aktualisieren',
              ),

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
        // Toggle Buttons für Indizes - zentriert mit max width
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1800),
            child: _buildIndexToggles(),
          ),
        ),

        // Content (Chart oder Tabelle)
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1800),
              child: _viewMode == 'chart' ? _buildChartView() : _buildTableView(),
            ),
          ),
        ),
      ],
    );
  }

  /// Toggle Buttons für jeden Index
  Widget _buildIndexToggles() {
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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: DestatisConstants.verfuegbareIndizes.entries.map((entry) {
          final indexCode = entry.key;
          final indexName = entry.value;
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
                    fontWeight:
                    isVisible ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (!hasData) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: isVisible
                        ? Colors.white
                        : SuewagColors.verkehrsorange,
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
                  height: 400,
                  child: IndexChartWidget(
                    indexDataMap: visibleData,
                    indexColors: colorMap,
                    showBaseline: true,
                    chartType: 'line',
                  ),
                ),

                const SizedBox(height: 24),

                // Statistik-Cards
                ...visibleData.entries.map((entry) {
                  return _buildStatsCard(entry.key, entry.value);
                }).toList(),
              ],
            ),
          );
        }
      },
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
                    name,
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
                  current.value.toStringAsFixed(1),
                  style: SuewagTextStyles.numberLarge.withColor(color),
                ),
                Text(
                  'Aktuell',
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
                              '${monthlyChange >= 0 ? '+' : ''}${monthlyChange.toStringAsFixed(1)}%',
                              style: SuewagTextStyles.caption.withColor(
                                monthlyChange >= 0
                                    ? SuewagColors.erdbeerrot
                                    : SuewagColors.leuchtendgruen,
                              ),
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
      child: Row(
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
            final name = DestatisConstants.kurzNamen[indexCode] ??
                DestatisConstants.verfuegbareIndizes[indexCode] ??
                indexCode;

            return Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        name,
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
                '${_getMonthName(date.month)} ${date.year}',
                style: SuewagTextStyles.tableCell,
              ),
            ),
          ),

          // Werte
          ...values.entries.map((entry) {
            final indexCode = entry.key;
            final value = entry.value;
            final color = _getIndexColor(indexCode);

            return Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  value.toStringAsFixed(1),
                  style: SuewagTextStyles.tableNumber.withColor(color),
                  textAlign: TextAlign.right,
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
                        '${monthlyChange >= 0 ? '+' : ''}${monthlyChange.toStringAsFixed(1)}%',
                        style: SuewagTextStyles.caption.withColor(
                          monthlyChange >= 0
                              ? SuewagColors.erdbeerrot
                              : SuewagColors.leuchtendgruen,
                        ),
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