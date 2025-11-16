// lib/widgets/kostenvergleich_parameter_widget.dart

import 'package:flutter/material.dart';
import '../constants/suewag_colors.dart';
import '../constants/suewag_text_styles.dart';
import '../models/kostenvergleich_data.dart';

import '../utils/numberFormatter.dart';

class KostenvergleichParameterWidget extends StatelessWidget {
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const KostenvergleichParameterWidget({
    Key? key,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berechnungsparameter',
            style: SuewagTextStyles.headline3,
          ),
          const SizedBox(height: 16),
          // In kostenvergleich_parameter_widget.dart

          Row(
            children: [
              // Zinssatz
              Expanded(
                child: _buildParameterCard(
                  titel: 'Zinssatz',
                  wert: stammdaten.finanzierung.zinssatz.wert,
                  einheit: '%',
                  nachkommastellen: 2,
                  icon: Icons.trending_up,
                  quelle: stammdaten.finanzierung.zinssatz.quelle,
                  onChanged: (neuerWert) {
                    final neueFinanzierung = FinanzierungsDaten(
                      zinssatz: WertMitQuelle(
                        wert: neuerWert,
                        quelle: stammdaten.finanzierung.zinssatz.quelle,
                      ),
                      laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
                      foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                      foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                    );
                    onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                  },
                  onQuelleChanged: (neueQuelle) {
                    final neueFinanzierung = FinanzierungsDaten(
                      zinssatz: WertMitQuelle(
                        wert: stammdaten.finanzierung.zinssatz.wert,
                        quelle: neueQuelle,
                      ),
                      laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
                      foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                      foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                    );
                    onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Laufzeit
              Expanded(
                child: _buildParameterCard(
                  titel: 'Laufzeit',
                  wert: stammdaten.finanzierung.laufzeitJahre.wert.toDouble(),
                  einheit: 'Jahre',
                  nachkommastellen: 0,
                  icon: Icons.calendar_today,
                  quelle: stammdaten.finanzierung.laufzeitJahre.quelle,
                  onChanged: (neuerWert) {
                    final neueFinanzierung = FinanzierungsDaten(
                      zinssatz: stammdaten.finanzierung.zinssatz,
                      laufzeitJahre: WertMitQuelle(
                        wert: neuerWert.toInt(),
                        quelle: stammdaten.finanzierung.laufzeitJahre.quelle,
                      ),
                      foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                      foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                    );
                    onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                  },
                  onQuelleChanged: (neueQuelle) {
                    final neueFinanzierung = FinanzierungsDaten(
                      zinssatz: stammdaten.finanzierung.zinssatz,
                      laufzeitJahre: WertMitQuelle(
                        wert: stammdaten.finanzierung.laufzeitJahre.wert,
                        quelle: neueQuelle,
                      ),
                      foerderungBEG: stammdaten.finanzierung.foerderungBEG,
                      foerderungBEW: stammdaten.finanzierung.foerderungBEW,
                    );
                    onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
                  },
                ),
              ),
              const SizedBox(width: 16),

              // JAZ Wärmepumpe
              Expanded(
                child: _buildJAZCard('waermepumpe', 'JAZ Wärmepumpe'),
              ),
              const SizedBox(width: 16),

              // NEU: Anteil Gaswärme (für alle Szenarien)
              Expanded(
                child: _buildParameterCard(
                  titel: 'Anteil Gaswärme',
                  wert: stammdaten.grunddaten.anteilGaswaerme.wert * 100,
                  einheit: '%',
                  nachkommastellen: 0,
                  icon: Icons.local_fire_department,
                  quelle: stammdaten.grunddaten.anteilGaswaerme.quelle,
                  onChanged: (neuerWert) {
                    final neueGrunddaten = GrunddatenKostenvergleich(
                      beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
                      spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
                      heizenergiebedarf: stammdaten.grunddaten.heizenergiebedarf,
                      anteilGaswaerme: WertMitQuelle(
                        wert: neuerWert / 100,
                        quelle: stammdaten.grunddaten.anteilGaswaerme.quelle,
                      ),
                    );
                    onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
                  },
                  onQuelleChanged: (neueQuelle) {
                    final neueGrunddaten = GrunddatenKostenvergleich(
                      beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
                      spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
                      heizenergiebedarf: stammdaten.grunddaten.heizenergiebedarf,
                      anteilGaswaerme: WertMitQuelle(
                        wert: stammdaten.grunddaten.anteilGaswaerme.wert,
                        quelle: neueQuelle,
                      ),
                    );
                    onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJAZCard(String szenarioId, String titel) {
    final szenario = stammdaten.szenarien[szenarioId];
    if (szenario == null || szenario.waermekosten.jahresarbeitszahl == null) {
      return const SizedBox.shrink();
    }

    final jaz = szenario.waermekosten.jahresarbeitszahl!;

    return _buildParameterCard(
      titel: titel,
      wert: jaz.wert,
      einheit: '',
      nachkommastellen: 2,
      icon: Icons.thermostat,
      quelle: jaz.quelle,
      onChanged: (neuerWert) {
        final neueWaermekosten = szenario.waermekosten.copyWith(
          jahresarbeitszahl: WertMitQuelle(
            wert: neuerWert,
            quelle: jaz.quelle,
          ),
        );

        final neuesSzenario = SzenarioStammdaten(
          id: szenario.id,
          bezeichnung: szenario.bezeichnung,
          beschreibung: szenario.beschreibung,
          typ: szenario.typ,
          sortierung: szenario.sortierung,
          investition: szenario.investition,
          waermekosten: neueWaermekosten,
          nebenkosten: szenario.nebenkosten,
        );

        final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
        neueSzenarien[szenarioId] = neuesSzenario;

        onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
      },
      onQuelleChanged: (neueQuelle) {
        final neueWaermekosten = szenario.waermekosten.copyWith(
          jahresarbeitszahl: WertMitQuelle(
            wert: jaz.wert,
            quelle: neueQuelle,
          ),
        );

        final neuesSzenario = SzenarioStammdaten(
          id: szenario.id,
          bezeichnung: szenario.bezeichnung,
          beschreibung: szenario.beschreibung,
          typ: szenario.typ,
          sortierung: szenario.sortierung,
          investition: szenario.investition,
          waermekosten: neueWaermekosten,
          nebenkosten: szenario.nebenkosten,
        );

        final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
        neueSzenarien[szenarioId] = neuesSzenario;

        onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
      },
    );
  }

  Widget _buildParameterCard({
    required String titel,
    required double wert,
    required String einheit,
    required int nachkommastellen,
    required IconData icon,
    required QuellenInfo quelle,
    required Function(double) onChanged,
    required Function(QuellenInfo) onQuelleChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SuewagColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: SuewagColors.primary),
              const SizedBox(width: 6),
              Text(
                titel,
                style: SuewagTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SuewagColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: deutscheZahl(wert, nachkommastellen),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    GermanNumberInputFormatter(nachkommastellen: nachkommastellen),
                  ],
                  style: SuewagTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: einheit,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    final parsed = parseGermanNumber(text);
                    if (parsed != null) {
                      onChanged(parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (context) => InkWell(
                  onTap: () => _zeigeQuellenDialog(context, titel, quelle, onQuelleChanged),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: SuewagColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _zeigeQuellenDialog(
      BuildContext context,
      String titel,
      QuellenInfo quelle,
      Function(QuellenInfo) onQuelleChanged,
      ) {
    final titelController = TextEditingController(text: quelle.titel);
    final beschreibungController = TextEditingController(text: quelle.beschreibung);
    final linkController = TextEditingController(text: quelle.link ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quelle: $titel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titelController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final neueQuelle = QuellenInfo(
                titel: titelController.text,
                beschreibung: beschreibungController.text,
                link: linkController.text.isEmpty ? null : linkController.text,
              );
              onQuelleChanged(neueQuelle);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}