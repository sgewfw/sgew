// lib/widgets/monatstabelle_widget.dart

import 'package:flutter/material.dart';
import '../models/index_data.dart';
import '../models/arbeitspreis_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';

/// Monatstabelle mit Rohdaten der Indizes
/// Hebt die 3 Berechnungsmonate hervor
class MonatstabelleWidget extends StatelessWidget {
  final List<IndexData> kData; // Kostenelement
  final List<IndexData> mData; // Marktelement
  final String kLabel; // z.B. "K Gas"
  final String mLabel; // z.B. "M Gas"
  final Color kColor;
  final Color mColor;
  final QuartalsBerechnungsdaten? selectedBerechnungsdaten;

  const MonatstabelleWidget({
    Key? key,
    required this.kData,
    required this.mData,
    required this.kLabel,
    required this.mLabel,
    required this.kColor,
    required this.mColor,
    this.selectedBerechnungsdaten,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dates = _getCommonDates();

    if (dates.isEmpty) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Scrollbare Tabelle
          Expanded(
            child: ListView.builder(
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isHighlighted = selectedBerechnungsdaten?.istBerechnungsmonat(date) ?? false;

                return _buildRow(
                  date: date,
                  index: index,
                  isHighlighted: isHighlighted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuewagColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Monat
          Expanded(
            flex: 2,
            child: Text(
              'Monat',
              style: SuewagTextStyles.tableHeader.copyWith(
                color: SuewagColors.primary,
              ),
            ),
          ),

          // K Index
          Expanded(
            flex: 2,
            child: _buildHeaderCell(kLabel, kColor, 'K'),
          ),

          // M Index
          Expanded(
            flex: 2,
            child: _buildHeaderCell(mLabel, mColor, 'M'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, Color color, String badge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: SuewagTextStyles.tableHeader.copyWith(color: color),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: badge == 'K'
                ? SuewagColors.indiablau.withOpacity(0.2)
                : SuewagColors.leuchtendgruen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: badge == 'K'
                  ? SuewagColors.indiablau
                  : SuewagColors.leuchtendgruen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required DateTime date,
    required int index,
    required bool isHighlighted,
  }) {
    final kWert = _findValue(kData, date);
    final mWert = _findValue(mData, date);

    final backgroundColor = isHighlighted
        ? SuewagColors.primary.withOpacity(0.15)
        : index.isEven
        ? SuewagColors.quartzgrau10
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: SuewagColors.divider, width: 0.5),
          left: isHighlighted
              ? BorderSide(color: SuewagColors.primary, width: 4)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Datum
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    _formatDate(date),
                    style: SuewagTextStyles.tableCell.copyWith(
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isHighlighted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SuewagColors.leuchtendgruen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'n',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // K Wert
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: kWert,
              color: kColor,
              isHighlighted: isHighlighted,
            ),
          ),

          // M Wert
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: mWert,
              color: mColor,
              isHighlighted: isHighlighted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell({
    required double? value,
    required Color color,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.15) : Colors.transparent,
        border: isHighlighted
            ? Border.all(color: color, width: 2)
            : null,
        borderRadius: isHighlighted ? BorderRadius.circular(6) : null,
      ),
      child: Text(
        value?.toStringAsFixed(1) ?? '-',
        style: SuewagTextStyles.tableNumber.copyWith(
          color: isHighlighted ? color : SuewagColors.textPrimary,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  List<DateTime> _getCommonDates() {
    final dates = <DateTime>{};
    dates.addAll(kData.map((d) => d.date));
    dates.addAll(mData.map((d) => d.date));
    return dates.toList()..sort((a, b) => b.compareTo(a));
  }

  double? _findValue(List<IndexData> data, DateTime date) {
    try {
      return data.firstWhere((d) =>
      d.date.year == date.year && d.date.month == date.month
      ).value;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Quartalstabelle mit berechneten Mittelwerten
/// Hebt das ausgewählte Quartal hervor
class QuartalstabelleWidget extends StatelessWidget {
  final List<QuartalsUebersicht> quartale;
  final String kLabel;
  final String mLabel;
  final Color kColor;
  final Color mColor;
  final DateTime? selectedQuartal;

  const QuartalstabelleWidget({
    Key? key,
    required this.quartale,
    required this.kLabel,
    required this.mLabel,
    required this.kColor,
    required this.mColor,
    this.selectedQuartal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quartale.isEmpty) {
      return const Center(child: Text('Keine Quartale berechnet'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Quartale
          Expanded(
            child: ListView.builder(
              itemCount: quartale.length,
              itemBuilder: (context, index) {
                final q = quartale[index];
                final isHighlighted = selectedQuartal != null &&
                    q.quartal.year == selectedQuartal!.year &&
                    q.quartalNummer == ArbeitspreisKonstanten.getQuartalNummer(selectedQuartal!);

                return _buildRow(q, index, isHighlighted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Quartal
          Expanded(
            flex: 2,
            child: Text(
              'Quartal',
              style: SuewagTextStyles.tableHeader.copyWith(
                color: SuewagColors.indiablau,
              ),
            ),
          ),

          // K Ø
          Expanded(
            flex: 2,
            child: _buildHeaderCell('$kLabel Ø', kColor),
          ),

          // M Ø
          Expanded(
            flex: 2,
            child: _buildHeaderCell('$mLabel Ø', mColor),
          ),

          // Preis
          Expanded(
            flex: 2,
            child: Text(
              'Preis',
              style: SuewagTextStyles.tableHeader.copyWith(
                color: SuewagColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, Color color) {
    return Text(
      label,
      style: SuewagTextStyles.tableHeader.copyWith(color: color),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildRow(QuartalsUebersicht q, int index, bool isHighlighted) {
    final backgroundColor = isHighlighted
        ? SuewagColors.indiablau.withOpacity(0.15)
        : index.isEven
        ? SuewagColors.quartzgrau10
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: SuewagColors.divider, width: 0.5),
          left: isHighlighted
              ? BorderSide(color: SuewagColors.indiablau, width: 4)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Quartal
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isHighlighted
                        ? SuewagColors.indiablau
                        : SuewagColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    q.bezeichnung,
                    style: SuewagTextStyles.tableCell.copyWith(
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                      color: isHighlighted
                          ? SuewagColors.indiablau
                          : SuewagColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // K Mittelwert
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: q.kMittelwert,
              color: kColor,
              isHighlighted: isHighlighted,
            ),
          ),

          // M Mittelwert
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: q.mMittelwert,
              color: mColor,
              isHighlighted: isHighlighted,
            ),
          ),

          // Preis
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${q.preis.toStringAsFixed(2)} ct',
                style: SuewagTextStyles.tableNumber.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted
                      ? SuewagColors.primary
                      : SuewagColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell({
    required double value,
    required Color color,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.15) : Colors.transparent,
        border: isHighlighted
            ? Border.all(color: color, width: 2)
            : null,
        borderRadius: isHighlighted ? BorderRadius.circular(6) : null,
      ),
      child: Text(
        value.toStringAsFixed(1),
        style: SuewagTextStyles.tableNumber.copyWith(
          color: isHighlighted ? color : SuewagColors.textPrimary,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}