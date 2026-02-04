// lib/widgets/map/city_selector_card.dart

import 'package:flutter/material.dart';
import '../../constants/suewag_colors.dart';
import '../../models/city.dart';
import '../../models/zone.dart';

/// Schwebende Sidebar-Card für Stadtauswahl und Legende
class CitySelectorCard extends StatelessWidget {
  final List<City> cities;
  final City? selectedCity;
  final ValueChanged<City?> onCityChanged;
  final bool isLoading;

  const CitySelectorCard({
    Key? key,
    required this.cities,
    required this.selectedCity,
    required this.onCityChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
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
              color: SuewagColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Fernwärme-Gebiete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Stadt-Dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stadt auswählen',
                  style: TextStyle(
                    color: SuewagColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (cities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SuewagColors.quartzgrau10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SuewagColors.divider),
                    ),
                    child: Text(
                      'Keine Städte verfügbar',
                      style: TextStyle(
                        color: SuewagColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: SuewagColors.quartzgrau10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SuewagColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<City>(
                        value: selectedCity,
                        isExpanded: true,
                        hint: const Text('Stadt wählen...'),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: cities.map((city) {
                          return DropdownMenuItem<City>(
                            value: city,
                            child: Text(
                              city.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: onCityChanged,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Legende
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legende',
                  style: TextStyle(
                    color: SuewagColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  color: Zone.getDefaultColor(ZoneType.existing),
                  label: 'Bestand',
                  description: 'Fernwärme verfügbar',
                ),
                const SizedBox(height: 8),
                _buildLegendItem(
                  color: Zone.getDefaultColor(ZoneType.potential),
                  label: 'Ausbaugebiet',
                  description: 'Geplante Erweiterung',
                ),
              ],
            ),
          ),

          // Info-Hinweis
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SuewagColors.karibikblau.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SuewagColors.karibikblau.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: SuewagColors.alpenblau,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Klicken Sie auf die Karte, um Ihr Interesse anzumelden.',
                    style: TextStyle(
                      color: SuewagColors.textPrimary,
                      fontSize: 12,
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.35),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: SuewagColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: SuewagColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
