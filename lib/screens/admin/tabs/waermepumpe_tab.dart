// lib/screens/admin/tabs/waermepumpe_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/suewag_colors.dart';
import '../../../constants/suewag_text_styles.dart';
import '../../../models/kostenvergleich_data.dart';

class WaermepumpeTab extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const WaermepumpeTab({
    Key? key,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  SzenarioStammdaten get _szenario => stammdaten.szenarien['waermepumpe']!;

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
                title: 'Investitionskosten',
                icon: Icons.euro,
                children: [
                  _buildInvestitionsList(),
                  const SizedBox(height: 16),
                  _buildInvestitionsGesamtInfo(),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Wärmekosten (laufend)',
                icon: Icons.payments,
                children: [
                  _buildNumberField(
                    label: 'Jahresarbeitszahl (JAZ)',
                    wert: _szenario.waermekosten.jahresarbeitszahl ?? 3.0,
                    nachkommastellen: 2,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(jahresarbeitszahl: wert),
                    ),
                    helperText: 'Verhältnis Wärmeenergie / elektrische Energie',
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: 'Stromverbrauch (berechnet)',
                    einheit: 'kWh/a',
                    wert: stammdaten.grunddaten.heizenergiebedarf /
                        (_szenario.waermekosten.jahresarbeitszahl ?? 3.0),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Stromarbeitspreis',
                    einheit: 'ct/kWh',
                    wert: _szenario.waermekosten.stromarbeitspreisCtKWh ?? 16.52,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(stromarbeitspreisCtKWh: wert),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Strom-Grundpreis',
                    einheit: '€/Monat',
                    wert: _szenario.waermekosten.stromGrundpreisEuroMonat ?? 9.0,
                    onChanged: (wert) => _updateWaermekosten(
                      _szenario.waermekosten.copyWith(stromGrundpreisEuroMonat: wert),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Nebenkosten (laufend)',
                icon: Icons.build,
                children: [
                  _buildNumberField(
                    label: 'Wartung & Instandhaltung',
                    einheit: '€/Jahr',
                    wert: _szenario.nebenkosten.wartungEuroJahr ?? 490.0,
                    nachkommastellen: 0,
                    onChanged: (wert) => _updateNebenkosten(
                      NebenkostenDaten(wartungEuroJahr: wert),
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

  Widget _buildInvestitionsList() {
    return Column(
      children: _szenario.investition.positionen.asMap().entries.map((entry) {
        final index = entry.key;
        final position = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(position.bezeichnung),
            subtitle: position.bemerkung != null
                ? Text(position.bemerkung!, style: SuewagTextStyles.caption)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${position.betrag.toStringAsFixed(0)} €',
                  style: SuewagTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editInvestitionsposition(index, position),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestitionsGesamtInfo() {
    final foerderquote = stammdaten.finanzierung.foerderungBEG;
    final gesamtBrutto = _szenario.investition.gesamtBrutto;
    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SuewagColors.fasergruen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.fasergruen),
      ),
      child: Column(
        children: [
          _buildSummenZeile('Investition brutto:', gesamtBrutto),
          _buildSummenZeile(
            'Förderung BEG (${(foerderquote * 100).toStringAsFixed(0)}%):',
            -foerderbetrag,
            color: Colors.green,
          ),
          const Divider(),
          _buildSummenZeile(
            'Investition netto:',
            netto,
            istGesamt: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummenZeile(String label, double betrag,
      {Color? color, bool istGesamt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: istGesamt
                ? SuewagTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.bold)
                : SuewagTextStyles.bodyMedium,
          ),
          Text(
            '${betrag.toStringAsFixed(0)} €',
            style: TextStyle(
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
              fontSize: istGesamt ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _editInvestitionsposition(int index, InvestitionsPosition position) {
    // TODO: Dialog zum Bearbeiten öffnen
    // Für jetzt: Placeholder
  }

  void _updateWaermekosten(WaermekostenDaten neueWaermekosten) {
    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: _szenario.investition,
      waermekosten: neueWaermekosten,
      nebenkosten: _szenario.nebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien['waermepumpe'] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  void _updateNebenkosten(NebenkostenDaten neueNebenkosten) {
    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: _szenario.investition,
      waermekosten: _szenario.waermekosten,
      nebenkosten: neueNebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien['waermepumpe'] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
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
    required double wert,
    required Function(double) onChanged,
    String? einheit,
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

// Helper extension für copyWith auf WaermekostenDaten
extension WaermekostenDatenCopyWith on WaermekostenDaten {
  WaermekostenDaten copyWith({
    double? stromverbrauchKWh,
    double? waermeVerbrauchGasKWh,
    double? waermeVerbrauchStromKWh,
    double? stromarbeitspreisCtKWh,
    double? waermeGasArbeitspreisCtKWh,
    double? waermeStromArbeitspreisCtKWh,
    double? stromGrundpreisEuroMonat,
    double? waermeGrundpreisEuroJahr,
    double? waermeMesspreisEuroJahr,
    double? jahresarbeitszahl,
  }) {
    return WaermekostenDaten(
      stromverbrauchKWh: stromverbrauchKWh ?? this.stromverbrauchKWh,
      waermeVerbrauchGasKWh: waermeVerbrauchGasKWh ?? this.waermeVerbrauchGasKWh,
      waermeVerbrauchStromKWh: waermeVerbrauchStromKWh ?? this.waermeVerbrauchStromKWh,
      stromarbeitspreisCtKWh: stromarbeitspreisCtKWh ?? this.stromarbeitspreisCtKWh,
      waermeGasArbeitspreisCtKWh: waermeGasArbeitspreisCtKWh ?? this.waermeGasArbeitspreisCtKWh,
      waermeStromArbeitspreisCtKWh: waermeStromArbeitspreisCtKWh ?? this.waermeStromArbeitspreisCtKWh,
      stromGrundpreisEuroMonat: stromGrundpreisEuroMonat ?? this.stromGrundpreisEuroMonat,
      waermeGrundpreisEuroJahr: waermeGrundpreisEuroJahr ?? this.waermeGrundpreisEuroJahr,
      waermeMesspreisEuroJahr: waermeMesspreisEuroJahr ?? this.waermeMesspreisEuroJahr,
      jahresarbeitszahl: jahresarbeitszahl ?? this.jahresarbeitszahl,
    );
  }
}