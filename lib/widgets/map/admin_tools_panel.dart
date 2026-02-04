// lib/widgets/map/admin_tools_panel.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../models/zone.dart';

/// Admin-Tools Panel für Polygon-Zeichenfunktion
class AdminToolsPanel extends StatelessWidget {
  final bool isEditModeActive;
  final ZoneType selectedZoneType;
  final int currentPointCount;
  final VoidCallback onToggleEditMode;
  final ValueChanged<ZoneType> onZoneTypeChanged;
  final VoidCallback? onSavePolygon;
  final VoidCallback? onCancelDrawing;
  final VoidCallback? onUndoPoint;

  const AdminToolsPanel({
    Key? key,
    required this.isEditModeActive,
    required this.selectedZoneType,
    required this.currentPointCount,
    required this.onToggleEditMode,
    required this.onZoneTypeChanged,
    this.onSavePolygon,
    this.onCancelDrawing,
    this.onUndoPoint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SuewagColors.brilliantkarmin,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin-Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Edit Mode Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toggle Button
                Material(
                  color: isEditModeActive
                      ? SuewagColors.leuchtendgruen.withOpacity(0.15)
                      : SuewagColors.quartzgrau10,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onToggleEditMode,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isEditModeActive
                                  ? SuewagColors.leuchtendgruen
                                  : SuewagColors.quartzgrau50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isEditModeActive ? Icons.edit : Icons.edit_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bearbeitungsmodus',
                                  style: TextStyle(
                                    color: SuewagColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  isEditModeActive ? 'Aktiv' : 'Inaktiv',
                                  style: TextStyle(
                                    color: isEditModeActive
                                        ? SuewagColors.leuchtendgruen
                                        : SuewagColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isEditModeActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isEditModeActive,
                            onChanged: (_) => onToggleEditMode(),
                            activeColor: SuewagColors.leuchtendgruen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Zone Type Selector (nur wenn Edit Mode aktiv)
                if (isEditModeActive) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Zonentyp',
                    style: TextStyle(
                      color: SuewagColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildZoneTypeButton(
                        type: ZoneType.existing,
                        label: 'Bestand',
                        color: Zone.getDefaultColor(ZoneType.existing),
                      ),
                      const SizedBox(width: 8),
                      _buildZoneTypeButton(
                        type: ZoneType.potential,
                        label: 'Ausbau',
                        color: Zone.getDefaultColor(ZoneType.potential),
                      ),
                    ],
                  ),

                  // Punkt-Zähler
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SuewagColors.quartzgrau10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.place,
                          size: 18,
                          color: SuewagColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentPointCount Punkte gesetzt',
                          style: TextStyle(
                            color: SuewagColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  if (currentPointCount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onUndoPoint,
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Undo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SuewagColors.textSecondary,
                              side: BorderSide(color: SuewagColors.divider),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancelDrawing,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Löschen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SuewagColors.erdbeerrot,
                              side:
                                  BorderSide(color: SuewagColors.erdbeerrot),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Speichern Button (nur wenn >= 3 Punkte)
                  if (currentPointCount >= 3) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onSavePolygon,
                      icon: const Icon(Icons.check),
                      label: const Text('Polygon speichern'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SuewagColors.leuchtendgruen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Keyboard Shortcuts Info
          if (isEditModeActive)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SuewagColors.orientgelb.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SuewagColors.orientgelb.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tastaturkürzel',
                    style: TextStyle(
                      color: SuewagColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildShortcutRow('Enter', 'Polygon speichern'),
                  _buildShortcutRow('Escape', 'Letzten Punkt entfernen'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoneTypeButton({
    required ZoneType type,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedZoneType == type;

    return Expanded(
      child: Material(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onZoneTypeChanged(type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : SuewagColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.5),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : SuewagColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SuewagColors.quartzgrau25,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: TextStyle(
                color: SuewagColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action,
            style: TextStyle(
              color: SuewagColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
