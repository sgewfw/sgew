import 'package:flutter/material.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/begehung_enums.dart';
import '../models/mangel_model.dart';

class MangelKarte extends StatelessWidget {
  final Mangel mangel;
  final VoidCallback? onTap;

  const MangelKarte({super.key, required this.mangel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Schweregrad-Indikator
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _schweregradFarbe,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Inhalt
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSchweregradChip(),
                        const SizedBox(width: 8),
                        _buildKategorieChip(),
                        const Spacer(),
                        _buildStatusChip(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mangel.beschreibung,
                      style: SuewagTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: SuewagColors.quartzgrau75,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mangel.zustaendigName,
                          style: SuewagTextStyles.caption,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: _fristFarbe,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fristText,
                          style: SuewagTextStyles.caption.copyWith(
                            color: _fristFarbe,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (mangel.fotoUrl != null)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.photo, color: SuewagColors.quartzgrau50),
                ),
              // Notiz-Indikator
              if (mangel.hatNotizen)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.comment_outlined,
                          size: 14, color: SuewagColors.indiablau),
                      const SizedBox(width: 2),
                      Text('${mangel.anzahlNotizen}',
                          style: SuewagTextStyles.caption.copyWith(
                              color: SuewagColors.indiablau,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchweregradChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _schweregradFarbe.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mangel.schweregrad.label,
        style: SuewagTextStyles.labelSmall.copyWith(color: _schweregradFarbe),
      ),
    );
  }

  Widget _buildKategorieChip() {
    return Text(
      mangel.kategorie.label,
      style: SuewagTextStyles.caption,
    );
  }

  Widget _buildStatusChip() {
    // Phase 2 FIX 4.1: Eigene Farbe für "In Bearbeitung"
    final Color farbe;
    switch (mangel.status) {
      case MangelStatus.behoben:
        farbe = SuewagColors.leuchtendgruen;
        break;
      case MangelStatus.inBearbeitung:
        farbe = SuewagColors.verkehrsorange;
        break;
      case MangelStatus.offen:
        farbe = SuewagColors.quartzgrau75;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: farbe.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mangel.status.label,
        style: SuewagTextStyles.labelSmall.copyWith(color: farbe),
      ),
    );
  }

  Color get _schweregradFarbe {
    switch (mangel.schweregrad) {
      case MangelSchweregrad.kritisch:
        return SuewagColors.erdbeerrot;
      case MangelSchweregrad.mittel:
        return SuewagColors.verkehrsorange;
      case MangelSchweregrad.gering:
        return SuewagColors.dahliengelb;
    }
  }

  Color get _fristFarbe {
    if (mangel.status == MangelStatus.behoben) return SuewagColors.leuchtendgruen;
    if (mangel.istUeberfaellig) return SuewagColors.erdbeerrot;
    if (mangel.fristLaeuftBaldAb) return SuewagColors.dahliengelb;
    return SuewagColors.quartzgrau75;
  }

  String get _fristText {
    if (mangel.status == MangelStatus.behoben) return 'Behoben';
    if (mangel.istUeberfaellig) return 'Überfällig';
    final tage = mangel.restzeit.inDays;
    if (tage == 0) return 'Heute fällig';
    if (tage == 1) return 'Morgen fällig';
    return 'Noch $tage Tage';
  }
}