// lib/screens/admin/tabs/grunddaten_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../../../models/kostenvergleich_data.dart';

class GrunddatenTab extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const GrunddatenTab({
    Key? key,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Gebäudedaten',
                icon: Icons.home,
                children: [
                  _buildNumberField(
                    label: 'Beheizte Fläche',
                    einheit: 'm²',
                    wert: stammdaten.grunddaten.beheizteFlaeche,
                    onChanged: (wert) {
                      final neueGrunddaten = GrunddatenKostenvergleich(
                        beheizteFlaeche: wert,
                        spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
                        heizenergiebedarf: wert * stammdaten.grunddaten.spezHeizenergiebedarf,
                      );
                      onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Spezifischer Heizenergiebedarf',
                    einheit: 'kWh/m²a',
                    wert: stammdaten.grunddaten.spezHeizenergiebedarf,
                    onChanged: (wert) {
                      final neueGrunddaten = GrunddatenKostenvergleich(
                        beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
                        spezHeizenergiebedarf: wert,
                        heizenergiebedarf: stammdaten.grunddaten.beheizteFlaeche * wert,
                      );
                      onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: 'Heizenergiebedarf (berechnet)',
                    einheit: 'kWh/a',
                    wert: stammdaten.grunddaten.heizenergiebedarf,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Finanzierung',
                icon: Icons.account_balance,
                children: [
                  _buildNumberField(
                    label: 'Zinssatz',
                    einheit: '%',
                    wert: stammdaten.finanzierung.zinssatz,
                    nachkommastellen: 3,
                    onChanged: (wert) {
                      final neueFinanzierung = FinanzierungsDaten(
                        zinssatz: wert,
                        laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
                        foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                        foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                      );
                      onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                    },
                    helperText: 'Zinssatz für Kapitaldienst-Berechnung',
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Laufzeit',
                    einheit: 'Jahre',
                    wert: stammdaten.finanzierung.laufzeitJahre.toDouble(),
                    nachkommastellen: 0,
                    onChanged: (wert) {
                      final neueFinanzierung = FinanzierungsDaten(
                        zinssatz: stammdaten.finanzierung.zinssatz,
                        laufzeitJahre: wert.toInt(),
                        foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                        foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                      );
                      onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Förderquoten',
                icon: Icons.euro,
                children: [
                  _buildPercentField(
                    label: 'BEG Förderung',
                    wert: stammdaten.finanzierung.foerderungBEG,
                    onChanged: (wert) {
                      final neueFinanzierung = FinanzierungsDaten(
                        zinssatz: stammdaten.finanzierung.zinssatz,
                        laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
                        foerderungBEG: wert,
                        foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                      );
                      onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                    },
                    helperText: 'Für Wärmepumpe und Wärmenetz Station Kunde',
                  ),
                  const SizedBox(height: 16),
                  _buildPercentField(
                    label: 'BEW Förderung',
                    wert: stammdaten.finanzierung.foerderungBEW,
                    onChanged: (wert) {
                      final neueFinanzierung = FinanzierungsDaten(
                        zinssatz: stammdaten.finanzierung.zinssatz,
                        laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
                        foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                        foerderungBEW: wert,
                      );
                      onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                    },
                    helperText: 'Für Wärmenetz Station Süwag',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SuewagColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: SuewagTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String einheit,
    required double wert,
    required Function(double) onChanged,
    int nachkommastellen = 2,
    String? helperText,
  }) {
    final controller = TextEditingController(
      text: wert.toStringAsFixed(nachkommastellen),
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: einheit,
        helperText: helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }

  Widget _buildPercentField({
    required String label,
    required double wert,
    required Function(double) onChanged,
    String? helperText,
  }) {
    final controller = TextEditingController(
      text: (wert * 100).toStringAsFixed(0),
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        helperText: helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) {
          onChanged(parsed / 100); // Convert to 0-1
        }
      },
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String einheit,
    required double wert,
  }) {
    return TextField(
      controller: TextEditingController(text: wert.toStringAsFixed(0)),
      decoration: InputDecoration(
        labelText: label,
        suffixText: einheit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: SuewagColors.background,
      ),
      enabled: false,
    );
  }
}