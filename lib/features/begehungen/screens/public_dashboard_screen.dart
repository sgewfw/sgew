import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/suewag_colors.dart';
import '../models/abteilung_model.dart';
import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

// =============================================================
// Theme Konstanten fuer das Display-Dashboard
// =============================================================
class _DashboardColors {
  final Color bgGradientTop;
  final Color bgGradientMid;
  final Color bgGradientBottom;
  final Color bgCard;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textMuted;
  final Color textDimmed;
  final Color logoContainerBg;
  final Color shaderStart;
  final Color shaderEnd;

  const _DashboardColors({
    required this.bgGradientTop,
    required this.bgGradientMid,
    required this.bgGradientBottom,
    required this.bgCard,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textMuted,
    required this.textDimmed,
    required this.logoContainerBg,
    required this.shaderStart,
    required this.shaderEnd,
  });

  static const dark = _DashboardColors(
    bgGradientTop: Color(0xFF0D1117),
    bgGradientMid: Color(0xFF0F1923),
    bgGradientBottom: Color(0xFF0D1117),
    bgCard: Color(0xFF161B22),
    borderSubtle: Color(0xFF30363D),
    textPrimary: Color(0xFFE6EDF3),
    textMuted: Color(0xFF8B949E),
    textDimmed: Color(0xFF484F58),
    logoContainerBg: Colors.white,
    shaderStart: Color(0xFFE6EDF3),
    shaderEnd: Color(0xFFB0BAC5),
  );

  static const light = _DashboardColors(
    bgGradientTop: Color(0xFFF8F9FA),
    bgGradientMid: Color(0xFFFFFFFF),
    bgGradientBottom: Color(0xFFF4F5F6),
    bgCard: Colors.white,
    borderSubtle: Color(0xFFE1E4E8),
    textPrimary: Color(0xFF24292F),
    textMuted: Color(0xFF57606A),
    textDimmed: Color(0xFF8B949E),
    logoContainerBg: Color(0xFFF6F8FA),
    shaderStart: Color(0xFF24292F),
    shaderEnd: Color(0xFF57606A),
  );
}

class PublicDashboardScreen extends ConsumerWidget {
  const PublicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abteilungen = ref.watch(abteilungenProvider);
    final gesamtBegehungen = ref.watch(gesamtBegehungenProvider);
    final gesamtOffene = ref.watch(gesamtOffeneMaengelProvider);
    final isDark = ref.watch(darkModeProvider);
    final colors = isDark ? _DashboardColors.dark : _DashboardColors.light;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.bgGradientTop,
            colors.bgGradientMid,
            colors.bgGradientBottom,
          ],
        ),
      ),
      child: abteilungen.when(
        data: (list) {
          if (list.isEmpty) return _buildEmptyState(ref, colors);
          return _buildDashboard(
              context, list, gesamtBegehungen, gesamtOffene, colors);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SuewagColors.verkehrsorange),
        ),
        error: (error, _) => Center(
          child: Text('Fehler: $error',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<Abteilung> abteilungen,
    int gesamtBegehungen,
    int gesamtOffene,
    _DashboardColors colors,
  ) {
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 48 : 20,
        vertical: isLargeScreen ? 32 : 16,
      ),
      child: Column(
        children: [
          // ===== HEADER: Logo + Mission Zero =====
          _buildHeader(isLargeScreen, colors),
          SizedBox(height: isLargeScreen ? 40 : 24),

          // ===== KPI CARDS =====
          _buildKPIRow(gesamtBegehungen, gesamtOffene, abteilungen.length,
              isLargeScreen, colors),
          SizedBox(height: isLargeScreen ? 40 : 24),

          // ===== MAIN CONTENT: Fortschritt + Status =====
          if (isLargeScreen)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child:
                        _buildFortschrittSection(abteilungen, true, colors),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildAmpelSection(abteilungen, true, colors),
                  ),
                ],
              ),
            )
          else ...[
            _buildFortschrittSection(abteilungen, false, colors),
            const SizedBox(height: 24),
            _buildAmpelSection(abteilungen, false, colors),
          ],

          SizedBox(height: isLargeScreen ? 32 : 20),

          // ===== FOOTER STATUS BANNER =====
          _buildStatusBanner(gesamtOffene, isLargeScreen),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HEADER
  // -------------------------------------------------------
  Widget _buildHeader(bool isLarge, _DashboardColors colors) {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.logoContainerBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            height: isLarge ? 80 : 48,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isLarge ? 24 : 16),
        // Titel
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colors.shaderStart, colors.shaderEnd],
          ).createShader(bounds),
          child: Text(
            'UNTERNEHMENSFORTSCHRITT UND STATUS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLarge ? 28 : 18,
              fontWeight: FontWeight.w700,
              letterSpacing: isLarge ? 4 : 2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mission Zero \u2014 Ziel: 0 Arbeitsunf\u00e4lle',
          style: TextStyle(
            fontSize: isLarge ? 16 : 13,
            color: colors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // KPI CARDS
  // -------------------------------------------------------
  Widget _buildKPIRow(int begehungen, int offene, int abteilungen,
      bool isLarge, _DashboardColors colors) {
    return Row(
      children: [
        Expanded(
          child: _KPICard(
            icon: Icons.verified_user,
            wert: '$begehungen',
            label: 'Begehungen',
            sublabel: 'Durchgef\u00fchrt',
            farbe: SuewagColors.leuchtendgruen,
            isLarge: isLarge,
            colors: colors,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KPICard(
            icon: Icons.warning_amber_rounded,
            wert: '$offene',
            label: 'Offene M\u00e4ngel',
            sublabel:
                offene == 0 ? 'Kein Handlungsbedarf' : 'Handlungsbedarf',
            farbe: offene > 0
                ? SuewagColors.verkehrsorange
                : SuewagColors.leuchtendgruen,
            isLarge: isLarge,
            colors: colors,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KPICard(
            icon: Icons.apartment_rounded,
            wert: '$abteilungen',
            label: 'Abteilungen',
            sublabel: 'Aktiv',
            farbe: SuewagColors.alpenblau,
            isLarge: isLarge,
            colors: colors,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // JAHRESFORTSCHRITT SECTION
  // -------------------------------------------------------
  Widget _buildFortschrittSection(
      List<Abteilung> abteilungen, bool isLarge, _DashboardColors colors) {
    return _ThemedCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: SuewagColors.alpenblau,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jahresfortschritt',
                style: TextStyle(
                  fontSize: isLarge ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'YTD',
                style: TextStyle(
                  fontSize: isLarge ? 14 : 12,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...abteilungen.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FortschrittsRow(
                    abteilung: a, isLarge: isLarge, colors: colors),
              )),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // AMPEL SECTION
  // -------------------------------------------------------
  Widget _buildAmpelSection(
      List<Abteilung> abteilungen, bool isLarge, _DashboardColors colors) {
    final alleGruen = abteilungen.every((a) => a.offeneMaengel == 0);

    return _ThemedCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: alleGruen
                      ? SuewagColors.leuchtendgruen
                      : SuewagColors.verkehrsorange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'M\u00e4ngel-Status',
                style: TextStyle(
                  fontSize: isLarge ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...abteilungen.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    _AmpelRow(abteilung: a, isLarge: isLarge, colors: colors),
              )),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // STATUS BANNER
  // -------------------------------------------------------
  Widget _buildStatusBanner(int offene, bool isLarge) {
    final alleGruen = offene == 0;
    final farbe =
        alleGruen ? SuewagColors.leuchtendgruen : SuewagColors.verkehrsorange;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isLarge ? 20 : 14,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            farbe.withAlpha(25),
            farbe.withAlpha(40),
            farbe.withAlpha(25),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: farbe.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isLarge ? 14 : 10,
            height: isLarge ? 14 : 10,
            decoration: BoxDecoration(
              color: farbe,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: farbe.withAlpha(120),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            alleGruen
                ? 'ALLE BEREICHE: STATUS GR\u00dcN'
                : '$offene OFFENE M\u00c4NGEL \u2014 HANDLUNGSBEDARF',
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: farbe,
              letterSpacing: isLarge ? 3 : 1.5,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: isLarge ? 14 : 10,
            height: isLarge ? 14 : 10,
            decoration: BoxDecoration(
              color: farbe,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: farbe.withAlpha(120),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------
  Widget _buildEmptyState(WidgetRef ref, _DashboardColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 64, color: colors.textDimmed),
          const SizedBox(height: 16),
          Text(
            'Noch keine Abteilungen angelegt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ein Admin muss zuerst die Abteilungen initialisieren.',
            style: TextStyle(color: colors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final service = ref.read(abteilungServiceProvider);
              await service.seedAbteilungen();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Abteilungen anlegen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SuewagColors.verkehrsorange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// KPI CARD
// =============================================================
class _KPICard extends StatelessWidget {
  final IconData icon;
  final String wert;
  final String label;
  final String sublabel;
  final Color farbe;
  final bool isLarge;
  final _DashboardColors colors;

  const _KPICard({
    required this.icon,
    required this.wert,
    required this.label,
    required this.sublabel,
    required this.farbe,
    required this.isLarge,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: farbe.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isLarge ? 12 : 8),
                decoration: BoxDecoration(
                  color: farbe.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: farbe.withAlpha(40)),
                ),
                child: Icon(icon, color: farbe, size: isLarge ? 28 : 20),
              ),
              const Spacer(),
              CustomPaint(
                size: Size(isLarge ? 60 : 40, isLarge ? 24 : 16),
                painter: _SparklinePainter(farbe),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 10),
          Text(
            wert,
            style: TextStyle(
              fontSize: isLarge ? 48 : 28,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 14 : 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: isLarge ? 12 : 10,
              color: farbe,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// THEMED CARD CONTAINER
// =============================================================
class _ThemedCard extends StatelessWidget {
  final Widget child;
  final _DashboardColors colors;

  const _ThemedCard({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: child,
    );
  }
}

// =============================================================
// FORTSCHRITTS-ROW
// =============================================================
class _FortschrittsRow extends StatelessWidget {
  final Abteilung abteilung;
  final bool isLarge;
  final _DashboardColors colors;

  const _FortschrittsRow({
    required this.abteilung,
    required this.isLarge,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final prozent = abteilung.jahresZiel > 0
        ? (abteilung.begehungenDiesesJahr / abteilung.jahresZiel)
            .clamp(0.0, 1.0)
        : 0.0;
    final farbe = prozent >= 1.0
        ? SuewagColors.leuchtendgruen
        : prozent >= 0.5
            ? SuewagColors.alpenblau
            : SuewagColors.verkehrsorange;

    return Row(
      children: [
        SizedBox(
          width: isLarge ? 180 : 120,
          child: Text(
            abteilung.name,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: isLarge ? 10 : 7,
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: prozent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    colors: [farbe.withAlpha(180), farbe],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: farbe.withAlpha(60),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: isLarge ? 48 : 38,
          child: Text(
            '${(prozent * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: isLarge ? 56 : 44,
          child: Text(
            abteilung.jahresZiel > 0
                ? '${abteilung.begehungenDiesesJahr}/${abteilung.jahresZiel}'
                : '${abteilung.begehungenDiesesJahr}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// AMPEL-ROW
// =============================================================
class _AmpelRow extends StatelessWidget {
  final Abteilung abteilung;
  final bool isLarge;
  final _DashboardColors colors;

  const _AmpelRow({
    required this.abteilung,
    required this.isLarge,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final offen = abteilung.offeneMaengel;
    final farbe = offen == 0
        ? SuewagColors.leuchtendgruen
        : offen > 5
            ? SuewagColors.erdbeerrot
            : SuewagColors.dahliengelb;
    final statusText =
        offen == 0 ? 'Keine offenen M\u00e4ngel' : '$offen offen';

    return Row(
      children: [
        Container(
          width: isLarge ? 12 : 10,
          height: isLarge ? 12 : 10,
          decoration: BoxDecoration(
            color: farbe,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: farbe.withAlpha(100),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            abteilung.name,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            fontSize: isLarge ? 13 : 11,
            color: farbe,
            fontWeight: FontWeight.w500,
            fontStyle: offen == 0 ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// DEKORATIVE SPARKLINE (rein kosmetisch)
// =============================================================
class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(100)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [0.5, 0.3, 0.6, 0.2, 0.7, 0.4, 0.8, 0.5];

    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
