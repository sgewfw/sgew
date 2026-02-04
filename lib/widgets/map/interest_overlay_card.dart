// lib/widgets/map/interest_overlay_card.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';

/// Overlay-Card für User-Interesse-Anmeldung
class InterestOverlayCard extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isSubmitting;

  const InterestOverlayCard({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SuewagColors.leuchtendgruen,
                  SuewagColors.arktisgruen,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fernwärme-Interesse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'an diesem Standort',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Möchten Sie hier Ihr Interesse für einen Fernwärme-Anschluss anmelden?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SuewagColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wir werden Sie kontaktieren, sobald ein Anschluss in Ihrer Nähe möglich ist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SuewagColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Abbrechen Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SuewagColors.textSecondary,
                      side: BorderSide(color: SuewagColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                // Absenden Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : onConfirm,
                    icon: isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Text(isSubmitting ? 'Wird gesendet...' : 'Ja, Absenden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SuewagColors.leuchtendgruen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
