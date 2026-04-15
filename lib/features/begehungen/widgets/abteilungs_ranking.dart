import 'package:flutter/material.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/abteilung_model.dart';

class AbteilungsRanking extends StatelessWidget {
  final List<Abteilung> abteilungen;

  const AbteilungsRanking({super.key, required this.abteilungen});

  @override
  Widget build(BuildContext context) {
    final sorted = List<Abteilung>.from(abteilungen)
      ..sort((a, b) => b.begehungenDiesesJahr.compareTo(a.begehungenDiesesJahr));

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = sorted[index];
          final medal = index < 3 ? _medaillen[index] : '${index + 1}.';

          return ListTile(
            leading: SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  medal,
                  style: SuewagTextStyles.headline3,
                ),
              ),
            ),
            title: Text(a.name),
            subtitle: Text(a.standort),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${a.begehungenDiesesJahr}',
                  style: SuewagTextStyles.numberSmall.copyWith(
                    color: a.jahresZielErreicht
                        ? SuewagColors.leuchtendgruen
                        : SuewagColors.quartzgrau100,
                  ),
                ),
                if (a.jahresZiel > 0)
                  Text(
                    'von ${a.jahresZiel}',
                    style: SuewagTextStyles.caption,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _medaillen = ['🥇', '🥈', '🥉'];
}
