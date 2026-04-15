import 'package:flutter/material.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/abteilung_model.dart';

class AmpelWidget extends StatelessWidget {
  final List<Abteilung> abteilungen;

  const AmpelWidget({super.key, required this.abteilungen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: abteilungen.map((a) {
            final farbe = _ampelFarbe(a);
            final status = _ampelText(a);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: farbe,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.name, style: SuewagTextStyles.bodyMedium),
                  ),
                  Text(
                    status,
                    style: SuewagTextStyles.bodySmall.copyWith(color: farbe),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _ampelFarbe(Abteilung a) {
    if (a.offeneMaengel == 0) return SuewagColors.leuchtendgruen;
    if (a.offeneMaengel > 5) return SuewagColors.erdbeerrot;
    return SuewagColors.dahliengelb;
  }

  String _ampelText(Abteilung a) {
    if (a.offeneMaengel == 0) return 'Keine offenen Mängel';
    return '${a.offeneMaengel} offen';
  }
}
