// lib/widgets/kostenvergleich_chart_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_ergebnis.dart';

class KostenvergleichChartWidget extends StatelessWidget {
  final List<KostenberechnungErgebnis> ergebnisse;

  const KostenvergleichChartWidget({
    Key? key,
    required this.ergebnisse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildChart(),
        ),
        const SizedBox(height: 16),
        _buildLegende(),
      ],
    );
  }

  Widget _buildChart() {
    if (ergebnisse.isEmpty) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    // Finde maximalen Wert für Y-Achse
    double maxWert = 0;
    for (final ergebnis in ergebnisse) {
      final summe = ergebnis.preisbestandteile.summeOhneFoerderung;
      if (summe > maxWert) maxWert = summe;
    }

    final maxY = (maxWert * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final ergebnis = ergebnisse[groupIndex];
              return BarTooltipItem(
                '${ergebnis.szenarioBezeichnung}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Gesamt: ${ergebnis.preisbestandteile.summeMitFoerderung.toStringAsFixed(2)} ct/kWh\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  if (ergebnis.preisbestandteile.zusaetzlicheKapitalkostenOhneFoerderung > 0)
                    TextSpan(
                      text: 'Ohne Förderung: ${ergebnis.preisbestandteile.summeOhneFoerderung.toStringAsFixed(2)} ct/kWh',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < ergebnisse.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getSzenarioKurz(ergebnisse[index].szenarioBezeichnung),
                      style: SuewagTextStyles.caption.copyWith(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: SuewagTextStyles.caption.copyWith(fontSize: 9),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: SuewagColors.divider,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: SuewagColors.divider),
        ),
        barGroups: _createBarGroups(),
      ),
    );
  }

  String _getSzenarioKurz(String bezeichnung) {
    if (bezeichnung.contains('Wärmepumpe')) return 'Wärme-\npumpe';
    if (bezeichnung.contains('ohne')) return 'Netz\nohne ÜGS';
    if (bezeichnung.contains('Kunde')) return 'Netz\nKunde';
    if (bezeichnung.contains('Süwag')) return 'Netz\nSüwag';
    return bezeichnung;
  }

  List<BarChartGroupData> _createBarGroups() {
    return ergebnisse.asMap().entries.map((entry) {
      final index = entry.key;
      final ergebnis = entry.value;
      final preise = ergebnis.preisbestandteile;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: preise.summeOhneFoerderung,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            rodStackItems: _createStackItems(preise),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartRodStackItem> _createStackItems(PreisbestandteileChart preise) {
    final items = <BarChartRodStackItem>[];
    double current = 0;

    // Reihenfolge von unten nach oben (wie in Excel)
    final segmente = preise.segmente;

    for (final segment in segmente) {
      final fromY = current;
      final toY = current + segment.wert;

      // Farbe und Stil basierend auf Segment-Typ
      final color = segment.farbe.color;

      items.add(BarChartRodStackItem(
        fromY,
        toY,
        color,
        BorderSide(
          color: segment.typ == SegmentTyp.dashed
              ? Colors.white
              : Colors.transparent,
          width: segment.typ == SegmentTyp.dashed ? 2 : 0,
        ),
      ));

      current = toY;
    }

    return items;
  }

  Widget _buildLegende() {
    // Sammle alle einzigartigen Segmente
    final alleSegmente = <ChartFarbe, ChartSegment>{};

    for (final ergebnis in ergebnisse) {
      for (final segment in ergebnis.preisbestandteile.segmente) {
        alleSegmente[segment.farbe] = segment;
      }
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: alleSegmente.values.map((segment) {
        return _buildLegendeItem(
          farbe: segment.farbe.color,
          label: segment.farbe.bezeichnung,
          isDashed: segment.typ == SegmentTyp.dashed,
        );
      }).toList(),
    );
  }

  Widget _buildLegendeItem({
    required Color farbe,
    required String label,
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: farbe,
            border: isDashed ? Border.all(color: Colors.white, width: 2) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: SuewagTextStyles.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}