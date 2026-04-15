import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/suewag_colors.dart';
import '../../../../constants/suewag_text_styles.dart';
import '../../models/abteilung_model.dart';
import '../../models/begehung_enums.dart';
import '../../models/user_model.dart';
import '../../models/app_exception.dart';
import '../../providers/auth_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/responsive_helper.dart';

class UserVerwaltungScreen extends ConsumerStatefulWidget {
  const UserVerwaltungScreen({super.key});
  @override ConsumerState<UserVerwaltungScreen> createState() => _UserVerwaltungScreenState();
}

class _UserVerwaltungScreenState extends ConsumerState<UserVerwaltungScreen> {
  UserStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(alleUsersProvider);
    return SingleChildScrollView(child: ResponsiveHelper.centeredContent(context: context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Benutzerverwaltung', style: SuewagTextStyles.headline2), const SizedBox(height: 4),
      Text('Rollen und Zugänge der Mitarbeiter verwalten', style: SuewagTextStyles.bodySmall), const SizedBox(height: 16),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: const Text('Alle'), selected: _filterStatus == null, onSelected: (_) => setState(() => _filterStatus = null),
            selectedColor: SuewagColors.verkehrsorange.withOpacity(0.2), checkmarkColor: SuewagColors.verkehrsorange,
            labelStyle: SuewagTextStyles.bodySmall.copyWith(color: _filterStatus == null ? SuewagColors.verkehrsorange : SuewagColors.textSecondary, fontWeight: _filterStatus == null ? FontWeight.w600 : FontWeight.normal))),
        ...UserStatus.values.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(s.label), selected: _filterStatus == s, onSelected: (_) => setState(() => _filterStatus = s),
            selectedColor: SuewagColors.verkehrsorange.withOpacity(0.2), checkmarkColor: SuewagColors.verkehrsorange,
            labelStyle: SuewagTextStyles.bodySmall.copyWith(color: _filterStatus == s ? SuewagColors.verkehrsorange : SuewagColors.textSecondary, fontWeight: _filterStatus == s ? FontWeight.w600 : FontWeight.normal))))])),
      const SizedBox(height: 16),
      users.when(
          data: (liste) {
            final gef = _filterStatus == null ? liste : liste.where((u) => u.status == _filterStatus).toList();
            if (gef.isEmpty) return Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
              Icon(Icons.people_outline, size: 48, color: SuewagColors.textSecondary), const SizedBox(height: 12),
              Text(_filterStatus == null ? 'Noch keine Benutzer registriert' : 'Keine Benutzer mit Status "${_filterStatus!.label}"',
                  style: SuewagTextStyles.bodyMedium.copyWith(color: SuewagColors.textSecondary), textAlign: TextAlign.center)])));
            return Card(child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: gef.length,
                separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) => _UserTile(user: gef[i])));
          },
          loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Text('Fehler beim Laden')),
    ])));
  }
}

class _UserTile extends ConsumerWidget {
  final BegehungUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (sc, si, sl) = switch (user.status) {
      UserStatus.ausstehend => (SuewagColors.verkehrsorange, Icons.hourglass_empty, 'Ausstehend'),
      UserStatus.gesperrt => (SuewagColors.erdbeerrot, Icons.block, 'Gesperrt'),
      UserStatus.abgelehnt => (SuewagColors.erdbeerrot, Icons.close, 'Abgelehnt'),
      UserStatus.aktiv => (SuewagColors.leuchtendgruen, Icons.check_circle, 'Aktiv') };
    final rf = switch (user.rolle) { UserRolle.admin => SuewagColors.erdbeerrot, UserRolle.be2 => SuewagColors.indiablau, UserRolle.be3 => SuewagColors.verkehrsorange, UserRolle.be4 => SuewagColors.dahliengelb, UserRolle.mitarbeiter => SuewagColors.quartzgrau75 };

    return ListTile(
        leading: CircleAvatar(backgroundColor: rf.withOpacity(0.15), child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: TextStyle(color: rf, fontWeight: FontWeight.bold))),
        title: Row(children: [Expanded(child: Text(user.name, style: SuewagTextStyles.labelMedium)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(si, size: 11, color: sc), const SizedBox(width: 4), Text(sl, style: SuewagTextStyles.labelSmall.copyWith(color: sc, fontSize: 11))]))]),
        subtitle: Text('${user.email}  ·  ${user.rolle.label}${user.abteilung.isNotEmpty ? '  ·  ${user.abteilung}' : ''}', style: SuewagTextStyles.caption),
        onTap: () => _showEditDialog(context, ref, user));
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, BegehungUser user) {
    var selRolle = user.rolle; var selStatus = user.status; var selAbt = user.abteilung;
    final abtAsync = ref.read(abteilungenProvider);
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
      final abts = abtAsync.when(data: (l) => l, loading: () => <Abteilung>[], error: (_, __) => <Abteilung>[]);
      final standort = abts.where((a) => a.name == selAbt).map((a) => a.standort).firstOrNull ?? user.standort;
      final braucht = selStatus == UserStatus.aktiv && selAbt.isEmpty;
      return AlertDialog(title: const Text('Benutzer bearbeiten'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.name, style: SuewagTextStyles.labelMedium), Text(user.email, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary)), const SizedBox(height: 20),
        Row(children: [Text('Abteilung', style: SuewagTextStyles.labelSmall), if (selStatus == UserStatus.aktiv) Text(' *', style: SuewagTextStyles.labelSmall.copyWith(color: SuewagColors.erdbeerrot, fontWeight: FontWeight.bold))]), const SizedBox(height: 6),
        DropdownButtonFormField<String>(value: abts.any((a) => a.name == selAbt) ? selAbt : null, isExpanded: true,
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), hintText: 'Abteilung wählen',
                enabledBorder: braucht ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: SuewagColors.erdbeerrot, width: 1.5)) : null),
            onChanged: (v) { if (v != null) setDS(() => selAbt = v); },
            items: abts.map((a) => DropdownMenuItem(value: a.name, child: Text('${a.name} (${a.standort})', overflow: TextOverflow.ellipsis))).toList()),
        if (braucht) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.warning_amber_rounded, size: 14, color: SuewagColors.erdbeerrot), const SizedBox(width: 4),
          Expanded(child: Text('Abteilung ist Pflicht um zu aktivieren', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.erdbeerrot, fontSize: 11)))])],
        if (standort.isNotEmpty) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.location_on, size: 14, color: SuewagColors.textSecondary), const SizedBox(width: 4),
          Text('Standort: $standort', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary))])],
        const SizedBox(height: 16), Text('Rolle', style: SuewagTextStyles.labelSmall), const SizedBox(height: 6),
        DropdownButtonFormField<UserRolle>(value: selRolle, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            onChanged: (v) { if (v != null) setDS(() => selRolle = v); }, items: UserRolle.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList()),
        const SizedBox(height: 16), Text('Status', style: SuewagTextStyles.labelSmall), const SizedBox(height: 6),
        DropdownButtonFormField<UserStatus>(value: selStatus, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            onChanged: (v) { if (v != null) setDS(() => selStatus = v); }, items: UserStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList()),
      ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            ElevatedButton(onPressed: braucht ? null : () async {
              try {
                final svc = ref.read(userServiceProvider);
                if (selRolle != user.rolle) await svc.updateRolle(user.uid, selRolle);
                if (selStatus != user.status) await svc.updateStatus(user.uid, selStatus);
                final ns = abts.where((a) => a.name == selAbt).map((a) => a.standort).firstOrNull ?? '';
                if (selAbt != user.abteilung || ns != user.standort) await svc.updateAbteilung(user.uid, selAbt, ns);
                if (ctx.mounted) { Navigator.pop(ctx); showAppSuccess(ctx, '${user.name} aktualisiert'); }
              } catch (e) { if (ctx.mounted) showAppError(ctx, e); }
            }, style: ElevatedButton.styleFrom(backgroundColor: braucht ? SuewagColors.quartzgrau50 : SuewagColors.verkehrsorange, foregroundColor: Colors.white), child: const Text('Speichern'))]);
    }));
  }
}