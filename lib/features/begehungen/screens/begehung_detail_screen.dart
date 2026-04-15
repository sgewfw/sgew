import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/begehung_model.dart';
import '../models/begehung_enums.dart';
import '../providers/begehung_providers.dart';
import '../widgets/mangel_karte.dart';
import 'mangel_detail_screen.dart';

class BegehungDetailScreen extends ConsumerWidget {
  final Begehung begehung;
  const BegehungDetailScreen({super.key, required this.begehung});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maengel = ref.watch(maengelProvider(begehung.id));
    return Scaffold(
      appBar: AppBar(title: Text(begehung.typ.label)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.construction, color: SuewagColors.verkehrsorange), const SizedBox(width: 8),
              Expanded(child: Text(begehung.typ.label, style: SuewagTextStyles.headline3)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _statusFarbe.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(begehung.status.label, style: SuewagTextStyles.labelSmall.copyWith(color: _statusFarbe))),
            ]),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Datum', DateFormat('dd.MM.yyyy, HH:mm').format(begehung.datum)),
            _buildInfoRow(Icons.location_on_outlined, 'Ort', begehung.ort),
            _buildInfoRow(Icons.business_outlined, 'Abteilung', begehung.abteilung),
            _buildInfoRow(Icons.map_outlined, 'Standort', begehung.standort),
            _buildInfoRow(Icons.person_outline, 'Ersteller', begehung.erstellerName),
            if (begehung.smaponeReportId.isNotEmpty) _buildInfoRow(Icons.description_outlined, 'SmapOne Report', begehung.smaponeReportId),
          ]))),
          const SizedBox(height: 16),

          // Teilnehmer
          if (begehung.hatTeilnehmer) ...[
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.groups_outlined, size: 20, color: SuewagColors.verkehrsorange), const SizedBox(width: 8),
                Text('Teilnehmer (${begehung.teilnehmer.length})', style: SuewagTextStyles.headline4)]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: begehung.teilnehmer.map((name) => Chip(
                  avatar: CircleAvatar(backgroundColor: SuewagColors.verkehrsorange.withOpacity(0.15),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: SuewagColors.verkehrsorange, fontSize: 12, fontWeight: FontWeight.bold))),
                  label: Text(name), backgroundColor: SuewagColors.quartzgrau10, side: BorderSide.none)).toList()),
            ]))),
            const SizedBox(height: 16),
          ],

          if (begehung.berichtsText.isNotEmpty) ...[
            Text('Berichtstext', style: SuewagTextStyles.headline3), const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(begehung.berichtsText, style: SuewagTextStyles.bodyMedium))),
            const SizedBox(height: 16),
          ],

          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildStatColumn('Gesamt', begehung.anzahlMaengel, SuewagColors.quartzgrau75),
            _buildStatColumn('Offen', begehung.offeneMaengel, SuewagColors.verkehrsorange),
            _buildStatColumn('Behoben', begehung.behobeneMaengel, SuewagColors.leuchtendgruen),
          ]))),
          const SizedBox(height: 24),

          Text('Mängel', style: SuewagTextStyles.headline3), const SizedBox(height: 12),
          maengel.when(
            data: (liste) {
              if (liste.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Keine Mängel erfasst')));
              return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: liste.length,
                  itemBuilder: (context, index) { final m = liste[index]; return MangelKarte(mangel: m, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MangelDetailScreen(mangel: m, begehungId: begehung.id)))); });
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Fehler beim Laden der Mängel'),
          ),
        ]),
      ),
    );
  }

  Color get _statusFarbe => switch (begehung.status) {
    BegehungStatus.offen => SuewagColors.verkehrsorange,
    BegehungStatus.abgeschlossen => SuewagColors.leuchtendgruen,
    BegehungStatus.archiviert => SuewagColors.quartzgrau75,
  };

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Icon(icon, size: 16, color: SuewagColors.quartzgrau75), const SizedBox(width: 8),
      SizedBox(width: 100, child: Text(label, style: SuewagTextStyles.labelSmall)),
      Expanded(child: Text(value, style: SuewagTextStyles.bodyMedium)),
    ]));
  }

  Widget _buildStatColumn(String label, int wert, Color farbe) {
    return Column(children: [Text('$wert', style: SuewagTextStyles.numberMedium.copyWith(color: farbe)), const SizedBox(height: 4), Text(label, style: SuewagTextStyles.caption)]);
  }
}