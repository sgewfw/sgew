// lib/widgets/waermeanteil_admin_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/waermepreis_data.dart';

class WaermeanteilAdminDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const WaermeanteilAdminDialog({
    Key? key,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<WaermeanteilAdminDialog> createState() => _WaermeanteilAdminDialogState();
}

class _WaermeanteilAdminDialogState extends State<WaermeanteilAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jahrController = TextEditingController(text: '2025');

  int _selectedQuartal = 4;
  double _anteilGas = 0.65; // 65% Standard
  bool _isSaving = false;

  @override
  void dispose() {
    _jahrController.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final jahr = int.parse(_jahrController.text);
      final data = WaermeanteilData(
        jahr: jahr,
        quartal: _selectedQuartal,
        anteilGas: _anteilGas,
      );

      final docId = '$jahr-q$_selectedQuartal';

      await FirebaseFirestore.instance
          .collection('waermeanteile')
          .doc(docId)
          .set(data.toMap());

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Wärmeanteil für Q$_selectedQuartal $jahr gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: SuewagColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Wärmeanteil anlegen',
                    style: SuewagTextStyles.headline3,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Jahr
              TextFormField(
                controller: _jahrController,
                decoration: InputDecoration(
                  labelText: 'Jahr',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Jahr eingeben';
                  }
                  final jahr = int.tryParse(value);
                  if (jahr == null || jahr < 2020 || jahr > 2050) {
                    return 'Ungültiges Jahr';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quartal
              DropdownButtonFormField<int>(
                value: _selectedQuartal,
                decoration: InputDecoration(
                  labelText: 'Quartal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.pie_chart),
                ),
                items: [1, 2, 3, 4].map((q) {
                  return DropdownMenuItem(
                    value: q,
                    child: Text('Q$q'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedQuartal = value!);
                },
              ),
              const SizedBox(height: 24),

              // Anteil Gas (Slider)
              Text(
                'Anteil Wärme aus Erdgas (yₙ)',
                style: SuewagTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _anteilGas,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      activeColor: SuewagColors.erdgas,
                      onChanged: (value) {
                        setState(() => _anteilGas = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${(_anteilGas * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SuewagColors.erdgas,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info-Box mit Berechnung
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SuewagColors.indiablau.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: SuewagColors.erdgas,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anteil Erdgas: ${(_anteilGas * 100).toStringAsFixed(1)}%',
                          style: SuewagTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 16,
                          color: SuewagColors.chartGewerbe,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anteil Strom: ${((1 - _anteilGas) * 100).toStringAsFixed(1)}%',
                          style: SuewagTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _speichern,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Speichert...' : 'Speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuewagColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}