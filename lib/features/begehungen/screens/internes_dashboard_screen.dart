import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/begehung_enums.dart';
import '../models/mangel_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/begehung_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/mangel_karte.dart';
import '../widgets/responsive_helper.dart';

enum ZeitraumFilter {
  aktuell('Aktuell', null, null), dieserMonat('Dieser Monat', null, null),
  letzte30Tage('30 Tage', 30, null), letzte90Tage('90 Tage', 90, null),
  q1('Q1', null, 1), q2('Q2', null, 2), q3('Q3', null, 3), q4('Q4', null, 4);
  final String label; final int? _tage; final int? _quartal;
  const ZeitraumFilter(this.label, this._tage, this._quartal);

  DateTime? get startDatum {
    final now = DateTime.now();
    if (_tage != null) return now.subtract(Duration(days: _tage!));
    if (_quartal != null) return DateTime(now.year, (_quartal! - 1) * 3 + 1, 1);
    if (this == ZeitraumFilter.dieserMonat) return DateTime(now.year, now.month, 1);
    return null;
  }
  DateTime? get endDatum {
    final now = DateTime.now();
    if (_quartal != null) { final end = DateTime(now.year, _quartal! * 3 + 1, 1); return end.isAfter(now) ? now : end; }
    return null;
  }
}

class InternesDashboardScreen extends ConsumerStatefulWidget {
  const InternesDashboardScreen({super.key});
  @override ConsumerState<InternesDashboardScreen> createState() => _InternesDashboardScreenState();
}

class _InternesDashboardScreenState extends ConsumerState<InternesDashboardScreen> {
  MangelSchweregrad? _filterSchweregrad;
  MangelStatus? _filterStatus;
  ZeitraumFilter _zeitraum = ZeitraumFilter.aktuell;

  @override
  Widget build(BuildContext context) {
    final rolle = ref.watch(userRolleProvider);
    final currentUser = ref.watch(currentBegehungUserProvider);
    final alleOffenen = ref.watch(alleOffenenMaengelProvider);
    final userRanking = ref.watch(userRankingProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Internes Dashboard', style: SuewagTextStyles.headline2), const SizedBox(height: 8),
      Text(_sichtbarkeitHinweis(rolle), style: SuewagTextStyles.bodySmall), const SizedBox(height: 16),

      // Zeitraum-Filter
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: ZeitraumFilter.values.map((z) { final sel = _zeitraum == z; return Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(z.label), selected: sel, onSelected: (_) => setState(() => _zeitraum = z),
                  selectedColor: SuewagColors.indiablau.withOpacity(0.2),
                  labelStyle: SuewagTextStyles.bodySmall.copyWith(color: sel ? SuewagColors.indiablau : SuewagColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal))); }).toList())),
      const SizedBox(height: 24),

      Text('Mitarbeiter-Ranking', style: SuewagTextStyles.headline3), const SizedBox(height: 12),
      Builder(builder: (context) {
        final gefiltert = _filtereUserNachRolle(userRanking, rolle, currentUser);
        if (gefiltert.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Keine Mitarbeiter gefunden'));
        return Card(child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: gefiltert.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) { final u = gefiltert[i]; return ListTile(
                leading: CircleAvatar(backgroundColor: SuewagColors.verkehrsorange, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                title: Text(u.name), subtitle: Text(u.abteilung), trailing: Text('${u.begehungenDiesesJahr}', style: SuewagTextStyles.numberSmall)); }));
      }),
      const SizedBox(height: 24),

      Text('Offene Mängel', style: SuewagTextStyles.headline3), const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        DropdownButton<MangelSchweregrad?>(value: _filterSchweregrad, hint: const Text('Schweregrad'), onChanged: (v) => setState(() => _filterSchweregrad = v),
            items: [const DropdownMenuItem(value: null, child: Text('Alle')), ...MangelSchweregrad.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))]),
        DropdownButton<MangelStatus?>(value: _filterStatus, hint: const Text('Status'), onChanged: (v) => setState(() => _filterStatus = v),
            items: [const DropdownMenuItem(value: null, child: Text('Alle')), ...MangelStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))]),
      ]),
      const SizedBox(height: 12),

      alleOffenen.when(
        data: (maengel) {
          final gefiltert = _filtereMaengel(maengel);
          if (gefiltert.isEmpty) return Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(
              _zeitraum == ZeitraumFilter.aktuell ? 'Keine offenen Mängel' : 'Keine Mängel im Zeitraum "${_zeitraum.label}"',
              style: SuewagTextStyles.bodyMedium.copyWith(color: SuewagColors.textSecondary))));
          final kritisch = gefiltert.where((m) => m.schweregrad == MangelSchweregrad.kritisch).length;
          final ueberfaellig = gefiltert.where((m) => m.istUeberfaellig).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _miniStat('Gesamt', '${gefiltert.length}', SuewagColors.quartzgrau75), const SizedBox(width: 8),
              _miniStat('Kritisch', '$kritisch', kritisch > 0 ? SuewagColors.erdbeerrot : SuewagColors.leuchtendgruen), const SizedBox(width: 8),
              _miniStat('Überfällig', '$ueberfaellig', ueberfaellig > 0 ? SuewagColors.erdbeerrot : SuewagColors.leuchtendgruen),
            ]), const SizedBox(height: 12),
            ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: gefiltert.length,
                itemBuilder: (_, i) => MangelKarte(mangel: gefiltert[i])),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('🔴 [InternesDashboard] Mängel-Fehler: $error');
          debugPrint('🔴 [InternesDashboard] Stack: $stack');
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Fehler beim Laden der Mängel:\n$error',
                textAlign: TextAlign.center,
                style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.erdbeerrot)),
          ));
        },
      ),
    ]));
  }

  Widget _miniStat(String label, String wert, Color farbe) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: farbe.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: farbe.withOpacity(0.2))),
        child: Column(children: [Text(wert, style: SuewagTextStyles.headline3.copyWith(color: farbe, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(label, style: SuewagTextStyles.caption.copyWith(color: farbe))])));
  }

  List<Mangel> _filtereMaengel(List<Mangel> maengel) {
    return maengel.where((m) {
      if (_filterSchweregrad != null && m.schweregrad != _filterSchweregrad) return false;
      if (_filterStatus != null && m.status != _filterStatus) return false;
      final start = _zeitraum.startDatum; final end = _zeitraum.endDatum;
      if (start != null && m.createdAt.isBefore(start)) return false;
      if (end != null && m.createdAt.isAfter(end)) return false;
      return true;
    }).toList();
  }

  List<BegehungUser> _filtereUserNachRolle(List<BegehungUser> users, UserRolle rolle, AsyncValue<BegehungUser?> cu) {
    if (rolle.kannAlleAbteilungenSehen) return users;
    final u = cu.valueOrNull; if (u == null) return [];
    return users.where((x) { if (rolle == UserRolle.be4) return x.abteilung == u.abteilung; if (rolle == UserRolle.be3) return x.standort == u.standort; return true; }).toList();
  }

  String _sichtbarkeitHinweis(UserRolle rolle) => switch (rolle) {
    UserRolle.be4 => 'Sie sehen Daten Ihrer Abteilung', UserRolle.be3 => 'Sie sehen Daten Ihres Bereichs',
    UserRolle.be2 || UserRolle.admin => 'Sie sehen alle Daten', _ => '' };
}