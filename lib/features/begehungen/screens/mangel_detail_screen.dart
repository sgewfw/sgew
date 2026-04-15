import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../models/begehung_enums.dart';
import '../models/mangel_model.dart';
import '../providers/auth_providers.dart';
import '../providers/begehung_providers.dart';

class MangelDetailScreen extends ConsumerWidget {
  final Mangel mangel;
  final String begehungId;

  const MangelDetailScreen({
    super.key,
    required this.mangel,
    required this.begehungId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentBegehungUserProvider);
    final maengelAsync = ref.watch(maengelProvider(begehungId));
    final m = maengelAsync.when(
      data: (list) =>
      list.where((item) => item.id == mangel.id).firstOrNull ?? mangel,
      loading: () => mangel,
      error: (_, __) => mangel,
    );

    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Mangel-Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: isWide
          ? _buildWideLayout(context, ref, m, currentUser)
          : _buildNarrowLayout(context, ref, m, currentUser),
    );
  }

  // ─── Desktop / Tablet ─────────────────────────────────────
  Widget _buildWideLayout(
      BuildContext context, WidgetRef ref, Mangel m, AsyncValue currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildFotoGalerie(context, m),
                    const SizedBox(height: 16),
                    _buildFristAmpel(m),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildSchweregradHeader(m),
                    const SizedBox(height: 16),
                    _buildBeschreibungCard(m),
                    const SizedBox(height: 16),
                    _buildDetailsCard(m),
                    const SizedBox(height: 16),
                    _buildNotizenTimeline(context, ref, m, currentUser),
                    const SizedBox(height: 24),
                    _buildBehobenButton(context, ref, m, currentUser),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile ───────────────────────────────────────────────
  Widget _buildNarrowLayout(
      BuildContext context, WidgetRef ref, Mangel m, AsyncValue currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSchweregradHeader(m),
          const SizedBox(height: 16),
          _buildFotoGalerie(context, m),
          const SizedBox(height: 16),
          _buildBeschreibungCard(m),
          const SizedBox(height: 16),
          _buildDetailsCard(m),
          const SizedBox(height: 16),
          _buildNotizenTimeline(context, ref, m, currentUser),
          const SizedBox(height: 16),
          _buildFristAmpel(m),
          const SizedBox(height: 24),
          _buildBehobenButton(context, ref, m, currentUser),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Foto-Galerie ─────────────────────────────────────────
  Widget _buildFotoGalerie(BuildContext context, Mangel m) {
    final fotos = <String>[
      if (m.fotoUrl != null && m.fotoUrl!.isNotEmpty) m.fotoUrl!,
      if (m.fotoUrl2 != null && m.fotoUrl2!.isNotEmpty) m.fotoUrl2!,
    ];

    if (fotos.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E3E8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 48, color: SuewagColors.quartzgrau50),
            const SizedBox(height: 8),
            Text('Kein Foto vorhanden',
                style: SuewagTextStyles.bodySmall
                    .copyWith(color: SuewagColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: fotos.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () =>
                          _openFullscreenViewer(context, fotos, index),
                      child: Hero(
                        tag: 'foto_$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: fotos.length == 1 ? 16 / 10 : 1,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: const Color(0xFFF0F1F3),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress.expectedTotalBytes !=
                                          null
                                          ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                          : null,
                                      color: SuewagColors.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF0F1F3),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 32, color: Color(0xFFBBC0C7)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app,
                    size: 13, color: SuewagColors.quartzgrau50),
                const SizedBox(width: 4),
                Text(
                  'Antippen zum Vergrößern',
                  style: SuewagTextStyles.bodySmall.copyWith(
                    color: SuewagColors.quartzgrau50,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenViewer(
      BuildContext context, List<String> fotos, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenPhotoViewer(
            fotos: fotos,
            initialIndex: startIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ─── Schweregrad-Header ───────────────────────────────────
  Widget _buildSchweregradHeader(Mangel m) {
    final farbe = _schweregradFarbe(m);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [farbe.withOpacity(0.08), farbe.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: farbe.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: farbe,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: farbe.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.schweregrad.label,
                    style: SuewagTextStyles.headline3
                        .copyWith(color: farbe, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusFarbe(m).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(m.status.label,
                      style: SuewagTextStyles.labelSmall.copyWith(
                          color: _statusFarbe(m),
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ),
          ),
          if (m.status != MangelStatus.behoben)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fristFarbe(m).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    m.istUeberfaellig ? '!' : '${m.restzeit.inDays}',
                    style: SuewagTextStyles.headline3.copyWith(
                        color: _fristFarbe(m),
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                  Text(m.istUeberfaellig ? 'Fällig' : 'Tage',
                      style: SuewagTextStyles.labelSmall.copyWith(
                          color: _fristFarbe(m), fontSize: 9)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Beschreibung ─────────────────────────────────────────
  Widget _buildBeschreibungCard(Mangel m) {
    return _card(
      icon: Icons.description_outlined,
      titel: 'Beschreibung',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.beschreibung,
              style: SuewagTextStyles.bodyMedium
                  .copyWith(height: 1.5, color: const Color(0xFF374151))),
          if (m.ortNotiz != null && m.ortNotiz!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(m.ortNotiz!,
                          style: SuewagTextStyles.bodySmall
                              .copyWith(color: const Color(0xFF6B7280)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Details ──────────────────────────────────────────────
  Widget _buildDetailsCard(Mangel m) {
    return _card(
      icon: Icons.info_outline,
      titel: 'Details',
      child: Column(
        children: [
          _detailRow(Icons.category_outlined, 'Kategorie', m.kategorie.label),
          _detailRow(
              Icons.warning_amber_outlined, 'Schweregrad', m.schweregrad.label,
              color: _schweregradFarbe(m)),
          _detailRow(Icons.info_outline, 'Status', m.status.label,
              color: _statusFarbe(m)),
          _detailRow(Icons.person_outline, 'Zuständig', m.zustaendigName),
          if (m.zustaendigEmail.isNotEmpty)
            _detailRow(Icons.email_outlined, 'Email', m.zustaendigEmail),
          _detailRow(Icons.event_outlined, 'Frist',
              DateFormat('dd.MM.yyyy').format(m.frist),
              color: _fristFarbe(m)),
          _detailRow(Icons.access_time_outlined, 'Erfasst',
              DateFormat('dd.MM.yyyy, HH:mm').format(m.createdAt)),
          if (m.behobenAm != null)
            _detailRow(Icons.check_circle_outline, 'Behoben am',
                DateFormat('dd.MM.yyyy, HH:mm').format(m.behobenAm!),
                color: SuewagColors.leuchtendgruen),
          // Phase 3 FIX 2.4: Behoben-Kommentar anzeigen
          if (m.hatBehobenKommentar)
            _detailRow(Icons.comment_outlined, 'Kommentar',
                m.behobenKommentar!),
        ],
      ),
    );
  }

  Widget _card(
      {required IconData icon, required String titel, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: SuewagColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: SuewagColors.primary),
            ),
            const SizedBox(width: 10),
            Text(titel,
                style: SuewagTextStyles.headline4
                    .copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        SizedBox(
            width: 90,
            child: Text(label,
                style: SuewagTextStyles.bodySmall
                    .copyWith(color: const Color(0xFF9CA3AF)))),
        Expanded(
            child: Text(value,
                style: SuewagTextStyles.bodyMedium.copyWith(
                    color: color ?? const Color(0xFF374151),
                    fontWeight:
                    color != null ? FontWeight.w600 : FontWeight.w400))),
      ]),
    );
  }

  // ─── Frist-Ampel ──────────────────────────────────────────
  Widget _buildFristAmpel(Mangel m) {
    final Color farbe;
    final IconData icon;
    final String titel;
    final String text;

    if (m.status == MangelStatus.behoben) {
      farbe = SuewagColors.leuchtendgruen;
      icon = Icons.check_circle_rounded;
      titel = 'Behoben';
      text = 'Dieser Mangel wurde erfolgreich behoben.';
    } else if (m.istUeberfaellig) {
      farbe = SuewagColors.erdbeerrot;
      icon = Icons.error_rounded;
      titel = 'Überfällig';
      text = 'Die Frist ist abgelaufen!';
    } else if (m.fristLaeuftBaldAb) {
      farbe = SuewagColors.dahliengelb;
      icon = Icons.schedule_rounded;
      titel = 'Frist läuft bald ab';
      text = 'Noch ${m.restzeit.inHours} Stunden.';
    } else {
      farbe = SuewagColors.leuchtendgruen;
      icon = Icons.schedule_rounded;
      final t = m.restzeit.inDays;
      titel = 'Im Zeitplan';
      text = 'Noch $t ${t == 1 ? 'Tag' : 'Tage'}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: farbe.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: farbe.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration:
          BoxDecoration(color: farbe.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: farbe, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titel,
                  style: SuewagTextStyles.labelMedium
                      .copyWith(color: farbe, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(text,
                  style: SuewagTextStyles.bodySmall
                      .copyWith(color: farbe.withOpacity(0.8))),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── Action Buttons (Phase 2 FIX 4.1 + Phase 3 FIX 2.4) ──
  Widget _buildBehobenButton(
      BuildContext context, WidgetRef ref, Mangel m, AsyncValue currentUser) {
    if (m.status == MangelStatus.behoben) return const SizedBox.shrink();
    return currentUser.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return Column(
          children: [
            // "In Bearbeitung" — nur bei Status offen
            if (m.status == MangelStatus.offen) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _setzeInBearbeitung(context, ref),
                  icon: const Icon(Icons.engineering_rounded, size: 20),
                  label: const Text('In Bearbeitung nehmen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SuewagColors.verkehrsorange,
                    side: BorderSide(
                        color: SuewagColors.verkehrsorange.withOpacity(0.5),
                        width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // "Behoben" — immer wenn nicht behoben
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markiereAlsBehoben(context, ref, user.uid),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Als behoben markieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SuewagColors.leuchtendgruen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _setzeInBearbeitung(
      BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentBegehungUserProvider).value;
    if (currentUser == null) return;

    final notizController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('In Bearbeitung nehmen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Möchten Sie diesen Mangel bearbeiten?'),
            const SizedBox(height: 16),
            TextField(
              controller: notizController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notiz (optional)',
                hintText: 'z.B. geplante Maßnahme, Termin...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_add_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: SuewagColors.verkehrsorange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      notizController.dispose();
      return;
    }

    final notizText = notizController.text.trim();
    notizController.dispose();

    try {
      await ref.read(mangelServiceProvider).setzeInBearbeitung(
        begehungId,
        mangel.id,
        bearbeiterUid: currentUser.uid,
        bearbeiterName: currentUser.name,
        notizText: notizText.isNotEmpty ? notizText : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Mangel wird jetzt bearbeitet'),
          backgroundColor: SuewagColors.verkehrsorange,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: SuewagColors.erdbeerrot,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // Phase 3 FIX 2.4: Dialog mit Kommentar-Feld
  Future<void> _markiereAlsBehoben(
      BuildContext context, WidgetRef ref, String uid) async {
    final kommentarController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mangel als behoben markieren?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sind Sie sicher, dass dieser Mangel behoben wurde?'),
            const SizedBox(height: 16),
            // Kommentar-Feld
            TextField(
              controller: kommentarController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Kommentar (optional)',
                hintText: 'Beschreiben Sie die durchgeführte Maßnahme...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.comment_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: SuewagColors.leuchtendgruen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Behoben'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final kommentar = kommentarController.text.trim();
    kommentarController.dispose();

    try {
      await ref
          .read(mangelServiceProvider)
          .markiereAlsBehoben(
        begehungId,
        mangel.id,
        uid,
        kommentar: kommentar.isNotEmpty ? kommentar : null,
        behobenVonName: ref.read(currentBegehungUserProvider).value?.name,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Mangel als behoben markiert'),
          backgroundColor: SuewagColors.leuchtendgruen,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: SuewagColors.erdbeerrot,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ─── Notizen Timeline ──────────────────────────────────
  Widget _buildNotizenTimeline(
      BuildContext context, WidgetRef ref, Mangel m, AsyncValue currentUser) {
    return _card(
      icon: Icons.timeline_outlined,
      titel: 'Verlauf & Notizen (${m.anzahlNotizen})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notiz hinzufügen Button (nur wenn nicht behoben)
          if (m.status != MangelStatus.behoben)
            currentUser.when(
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showNotizDialog(context, ref, user.uid, user.name),
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Notiz hinzufügen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SuewagColors.indiablau,
                        side: BorderSide(
                            color: SuewagColors.indiablau.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Timeline
          if (m.notizen.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Noch keine Einträge',
                  style: SuewagTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF9CA3AF))),
            )
          else
            ...m.notizen.reversed.map((notiz) => _buildNotizEintrag(notiz)),
        ],
      ),
    );
  }

  Widget _buildNotizEintrag(MangelNotiz notiz) {
    final Color farbe;
    final IconData icon;
    switch (notiz.typ) {
      case 'behoben':
        farbe = SuewagColors.leuchtendgruen;
        icon = Icons.check_circle_outline;
        break;
      case 'status_aenderung':
        farbe = SuewagColors.verkehrsorange;
        icon = Icons.swap_horiz;
        break;
      default:
        farbe = SuewagColors.indiablau;
        icon = Icons.comment_outlined;
    }

    final datum = '${notiz.erstelltAm.day.toString().padLeft(2, '0')}.'
        '${notiz.erstelltAm.month.toString().padLeft(2, '0')}.'
        '${notiz.erstelltAm.year} '
        '${notiz.erstelltAm.hour.toString().padLeft(2, '0')}:'
        '${notiz.erstelltAm.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline-Dot
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: farbe.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: farbe),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notiz.autorName.isNotEmpty
                              ? notiz.autorName
                              : 'System',
                          style: SuewagTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151)),
                        ),
                      ),
                      Text(datum,
                          style: SuewagTextStyles.caption
                              .copyWith(color: const Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notiz.text,
                      style: SuewagTextStyles.bodySmall
                          .copyWith(color: const Color(0xFF4B5563))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotizDialog(
      BuildContext context, WidgetRef ref, String uid, String name) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notiz hinzufügen'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Fortschritt, Beobachtung, nächste Schritte...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.edit_note),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: SuewagColors.indiablau,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    final text = controller.text.trim();
    controller.dispose();

    if (confirmed != true || text.isEmpty) return;

    try {
      await ref.read(mangelServiceProvider).addNotiz(
        begehungId,
        mangel.id,
        autorUid: uid,
        autorName: name,
        text: text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Notiz gespeichert'),
          backgroundColor: SuewagColors.indiablau,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: SuewagColors.erdbeerrot,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _schweregradFarbe(Mangel m) => switch (m.schweregrad) {
    MangelSchweregrad.kritisch => SuewagColors.erdbeerrot,
    MangelSchweregrad.mittel => SuewagColors.verkehrsorange,
    MangelSchweregrad.gering => SuewagColors.dahliengelb,
  };

  Color _statusFarbe(Mangel m) => switch (m.status) {
    MangelStatus.offen => SuewagColors.verkehrsorange,
    MangelStatus.inBearbeitung => SuewagColors.dahliengelb,
    MangelStatus.behoben => SuewagColors.leuchtendgruen,
  };

  Color _fristFarbe(Mangel m) {
    if (m.status == MangelStatus.behoben) return SuewagColors.leuchtendgruen;
    if (m.istUeberfaellig) return SuewagColors.erdbeerrot;
    if (m.fristLaeuftBaldAb) return SuewagColors.dahliengelb;
    return SuewagColors.quartzgrau75;
  }
}

// ═════════════════════════════════════════════════════════════
// Fullscreen Photo Viewer — Swipe, Zoom, Hero-Animation
// ═════════════════════════════════════════════════════════════
class _FullscreenPhotoViewer extends StatefulWidget {
  final List<String> fotos;
  final int initialIndex;
  const _FullscreenPhotoViewer(
      {required this.fotos, required this.initialIndex});

  @override
  State<_FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<_FullscreenPhotoViewer> {
  late PageController _pc;
  late int _i;

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex;
    _pc = PageController(initialPage: _i);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Swipeable photos with pinch-to-zoom
          PageView.builder(
            controller: _pc,
            itemCount: widget.fotos.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'foto_$i',
                    child: Image.network(
                      widget.fotos[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              size: 64, color: Colors.white38)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: pad.top + 8,
            right: 16,
            child: Material(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          // Page indicator dots
          if (widget.fotos.length > 1)
            Positioned(
              bottom: pad.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.fotos.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

          // Counter badge
          if (widget.fotos.length > 1)
            Positioned(
              top: pad.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_i + 1} / ${widget.fotos.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}