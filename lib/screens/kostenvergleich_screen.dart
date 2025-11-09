// lib/screens/kostenvergleich_screen.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../services/kostenvergleich_firebase_service.dart';
import '../services/kostenvergleich_berechnung_service.dart';
import '../models/kostenvergleich_data.dart';
import '../models/kostenvergleich_ergebnis.dart';
import '../widgets/loading_widget.dart' as custom;
import '../widgets/logo_widget.dart';
import 'kostenvergleich_standard_tab.dart';
import 'kostenvergleich_rechner_tab.dart';
import 'kostenvergleich_info_screen.dart';

class KostenvergleichScreen extends StatefulWidget {
  const KostenvergleichScreen({Key? key}) : super(key: key);

  @override
  State<KostenvergleichScreen> createState() => _KostenvergleichScreenState();
}

class _KostenvergleichScreenState extends State<KostenvergleichScreen>
    with SingleTickerProviderStateMixin {
  final KostenvergleichFirebaseService _firebaseService =
  KostenvergleichFirebaseService();
  final KostenvergleichBerechnungService _berechnungService =
  KostenvergleichBerechnungService();

  late TabController _tabController;

  KostenvergleichJahr? _stammdaten;
  KostenvergleichErgebnis? _ergebnis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lade aktuelles Jahr
      final aktuellesJahr = await _firebaseService.getAktuellesJahr();

      if (aktuellesJahr == null) {
        throw Exception('Kein aktives Jahr konfiguriert');
      }

      // Lade Stammdaten
      final stammdaten = await _firebaseService.ladeStammdaten(aktuellesJahr);

      if (stammdaten == null) {
        throw Exception('Stammdaten für Jahr $aktuellesJahr nicht gefunden');
      }

      // Berechne Ergebnisse
      final ergebnis = _berechnungService.berechneVergleich(
        stammdaten: stammdaten,
      );

      if (mounted) {
        setState(() {
          _stammdaten = stammdaten;
          _ergebnis = ergebnis;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Fehler beim Laden: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Lade Kostenvergleich...')
          : _error != null
          ? custom.ErrorWidget(message: _error!, onRetry: _loadData)
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Vergleich',
                style: SuewagTextStyles.headline2,
              ),
              const SizedBox(width: 12),
              // ✅ NUR anzeigen wenn Daten vorhanden
              if (_stammdaten != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SuewagColors.indiablau.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Jahr ${_stammdaten!.jahr}', // ← Jetzt sicher!
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: SuewagColors.indiablau,
                    ),
                  ),
                ),
            ],
          ),
          if (_stammdaten != null) ...[
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Informationen & Quellen',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KostenvergleichInfoScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const AppLogo(height: 32),
              ],
            ),
          ],
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: SuewagColors.quartzgrau100,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: SuewagColors.fasergruen,
        indicatorWeight: 3,
        labelColor: SuewagColors.quartzgrau100,
        unselectedLabelColor: SuewagColors.quartzgrau50,
        tabs: const [
          Tab(
            icon: Icon(Icons.bar_chart),
            text: 'Standard-Vergleich',
          ),
          Tab(
            icon: Icon(Icons.calculate),
            text: 'Szenario-Rechner',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight, // 🆕 Nutze volle verfügbare Höhe
          child: TabBarView(
            controller: _tabController,
            children: [
              KostenvergleichStandardTab(
                stammdaten: _stammdaten!,
                ergebnis: _ergebnis!,
              ),
              KostenvergleichRechnerTab(
                stammdaten: _stammdaten!,
                berechnungService: _berechnungService,
              ),
            ],
          ),
        );
      },
    );
  }
}