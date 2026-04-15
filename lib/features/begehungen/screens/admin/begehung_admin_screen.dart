import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/suewag_colors.dart';
import '../../../../constants/suewag_text_styles.dart';
import '../../providers/begehung_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../services/abteilung_service.dart';
import '../../widgets/begehungs_karte.dart';
import '../begehung_detail_screen.dart';
import '../user_freigabe_screen.dart';

class BegehungAdminScreen extends ConsumerStatefulWidget {
  const BegehungAdminScreen({super.key});
  @override ConsumerState<BegehungAdminScreen> createState() => _BegehungAdminScreenState();
}

class _BegehungAdminScreenState extends ConsumerState<BegehungAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ausstehend = ref.watch(pendingCountProvider).value ?? 0;
    return Column(children: [
      Material(color: Theme.of(context).scaffoldBackgroundColor, child: TabBar(controller: _tabController,
          labelColor: SuewagColors.verkehrsorange, unselectedLabelColor: SuewagColors.textSecondary, indicatorColor: SuewagColors.verkehrsorange,
          tabs: [
            const Tab(icon: Icon(Icons.checklist_rounded), text: 'Begehungen'),
            Tab(icon: ausstehend > 0 ? Badge(label: Text('$ausstehend'), backgroundColor: SuewagColors.erdbeerrot, child: const Icon(Icons.how_to_reg_outlined)) : const Icon(Icons.how_to_reg_outlined), text: 'Freigaben'),
          ])),
      Expanded(child: TabBarView(controller: _tabController, children: const [_BegehungenTab(), UserFreigabeScreen()])),
    ]);
  }
}

class _BegehungenTab extends ConsumerWidget {
  const _BegehungenTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final begehungen = ref.watch(begehungenProvider);
    final abteilungen = ref.watch(abteilungenProvider);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Begehungs-Verwaltung', style: SuewagTextStyles.headline2), const Spacer(),
        abteilungen.when(
            data: (l) => l.isEmpty ? ElevatedButton.icon(onPressed: () => _seedAbteilungen(context), icon: const Icon(Icons.add), label: const Text('Abteilungen anlegen'),
                style: ElevatedButton.styleFrom(backgroundColor: SuewagColors.verkehrsorange, foregroundColor: Colors.white)) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(), error: (_, _) => const SizedBox.shrink())]),
      const SizedBox(height: 8), Text('Übersicht aller Begehungen im System', style: SuewagTextStyles.bodySmall), const SizedBox(height: 24),
      abteilungen.when(
          data: (l) { final g = l.fold<int>(0, (s, a) => s + a.begehungenDiesesJahr); final o = l.fold<int>(0, (s, a) => s + a.offeneMaengel);
          return Row(children: [_stat('Abteilungen', '${l.length}', SuewagColors.indiablau), const SizedBox(width: 12), _stat('Begehungen', '$g', SuewagColors.verkehrsorange), const SizedBox(width: 12),
            _stat('Offene Mängel', '$o', o > 0 ? SuewagColors.erdbeerrot : SuewagColors.leuchtendgruen)]); },
          loading: () => const SizedBox.shrink(), error: (_, _) => const SizedBox.shrink()),
      const SizedBox(height: 24), Text('Alle Begehungen', style: SuewagTextStyles.headline3), const SizedBox(height: 12),
      begehungen.when(
          data: (l) { if (l.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Noch keine Begehungen vorhanden.\nBegehungen werden automatisch über den SmapOne-Webhook importiert.', textAlign: TextAlign.center)));
          return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: l.length,
              itemBuilder: (_, i) { final b = l[i]; return BegehungsKarte(begehung: b, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BegehungDetailScreen(begehung: b)))); }); },
          loading: () => const Center(child: CircularProgressIndicator()), error: (_, _) => const Text('Fehler beim Laden der Begehungen')),
    ]));
  }

  Widget _stat(String label, String wert, Color farbe) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(children: [Text(wert, style: SuewagTextStyles.numberMedium.copyWith(color: farbe)), const SizedBox(height: 4), Text(label, style: SuewagTextStyles.caption)]))));

  Future<void> _seedAbteilungen(BuildContext context) async {
    try { await AbteilungService().seedAbteilungen(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abteilungen erfolgreich angelegt'), backgroundColor: SuewagColors.leuchtendgruen));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: SuewagColors.erdbeerrot)); }
  }
}