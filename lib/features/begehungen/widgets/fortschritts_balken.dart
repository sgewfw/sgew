import 'package:flutter/material.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';

class FortschrittsBalken extends StatelessWidget {
  final String label;
  final int aktuell;
  final int ziel;

  const FortschrittsBalken({
    super.key,
    required this.label,
    required this.aktuell,
    required this.ziel,
  });

  @override
  Widget build(BuildContext context) {
    final prozent = ziel > 0 ? (aktuell / ziel).clamp(0.0, 1.0) : 0.0;
    final farbe = prozent >= 1.0
        ? SuewagColors.leuchtendgruen
        : prozent >= 0.5
            ? SuewagColors.dahliengelb
            : SuewagColors.verkehrsorange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: SuewagTextStyles.labelMedium),
                Text(
                  ziel > 0 ? '$aktuell / $ziel' : '$aktuell',
                  style: SuewagTextStyles.numberSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: prozent,
                minHeight: 12,
                backgroundColor: SuewagColors.quartzgrau10,
                valueColor: AlwaysStoppedAnimation<Color>(farbe),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
