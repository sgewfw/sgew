// lib/screens/admin/kostenvergleich_jahr_editor_screen.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../services/kostenvergleich_firebase_service.dart';
import '../../models/kostenvergleich_data.dart';

import 'kostenvergleich_edit_table_widget.dart';

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
    extends State<KostenvergleichJahrEditorScreen> {
  final KostenvergleichFirebaseService _service =
  KostenvergleichFirebaseService();

  KostenvergleichJahr? _stammdaten;
  KostenvergleichJahr? _originalStammdaten; // Für Änderungserkennung
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final daten = await _service.ladeStammdaten(widget.jahr);

      if (mounted) {
        setState(() {
          _stammdaten = daten;
          _originalStammdaten = daten;
          _isLoading = false;
          _hasChanges = false;
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
          content: SingleChildScrollView(
            child: Column(
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
          _originalStammdaten = aktualisiert;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gespeichert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
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
            : KostenvergleichEditTableWidget(
          initialStammdaten: _stammdaten!,
          onChanged: _onDataChanged,
        ),
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
        // Speichern-Button (immer sichtbar, aber disabled wenn keine Änderungen)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: _hasChanges ? _speichern : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Speichern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges ? SuewagColors.primary : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
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