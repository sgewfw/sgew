// lib/widgets/formel_erklaerung_widget.dart

import 'package:flutter/material.dart';
import '../models/arbeitspreis_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';

/// Widget für den aktuellen Preis - prominent und auffällig
class AktuellerPreisWidget extends StatelessWidget {
  final String typ; // 'gas' oder 'strom'
  final QuartalsPreis aktuellerPreis;
  final QuartalsPreis? vorherigerPreis;

  const AktuellerPreisWidget({
    Key? key,
    required this.typ,
    required this.aktuellerPreis,
    this.vorherigerPreis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGas = typ == 'gas';
    final color = isGas ? SuewagColors.erdgas : SuewagColors.chartGewerbe;

    // Berechne Änderung zum Vorquartal
    double? aenderung;
    if (vorherigerPreis != null) {
      aenderung = aktuellerPreis.preis - vorherigerPreis!.preis;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titel
          Row(
            children: [
              Icon(Icons.euro, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aktueller Preis',
                style: SuewagTextStyles.headline4.copyWith(
                  fontSize: 14,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isGas ? 'Gas' : 'Strom',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Großer Preis
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                aktuellerPreis.preis.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'ct/kWh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SuewagColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quartal und Änderung
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: SuewagColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                aktuellerPreis.bezeichnung,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SuewagColors.textSecondary,
                ),
              ),
              if (aenderung != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aenderung > 0
                        ? Colors.red.withOpacity(0.1)
                        : aenderung < 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aenderung > 0
                            ? Icons.arrow_upward
                            : aenderung < 0
                            ? Icons.arrow_downward
                            : Icons.remove,
                        size: 12,
                        color: aenderung > 0
                            ? Colors.red
                            : aenderung < 0
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${aenderung > 0 ? '+' : ''}${aenderung.toStringAsFixed(2)} ct/kWh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: aenderung > 0
                              ? Colors.red
                              : aenderung < 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget für die Preisformel  - kompakt mit Info-Dialog
class PreisformelWidget extends StatelessWidget {
  final String typ; // 'gas' oder 'strom'

  const PreisformelWidget({
    Key? key,
    required this.typ,
  }) : super(key: key);

  void _showFormelInfo(BuildContext context) {
    final isGas = typ == 'gas';
    final startpreis = isGas
        ? ArbeitspreisKonstanten.ap0Gas
        : ArbeitspreisKonstanten.ap0Strom;
    final kBasis = isGas
        ? ArbeitspreisKonstanten.kGasBasis
        : ArbeitspreisKonstanten.kStromBasis;
    final mBasis = isGas
        ? ArbeitspreisKonstanten.mGasBasis
        : ArbeitspreisKonstanten.mStromBasis;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calculate, color: SuewagColors.primary, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Preisformel  Details', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Formel:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AP = $startpreis × (0,5 × K_Ø / $kBasis + 0,5 × M_Ø / $mBasis)',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Startpreis (AP₀)', '$startpreis ct/kWh (Basis Q3 2025)'),
              _buildDetailRow('Kostenindex (K)', isGas ? 'Erdgas Gewerbe' : 'Strom Gewerbe'),
              _buildDetailRow('Marktindex (M)', isGas ? 'Wärmepreis' : 'Strom Haushalte'),
              _buildDetailRow('K-Basis', '$kBasis (Referenzwert Q3 2025)'),
              _buildDetailRow('M-Basis', '$mBasis (Referenzwert Q3 2025)'),
              _buildDetailRow('Gewichtung', '50% Kosten + 50% Markt'),
              _buildDetailRow('Berechnungsperiode', 'Mittelwert aus n-4, n-3, n-2 Monaten'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGas = typ == 'gas';
    final color = isGas ? SuewagColors.erdgas : SuewagColors.chartGewerbe;
    final startpreis = isGas
        ? ArbeitspreisKonstanten.ap0Gas
        : ArbeitspreisKonstanten.ap0Strom;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Titel mit Info-Button
          Row(
            children: [
              Icon(Icons.calculate, color: SuewagColors.erdgas, size: 20),
              const SizedBox(width: 8),
              Text('Preisformel', style: SuewagTextStyles.headline4.copyWith(fontSize: 16)),
              const Spacer(),
              if (typ == 'gas')
                _buildBadge('Gas', SuewagColors.erdgas)
              else
                _buildBadge('Strom', SuewagColors.chartGewerbe),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showFormelInfo(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SuewagColors.indiablau.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 18, color: SuewagColors.indiablau),
                ),
              ),
            ],
          ),


          // Kompakte Formel
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      color: SuewagColors.textPrimary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'AP = ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                      TextSpan(
                        text: '$startpreis',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' × ('),
                      TextSpan(
                        text: '0,5 × K_Ø / K₀',
                        style: TextStyle(
                          color: SuewagColors.indiablau,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' + '),
                      TextSpan(
                        text: '0,5 × M_Ø / M₀',
                        style: TextStyle(
                          color: SuewagColors.leuchtendgruen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Widget für das Arbeitspreis-Ergebnis (Schritt 3) - kompakt
class ArbeitspreisErgebnisWidget extends StatelessWidget {
  final String typ;
  final QuartalsBerechnungsdaten berechnungsdaten;

  const ArbeitspreisErgebnisWidget({
    Key? key,
    required this.typ,
    required this.berechnungsdaten,
  }) : super(key: key);

  void _showBerechnungsDetails(BuildContext context) {
    final b = berechnungsdaten;
    final isGas = typ == 'gas';
    final startpreis = isGas
        ? ArbeitspreisKonstanten.ap0Gas
        : ArbeitspreisKonstanten.ap0Strom;
    final kostenFaktor = b.kMittelwert / b.kBasis;
    final marktFaktor = b.mMittelwert / b.mBasis;
    final preis = startpreis * (0.5 * kostenFaktor + 0.5 * marktFaktor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, size: 24, color: SuewagColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Berechnung ${b.quartalBezeichnung}',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Berechnungszeitraum (n-4 bis n-2):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Für das Lieferquartal ${b.quartalBezeichnung} werden die Monate '
                    '${_formatMonth(b.monat1)}, ${_formatMonth(b.monat2)} und '
                    '${_formatMonth(b.monat3)} verwendet (4, 3 und 2 Monate vor Lieferbeginn).',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Detaillierte Berechnung:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalcRow('Startpreis:', '$startpreis ct/kWh'),
                    _buildCalcRow(
                      'Kostenfaktor:',
                      '${b.kMittelwert.toStringAsFixed(2)} ÷ ${b.kBasis} = ${kostenFaktor.toStringAsFixed(4)}',
                    ),
                    _buildCalcRow(
                      'Marktfaktor:',
                      '${b.mMittelwert.toStringAsFixed(2)} ÷ ${b.mBasis} = ${marktFaktor.toStringAsFixed(4)}',
                    ),
                    const Divider(height: 16),
                    _buildCalcRow(
                      'Rechnung:',
                      '$startpreis × (0,5 × ${kostenFaktor.toStringAsFixed(4)} + 0,5 × ${marktFaktor.toStringAsFixed(4)})',
                    ),
                    _buildCalcRow(
                      '',
                      '= $startpreis × ${(0.5 * kostenFaktor + 0.5 * marktFaktor).toStringAsFixed(4)}',
                    ),
                    const Divider(height: 16),
                    _buildCalcRow(
                      'Arbeitspreis:',
                      '${preis.toStringAsFixed(2)} ct/kWh',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: isBold ? null : 'monospace',
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = berechnungsdaten;
    final isGas = typ == 'gas';
    final color = isGas ? SuewagColors.erdgas : SuewagColors.chartGewerbe;
    final startpreis = isGas
        ? ArbeitspreisKonstanten.ap0Gas
        : ArbeitspreisKonstanten.ap0Strom;

    // Berechne finalen Preis
    final kostenFaktor = b.kMittelwert / b.kBasis;
    final marktFaktor = b.mMittelwert / b.mBasis;
    final preis = startpreis * (0.5 * kostenFaktor + 0.5 * marktFaktor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Titel mit Nummer - wie bei Index-Widgets
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Arbeitspreis',
                  style: SuewagTextStyles.headline4.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showBerechnungsDetails(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SuewagColors.indiablau.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 18, color: SuewagColors.indiablau),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),


// Formel mit eingesetzten Werten
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: SuewagColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'AP = ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  TextSpan(
                    text: '$startpreis',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' × ('),
                  TextSpan(
                    text: '0,5 × ${b.kMittelwert.toStringAsFixed(1)} / ${b.kBasis}',
                    style: TextStyle(
                      color: SuewagColors.indiablau,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' + '),
                  TextSpan(
                    text: '0,5 × ${b.mMittelwert.toStringAsFixed(1)} / ${b.mBasis}',
                    style: TextStyle(
                      color: SuewagColors.leuchtendgruen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ')'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),


          // Kompakte Berechnung
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  'AP = ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SuewagColors.textSecondary,
                  ),
                ),
                Text(
                  '${preis.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  'ct/kWh',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildCompactRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
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

/// Widget für Index-Berechnung (Schritt 1 oder 2) - kompakt
class IndexBerechnungWidget extends StatelessWidget {
  final String typ; // 'gas' oder 'strom'
  final QuartalsBerechnungsdaten berechnungsdaten;
  final String indexTyp; // 'k' oder 'm'

  const IndexBerechnungWidget({
    Key? key,
    required this.typ,
    required this.berechnungsdaten,
    required this.indexTyp,
  }) : super(key: key);

  void _showIndexDetails(BuildContext context) {
    final b = berechnungsdaten;
    final isKIndex = indexTyp == 'k';
    final wert1 = isKIndex ? b.kWert1 : b.mWert1;
    final wert2 = isKIndex ? b.kWert2 : b.mWert2;
    final wert3 = isKIndex ? b.kWert3 : b.mWert3;
    final mittelwert = isKIndex ? b.kMittelwert : b.mMittelwert;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.calculate,
              size: 24,
              color: isKIndex ? SuewagColors.indiablau : SuewagColors.leuchtendgruen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isKIndex ? 'Kostenelement Details' : 'Marktelement Details',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arithmetisches Mittel aus 3 Monaten:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(_formatMonth(b.monat1), wert1.toStringAsFixed(2)),
            _buildDetailRow(_formatMonth(b.monat2), wert2.toStringAsFixed(2)),
            _buildDetailRow(_formatMonth(b.monat3), wert3.toStringAsFixed(2)),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '(${wert1.toStringAsFixed(1)} + ${wert2.toStringAsFixed(1)} + ${wert3.toStringAsFixed(1)}) ÷ 3',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '= ${mittelwert.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = berechnungsdaten;
    final isKIndex = indexTyp == 'k';

    final color = isKIndex ? SuewagColors.indiablau : SuewagColors.leuchtendgruen;
    final nummer = isKIndex ? '1' : '2';
    final titel = isKIndex ? 'Kostenelement' : 'Marktelement';

    final wert1 = isKIndex ? b.kWert1 : b.mWert1;
    final wert2 = isKIndex ? b.kWert2 : b.mWert2;
    final wert3 = isKIndex ? b.kWert3 : b.mWert3;
    final mittelwert = isKIndex ? b.kMittelwert : b.mMittelwert;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Titel mit Nummer
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    nummer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titel,
                  style: SuewagTextStyles.headline4.copyWith(
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showIndexDetails(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 16, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Kompakte Monatswerte
          Row(
            children: [
              _buildCompactMonth(_formatMonth(b.monat1), wert1, color),
              const SizedBox(width: 4),
              Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildCompactMonth(_formatMonth(b.monat2), wert2, color),
              const SizedBox(width: 4),
              Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              _buildCompactMonth(_formatMonth(b.monat3), wert3, color),
            ],
          ),
          const SizedBox(height: 12),

          // Ergebnis
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ø Mittelwert:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  mittelwert.toStringAsFixed(2),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMonth(String monat, double wert, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              monat,
              style: SuewagTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              wert.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
              textAlign: TextAlign.center,
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