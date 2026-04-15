import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/suewag_colors.dart';
import '../../../../constants/suewag_text_styles.dart';

import '../models/begehung_enums.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class UserFreigabeScreen extends ConsumerWidget {
  const UserFreigabeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 2, child: Scaffold(
        backgroundColor: SuewagColors.background,
        appBar: AppBar(title: const Text('Benutzer-Freigabe'), backgroundColor: SuewagColors.primary, foregroundColor: Colors.white,
            bottom: TabBar(labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: SuewagColors.verkehrsorange, tabs: const [
              Tab(icon: Icon(Icons.hourglass_empty), text: 'Ausstehend'), Tab(icon: Icon(Icons.people), text: 'Alle Benutzer')])),
        body: const TabBarView(children: [_AusstehendTab(), _AlleUserTab()])));
  }
}

class _AusstehendTab extends ConsumerWidget {
  const _AusstehendTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(pendingUsersProvider);
    return users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) {
          if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 64, color: SuewagColors.leuchtendgruen), const SizedBox(height: 16),
            Text('Keine ausstehenden Anfragen', style: SuewagTextStyles.headline3.copyWith(color: SuewagColors.textSecondary))]));
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) => _PendingUserCard(user: list[i]));
        });
  }
}

class _PendingUserCard extends ConsumerStatefulWidget {
  final BegehungUser user;
  const _PendingUserCard({required this.user});
  @override ConsumerState<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<_PendingUserCard> {
  bool _isProcessing = false;

  Future<void> _freigeben() async {
    final abteilungen = ref.read(abteilungenProvider).when(data: (l) => l, loading: () => <dynamic>[], error: (_, __) => <dynamic>[]);
    if (!mounted) return;
    String? selectedAbteilung;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
      final standort = abteilungen.where((a) => a.name == selectedAbteilung).map((a) => a.standort).firstOrNull;
      final fehlt = selectedAbteilung == null || selectedAbteilung!.isEmpty;
      return AlertDialog(title: const Text('Benutzer freigeben'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [CircleAvatar(backgroundColor: SuewagColors.leuchtendgruen.withOpacity(0.15), child: Icon(Icons.person, color: SuewagColors.leuchtendgruen)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.user.name, style: SuewagTextStyles.headline4), Text(widget.user.email, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary))]))]),
        const SizedBox(height: 20),
        Row(children: [Text('Abteilung zuweisen', style: SuewagTextStyles.labelSmall), Text(' *', style: SuewagTextStyles.labelSmall.copyWith(color: SuewagColors.erdbeerrot, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(value: selectedAbteilung, isExpanded: true,
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), hintText: 'Abteilung wählen',
                enabledBorder: fehlt ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: SuewagColors.erdbeerrot, width: 1.5)) : null),
            onChanged: (v) { if (v != null) setDS(() => selectedAbteilung = v); },
            items: abteilungen.map((a) => DropdownMenuItem<String>(value: a.name, child: Text('${a.name} (${a.standort})', overflow: TextOverflow.ellipsis))).toList()),
        if (fehlt) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.warning_amber_rounded, size: 14, color: SuewagColors.erdbeerrot), const SizedBox(width: 4),
          Expanded(child: Text('Bitte Abteilung zuweisen', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.erdbeerrot, fontSize: 11)))])],
        if (standort != null && standort.isNotEmpty) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.location_on, size: 14, color: SuewagColors.textSecondary), const SizedBox(width: 4),
          Text('Standort: $standort', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary))])],
      ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            ElevatedButton.icon(onPressed: fehlt ? null : () => Navigator.pop(ctx, true), icon: const Icon(Icons.check), label: const Text('Freigeben'),
                style: ElevatedButton.styleFrom(backgroundColor: fehlt ? SuewagColors.quartzgrau50 : SuewagColors.leuchtendgruen, foregroundColor: Colors.white))]);
    }));
    if (confirmed != true || selectedAbteilung == null) return;
    final standort = abteilungen.where((a) => a.name == selectedAbteilung).map((a) => a.standort).firstOrNull ?? '';
    setState(() => _isProcessing = true);
    try {
      await ref.read(userServiceProvider).freigebenMitAbteilung(widget.user.uid, selectedAbteilung!, standort);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.user.name} freigeschaltet ($selectedAbteilung)'), backgroundColor: SuewagColors.leuchtendgruen));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: SuewagColors.erdbeerrot));
    } finally { if (mounted) setState(() => _isProcessing = false); }
  }

  Future<void> _ablehnen() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Benutzer ablehnen?'),
        content: Text('Anfrage von "${widget.user.name}" ablehnen?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: SuewagColors.erdbeerrot), child: const Text('Ablehnen'))]));
    if (ok != true) return;
    setState(() => _isProcessing = true);
    try { await ref.read(userServiceProvider).ablehnen(widget.user.uid);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.user.name} abgelehnt'), backgroundColor: SuewagColors.erdbeerrot));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: SuewagColors.erdbeerrot));
    } finally { if (mounted) setState(() => _isProcessing = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: SuewagColors.verkehrsorange.withOpacity(0.4), width: 1)),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(backgroundColor: SuewagColors.verkehrsorange.withOpacity(0.15), child: Icon(Icons.person, color: SuewagColors.verkehrsorange)), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.user.name, style: SuewagTextStyles.headline4), Text(widget.user.email, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: SuewagColors.verkehrsorange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('Ausstehend', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.verkehrsorange, fontWeight: FontWeight.w600)))]),
          const SizedBox(height: 8), Text('Registriert: ${_formatTimeAgo(widget.user.createdAt)}', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _isProcessing ? null : _ablehnen, icon: const Icon(Icons.close), label: const Text('Ablehnen'),
                style: OutlinedButton.styleFrom(foregroundColor: SuewagColors.erdbeerrot, side: BorderSide(color: SuewagColors.erdbeerrot.withOpacity(0.5))))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(onPressed: _isProcessing ? null : _freigeben,
                icon: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.check),
                label: const Text('Freigeben'), style: ElevatedButton.styleFrom(backgroundColor: SuewagColors.leuchtendgruen, foregroundColor: Colors.white)))]),
        ])));
  }
  String _formatTimeAgo(DateTime dt) { final d = DateTime.now().difference(dt); if (d.inMinutes < 60) return 'vor ${d.inMinutes} Min.'; if (d.inHours < 24) return 'vor ${d.inHours} Std.'; return 'vor ${d.inDays} Tag(en)'; }
}

class _AlleUserTab extends ConsumerWidget {
  const _AlleUserTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersSortedProvider);
    return users.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) { if (list.isEmpty) return const Center(child: Text('Keine Benutzer'));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_, i) => _UserMgmtCard(user: list[i])); });
  }
}

class _UserMgmtCard extends ConsumerStatefulWidget {
  final BegehungUser user;
  const _UserMgmtCard({required this.user});
  @override ConsumerState<_UserMgmtCard> createState() => _UserMgmtCardState();
}

class _UserMgmtCardState extends ConsumerState<_UserMgmtCard> {
  static const _rollen = ['Mitarbeiter', 'BE4', 'BE3', 'BE2', 'Admin'];

  Future<void> _aktivierenMitAbteilung() async {
    final abteilungen = ref.read(abteilungenProvider).when(data: (l) => l, loading: () => <dynamic>[], error: (_, __) => <dynamic>[]);
    String? sel = widget.user.abteilung.isNotEmpty ? widget.user.abteilung : null;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
      final fehlt = sel == null || sel!.isEmpty;
      return AlertDialog(title: const Text('Benutzer aktivieren'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.user.name, style: SuewagTextStyles.labelMedium), Text(widget.user.email, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary)), const SizedBox(height: 20),
        Row(children: [Text('Abteilung', style: SuewagTextStyles.labelSmall), Text(' *', style: SuewagTextStyles.labelSmall.copyWith(color: SuewagColors.erdbeerrot, fontWeight: FontWeight.bold))]), const SizedBox(height: 6),
        DropdownButtonFormField<String>(value: abteilungen.any((a) => a.name == sel) ? sel : null, isExpanded: true,
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), hintText: 'Abteilung wählen',
                enabledBorder: fehlt ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: SuewagColors.erdbeerrot, width: 1.5)) : null),
            onChanged: (v) { if (v != null) setDS(() => sel = v); },
            items: abteilungen.map((a) => DropdownMenuItem<String>(value: a.name, child: Text('${a.name} (${a.standort})', overflow: TextOverflow.ellipsis))).toList()),
        if (fehlt) ...[const SizedBox(height: 6), Text('Abteilung ist Pflicht', style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.erdbeerrot, fontSize: 11))],
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
        ElevatedButton(onPressed: fehlt ? null : () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: fehlt ? SuewagColors.quartzgrau50 : SuewagColors.leuchtendgruen, foregroundColor: Colors.white), child: const Text('Aktivieren'))]);
    }));
    if (ok != true || sel == null) return;
    final standort = abteilungen.where((a) => a.name == sel).map((a) => a.standort).firstOrNull ?? '';
    try { await ref.read(userServiceProvider).freigebenMitAbteilung(widget.user.uid, sel!, standort);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.user.name} aktiviert'), backgroundColor: SuewagColors.leuchtendgruen));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: SuewagColors.erdbeerrot)); }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.user.status; final rolle = widget.user.rolle.label;
    final (sc, si) = switch (status) { UserStatus.ausstehend => (SuewagColors.verkehrsorange, Icons.hourglass_empty), UserStatus.abgelehnt => (SuewagColors.erdbeerrot, Icons.block),
      UserStatus.gesperrt => (SuewagColors.erdbeerrot, Icons.block), UserStatus.aktiv => (SuewagColors.leuchtendgruen, Icons.check_circle) };
    return Card(margin: const EdgeInsets.only(bottom: 10), elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          CircleAvatar(backgroundColor: sc.withOpacity(0.12), child: Icon(si, color: sc, size: 20)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.user.name, style: SuewagTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(widget.user.email, style: SuewagTextStyles.bodySmall.copyWith(color: SuewagColors.textSecondary))])),
          const SizedBox(width: 8),
          DropdownButton<String>(value: _rollen.contains(rolle) ? rolle : 'Mitarbeiter', underline: const SizedBox.shrink(), style: SuewagTextStyles.bodySmall,
              items: _rollen.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) async { if (v != null) try { await ref.read(userServiceProvider).updateRolle(widget.user.uid, UserRolle.fromString(v)); } catch (_) {} }),
          const SizedBox(width: 8),
          if (status == UserStatus.aktiv) IconButton(icon: Icon(Icons.block, color: SuewagColors.erdbeerrot), tooltip: 'Deaktivieren',
              onPressed: () async { try { await ref.read(userServiceProvider).updateStatus(widget.user.uid, UserStatus.gesperrt); } catch (_) {} })
          else if (status == UserStatus.gesperrt || status == UserStatus.abgelehnt)
            IconButton(icon: Icon(Icons.lock_open, color: SuewagColors.leuchtendgruen), tooltip: 'Aktivieren', onPressed: () => _aktivierenMitAbteilung()),
        ])));
  }
}