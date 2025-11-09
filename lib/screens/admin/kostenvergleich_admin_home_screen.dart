// lib/screens/admin/kostenvergleich_admin_home_screen.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../services/kostenvergleich_firebase_service.dart';
import '../../models/kostenvergleich_data.dart';
import 'kostenvergleich_jahr_editor_screen.dart';

class KostenvergleichAdminHomeScreen extends StatefulWidget {
  const KostenvergleichAdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<KostenvergleichAdminHomeScreen> createState() =>
      _KostenvergleichAdminHomeScreenState();
}

class _KostenvergleichAdminHomeScreenState
    extends State<KostenvergleichAdminHomeScreen> {
  final KostenvergleichFirebaseService _service =
  KostenvergleichFirebaseService();

  List<int> _verfuegbareJahre = [];
  int? _aktivesJahr;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final jahre = await _service.ladeVerfuegbareJahre();
      final aktiv = await _service.getAktuellesJahr();

      if (mounted) {
        setState(() {
          _verfuegbareJahre = jahre;
          _aktivesJahr = aktiv;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _neuesJahrAnlegen() async {
    final neuesJahr = DateTime.now().year + 1;

    // Dialog: Aus welchem Jahr kopieren?
    final vorjahr = await showDialog<int>(
      context: context,
      builder: (context) => _VorjahrAuswahlDialog(
        verfuegbareJahre: _verfuegbareJahre,
        neuesJahr: neuesJahr,
      ),
    );

    if (vorjahr == null) return;

    // Kopiere Vorjahr
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _service.kopiereVorjahr(
        neuesJahr: neuesJahr,
        vorjahr: vorjahr,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog schließen

        await _loadData();

        // Öffne Editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KostenvergleichJahrEditorScreen(jahr: neuesJahr),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog schließen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Kopieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _jahrLoeschen(int jahr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jahr löschen'),
        content: Text('Jahr $jahr wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.loescheJahr(jahr);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jahr $jahr gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _jahrAktivieren(int jahr) async {
    try {
      await _service.aktiviereJahr(jahr);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jahr $jahr aktiviert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: const Text(
          'Kostenvergleich Admin',
          style: SuewagTextStyles.headline2,
        ),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.quartzgrau100,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neuesJahrAnlegen,
        icon: const Icon(Icons.add),
        label: const Text('Neues Jahr'),
        backgroundColor: SuewagColors.primary,
      ),
    );
  }

  Widget _buildBody() {
    if (_verfuegbareJahre.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info-Card
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Jahre-Liste
              Text(
                'Verfügbare Jahre',
                style: SuewagTextStyles.headline3,
              ),
              const SizedBox(height: 16),

              ...(_verfuegbareJahre.map((jahr) => _buildJahrCard(jahr))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SuewagColors.indiablau.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.indiablau),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: SuewagColors.indiablau, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kostenvergleich Verwaltung',
                  style: SuewagTextStyles.headline4.copyWith(
                    color: SuewagColors.indiablau,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verwalten Sie Stammdaten für verschiedene Jahre. Nur ein Jahr kann gleichzeitig aktiv sein und wird den Benutzern angezeigt.',
                  style: SuewagTextStyles.bodyMedium,
                ),
                if (_aktivesJahr != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AKTIV: $_aktivesJahr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJahrCard(int jahr) {
    final istAktiv = jahr == _aktivesJahr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: istAktiv ? Colors.green : SuewagColors.divider,
          width: istAktiv ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: istAktiv
                    ? Colors.green.withOpacity(0.1)
                    : SuewagColors.quartzgrau10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: istAktiv ? Colors.green : SuewagColors.quartzgrau100,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Jahr $jahr',
                        style: SuewagTextStyles.headline3,
                      ),
                      const SizedBox(width: 8),
                      if (istAktiv)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AKTIV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    istAktiv
                        ? 'Wird Benutzern angezeigt'
                        : 'Entwurf / Archiviert',
                    style: SuewagTextStyles.bodySmall.copyWith(
                      color: SuewagColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Aktionen
            Row(
              children: [
                // Bearbeiten
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Bearbeiten',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            KostenvergleichJahrEditorScreen(jahr: jahr),
                      ),
                    ).then((_) => _loadData());
                  },
                ),

                // Aktivieren (wenn nicht schon aktiv)
                if (!istAktiv)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Aktivieren',
                    color: Colors.green,
                    onPressed: () => _jahrAktivieren(jahr),
                  ),

                // Löschen (nur wenn nicht aktiv)
                if (!istAktiv)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Löschen',
                    color: Colors.red,
                    onPressed: () => _jahrLoeschen(jahr),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: SuewagColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Jahre vorhanden',
            style: SuewagTextStyles.headline3.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie ein neues Jahr über den Button unten rechts',
            style: SuewagTextStyles.bodyMedium.copyWith(
              color: SuewagColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog zur Auswahl des Vorjahres
class _VorjahrAuswahlDialog extends StatelessWidget {
  final List<int> verfuegbareJahre;
  final int neuesJahr;

  const _VorjahrAuswahlDialog({
    required this.verfuegbareJahre,
    required this.neuesJahr,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Neues Jahr $neuesJahr anlegen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aus welchem Jahr sollen die Daten kopiert werden?'),
          const SizedBox(height: 16),
          ...verfuegbareJahre.map((jahr) {
            return ListTile(
              title: Text('Jahr $jahr'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.pop(context, jahr),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}