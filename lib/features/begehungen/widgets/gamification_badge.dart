import 'package:flutter/material.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../providers/gamification_provider.dart';

class GamificationBadgeWidget extends StatelessWidget {
  final BegehungBadge badge;

  const GamificationBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.typ.beschreibung,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: badge.earned
                    ? SuewagColors.verkehrsorange
                    : SuewagColors.quartzgrau10,
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.earned
                      ? SuewagColors.verkehrsorange
                      : SuewagColors.quartzgrau25,
                  width: 2,
                ),
              ),
              child: Icon(
                badge.typ.icon,
                color: badge.earned ? Colors.white : SuewagColors.quartzgrau50,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.typ.label,
              style: SuewagTextStyles.caption.copyWith(
                color: badge.earned
                    ? SuewagColors.textPrimary
                    : SuewagColors.quartzgrau50,
                fontWeight: badge.earned ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeLeiste extends StatelessWidget {
  final List<BegehungBadge> badges;

  const BadgeLeiste({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ihre Abzeichen', style: SuewagTextStyles.headline3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges
                  .map((b) => GamificationBadgeWidget(badge: b))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
