// lib/widgets/waerme_tab_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/waermepreis_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';

class WaermeTabWidget extends StatefulWidget {
  final List<QuartalsWaermepreis> waermepreise;

  const WaermeTabWidget({
    Key? key,
    required this.waermepreise,
  }) : super(key: key);

  @override
  State<WaermeTabWidget> createState() => _WaermeTabWidgetState();
}

class _WaermeTabWidgetState extends State<WaermeTabWidget> {
  QuartalsWaermepreis? _selectedPreis;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    if (widget.waermepreise.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox(
      height: 600, // 🆕 Feste Höhe für beide Widgets
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Links: Tabelle (40%)
          Expanded(
            flex: 6,
            child: _buildTabelleCard(),
          ),
          const SizedBox(width: 16),
          // Rechts: Chart (60%)
          Expanded(
            flex: 4,
            child: _buildChartCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTabelleCard(),
        const SizedBox(height: 16),
        _buildChartCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SuewagColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thermostat_outlined,
              size: 64,
              color: SuewagColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Keine Wärmepreise verfügbar',
              style: SuewagTextStyles.headline3.copyWith(
                color: SuewagColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verwende den Admin-Button (Logo), um Wärmeanteile anzulegen',
              textAlign: TextAlign.center,
              style: SuewagTextStyles.bodyMedium.copyWith(
                color: SuewagColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelleCard() {
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: SuewagColors.divider),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: SuewagColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Wärmepreise nach Quartal',
                  style: SuewagTextStyles.headline4,
                ),
              ],
            ),
          ),
          // Tabelle mit Scroll
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    SuewagColors.background,
                  ),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text('Quartal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Anteil Wärme\naus Gas (yₙ)', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Anteil Wärme\naus Strom (1-yₙ)', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Wärmepreise Gas', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Wärmepreis Strom', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),

                    DataColumn(
                      label: Text('Gesamt-\nWärmepreis', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                  ],
                  rows: widget.waermepreise.map((preis) {
                    final isSelected = _selectedPreis?.quartal == preis.quartal;

                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (_) {
                        setState(() {
                          _selectedPreis = isSelected ? null : preis;
                        });
                      },
                      cells: [
                        DataCell(
                          Text(
                            preis.bezeichnung,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(preis.anteilGas * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: SuewagColors.erdgas,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${(preis.anteilStrom * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: SuewagColors.chartGewerbe,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${preis.gasArbeitspreis.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: SuewagColors.erdgas.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${preis.stromArbeitspreis.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: SuewagColors.chartGewerbe.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SuewagColors.fasergruen.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${preis.waermepreisGesamt.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: SuewagColors.fasergruen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Footer mit Legende
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: SuewagColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formel: Wärmepreis = (yₙ × AP_Gas) + ((1-yₙ) × AP_Strom)',
                  style: SuewagTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alle Preise in ct/kWh',
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
          // Header
          if (_selectedPreis != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.fasergruen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SuewagColors.fasergruen, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.pin_drop, color: SuewagColors.fasergruen, size: 20),
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
                              _selectedPreis!.bezeichnung,
                              style: SuewagTextStyles.headline4.copyWith(
                                fontSize: 15,
                                color: SuewagColors.fasergruen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedPreis!.waermepreisGesamt.toStringAsFixed(2)} ct/kWh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: SuewagColors.fasergruen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedPreis = null);
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
                Icon(Icons.show_chart, color: SuewagColors.fasergruen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Wärmepreis-Entwicklung',
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
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (widget.waermepreise.isEmpty) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    // Erstelle Spots für alle 3 Linien
    final spotsGas = <FlSpot>[];
    final spotsStrom = <FlSpot>[];
    final spotsGesamt = <FlSpot>[];
    var xIndex = 0.0;

    for (final preis in widget.waermepreise) {
      // Jedes Quartal wird über 3 x-Einheiten dargestellt (Plateau)
      for (var i = 0; i < 3; i++) {
        spotsGas.add(FlSpot(xIndex + i, preis.waermepreisGasAnteil));
        spotsStrom.add(FlSpot(xIndex + i, preis.waermepreisStromAnteil));
        spotsGesamt.add(FlSpot(xIndex + i, preis.waermepreisGesamt));
      }
      xIndex += 3;
    }

    final maxPreis = widget.waermepreise
        .map((p) => p.waermepreisGesamt)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxPreis * 1.2).ceilToDouble();

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
              if (index >= 0 && index < widget.waermepreise.length) {
                setState(() {
                  _selectedPreis = widget.waermepreise[index];
                });
              }
            }
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final index = (entry.value.x / 3).floor();

                // Nur beim ersten Spot (Index 0) den Tooltip anzeigen
                if (entry.key == 0 && index >= 0 && index < widget.waermepreise.length) {
                  final preis = widget.waermepreise[index];

                  return LineTooltipItem(
                    '${preis.bezeichnung}\n'
                        'Gesamt: ${preis.waermepreisGesamt.toStringAsFixed(2)} ct/kWh\n\n',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  );
                }

                // Für die anderen Linien null zurückgeben (kein Tooltip)
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
                  value.toStringAsFixed(1).replaceAll('.', ','),
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
                if (index >= 0 && index < widget.waermepreise.length && position == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.waermepreise[index].bezeichnung,
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
          // Gas-Anteil (dünn gestrichelt)
          LineChartBarData(
            spots: spotsGas,
            isCurved: false,
            color: SuewagColors.erdgas.withOpacity(0.4),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Strom-Anteil (dünn gestrichelt)
          LineChartBarData(
            spots: spotsStrom,
            isCurved: false,
            color: SuewagColors.chartGewerbe.withOpacity(0.4),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Gesamt-Wärmepreis (dick durchgezogen)
          LineChartBarData(
            spots: spotsGesamt,
            isCurved: false,
            color: SuewagColors.fasergruen,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final quartalIndex = (spot.x / 3).floor();
                final isSelected = _selectedPreis != null &&
                    quartalIndex < widget.waermepreise.length &&
                    widget.waermepreise[quartalIndex].quartal == _selectedPreis!.quartal;

                return FlDotCirclePainter(
                  radius: isSelected ? 5 : 2.5,
                  color: SuewagColors.fasergruen,
                  strokeWidth: isSelected ? 2.5 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: SuewagColors.fasergruen.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}