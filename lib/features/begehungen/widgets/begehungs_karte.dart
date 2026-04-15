import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/begehung_model.dart';

class BegehungsKarte extends StatelessWidget {
  final Begehung begehung;
  final VoidCallback? onTap;

  const BegehungsKarte({super.key, required this.begehung, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _typIcon,
                    color: SuewagColors.verkehrsorange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      begehung.typ.label,
                      style: SuewagTextStyles.labelMedium,
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(begehung.datum),
                    style: SuewagTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: SuewagColors.quartzgrau75),
                  const SizedBox(width: 4),
                  Text(begehung.ort, style: SuewagTextStyles.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Icons.business_outlined,
                      size: 14, color: SuewagColors.quartzgrau75),
                  const SizedBox(width: 4),
                  Text(begehung.abteilung, style: SuewagTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: SuewagColors.quartzgrau75),
                  const SizedBox(width: 4),
                  Text(begehung.erstellerName,
                      style: SuewagTextStyles.bodySmall),
                  const Spacer(),
                  _buildMangelChip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMangelChip() {
    final offen = begehung.offeneMaengel;
    final gesamt = begehung.anzahlMaengel;

    if (gesamt == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: SuewagColors.leuchtendgruen.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Keine Mängel',
          style:
              SuewagTextStyles.labelSmall.copyWith(color: SuewagColors.leuchtendgruen),
        ),
      );
    }

    final farbe = offen > 0 ? SuewagColors.verkehrsorange : SuewagColors.leuchtendgruen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: farbe.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        offen > 0 ? '$offen / $gesamt offen' : 'Alle behoben',
        style: SuewagTextStyles.labelSmall.copyWith(color: farbe),
      ),
    );
  }

  IconData get _typIcon {
    switch (begehung.typ.label) {
      case 'Standardbegehung':
        return Icons.checklist;
      case 'Schwerpunktbegehung':
        return Icons.priority_high;
      case 'Nachbegehung':
        return Icons.replay;
      default:
        return Icons.construction;
    }
  }
}
