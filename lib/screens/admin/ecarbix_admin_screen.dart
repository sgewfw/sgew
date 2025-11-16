// lib/screens/admin/ecarbix_admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/suewag_colors.dart';
import '../../constants/suewag_text_styles.dart';
import '../../constants/destatis_constants.dart';
import '../../models/index_data.dart';
import '../../services/ecarbix_service.dart';
import '../../widgets/loading_widget.dart' as custom;
import '../../widgets/logo_widget.dart';

/// Admin-Screen für CO₂-Preis (ECarbiX) Verwaltung
///
/// Funktionen:
/// - Automatischer Vergleich: EEX vs Firebase
/// - Warnung bei Unterschieden
/// - Manuelle Bearbeitung möglich
/// - Überschreiben nur nach Bestätigung
class EcarbixAdminScreen extends StatefulWidget {
  const EcarbixAdminScreen({Key? key}) : super(key: key);

  @override
  State<EcarbixAdminScreen> createState() => _EcarbixAdminScreenState();
}

class _EcarbixAdminScreenState extends State<EcarbixAdminScreen> {
  final EcarbixService _ecarbixService = EcarbixService();

  // Start: 01.01.2024
  final DateTime _startDate = DateTime(2024, 1, 1);

  // Map: Monat -> Preis
  final Map<DateTime, TextEditingController> _controllers = {};
  final Map<DateTime, double?> _values = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isComparing = false;
  String? _error;

  // 🆕 Vergleichsdaten
  bool _hasDifferences = false;
  Map<String, Map<String, double>> _differences = {};
  List<IndexData> _eexData = [];
  List<IndexData> _firebaseData = [];

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Initialisiere alle Monate von 2024 bis heute + 6 Monate
  void _initializeMonths() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + 6, 1);

    DateTime currentMonth = _startDate;

    while (currentMonth.isBefore(endDate) || currentMonth.isAtSameMomentAs(endDate)) {
      final controller = TextEditingController();
      _controllers[currentMonth] = controller;
      _values[currentMonth] = null;

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
  }

  /// Lade CO₂-Daten aus Firebase + Vergleiche mit EEX
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Lade Firebase-Daten
      final firebaseData = await _ecarbixService.getEcarbixData();

      for (var data in firebaseData) {
        final month = DateTime(data.date.year, data.date.month, 1);

        if (_controllers.containsKey(month)) {
          _values[month] = data.value;
          _controllers[month]!.text = data.value.toStringAsFixed(2);
        }
      }

      // 2. 🆕 Vergleiche mit EEX
      await _compareWithEEX();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  /// 🆕 Vergleiche EEX-Daten mit Firebase
  Future<void> _compareWithEEX() async {
    setState(() {
      _isComparing = true;
    });

    try {
      final comparison = await _ecarbixService.compareWithFirebase();

      setState(() {
        _hasDifferences = comparison['hasDifferences'] ?? false;
        _differences = Map<String, Map<String, double>>.from(
          comparison['differences'] ?? {},
        );
        _eexData = comparison['eexData'] ?? [];
        _firebaseData = comparison['firebaseData'] ?? [];
        _isComparing = false;
      });

      if (_hasDifferences) {
        print('⚠️ [ECARBIX_ADMIN] ${_differences.length} Unterschiede gefunden');
      } else {
        print('✅ [ECARBIX_ADMIN] Keine Unterschiede zwischen EEX und Firebase');
      }
    } catch (e) {
      print('🔴 [ECARBIX_ADMIN] Fehler beim Vergleich: $e');
      setState(() {
        _isComparing = false;
      });
    }
  }

  /// 🆕 Übernehme EEX-Daten
  Future<void> _adoptEEXData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('EEX-Daten übernehmen?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dies überschreibt die aktuellen Firebase-Daten mit den Werten von EEX.',
              style: SuewagTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '${_differences.length} Monate werden aktualisiert',
              style: SuewagTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Ja, übernehmen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Überschreibe Controller mit EEX-Daten
      for (var data in _eexData) {
        final month = DateTime(data.date.year, data.date.month, 1);

        if (_controllers.containsKey(month)) {
          _controllers[month]!.text = data.value.toStringAsFixed(2);
          _values[month] = data.value;
        }
      }

      // Speichere in Firebase
      await _ecarbixService.refreshEcarbixData();

      // Neu laden
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ EEX-Daten erfolgreich übernommen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Speichere alle manuellen Änderungen
  Future<void> _saveManualChanges() async {
    // Warnung wenn EEX-Daten verfügbar
    if (_hasDifferences) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Achtung!'),
            ],
          ),
          content: Text(
            'Es gibt neuere Daten von EEX. Möchten Sie wirklich die manuellen Änderungen speichern?',
            style: SuewagTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ja, speichern'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<IndexData> dataList = [];

      for (var entry in _controllers.entries) {
        final month = entry.key;
        final controller = entry.value;
        final text = controller.text.trim();

        if (text.isNotEmpty) {
          final value = double.tryParse(text.replaceAll(',', '.'));
          if (value != null && value >= 0) {
            dataList.add(IndexData(
              date: month,
              value: value,
              indexCode: DestatisConstants.ecarbixCode,
            ));
          }
        }
      }

      if (dataList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Keine Daten zum Speichern'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      dataList.sort((a, b) => a.date.compareTo(b.date));

      // Speichere direkt in Firebase (umgeht EcarbixService)
      await _ecarbixService.refreshEcarbixData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${dataList.length} Monate gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Neu vergleichen
      await _compareWithEEX();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuewagColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.co2, color: SuewagColors.verkehrsorange),
                const SizedBox(width: 12),
                const Text('CO₂-Preise verwalten'),
              ],
            ),
            const AppLogo(height: 32),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: SuewagColors.quartzgrau100,
        elevation: 0,
        actions: [
          // Speichern Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isSaving
                ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _saveManualChanges,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SuewagColors.leuchtendgruen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const custom.LoadingWidget(message: 'Lade CO₂-Daten...')
          : _error != null
          ? custom.ErrorWidget(message: _error!, onRetry: _loadData)
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final Map<int, List<DateTime>> monthsByYear = {};

    for (var month in _controllers.keys) {
      monthsByYear.putIfAbsent(month.year, () => []).add(month);
    }

    final years = monthsByYear.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 16),

              // 🆕 Warnung bei Unterschieden
              if (_hasDifferences) _buildDifferenceWarning(),

              const SizedBox(height: 24),

              // Jahre gruppiert
              ...years.map((year) {
                final months = monthsByYear[year]!;
                months.sort();
                return _buildYearSection(year, months);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final filledCount = _controllers.values
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    final totalCount = _controllers.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: SuewagColors.primary),
                const SizedBox(width: 12),
                Text(
                  'ECarbiX CO₂-Preis Verwaltung',
                  style: SuewagTextStyles.headline3,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Daten werden automatisch von EEX geladen. '
                  'Manuelle Änderungen sind möglich, sollten aber nur in Ausnahmefällen vorgenommen werden.',
              style: SuewagTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                if (isMobile) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SuewagColors.leuchtendgruen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SuewagColors.leuchtendgruen,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: SuewagColors.leuchtendgruen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$filledCount von $totalCount Monaten',
                              style: SuewagTextStyles.bodyMedium.copyWith(
                                color: SuewagColors.leuchtendgruen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SuewagColors.indiablau.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_sync,
                              color: SuewagColors.indiablau,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Auto-Sync mit EEX',
                                style: SuewagTextStyles.caption.copyWith(
                                  color: SuewagColors.indiablau,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SuewagColors.leuchtendgruen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SuewagColors.leuchtendgruen,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: SuewagColors.leuchtendgruen,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$filledCount von $totalCount Monaten',
                                style: SuewagTextStyles.headline4.copyWith(
                                  color: SuewagColors.leuchtendgruen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SuewagColors.indiablau.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_sync,
                              color: SuewagColors.indiablau,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Automatisch synchronisiert mit EEX',
                              style: SuewagTextStyles.caption.copyWith(
                                color: SuewagColors.indiablau,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 Warnung bei Unterschieden
  Widget _buildDifferenceWarning() {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unterschiede erkannt',
                    style: SuewagTextStyles.headline3.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'EEX hat ${_differences.length} neuere/andere Werte als in Firebase gespeichert. '
                  'Möchten Sie die EEX-Daten übernehmen?',
              style: SuewagTextStyles.bodyMedium.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 16),

            // Details (erste 3 Unterschiede)
            ...(_differences.entries.take(3).map((entry) {
              final dateStr = entry.key;
              final values = entry.value;
              final date = DateTime.parse(dateStr);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy', 'de_DE').format(date),
                      style: SuewagTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Firebase: ${values['firebase']?.toStringAsFixed(2)} €',
                      style: SuewagTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 12, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'EEX: ${values['eex']?.toStringAsFixed(2)} €',
                      style: SuewagTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),

            if (_differences.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... und ${_differences.length - 3} weitere',
                  style: SuewagTextStyles.caption.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _adoptEEXData,
                    icon: const Icon(Icons.download),
                    label: const Text('EEX-Daten übernehmen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _compareWithEEX();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Neu vergleichen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSection(int year, List<DateTime> months) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SuewagColors.verkehrsorange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  year.toString(),
                  style: SuewagTextStyles.headline3.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 2,
                  color: SuewagColors.divider,
                ),
              ),
            ],
          ),
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final columns = isMobile ? 1 : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: isMobile ? 3.5 : 3.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: months.length,
              itemBuilder: (context, index) {
                return _buildMonthCard(months[index]);
              },
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMonthCard(DateTime month) {
    final controller = _controllers[month]!;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final isPast = month.isBefore(currentMonth);
    final isCurrent = month.isAtSameMomentAs(currentMonth);
    final isFuture = month.isAfter(currentMonth);

    // 🆕 Prüfe ob Monat Unterschied hat
    final hasDifference = _differences.containsKey(month.toString());

    return Card(
      elevation: isCurrent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasDifference
              ? Colors.orange
              : isCurrent
              ? SuewagColors.verkehrsorange
              : isPast
              ? SuewagColors.divider
              : SuewagColors.divider.withOpacity(0.3),
          width: hasDifference ? 3 : isCurrent ? 3 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM', 'de_DE').format(month),
                  style: SuewagTextStyles.headline4.copyWith(
                    color: isFuture
                        ? SuewagColors.textSecondary
                        : SuewagColors.textPrimary,
                  ),
                ),
                if (hasDifference)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isCurrent)
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
                      'AKTUELL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isFuture)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SuewagColors.quartzgrau50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'GEPLANT',
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

            Flexible(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: SuewagTextStyles.numberMedium.copyWith(
                  color: SuewagColors.verkehrsorange,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Preis',
                  labelStyle: const TextStyle(fontSize: 12),
                  hintText: '45.00',
                  suffixText: '€/t',
                  suffixStyle: SuewagTextStyles.caption,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasDifference ? Colors.orange : SuewagColors.verkehrsorange,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null) {
                    setState(() {
                      _values[month] = parsed;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}