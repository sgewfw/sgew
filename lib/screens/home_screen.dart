// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../extensions/text_style_extensions.dart';
import '../services/kostenvergleich_setup_service.dart';
import '../widgets/waermeanteil_admin_dialog.dart';
import 'preisentwicklung_screen.dart';
import 'arbeitspreis_screen.dart';
import 'kostenvergleich_screen.dart';
import 'admin/kostenvergleich_admin_home_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // 🆕 Admin-Zugang - Anzahl Klicks tracken
  static int _logoClickCount = 0;
  static DateTime? _lastClickTime;

  void _onLogoTap(BuildContext context) {
    final now = DateTime.now();

    // Reset counter wenn mehr als 2 Sekunden vergangen
    if (_lastClickTime == null ||
        now.difference(_lastClickTime!) > const Duration(seconds: 2)) {
      _logoClickCount = 0;
    }

    _logoClickCount++;
    _lastClickTime = now;

    // Nach 5 Klicks in 2 Sekunden: Admin-Menü
    if (_logoClickCount >= 5) {
      _logoClickCount = 0;
      _showAdminMenu(context);
    }
  }

// In home_screen.dart - im Admin-Dialog ergänzen:

  void _showAdminMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: SuewagColors.primary),
            const SizedBox(width: 12),
            const Text('Admin-Bereich'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.thermostat),
              title: const Text('Wärmeanteil verwalten'),
              subtitle: const Text('Wärmeanteile für Arbeitspreis'),
              onTap: () {
                Navigator.pop(context);
                _showWaermeanteilDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Kostenvergleich verwalten'),
              subtitle: const Text('Jahre und Stammdaten pflegen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KostenvergleichAdminHomeScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            // 🆕 Setup-Button
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('Initial-Setup ausführen'),
              subtitle: const Text('2025 Daten neu erstellen'),
              onTap: () {
                Navigator.pop(context);
                _executeSetup(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSetup(BuildContext context) async {
    // Bestätigung
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initial-Setup'),
        content: const Text(
          'Dies erstellt die 2025 Stammdaten neu. Fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ja, erstellen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final setupService = KostenvergleichSetupService();
      await setupService.pruefeUndErstelleInitialDaten();

      if (context.mounted) {
        Navigator.pop(context); // Loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Setup erfolgreich abgeschlossen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWaermeanteilDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WaermeanteilAdminDialog(
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Wärmeanteil gespeichert'),
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Logo - 🆕 Mit Tap-Handler für Admin-Zugang (5x klicken)
            GestureDetector(
              onTap: () => _onLogoTap(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Willkommens-Text
            _buildWelcomeSection(),

            const SizedBox(height: 32),

            // Feature Cards
            _buildFeatureCard(
              context: context,
              title: 'Indexentwicklung',
              description:
              'Verfolgen Sie die Entwicklung der Energie-Indizes für Erdgas, Strom sowie den Wärmepreisindex',
              icon: Icons.show_chart,
              color: SuewagColors.fasergruen,
              available: true,
              badge: null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreisentwicklungScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildFeatureCard(
              context: context,
              title: 'Arbeitspreisentwicklung',
              description:
              'Interaktive Visualisierung unserer verwendeten Preisformel',
              icon: Icons.calculate,
              color: SuewagColors.indiablau,
              available: true,
              badge: null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArbeitspreisScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 🆕 NEU: Kostenvergleich
            _buildFeatureCard(
              context: context,
              title: 'Kostenvergleich',
              description:
              'Vergleichen Sie die Kosten unserer Fernwärmelösung mit einer Wärmepumpe für ein Einfamilienhaus',
              icon: Icons.compare_arrows,
              color: SuewagColors.verkehrsorange,
              available: true,
              badge: null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KostenvergleichScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Info-Bereich
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SuewagColors.primary.withOpacity(0.3),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.thermostat,
                  size: 32,
                  color: SuewagColors.quartzgrau100,
                ),
              ),
              const SizedBox(width: 16),
               Expanded(
                child: Text(
                  'Willkommen',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: SuewagColors.quartzgrau100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Informieren Sie sich über die Entwicklung der Energiepreise und verstehen Sie die Zusammenhänge Ihrer Fernwärmekosten.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool available,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: available ? color : SuewagColors.divider,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: available
                      ? color.withOpacity(0.1)
                      : SuewagColors.quartzgrau10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: available ? color : SuewagColors.textDisabled,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: SuewagTextStyles.headline3.copyWith(
                              color: available
                                  ? SuewagColors.textPrimary
                                  : SuewagColors.textDisabled,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SuewagColors.leuchtendgruen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (!available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SuewagColors.verkehrsorange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BALD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: SuewagTextStyles.bodySmall.copyWith(
                        color: available
                            ? SuewagColors.textSecondary
                            : SuewagColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: available
                    ? SuewagColors.textSecondary
                    : SuewagColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuewagColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: SuewagColors.indiablau,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Info',
                style: SuewagTextStyles.headline4,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sie haben Fragen zu den gezeigten Daten?',
            style: SuewagTextStyles.bodyMedium,
          ),


          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _launchEmail('fernwaerme@suewag.de'),
                child: Text(
                  'fernwaerme@suewag.de',
                  style: TextStyle(
                    color: SuewagColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),



        ],
      ),
    );
  }
  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: SuewagColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: SuewagTextStyles.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyleExtension(SuewagTextStyles.bodySmall).semiBold(),
          ),
        ),
      ],
    );
  }
}