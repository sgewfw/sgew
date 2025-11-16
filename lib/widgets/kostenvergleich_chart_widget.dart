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
            tooltipPadding: const EdgeInsets.all(12),
            maxContentWidth: 400,
            tooltipMargin: 8, // Abstand zum Balken
            direction: TooltipDirection.auto, // oder .top, .bottom, .left, .right

            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final ergebnis = ergebnisse[groupIndex];

              // Prüfe ob Wärmepumpe-Szenario
              final istWaermepumpe = ergebnis.szenarioId == 'waermepumpe';

              // Für Wärmepumpe: summeOhneFoerderung, sonst summeMitFoerderung
              final gesamtCtKwh = istWaermepumpe
                  ? ergebnis.preisbestandteile.summeOhneFoerderung
                  : ergebnis.preisbestandteile.summeMitFoerderung;

              // Berechne entsprechende Jahreskosten
              final gesamtEuroJahr = (gesamtCtKwh / 100) * ergebnis.waermebedarf;

              return BarTooltipItem(
                '',
                const TextStyle(color: Colors.white),
                children: [
                  // Header
                  TextSpan(
                    text: '${ergebnis.szenarioBezeichnung}\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Bezogen auf ${_formatDeutscheZahl(ergebnis.waermebedarf , 0)} kWh/a\n\n',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // Gesamtkosten
                  TextSpan(
                    text: istWaermepumpe
                        ? 'Gesamtkosten (inkl. Kapitalkosten ohne Förderung)\n'
                        : 'Gesamtkosten (mit Förderung)\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatDeutscheZahl(gesamtCtKwh, 2)} ct/kWh  ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '(${_formatDeutscheZahl(gesamtEuroJahr, 2)} €/a)\n\n',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),

                  // Einzelpositionen Header
                  TextSpan(
                    text: 'Preisbestandteile:\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Einzelpositionen - dynamisch aus Segmenten
                  ..._erstelleSegmentZeilen(ergebnis),
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
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'ct/kWh (netto)',
                  style: SuewagTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              axisNameSize: 50,
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
  String _formatDeutscheZahl(double wert, int nachkommastellen) {
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
  List<TextSpan> _erstelleSegmentZeilen(KostenberechnungErgebnis ergebnis) {
    final spans = <TextSpan>[];

    for (final segment in ergebnis.preisbestandteile.segmente) {
      // Berechne Euro-Kosten für dieses Segment
      final euroKostenJahr = (segment.wert / 100) * ergebnis.waermebedarf;

      // Punkt mit Farbe (als Symbol)
      spans.add(
        TextSpan(
          text: '• ',
          style: TextStyle(
            color: segment.farbe.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      // ALLES IN EINER ZEILE: Bezeichnung: Wert ct/kWh (Wert €/a)
      spans.add(
        TextSpan(
          text: '${segment.farbe.bezeichnung}: ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: '${_formatDeutscheZahl(segment.wert, 2)} ct/kWh ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: '(${_formatDeutscheZahl(euroKostenJahr, 2)} €/a)',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
      );

      // Gestrichelt-Hinweis bei Bedarf
      if (segment.typ == SegmentTyp.dashed) {
        spans.add(
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        );
      }

      spans.add(const TextSpan(text: '\n'));
    }




    return spans;
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