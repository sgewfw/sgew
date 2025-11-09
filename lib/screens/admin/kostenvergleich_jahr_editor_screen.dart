// lib/screens/admin/kostenvergleich_jahr_editor_screen.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../services/kostenvergleich_firebase_service.dart';
import '../../models/kostenvergleich_data.dart';
import 'tabs/grunddaten_tab.dart';
import 'tabs/waermepumpe_tab.dart';
import 'tabs/waermenetz_tab.dart';

class KostenvergleichJahrEditorScreen extends StatefulWidget {
  final int jahr;

  const KostenvergleichJahrEditorScreen({
    Key? key,
    required this.jahr,
  }) : super(key: key);

  @override
  State<KostenvergleichJahrEditorScreen> createState() =>
      _KostenvergleichJahrEditorScreenState();
}

class _KostenvergleichJahrEditorScreenState
    extends State<KostenvergleichJahrEditorScreen>
    with SingleTickerProviderStateMixin {
  final KostenvergleichFirebaseService _service =
  KostenvergleichFirebaseService();

  late TabController _tabController;

  KostenvergleichJahr? _stammdaten;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final daten = await _service.ladeStammdaten(widget.jahr);

      if (mounted) {
        setState(() {
          _stammdaten = daten;
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

  Future<void> _speichern() async {
    if (_stammdaten == null) return;

    // Validierung
    final fehler = _service.validiereStammdaten(_stammdaten!);
    if (fehler.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Validierungsfehler'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fehler
                .map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(f)),
                ],
              ),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Speichern
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final aktualisiert = _stammdaten!.copyWith(
        aktualisiertAm: DateTime.now(),
      );

      await _service.speichereStammdaten(aktualisiert);

      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog
        setState(() {
          _stammdaten = aktualisiert;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDataChanged(KostenvergleichJahr neueStammdaten) {
    setState(() {
      _stammdaten = neueStammdaten;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_hasChanges) return true;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ungespeicherte Änderungen'),
            content: const Text(
              'Es gibt ungespeicherte Änderungen. Wirklich verlassen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Verwerfen'),
              ),
            ],
          ),
        );

        return confirm ?? false;
      },
      child: Scaffold(
        backgroundColor: SuewagColors.background,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stammdaten == null
            ? _buildErrorState()
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Text(
            'Jahr ${widget.jahr} bearbeiten',
            style: SuewagTextStyles.headline2,
          ),
          if (_hasChanges) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NICHT GESPEICHERT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: SuewagColors.quartzgrau100,
      elevation: 0,
      actions: [
        if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Speichern',
            onPressed: _speichern,
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: SuewagColors.fasergruen,
        labelColor: SuewagColors.quartzgrau100,
        unselectedLabelColor: SuewagColors.quartzgrau50,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Grunddaten'),
          Tab(text: 'Wärmepumpe'),
          Tab(text: 'Wärmenetz ohne ÜGS'),
          Tab(text: 'Wärmenetz Kunde'),
          Tab(text: 'Wärmenetz Süwag'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        GrunddatenTab(
          stammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
        WaermepumpeTab(
          stammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
        WaermenetzTab(
          szenarioId: 'waermenetzOhneUGS',
          stammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
        WaermenetzTab(
          szenarioId: 'waermenetzKunde',
          stammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
        WaermenetzTab(
          szenarioId: 'waermenetzSuewag',
          stammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Jahr ${widget.jahr} konnte nicht geladen werden',
            style: SuewagTextStyles.headline3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}