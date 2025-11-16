// lib/widgets/index_table_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/arbeitspreis_data.dart';
import '../models/index_data.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';

/// Interaktive Tabelle mit allen 4 Indizes
/// Hebt relevante Indizes farblich hervor
class IndexTableWidget extends StatelessWidget {
  final List<IndexData> kGasData;
  final List<IndexData> kStromData;
  final List<IndexData> mGasData;
  final List<IndexData> mStromData;
  final DateTime? selectedDate;
  final String highlightTyp; // 'gas', 'strom', oder 'beide'

  const IndexTableWidget({
    Key? key,
    required this.kGasData,
    required this.kStromData,
    required this.mGasData,
    required this.mStromData,
    this.selectedDate,
    this.highlightTyp = 'beide',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Finde gemeinsame Zeitpunkte
    final dates = _getCommonDates();

    if (dates.isEmpty) {
      return const Center(
        child: Text('Keine Daten verfügbar'),
      );
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
                final isSelected = selectedDate != null &&
                    date.year == selectedDate!.year &&
                    date.month == selectedDate!.month;

                return _buildRow(
                  date: date,
                  index: index,
                  isSelected: isSelected,
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
          // Datum
          Expanded(
            flex: 2,
            child: Text(
              'Monat',
              style: SuewagTextStyles.tableHeader.withColor(
                SuewagColors.primary,
              ),
            ),
          ),

          // K_Gas (Kosten)
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'K Gas',
              'Erdgas Gewerbe',
              SuewagColors.erdgas,
              'kosten',
            ),
          ),

          // K_Strom (Kosten)
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'K Strom',
              'Strom Gewerbe',
              SuewagColors.chartGewerbe,
              'kosten',
            ),
          ),

          // M_Gas (Markt)
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'M Gas',
              'Arbeitspreis',
              SuewagColors.waerme,
              'markt',
            ),
          ),

          // M_Strom (Markt)
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'M Strom',
              'Strom Haushalte',
              SuewagColors.chartHaushalte,
              'markt',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, String subtitle, Color color, String typ) {
    return Tooltip(
      message: '$subtitle\n($typ)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: SuewagTextStyles.tableHeader.withColor(color),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: typ == 'kosten'
                  ? SuewagColors.indiablau.withOpacity(0.2)
                  : SuewagColors.leuchtendgruen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typ == 'kosten' ? 'K' : 'M',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: typ == 'kosten'
                    ? SuewagColors.indiablau
                    : SuewagColors.leuchtendgruen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required DateTime date,
    required int index,
    required bool isSelected,
  }) {
    final kGas = _findValue(kGasData, date);
    final kStrom = _findValue(kStromData, date);
    final mGas = _findValue(mGasData, date);
    final mStrom = _findValue(mStromData, date);

    final backgroundColor = isSelected
        ? SuewagColors.primary.withOpacity(0.1)
        : index.isEven
        ? SuewagColors.quartzgrau10
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: SuewagColors.divider,
            width: 0.5,
          ),
          left: isSelected
              ? BorderSide(color: SuewagColors.primary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Datum
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                _formatDate(date),
                style: SuewagTextStyles.tableCell.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // K_Gas
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: kGas,
              color: SuewagColors.erdgas,
              isHighlighted: isSelected && _shouldHighlight('gas', 'kosten'),
            ),
          ),

          // K_Strom
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: kStrom,
              color: SuewagColors.chartGewerbe,
              isHighlighted: isSelected && _shouldHighlight('strom', 'kosten'),
            ),
          ),

          // M_Gas
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: mGas,
              color: SuewagColors.waerme,
              isHighlighted: isSelected && _shouldHighlight('gas', 'markt'),
            ),
          ),

          // M_Strom
          Expanded(
            flex: 2,
            child: _buildValueCell(
              value: mStrom,
              color: SuewagColors.chartHaushalte,
              isHighlighted: isSelected && _shouldHighlight('strom', 'markt'),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.15) : Colors.transparent,
        border: isHighlighted
            ? Border.all(color: color, width: 2)
            : null,
        borderRadius: isHighlighted ? BorderRadius.circular(6) : null,
      ),
      child: Text(
        value != null ? _formatGermanNumber(value) : '-',  // ← GEÄNDERT
        style: SuewagTextStyles.tableNumber.withColor(
          isHighlighted ? color : SuewagColors.textPrimary,
        ).copyWith(
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  bool _shouldHighlight(String energieTyp, String indexTyp) {
    if (highlightTyp == 'beide') return true;
    if (highlightTyp == energieTyp) return true;
    return false;
  }
  /// Formatiere Zahl im deutschen Format (1.234,5)
  String _formatGermanNumber(double value) {
    final formatter = NumberFormat('#,##0.0', 'de_DE');
    return formatter.format(value);
  }
  List<DateTime> _getCommonDates() {
    final dates = <DateTime>{};
    dates.addAll(kGasData.map((d) => d.date));
    dates.addAll(kStromData.map((d) => d.date));
    dates.addAll(mGasData.map((d) => d.date));
    dates.addAll(mStromData.map((d) => d.date));

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