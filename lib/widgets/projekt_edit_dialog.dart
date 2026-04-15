// lib/widgets/projekt_edit_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/project.dart';

/// Dialog zum Erstellen/Bearbeiten eines Projekts
class ProjektEditDialog extends StatefulWidget {
  final Project? project;

  const ProjektEditDialog({Key? key, this.project}) : super(key: key);

  @override
  State<ProjektEditDialog> createState() => _ProjektEditDialogState();
}

class _ProjektEditDialogState extends State<ProjektEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _projektNummerController;
  late final TextEditingController _ortController;
  late final TextEditingController _plzController;
  late final TextEditingController _projektNameController;
  late final TextEditingController _anlagentypController;
  late final TextEditingController _zusatzInfoController;
  late final TextEditingController _beschreibungController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _ansprechpartnerVornameController;
  late final TextEditingController _ansprechpartnerNachnameController;
  
  String _selectedType = Project.typeWaermenetz;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _projektNummerController = TextEditingController(text: p?.projektNummer ?? '');
    _ortController = TextEditingController(text: p?.ort ?? '');
    _plzController = TextEditingController(text: p?.plz ?? '');
    _projektNameController = TextEditingController(text: p?.projektName ?? '');
    _anlagentypController = TextEditingController(text: p?.installierterAnlagentyp ?? '');
    _zusatzInfoController = TextEditingController(text: p?.zusatzInfo ?? '');
    _beschreibungController = TextEditingController(text: p?.beschreibung ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _latitudeController = TextEditingController(text: p?.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: p?.longitude?.toString() ?? '');
    _ansprechpartnerVornameController = TextEditingController(text: p?.ansprechpartnerVorname ?? '');
    _ansprechpartnerNachnameController = TextEditingController(text: p?.ansprechpartnerNachname ?? '');
    _selectedType = p?.type ?? Project.typeWaermenetz;
  }

  @override
  void dispose() {
    _projektNummerController.dispose();
    _ortController.dispose();
    _plzController.dispose();
    _projektNameController.dispose();
    _anlagentypController.dispose();
    _zusatzInfoController.dispose();
    _beschreibungController.dispose();
    _imageUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ansprechpartnerVornameController.dispose();
    _ansprechpartnerNachnameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final project = Project(
      id: widget.project?.id ?? '',
      projektNummer: _projektNummerController.text.trim(),
      ort: _ortController.text.trim(),
      type: _selectedType,
      beschreibung: _beschreibungController.text.trim(),
      projektName: _projektNameController.text.trim(),
      plz: _plzController.text.trim(),
      installierterAnlagentyp: _anlagentypController.text.trim(),
      zusatzInfo: _zusatzInfoController.text.trim().isNotEmpty 
          ? _zusatzInfoController.text.trim() 
          : null,
      imageUrl: _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null,
      latitude: _latitudeController.text.trim().isNotEmpty
          ? double.tryParse(_latitudeController.text.trim())
          : null,
      longitude: _longitudeController.text.trim().isNotEmpty
          ? double.tryParse(_longitudeController.text.trim())
          : null,
      ansprechpartnerVorname: _ansprechpartnerVornameController.text.trim().isNotEmpty
          ? _ansprechpartnerVornameController.text.trim()
          : null,
      ansprechpartnerNachname: _ansprechpartnerNachnameController.text.trim().isNotEmpty
          ? _ansprechpartnerNachnameController.text.trim()
          : null,
      createdAt: widget.project?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SuewagColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Projekt bearbeiten' : 'Neues Projekt',
                      style: SuewagTextStyles.headline3.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Projektnummer und Ort
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _projektNummerController,
                              label: 'Projektnummer',
                              hint: 'z.B. 311',
                              icon: Icons.numbers,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              validator: (v) => v!.isEmpty || v.length < 3 
                                  ? '3 Ziffern erforderlich' 
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _ortController,
                              label: 'Ort',
                              hint: 'z.B. Mainz',
                              icon: Icons.location_city,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // PLZ und Projektname
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _plzController,
                              label: 'PLZ',
                              hint: 'z.B. 55116',
                              icon: Icons.pin_drop,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _projektNameController,
                              label: 'Projektname',
                              hint: 'z.B. Fernwärme Mainz-Zentrum',
                              icon: Icons.business,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Netztyp
                      Text('Netztyp', style: SuewagTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: Project.availableTypes.map((type) {
                          final isSelected = _selectedType == type;
                          final isWaermenetz = type == Project.typeWaermenetz;
                          final color = isWaermenetz 
                              ? SuewagColors.verkehrsorange 
                              : SuewagColors.indiablau;
                          
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: type == Project.typeWaermenetz ? 8 : 0,
                              ),
                              child: InkWell(
                                onTap: () => setState(() => _selectedType = type),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? color.withAlpha(38) 
                                        : SuewagColors.quartzgrau10,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? color : SuewagColors.divider,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        isWaermenetz 
                                            ? Icons.local_fire_department 
                                            : Icons.home_work,
                                        color: isSelected ? color : SuewagColors.textSecondary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        type,
                                        style: SuewagTextStyles.bodyMedium.copyWith(
                                          color: isSelected ? color : SuewagColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Anlagentyp
                      _buildTextField(
                        controller: _anlagentypController,
                        label: 'Installierter Anlagentyp',
                        hint: 'z.B. Blockheizkraftwerk mit Gaskessel-Backup',
                        icon: Icons.engineering,
                      ),
                      const SizedBox(height: 16),
                      
                      // Zusatzinfo
                      _buildTextField(
                        controller: _zusatzInfoController,
                        label: 'Zusatzinfo (optional)',
                        hint: 'z.B. Versorgungsgebiet, Besonderheiten',
                        icon: Icons.info_outline,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      
                      // Bild URL
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Bild-URL (optional)',
                        hint: 'https://... (leer = Kartenansicht)',
                        icon: Icons.image,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      
                      // Koordinaten Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SuewagColors.leuchtendgruen.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SuewagColors.leuchtendgruen.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.map, color: SuewagColors.leuchtendgruen),
                                const SizedBox(width: 8),
                                Text(
                                  'Koordinaten (Google Maps)',
                                  style: SuewagTextStyles.headline4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leer lassen für Default-Position (Frankfurt Höchst)',
                              style: SuewagTextStyles.bodySmall.copyWith(
                                color: SuewagColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _latitudeController,
                                    label: 'Latitude',
                                    hint: 'z.B. 50.0012',
                                    icon: Icons.north,
                                    required: false,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[\d.-]')),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      final lat = double.tryParse(v);
                                      if (lat == null || lat < -90 || lat > 90) {
                                        return 'Ungültig (-90 bis 90)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _longitudeController,
                                    label: 'Longitude',
                                    hint: 'z.B. 8.2710',
                                    icon: Icons.east,
                                    required: false,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[\d.-]')),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      final lng = double.tryParse(v);
                                      if (lng == null || lng < -180 || lng > 180) {
                                        return 'Ungültig (-180 bis 180)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Ansprechpartner Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SuewagColors.quartzgrau10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SuewagColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: SuewagColors.indiablau),
                                const SizedBox(width: 8),
                                Text(
                                  'Ansprechpartner',
                                  style: SuewagTextStyles.headline4,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leer lassen für "Team Dekarbonisierung"',
                              style: SuewagTextStyles.bodySmall.copyWith(
                                color: SuewagColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _ansprechpartnerVornameController,
                                    label: 'Vorname',
                                    hint: 'z.B. Max',
                                    icon: Icons.badge,
                                    required: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _ansprechpartnerNachnameController,
                                    label: 'Nachname',
                                    hint: 'z.B. Mustermann',
                                    icon: Icons.badge_outlined,
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                            if (_ansprechpartnerVornameController.text.isNotEmpty &&
                                _ansprechpartnerNachnameController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${_ansprechpartnerVornameController.text.toLowerCase()}.${_ansprechpartnerNachnameController.text.toLowerCase()}@suewag.de',
                                style: SuewagTextStyles.bodySmall.copyWith(
                                  color: SuewagColors.indiablau,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Beschreibung
                      _buildTextField(
                        controller: _beschreibungController,
                        label: 'Projektbeschreibung',
                        hint: 'Ausführliche Beschreibung des Projekts...',
                        icon: Icons.description,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SuewagColors.quartzgrau10,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? 'Speichern' : 'Erstellen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuewagColors.leuchtendgruen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator ?? (required 
          ? (v) => v!.isEmpty ? 'Pflichtfeld' : null 
          : null),
    );
  }
}
