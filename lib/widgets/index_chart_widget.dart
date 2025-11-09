// lib/widgets/index_chart_widget.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../models/index_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../constants/destatis_constants.dart';

/// Widget zur Darstellung von Index-Daten als Chart
///
/// Unterstützt Multi-Index Darstellung (mehrere Linien)
class IndexChartWidget extends StatelessWidget {
  /// Map: IndexCode -> IndexData Liste
  final Map<String, List<IndexData>> indexDataMap;

  /// Map: IndexCode -> Farbe
  final Map<String, Color> indexColors;

  /// Zeige Datenlabels
  final bool showDataLabels;

  /// Zeige Basis-Linie (2020 = 100)
  final bool showBaseline;

  /// Chart-Typ: 'line' oder 'area'
  final String chartType;

  const IndexChartWidget({
    Key? key,
    required this.indexDataMap,
    required this.indexColors,
    this.showDataLabels = false,
    this.showBaseline = true,
    this.chartType = 'line',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (indexDataMap.isEmpty ||
        indexDataMap.values.every((data) => data.isEmpty)) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,

        // X-Achse (Zeit)
        primaryXAxis: DateTimeAxis(
          majorGridLines: const MajorGridLines(width: 0),
          dateFormat: DateFormat.yMMMM('de'),
          intervalType: DateTimeIntervalType.months,
          labelRotation: -45,
          labelStyle: SuewagTextStyles.chartAxisLabel,
          edgeLabelPlacement: EdgeLabelPlacement.shift,
        ),

        // Y-Achse (Index-Wert)
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: SuewagTextStyles.chartAxisLabel,
          numberFormat: NumberFormat('#0.0'),
          title: AxisTitle(
            text: 'Index (${DestatisConstants.basisJahr}=100)',
            textStyle: SuewagTextStyles.labelSmall,
          ),
        ),

        // Tooltip
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x: point.y',
          textStyle: SuewagTextStyles.bodySmall,
          borderWidth: 1,
          borderColor: SuewagColors.divider,
        ),

        // Legende
        legend: Legend(
          isVisible: indexDataMap.length > 1,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: SuewagTextStyles.chartLegend,
          itemPadding: 8,
        ),

        // Serien
        series: _buildSeries(),
      ),
    );
  }

  /// Erstelle Chart-Serien basierend auf Daten
  List<CartesianSeries> _buildSeries() {
    final List<CartesianSeries> seriesList = [];

    // Basis-Linie (2020 = 100)
    if (showBaseline && indexDataMap.isNotEmpty) {
      final firstData = indexDataMap.values.first;
      if (firstData.isNotEmpty) {
        seriesList.add(
          LineSeries<IndexData, DateTime>(
            dataSource: firstData,
            xValueMapper: (data, _) => data.date,
            yValueMapper: (_, __) => DestatisConstants.basisWert,
            name: '',
            color: SuewagColors.quartzgrau50,
            width: 2,
            dashArray: [5, 5],
            enableTooltip: false,
          ),
        );
      }
    }

    // Index-Daten Serien
    for (var entry in indexDataMap.entries) {
      final indexCode = entry.key;
      final data = entry.value;

      if (data.isEmpty) continue;

      final color = indexColors[indexCode] ?? SuewagColors.primary;
      final name = DestatisConstants.verfuegbareIndizes[indexCode] ?? indexCode;

      if (chartType == 'area') {
        // Area Chart
        seriesList.add(
          AreaSeries<IndexData, DateTime>(
            dataSource: data,
            xValueMapper: (data, _) => data.date,
            yValueMapper: (data, _) => data.value,
            name: name,
            color: color.withOpacity(0.3),
            borderColor: color,
            borderWidth: 2,
            markerSettings: MarkerSettings(
              isVisible: indexDataMap.length == 1,
              height: 5,
              width: 5,
              shape: DataMarkerType.circle,
              borderColor: color,
              borderWidth: 2,
            ),
          ),
        );
      } else {
        // Line Chart
        seriesList.add(
          LineSeries<IndexData, DateTime>(
            dataSource: data,
            xValueMapper: (data, _) => data.date,
            yValueMapper: (data, _) => data.value,
            name: name,
            color: color,
            width: 2.5,
            markerSettings: MarkerSettings(
              isVisible: indexDataMap.length <= 2,
              height: 5,
              width: 5,
              shape: DataMarkerType.circle,
              color: color,
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: showDataLabels && indexDataMap.length == 1,
              labelAlignment: ChartDataLabelAlignment.top,
              textStyle: SuewagTextStyles.chartDataLabel,
            ),
          ),
        );
      }
    }

    return seriesList;
  }

  /// Empty State wenn keine Daten
  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: SuewagColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Daten vorhanden',
              style: SuewagTextStyles.bodyMedium.withColor(
                SuewagColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte laden Sie die Daten über die Admin-Funktion',
              style: SuewagTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompaktes Chart-Widget für kleine Spaces
class CompactIndexChartWidget extends StatelessWidget {
  /// Index-Daten
  final List<IndexData> indexData;

  /// Farbe
  final Color color;

  /// Index Name
  final String indexName;

  const CompactIndexChartWidget({
    Key? key,
    required this.indexData,
    required this.color,
    required this.indexName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (indexData.isEmpty) {
      return _buildEmptyState();
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,

      primaryXAxis: DateTimeAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),

      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),

      series: <CartesianSeries>[
        AreaSeries<IndexData, DateTime>(
          dataSource: indexData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.value,
          color: color.withOpacity(0.2),
          borderColor: color,
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Icon(
        Icons.show_chart,
        size: 32,
        color: SuewagColors.textDisabled,
      ),
    );
  }
}