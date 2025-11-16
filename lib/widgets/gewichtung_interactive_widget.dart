// lib/widgets/gewichtung_interactive_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/arbeitspreis_alt_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';

/// Interaktive Gewichtungs-Visualisierung
///
/// Zeigt wie Monatsindizes → Gewichtete Summe werden
/// Mit Schiebereglern für fehlende Monate
class GewichtungInteractiveWidget extends StatefulWidget {
  final ArbeitspreisAlt jahresPreis;

  const GewichtungInteractiveWidget({
    Key? key,
    required this.jahresPreis,
  }) : super(key: key);

  @override
  State<GewichtungInteractiveWidget> createState() => _GewichtungInteractiveWidgetState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GewichtungInteractiveWidget(jahr: ${jahresPreis.jahr})';
  }
}

class _GewichtungInteractiveWidgetState extends State<GewichtungInteractiveWidget> {
  // Manuelle Werte für fehlende Monate
  final Map<String, double> _manuelleWerte = {};

  @override
  void initState() {
    super.initState();
    _initializeManuelleWerte();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateWert(String key, double value) {
    if (mounted) {
      setState(() {
        _manuelleWerte[key] = value.toDouble();
      });
    }
  }

  void _initializeManuelleWerte() {
    // Initialisiere fehlende Monate UND fehlende Einzelwerte mit Vormonatswert
    for (int monat = 1; monat <= 12; monat++) {
      final monatsDaten = _findMonatsDaten(monat);

      // Fall 1: Monat fehlt komplett
      if (monatsDaten == null) {
        final letzterWert = _findeLetztenBekanntenWertMitManuellen(monat);
        _manuelleWerte['G-$monat'] = letzterWert['G']!;
        _manuelleWerte['GI-$monat'] = letzterWert['GI']!;
        _manuelleWerte['Z-$monat'] = letzterWert['Z']!;
        _manuelleWerte['KCO2-$monat'] = letzterWert['KCO2']!; // 🆕
      }
      // Fall 2: Monat existiert, aber einzelne Werte fehlen
      else {
        if (monatsDaten.gWert == null) {
          final letzterWert = _findeLetztenBekanntenWertMitManuellen(monat);
          _manuelleWerte['G-$monat'] = letzterWert['G']!;
        }
        if (monatsDaten.giWert == null) {
          final letzterWert = _findeLetztenBekanntenWertMitManuellen(monat);
          _manuelleWerte['GI-$monat'] = letzterWert['GI']!;
        }
        if (monatsDaten.zWert == null) {
          final letzterWert = _findeLetztenBekanntenWertMitManuellen(monat);
          _manuelleWerte['Z-$monat'] = letzterWert['Z']!;
        }
        if (monatsDaten.kco2Wert == null) { // 🆕
          final letzterWert = _findeLetztenBekanntenWertMitManuellen(monat);
          _manuelleWerte['KCO2-$monat'] = letzterWert['KCO2']!;
        }
      }
    }
  }

  Map<String, double> _findeLetztenBekanntenWertMitManuellen(int monat) {
    // Suche rückwärts nach letztem bekannten Monat
    for (int m = monat - 1; m >= 1; m--) {
      // 1. Prüfe ob bereits manuelle Werte existieren
      final hasManualG = _manuelleWerte.containsKey('G-$m');
      final hasManualGI = _manuelleWerte.containsKey('GI-$m');
      final hasManualZ = _manuelleWerte.containsKey('Z-$m');
      final hasManualKCO2 = _manuelleWerte.containsKey('KCO2-$m'); // 🆕

      if (hasManualG || hasManualGI || hasManualZ || hasManualKCO2) {
        return {
          'G': _manuelleWerte['G-$m'] ?? _findOfficialValue(m, 'G'),
          'GI': _manuelleWerte['GI-$m'] ?? _findOfficialValue(m, 'GI'),
          'Z': _manuelleWerte['Z-$m'] ?? _findOfficialValue(m, 'Z'),
          'KCO2': _manuelleWerte['KCO2-$m'] ?? _findOfficialValue(m, 'KCO2'), // 🆕
        };
      }

      // 2. Prüfe offizielle Daten
      try {
        final monatsDaten = widget.jahresPreis.monate.firstWhere(
              (md) => md.monat.month == m,
        );

        if (monatsDaten.gWert != null || monatsDaten.giWert != null ||
            monatsDaten.zWert != null || monatsDaten.kco2Wert != null) {
          return {
            'G': monatsDaten.gWert ?? 100.0,
            'GI': monatsDaten.giWert ?? 100.0,
            'Z': monatsDaten.zWert ?? 100.0,
            'KCO2': monatsDaten.kco2Wert ?? 70.0, // 🆕
          };
        }
      } catch (e) {
        continue;
      }
    }

    // Falls nichts gefunden: Nehme ersten bekannten Monat
    if (widget.jahresPreis.monate.isNotEmpty) {
      final first = widget.jahresPreis.monate.first;
      return {
        'G': first.gWert ?? 100.0,
        'GI': first.giWert ?? 100.0,
        'Z': first.zWert ?? 100.0,
        'KCO2': first.kco2Wert ?? 70.0, // 🆕
      };
    }

    // Absoluter Fallback
    return {'G': 100.0, 'GI': 100.0, 'Z': 100.0, 'KCO2': 70.0}; // 🆕
  }

  double _findOfficialValue(int monat, String typ) {
    try {
      final monatsDaten = widget.jahresPreis.monate.firstWhere(
            (md) => md.monat.month == monat,
      );
      switch (typ) {
        case 'G':
          return monatsDaten.gWert ?? 100.0;
        case 'GI':
          return monatsDaten.giWert ?? 100.0;
        case 'Z':
          return monatsDaten.zWert ?? 100.0;
        case 'KCO2': // 🆕
          return monatsDaten.kco2Wert ?? 70.0;
        default:
          return 100.0;
      }
    } catch (e) {
      return typ == 'KCO2' ? 70.0 : 100.0; // 🆕
    }
  }


  Map<String, double>? _findeLetztenBekanntenWert(int monat) {
    // Suche rückwärts nach letztem bekannten Monat
    for (int m = monat - 1; m >= 1; m--) {
      try {
        final monatsDaten = widget.jahresPreis.monate.firstWhere(
              (md) => md.monat.month == m,
        );
        return {
          'G': monatsDaten.gWert ?? 100.0,
          'GI': monatsDaten.giWert ?? 100.0,
          'Z': monatsDaten.zWert ?? 100.0,
        };
      } catch (e) {
        continue;
      }
    }
    // Falls nichts gefunden: Nehme ersten bekannten Monat
    if (widget.jahresPreis.monate.isNotEmpty) {
      final first = widget.jahresPreis.monate.first;
      return {
        'G': first.gWert ?? 100.0,
        'GI': first.giWert ?? 100.0,
        'Z': first.zWert ?? 100.0,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SuewagColors.divider, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildErklaeung(),
          const SizedBox(height: 24),
          _buildMonatstabelle(),
          const SizedBox(height: 24),
          _buildSummen(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SuewagColors.indiablau.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calculate,
            color: SuewagColors.indiablau,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interaktive Gewichtungsberechnung',
                style: SuewagTextStyles.headline3,
              ),
              const SizedBox(height: 4),
              Text(
                'Jahr ${widget.jahresPreis.jahr} - Wie werden die Monatsindizes gewichtet?',
                style: SuewagTextStyles.bodySmall.copyWith(
                  color: SuewagColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErklaeung() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.indiablau.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: SuewagColors.indiablau, size: 20),
              const SizedBox(width: 8),
              Text(
                'So funktioniert die Gewichtung:',
                style: SuewagTextStyles.headline4.copyWith(
                  color: SuewagColors.indiablau,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormelSchritt('1', 'Monatsindex × Promille-Gewicht', 'z.B. 76,1 × 170 = 12.937'),
          const SizedBox(height: 8),
          _buildFormelSchritt('2', 'Summe aller 12 Monate', 'z.B. 12.937 + 9.930 + ... = 86.200'),
          const SizedBox(height: 8),
          _buildFormelSchritt('3', '÷ 1000, dann auf 1 NK runden', 'z.B. 86.200 ÷ 1000 = 86,2'),
          const SizedBox(height: 8),
          _buildFormelSchritt('4', 'Mit Anteil multiplizieren', 'z.B. 0,40 × (86,2 ÷ 33,0)'),
          const SizedBox(height: 8),
          _buildFormelSchritt('5', 'Dann auf 4 NK runden', 'z.B. = 1,0448'),
        ],
      ),
    );
  }

  Widget _buildFormelSchritt(String nummer, String titel, String beispiel) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: SuewagColors.indiablau,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nummer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titel,
                  style: SuewagTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  beispiel,
                  style: SuewagTextStyles.bodySmall.copyWith(
                    color: SuewagColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonatstabelle() {
    // Prüfe ob es fehlende Monate gibt
    final hatFehlendeMonate = widget.jahresPreis.monate.length < 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monatliche Berechnung',
          style: SuewagTextStyles.headline4,
        ),
        const SizedBox(height: 16),

        // ⚠️ WARNUNG bei fehlenden Monaten
        if (hatFehlendeMonate) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ACHTUNG: Nicht alle Daten verfügbar',
                        style: SuewagTextStyles.headline4.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fehlende Monate wurden mit dem letzten bekannten Wert vorausgefüllt. '
                            'Diese Werte sind NICHT offiziell veröffentlicht und dienen nur zur Schätzung. '
                            'Sie können die Werte mit den Schiebereglern anpassen (±50 Indexpunkte).',
                        style: SuewagTextStyles.bodySmall.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Responsive: Desktop = Tabelle, Mobile = Cards
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1000) {
              return _buildMonatsgridDesktop();
            } else {
              return _buildMonatslisteMobile();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonatsgridDesktop() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(3),
        4: FlexColumnWidth(3), // 🆕 CO₂
        5: FlexColumnWidth(4), // Gewichtung
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: SuewagColors.divider),
      ),
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: SuewagColors.quartzgrau10),
          children: [
            _buildTableHeader('Monat'),
            _buildTableHeader('G (Börse)'),
            _buildTableHeader('GI (Gewerbe)'),
            _buildTableHeader('Z (Wärme)'),
            _buildTableHeader('CO₂ (€/t)'), // 🆕
            _buildTableHeader('Gewichtung'),
          ],
        ),
        // Daten
        ...List.generate(12, (index) {
          final monat = index + 1;
          final monatsDaten = _findMonatsDaten(monat);
          return _buildMonatsRow(monat, monatsDaten);
        }),
      ],
    );
  }

  Widget _buildMonatslisteMobile() {
    return Column(
      children: List.generate(12, (index) {
        final monat = index + 1;
        final monatsDaten = _findMonatsDaten(monat);
        return _buildMonatsCardMobile(monat, monatsDaten);
      }),
    );
  }

  MonatsberechnungAlt? _findMonatsDaten(int monat) {
    try {
      return widget.jahresPreis.monate.firstWhere(
            (m) => m.monat.month == monat,
      );
    } catch (e) {
      return null;
    }
  }

  TableRow _buildMonatsRow(int monat, MonatsberechnungAlt? daten) {
    final promille = ArbeitspreisAltKonstanten.getPromille(monat);

    // Prüfe ob Monat komplett fehlt
    final monatVorhanden = daten != null;

    return TableRow(
      decoration: BoxDecoration(
        color: (monatVorhanden && daten.istVollstaendig)
            ? null
            : Colors.orange.withOpacity(0.05),
      ),
      children: [
        _buildTableCell(
          DateFormat('MMM', 'de_DE').format(DateTime(widget.jahresPreis.jahr, monat)),
          bold: true,
        ),
        _buildIndexCell('G', monat, daten?.gWert, monatVorhanden),
        _buildIndexCell('GI', monat, daten?.giWert, monatVorhanden),
        _buildIndexCell('Z', monat, daten?.zWert, monatVorhanden),
        _buildCO2Cell(monat, daten?.kco2Wert), // 🆕
        _buildGewichtungCell(daten, promille),
      ],
    );
  }
  Widget _buildCO2Cell(int monat, double? wert) {
    if (wert != null) {
      // Offizieller CO₂-Wert
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${_formatGermanNumber(wert, 2)} €/t',
          style: SuewagTextStyles.bodySmall.copyWith(
            color: SuewagColors.verkehrsorange,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      // Geschätzter Wert
      final key = 'KCO2-$monat';
      final currentValue = _manuelleWerte[key] ?? 70.0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${_formatGermanNumber(currentValue, 2)} €/t',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    final newValue = (currentValue - 1).clamp(0, double.infinity);
                    _updateWert(key, newValue.toDouble());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    final newValue = (currentValue + 1).clamp(0, currentValue + 20);
                    _updateWert(key, newValue.toDouble());
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  Widget _buildMonatsCardMobile(int monat, MonatsberechnungAlt? daten) {
    final promille = ArbeitspreisAltKonstanten.getPromille(monat);
    final hatDaten = daten != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hatDaten ? Colors.white : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hatDaten ? SuewagColors.divider : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM yyyy', 'de_DE').format(DateTime(widget.jahresPreis.jahr, monat)),
                style: SuewagTextStyles.headline4,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPromilleColor(promille),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(promille / 10).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIndexRowMobile('G (Börse)', monat, daten?.gWert),
          const SizedBox(height: 8),
          _buildIndexRowMobile('GI (Gewerbe)', monat, daten?.giWert),
          const SizedBox(height: 8),
          _buildIndexRowMobile('Z (Wärme)', monat, daten?.zWert),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildCO2RowMobile(monat, daten?.kco2Wert), // 🆕
          if (daten != null && !daten.istVollstaendig) ...[
            const SizedBox(height: 12),
            Text(
              '⚠️ Keine offiziellen Daten - Schätzung anhand Vormonat',
              style: SuewagTextStyles.caption.copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildCO2RowMobile(int monat, double? wert) {
    if (wert != null) {
      // Offizieller Wert
      return Row(
        children: [
          Icon(Icons.co2, size: 16, color: SuewagColors.verkehrsorange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'CO₂-Preis',
              style: SuewagTextStyles.bodySmall,
            ),
          ),
          Text(
            '${_formatGermanNumber(wert, 2)} €/t',
            style: SuewagTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: SuewagColors.verkehrsorange,
            ),
          ),
        ],
      );
    } else {
      // Geschätzter Wert
      final key = 'KCO2-$monat';
      final currentValue = _manuelleWerte[key] ?? 70.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.co2, size: 16, color: SuewagColors.verkehrsorange),
              const SizedBox(width: 8),
              Expanded(
                child: Text('CO₂-Preis', style: SuewagTextStyles.bodySmall),
              ),
              Icon(Icons.warning_amber, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '${_formatGermanNumber(currentValue, 2)} €/t',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.remove, size: 16),
                label: const Text('-1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final newValue = (currentValue - 1).clamp(0.0, double.infinity);
                  _updateWert(key, newValue);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final newValue = (currentValue + 1).clamp(0.0, currentValue + 20);
                  _updateWert(key, newValue);
                },
              ),
            ],
          ),
        ],
      );
    }
  }
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: SuewagTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool bold = false}) {
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

  Widget _buildIndexCell(String typ, int monat, double? wert, bool hatDaten) {
    // Zeige offiziellen Wert ODER Schätzwert mit Buttons
    if (wert != null) {
      return _buildTableCell(_formatGermanNumber(wert, 1));
    } else {
      // ⚠️ Wert fehlt - zeige Schätzung mit +/- Buttons
      final key = '$typ-$monat';
      final currentValue = _manuelleWerte[key] ?? 100.0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  _formatGermanNumber(currentValue, 1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    final newValue = (currentValue - 5).clamp(0, double.infinity);
                    _updateWert(key, newValue.toDouble());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () {
                    final newValue = (currentValue + 5).clamp(0, currentValue + 50);
                    _updateWert(key, newValue.toDouble());
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  Widget _buildIndexRowMobile(String label, int monat, double? wert) {
    if (wert != null) {
      // Offizieller Wert
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: SuewagTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              _formatGermanNumber(wert, 1),
              style: SuewagTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    } else {
      // Geschätzter Wert
      final typ = label.split(' ').first;
      final key = '$typ-$monat';
      final currentValue = _manuelleWerte[key] ?? 100.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: SuewagTextStyles.bodySmall)),
              Icon(Icons.warning_amber, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                _formatGermanNumber(currentValue, 1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.remove, size: 16),
                label: const Text('-5'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final newValue = (currentValue - 5).clamp(0.0, double.infinity);
                  _updateWert(key, newValue.toDouble());
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+5'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final newValue = (currentValue + 5).clamp(0.0, currentValue + 50);
                  _updateWert(key, newValue.toDouble());
                },
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildGewichtungCell(MonatsberechnungAlt? daten, double promille) {
    // Prüfe ob ALLE Werte vorhanden sind
    final istVollstaendig = daten?.istVollstaendig ?? false;

    // Hole die Werte (offiziell oder geschätzt)
    final monat = daten?.monat.month ?? 0;
    final gWert = daten?.gWert ?? _manuelleWerte['G-$monat'] ?? 100.0;
    final giWert = daten?.giWert ?? _manuelleWerte['GI-$monat'] ?? 100.0;
    final zWert = daten?.zWert ?? _manuelleWerte['Z-$monat'] ?? 100.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${(promille / 10).toStringAsFixed(1)}% (${promille.toInt()}‰)',
                style: SuewagTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!istVollstaendig) ...[
                const SizedBox(width: 4),
                Icon(Icons.warning_amber, size: 12, color: Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'G: ${_formatGermanNumber(gWert, 1)} × ${promille.toInt()} = ${_formatGermanNumber(gWert * promille, 0)}',
            style: SuewagTextStyles.caption.copyWith(
              fontSize: 10,
              fontFamily: 'monospace',
              color: istVollstaendig ? null : Colors.orange,
            ),
          ),
          Text(
            'GI: ${_formatGermanNumber(giWert, 1)} × ${promille.toInt()} = ${_formatGermanNumber(giWert * promille, 0)}',
            style: SuewagTextStyles.caption.copyWith(
              fontSize: 10,
              fontFamily: 'monospace',
              color: istVollstaendig ? null : Colors.orange,
            ),
          ),
          Text(
            'Z: ${_formatGermanNumber(zWert, 1)} × ${promille.toInt()} = ${_formatGermanNumber(zWert * promille, 0)}',
            style: SuewagTextStyles.caption.copyWith(
              fontSize: 10,
              fontFamily: 'monospace',
              color: istVollstaendig ? null : Colors.orange,
            ),
          ),
          if (!istVollstaendig) ...[
            const SizedBox(height: 4),
            Text(
              'Geschätzt',
              style: SuewagTextStyles.caption.copyWith(
                fontSize: 9,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildSummen() {
    // Berechne Summen MIT geschätzten Werten!
    double gSummeRoh = 0;
    double giSummeRoh = 0;
    double zSummeRoh = 0;

    // 🆕 CO₂-Werte sammeln für Jahresmittelwert
    final List<double> kco2Werte = [];

    // ✅ Zähle vollständige vs. geschätzte Monate
    int vollstaendigeMonate = 0;
    int geschaetzteMonate = 0;

    for (int monat = 1; monat <= 12; monat++) {
      final monatsDaten = _findMonatsDaten(monat);
      final promille = ArbeitspreisAltKonstanten.getPromille(monat);

      // Prüfe ob Monat vollständig ist
      if (monatsDaten?.istVollstaendig ?? false) {
        vollstaendigeMonate++;
      } else {
        geschaetzteMonate++;
      }

      // Verwende offizielle Werte ODER manuelle Schätzungen
      final gWert = monatsDaten?.gWert ?? _manuelleWerte['G-$monat'] ?? 100.0;
      final giWert = monatsDaten?.giWert ?? _manuelleWerte['GI-$monat'] ?? 100.0;
      final zWert = monatsDaten?.zWert ?? _manuelleWerte['Z-$monat'] ?? 100.0;
      final kco2Wert = monatsDaten?.kco2Wert ?? _manuelleWerte['KCO2-$monat'] ?? 70.0; // 🆕

      gSummeRoh += gWert * promille;
      giSummeRoh += giWert * promille;
      zSummeRoh += zWert * promille;
      kco2Werte.add(kco2Wert); // 🆕 Sammle für Mittelwert
    }

    // Berechne Arbeitspreis
    final gSumme = ArbeitspreisAltKonstanten.runde1(gSummeRoh / 1000);
    final giSumme = ArbeitspreisAltKonstanten.runde1(giSummeRoh / 1000);
    final zSumme = ArbeitspreisAltKonstanten.runde1(zSummeRoh / 1000);

    final gFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtG * (gSumme / ArbeitspreisAltKonstanten.g0)
    );
    final giFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtGI * (giSumme / ArbeitspreisAltKonstanten.gi0)
    );
    final zFaktor = ArbeitspreisAltKonstanten.runde4(
        ArbeitspreisAltKonstanten.gewichtZ * (zSumme / ArbeitspreisAltKonstanten.z0)
    );

    final aenderungsfaktor = gFaktor + giFaktor + zFaktor;
    final arbeitspreisOhneEmission = ArbeitspreisAltKonstanten.ap0 * aenderungsfaktor;

    // 🆕 Berechne CO₂-Preis
    final kco2Mittelwert = kco2Werte.fold<double>(0, (sum, w) => sum + w) / kco2Werte.length;
    final jahr = widget.jahresPreis.jahr;
    final zAbschmelzung = ArbeitspreisAltKonstanten.getAbschmelzungsfaktor(jahr);
    final emissionspreis = ArbeitspreisAltKonstanten.berechneEmissionspreis(
      jahr: jahr,
      kco2Mittelwert: kco2Mittelwert,
    );

    final arbeitspreisGesamt = arbeitspreisOhneEmission + emissionspreis;

    // ✅ Entscheide Farbe basierend auf Datenlage
    final hatGeschaetzteMonate = geschaetzteMonate > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SuewagColors.fasergruen.withOpacity(0.1),
            SuewagColors.indiablau.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.fasergruen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, color: SuewagColors.fasergruen, size: 24),
              const SizedBox(width: 12),
              Text('Ergebnis', style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Zeige Warnung bei geschätzten Monaten
          if (hatGeschaetzteMonate) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 24, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ SCHÄTZUNG: $geschaetzteMonate ${geschaetzteMonate == 1 ? 'Monat fehlt' : 'Monate fehlen'}',
                          style: SuewagTextStyles.headline4.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$vollstaendigeMonate von 12 Monaten mit offiziellen Daten. '
                              'Das Ergebnis basiert auf Schätzungen und ist NICHT offiziell!',
                          style: SuewagTextStyles.bodySmall.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.fasergruen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SuewagColors.fasergruen),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: SuewagColors.fasergruen),
                  const SizedBox(width: 8),
                  Text(
                    '✓ Alle 12 Monate mit offiziellen Daten',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.fasergruen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          _buildSummenRow('G (Börse)', gSummeRoh, gSumme, gFaktor, ArbeitspreisAltKonstanten.g0),
          const SizedBox(height: 12),
          _buildSummenRow('GI (Gewerbe)', giSummeRoh, giSumme, giFaktor, ArbeitspreisAltKonstanten.gi0),
          const SizedBox(height: 12),
          _buildSummenRow('Z (Wärme)', zSummeRoh, zSumme, zFaktor, ArbeitspreisAltKonstanten.z0),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Änderungsfaktor + Arbeitspreis
          _buildAenderungsfaktorMitWerten(
            gFaktor: gFaktor,
            giFaktor: giFaktor,
            zFaktor: zFaktor,
            aenderungsfaktor: aenderungsfaktor,
            arbeitspreisOhneEmission: arbeitspreisOhneEmission,
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // 🆕 CO₂-Berechnung
          _buildCO2Berechnung(
            kco2Mittelwert: kco2Mittelwert,
            zAbschmelzung: zAbschmelzung,
            emissionspreis: emissionspreis,
            jahr: jahr,
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // Gesamt
          _buildGesamtpreis(
            arbeitspreisOhneEmission: arbeitspreisOhneEmission,
            emissionspreis: emissionspreis,
            arbeitspreisGesamt: arbeitspreisGesamt,
          ),
        ],
      ),
    );
  }
  // 🆕 CO₂-Berechnung anzeigen
  Widget _buildCO2Berechnung({
    required double kco2Mittelwert,
    required double zAbschmelzung,
    required double emissionspreis,
    required int jahr,
  })
  {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.verkehrsorange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.verkehrsorange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.co2, color: SuewagColors.verkehrsorange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Emissionspreis (CO₂)',
                style: SuewagTextStyles.headline4.copyWith(
                  color: SuewagColors.verkehrsorange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Schritt 1: Jahresmittelwert KCO₂
          Text(
            'Schritt 1: Jahresmittelwert ECarbiX',
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KCO₂ Ø = ${_formatGermanNumber(kco2Mittelwert, 2)} €/Tonne',
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
              color: SuewagColors.verkehrsorange,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Schritt 2: Parameter
          Text(
            'Schritt 2: Parameter einsetzen',
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFormelZeile('Em (Emissionsfaktor)', '170,28 g CO₂/kWh'),
          _buildFormelZeile('Z (Abschmelzung $jahr)', _formatGermanNumber(zAbschmelzung, 4)),
          _buildFormelZeile('F (Umrechnung)', '0,0001'),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Schritt 3: Berechnung
          Text(
            'Schritt 3: EP = (1 - Z) × Em × KCO₂ × F',
            style: SuewagTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EP = (1 - ${_formatGermanNumber(zAbschmelzung, 4)}) × 170,28 × ${_formatGermanNumber(kco2Mittelwert, 2)} × 0,0001',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EP = ${_formatGermanNumber(1 - zAbschmelzung, 4)} × 170,28 × ${_formatGermanNumber(kco2Mittelwert, 2)} × 0,0001',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EP = ${_formatGermanNumber(emissionspreis, 4)} ct/kWh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SuewagColors.verkehrsorange,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAenderungsfaktorMitWerten({
    required double gFaktor,
    required double giFaktor,
    required double zFaktor,
    required double aenderungsfaktor,
    required double arbeitspreisOhneEmission,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Änderungsfaktor',
            style: SuewagTextStyles.headline4,
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatGermanNumber(gFaktor, 4)} + '
                '${_formatGermanNumber(giFaktor, 4)} + '
                '${_formatGermanNumber(zFaktor, 4)}',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '= ${_formatGermanNumber(aenderungsfaktor, 4)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Arbeitspreis (ohne CO₂)',
            style: SuewagTextStyles.headline4,
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatGermanNumber(ArbeitspreisAltKonstanten.ap0, 4)} ct/kWh × '
                '${_formatGermanNumber(aenderungsfaktor, 4)}',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '= ${_formatGermanNumber(arbeitspreisOhneEmission, 4)} ct/kWh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SuewagColors.indiablau,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFormelZeile(String label, String wert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: SuewagTextStyles.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              wert,
              style: SuewagTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSummenRow(String label, double summeRoh, double summe, double faktor, double basis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Summe gewichtet: ${_formatGermanNumber(summeRoh, 3)}',
            style: SuewagTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
          ),
          Text(
            '÷ 1000 = ${_formatGermanNumber(summe, 1)} (auf 1 NK gerundet)',
            style: SuewagTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
          ),
          Text(
            '0,${label.contains('Börse') ? '40' : label.contains('Gewerbe') ? '35' : '25'} × (${_formatGermanNumber(summe, 1)} ÷ ${_formatGermanNumber(basis, 1)}) = ${_formatGermanNumber(faktor, 4)} (auf 4 NK gerundet)',
            style: SuewagTextStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: SuewagColors.fasergruen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGesamtpreis({
    required double arbeitspreisOhneEmission,
    required double emissionspreis,
    required double arbeitspreisGesamt,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SuewagColors.fasergruen,
            SuewagColors.fasergruen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SuewagColors.fasergruen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'ARBEITSPREIS GESAMT',
                style: SuewagTextStyles.headline3.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arbeitspreis:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_formatGermanNumber(arbeitspreisOhneEmission, 4)} ct/kWh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emissionspreis:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '+ ${_formatGermanNumber(emissionspreis, 4)} ct/kWh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white54),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GESAMT:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatGermanNumber(arbeitspreisGesamt, 4)} ct/kWh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPromilleColor(double promille) {
    if (promille >= 150) return SuewagColors.verkehrsorange.withOpacity(0.2);
    if (promille >= 100) return SuewagColors.indiablau.withOpacity(0.2);
    if (promille >= 50) return SuewagColors.fasergruen.withOpacity(0.2);
    return SuewagColors.quartzgrau10;
  }

  String _formatGermanNumber(double value, int decimals) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'de_DE');
    return formatter.format(value);
  }
}