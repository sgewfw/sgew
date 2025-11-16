// lib/screens/admin/tabs/waermenetz_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/suewag_colors.dart';
import '../../../models/kostenvergleich_data.dart';

class WaermenetzTab extends StatelessWidget {
  final String szenarioId;
  final KostenvergleichJahr stammdaten;
  final Function(KostenvergleichJahr) onChanged;

  const WaermenetzTab({
    Key? key,
    required this.szenarioId,
    required this.stammdaten,
    required this.onChanged,
  }) : super(key: key);

  SzenarioStammdaten get _szenario => stammdaten.szenarien[szenarioId]!;

  // Bestimme ob Investition angezeigt werden soll
  bool get _showInvestition => szenarioId != 'waermenetzOhneUGS';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INVESTITION (nur wenn nicht waermenetzOhneUGS)
          if (_showInvestition) ...[
            _buildSection(
              title: 'Investitionskosten',
              icon: Icons.euro,
              children: [
                _buildInvestitionsBlock(),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // WÄRMEKOSTEN
          _buildSection(
            title: 'Wärmekosten (laufend)',
            icon: Icons.payments,
            children: [
              if (_szenario.waermekosten.waermeGasArbeitspreisCtKWh != null)
                _buildNumberFieldMitQuelle(
                  label: 'AP Gas',
                  einheit: 'ct/kWh',
                  wertMitQuelle: _szenario.waermekosten.waermeGasArbeitspreisCtKWh!,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeGasArbeitspreisCtKWh: neuerWert),
                    );
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.waermeStromArbeitspreisCtKWh != null)
                _buildNumberFieldMitQuelle(
                  label: 'AP Strom',
                  einheit: 'ct/kWh',
                  wertMitQuelle: _szenario.waermekosten.waermeStromArbeitspreisCtKWh!,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeStromArbeitspreisCtKWh: neuerWert),
                    );
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.waermeGrundpreisEuroJahr != null)
                _buildNumberFieldMitQuelle(
                  label: 'Grundpreis',
                  einheit: '€/Jahr',
                  wertMitQuelle: _szenario.waermekosten.waermeGrundpreisEuroJahr!,
                  nachkommastellen: 0,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeGrundpreisEuroJahr: neuerWert),
                    );
                  },
                ),
              const SizedBox(height: 16),

              if (_szenario.waermekosten.waermeMesspreisEuroJahr != null)
                _buildNumberFieldMitQuelle(
                  label: 'Messpreis',
                  einheit: '€/Jahr',
                  wertMitQuelle: _szenario.waermekosten.waermeMesspreisEuroJahr!,
                  onChanged: (neuerWert) {
                    _updateWaermekosten(
                      _szenario.waermekosten.copyWith(waermeMesspreisEuroJahr: neuerWert),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // NEBENKOSTEN
          _buildSection(
            title: 'Nebenkosten',
            icon: Icons.build,
            children: [
              if (_szenario.nebenkosten.wartungEuroJahr != null)
                _buildNumberFieldMitQuelle(
                  label: 'Wartung',
                  einheit: '€/Jahr',
                  wertMitQuelle: _szenario.nebenkosten.wartungEuroJahr!,
                  nachkommastellen: 0,
                  onChanged: (neuerWert) {
                    _updateNebenkosten(
                      NebenkostenDaten(
                        wartungEuroJahr: neuerWert,
                        grundpreisUebergabestationEuroJahr:
                        _szenario.nebenkosten.grundpreisUebergabestationEuroJahr,
                      ),
                    );
                  },
                ),
              if (szenarioId == 'waermenetzSuewag' &&
                  _szenario.nebenkosten.grundpreisUebergabestationEuroJahr != null) ...[
                const SizedBox(height: 16),
                _buildNumberFieldMitQuelle(
                  label: 'GP ÜGS',
                  einheit: '€/Jahr',
                  wertMitQuelle: _szenario.nebenkosten.grundpreisUebergabestationEuroJahr!,
                  nachkommastellen: 0,
                  onChanged: (neuerWert) {
                    _updateNebenkosten(
                      NebenkostenDaten(
                        wartungEuroJahr: _szenario.nebenkosten.wartungEuroJahr,
                        grundpreisUebergabestationEuroJahr: neuerWert,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestitionsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Übergabestation (nur waermenetzKunde)
        if (szenarioId == 'waermenetzKunde' && _szenario.investition.uebergabestation != null)
          _buildInvestitionsPosition(
            position: _szenario.investition.uebergabestation!,
            onChanged: (neuePosition) {
              _updateInvestitionsPosition('uebergabestation', neuePosition);
            },
          ),
        if (szenarioId == 'waermenetzKunde') const SizedBox(height: 16),

        // TWW-Speicher (nur waermenetzKunde)
        if (szenarioId == 'waermenetzKunde' && _szenario.investition.twwSpeicher != null)
          _buildInvestitionsPosition(
            position: _szenario.investition.twwSpeicher!,
            onChanged: (neuePosition) {
              _updateInvestitionsPosition('twwSpeicher', neuePosition);
            },
          ),
        if (szenarioId == 'waermenetzKunde') const SizedBox(height: 16),

        // Heizlastberechnung (nur waermenetzKunde)
        if (szenarioId == 'waermenetzKunde' && _szenario.investition.heizlastberechnung != null)
          _buildInvestitionsPosition(
            position: _szenario.investition.heizlastberechnung!,
            onChanged: (neuePosition) {
              _updateInvestitionsPosition('heizlastberechnung', neuePosition);
            },
          ),
        if (szenarioId == 'waermenetzKunde') const SizedBox(height: 16),

        // BKZ (nur waermenetzSuewag)
        if (szenarioId == 'waermenetzSuewag' && _szenario.investition.bkz != null)
          _buildInvestitionsPosition(
            position: _szenario.investition.bkz!,
            onChanged: (neuePosition) {
              _updateInvestitionsPosition('bkz', neuePosition);
            },
          ),

        const Divider(),
        _buildInvestitionsSumme(),
      ],
    );
  }

  Widget _buildInvestitionsPosition({
    required InvestitionsPosition position,
    required Function(InvestitionsPosition) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bezeichnung mit Edit-Button
        Row(
          children: [
            Expanded(
              child: Text(
                position.bezeichnung,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Builder(
              builder: (context) => InkWell(
                onTap: () => _zeigeBezeichnungBearbeitenDialog(context, position, onChanged),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: SuewagColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: SuewagColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildNumberFieldMitQuelle(
          label: 'Betrag',
          einheit: '€',
          wertMitQuelle: position.betrag,
          nachkommastellen: 0,
          onChanged: (neuerWert) {
            onChanged(InvestitionsPosition(
              bezeichnung: position.bezeichnung,
              betrag: neuerWert,
              bemerkung: position.bemerkung,
            ));
          },
        ),
      ],
    );
  }

// Dialog zum Bearbeiten der Bezeichnung
  void _zeigeBezeichnungBearbeitenDialog(
      BuildContext context,
      InvestitionsPosition position,
      Function(InvestitionsPosition) onChanged,
      ) {
    final controller = TextEditingController(text: position.bezeichnung);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bezeichnung bearbeiten'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bezeichnung',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(InvestitionsPosition(
                bezeichnung: controller.text,
                betrag: position.betrag,
                bemerkung: position.bemerkung,
              ));
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  Widget _buildInvestitionsSumme() {
    final gesamtBrutto = _berechneGesamtBrutto();

    double foerderquote = 0.0;
    if (szenarioId == 'waermenetzKunde') {
      foerderquote = stammdaten.finanzierung.foerderungBEG.wert;
    } else if (szenarioId == 'waermenetzSuewag') {
      foerderquote = stammdaten.finanzierung.foerderungBEW.wert;
    }

    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    return Column(
      children: [
        _buildSummenZeile('Gesamt brutto:', gesamtBrutto),
        if (foerderquote > 0) ...[
          _buildSummenZeile(
            'Förderung ${szenarioId == 'waermenetzKunde' ? 'BEG' : 'BEW'} (${(foerderquote * 100).toStringAsFixed(0)}%):',
            -foerderbetrag,
            color: Colors.red,
          ),
          const Divider(height: 12),
          _buildSummenZeile(
            'Netto nach Förderung:',
            netto,
            istGesamt: true,
          ),
        ],
      ],
    );
  }

  double _berechneGesamtBrutto() {
    double summe = 0;
    if (_szenario.investition.uebergabestation != null) {
      summe += _szenario.investition.uebergabestation!.betrag.wert;
    }
    if (_szenario.investition.twwSpeicher != null) {
      summe += _szenario.investition.twwSpeicher!.betrag.wert;
    }
    if (_szenario.investition.heizlastberechnung != null) {
      summe += _szenario.investition.heizlastberechnung!.betrag.wert;
    }
    if (_szenario.investition.bkz != null) {
      summe += _szenario.investition.bkz!.betrag.wert;
    }
    return summe;
  }

  Widget _buildSummenZeile(String label, double betrag,
      {Color? color, bool istGesamt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${betrag.toStringAsFixed(0)} €',
            style: TextStyle(
              fontWeight: istGesamt ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _updateInvestitionsPosition(String key, InvestitionsPosition neuePosition) {
    final gesamtBrutto = _berechneNeuenGesamtBrutto(key, neuePosition);

    double foerderquote = 0.0;
    FoerderungsTyp foerderungsTyp = FoerderungsTyp.keine;

    if (szenarioId == 'waermenetzKunde') {
      foerderquote = stammdaten.finanzierung.foerderungBEG.wert;
      foerderungsTyp = FoerderungsTyp.beg;
    } else if (szenarioId == 'waermenetzSuewag') {
      foerderquote = stammdaten.finanzierung.foerderungBEW.wert;
      foerderungsTyp = FoerderungsTyp.bew;
    }

    final foerderbetrag = gesamtBrutto * foerderquote;
    final netto = gesamtBrutto - foerderbetrag;

    InvestitionskostenDaten neueInvestition;

    switch (key) {
      case 'uebergabestation':
        neueInvestition = InvestitionskostenDaten(
          uebergabestation: neuePosition,
          twwSpeicher: _szenario.investition.twwSpeicher,
          hydraulik: _szenario.investition.hydraulik,
          heizlastberechnung: _szenario.investition.heizlastberechnung,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: foerderungsTyp,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      case 'twwSpeicher':
        neueInvestition = InvestitionskostenDaten(
          uebergabestation: _szenario.investition.uebergabestation,
          twwSpeicher: neuePosition,
          hydraulik: _szenario.investition.hydraulik,
          heizlastberechnung: _szenario.investition.heizlastberechnung,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: foerderungsTyp,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      case 'heizlastberechnung':
        neueInvestition = InvestitionskostenDaten(
          uebergabestation: _szenario.investition.uebergabestation,
          twwSpeicher: _szenario.investition.twwSpeicher,
          hydraulik: _szenario.investition.hydraulik,
          heizlastberechnung: neuePosition,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: foerderungsTyp,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      case 'bkz':
        neueInvestition = InvestitionskostenDaten(
          bkz: neuePosition,
          gesamtBrutto: gesamtBrutto,
          foerderungsTyp: foerderungsTyp,
          foerderquote: foerderquote,
          foerderbetrag: foerderbetrag,
          nettoNachFoerderung: netto,
        );
        break;
      default:
        return;
    }

    final neuesSzenario = SzenarioStammdaten(
      id: _szenario.id,
      bezeichnung: _szenario.bezeichnung,
      beschreibung: _szenario.beschreibung,
      typ: _szenario.typ,
      sortierung: _szenario.sortierung,
      investition: neueInvestition,
      waermekosten: _szenario.waermekosten,
      nebenkosten: _szenario.nebenkosten,
    );

    final neueSzenarien = Map<String, SzenarioStammdaten>.from(stammdaten.szenarien);
    neueSzenarien[szenarioId] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  double _berechneNeuenGesamtBrutto(String key, InvestitionsPosition neuePosition) {
    double summe = 0;

    if (key == 'uebergabestation') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.uebergabestation != null) {
      summe += _szenario.investition.uebergabestation!.betrag.wert;
    }

    if (key == 'twwSpeicher') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.twwSpeicher != null) {
      summe += _szenario.investition.twwSpeicher!.betrag.wert;
    }

    if (key == 'heizlastberechnung') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.heizlastberechnung != null) {
      summe += _szenario.investition.heizlastberechnung!.betrag.wert;
    }

    if (key == 'bkz') {
      summe += neuePosition.betrag.wert;
    } else if (_szenario.investition.bkz != null) {
      summe += _szenario.investition.bkz!.betrag.wert;
    }

    return summe;
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
    neueSzenarien[szenarioId] = neuesSzenario;

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
    neueSzenarien[szenarioId] = neuesSzenario;

    onChanged(stammdaten.copyWith(szenarien: neueSzenarien));
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SuewagColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SuewagColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Zahlenfeld mit Quelle
  Widget _buildNumberFieldMitQuelle({
    required String label,
    required WertMitQuelle<double> wertMitQuelle,
    required Function(WertMitQuelle<double>) onChanged,
    String? einheit,
    int nachkommastellen = 2,
  }) {
    final controller = TextEditingController(
      text: wertMitQuelle.wert.toStringAsFixed(nachkommastellen),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 14),
              suffixText: einheit,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) {
                onChanged(WertMitQuelle(
                  wert: parsed,
                  quelle: wertMitQuelle.quelle,
                ));
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        _buildInfoButton(wertMitQuelle.quelle),
        const SizedBox(width: 8),
        _buildEditQuelleButton(
          quelle: wertMitQuelle.quelle,
          onQuelleChanged: (neueQuelle) {
            onChanged(WertMitQuelle(
              wert: wertMitQuelle.wert,
              quelle: neueQuelle,
            ));
          },
        ),
      ],
    );
  }

  // Info-Button (zeigt Quelle an)
  Widget _buildInfoButton(QuellenInfo quelle) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _zeigeQuellenDialog(context, quelle),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SuewagColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: SuewagColors.primary,
          ),
        ),
      ),
    );
  }

  // Edit-Button (bearbeitet Quelle)
  Widget _buildEditQuelleButton({
    required QuellenInfo quelle,
    required Function(QuellenInfo) onQuelleChanged,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _zeigeQuelleBearbeitenDialog(context, quelle, onQuelleChanged),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SuewagColors.verkehrsorange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.edit,
            size: 18,
            color: SuewagColors.verkehrsorange,
          ),
        ),
      ),
    );
  }

  // Dialog: Quelle anzeigen
  void _zeigeQuellenDialog(BuildContext context, QuellenInfo quelle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quelle.titel),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quelle.beschreibung),
              if (quelle.link != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    // Link öffnen (url_launcher)
                  },
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: SuewagColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quelle.link!,
                          style: TextStyle(
                            color: SuewagColors.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  // Dialog: Quelle bearbeiten
  void _zeigeQuelleBearbeitenDialog(
      BuildContext context,
      QuellenInfo quelle,
      Function(QuellenInfo) onQuelleChanged,
      ) {
    final titelController = TextEditingController(text: quelle.titel);
    final beschreibungController = TextEditingController(text: quelle.beschreibung);
    final linkController = TextEditingController(text: quelle.link ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quelle bearbeiten'),
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

// Helper extension für copyWith auf WaermekostenDaten
extension WaermekostenDatenCopyWith on WaermekostenDaten {
  WaermekostenDaten copyWith({
    WertMitQuelle<double>? stromverbrauchKWh,
    WertMitQuelle<double>? waermeVerbrauchGasKWh,
    WertMitQuelle<double>? waermeVerbrauchStromKWh,
    WertMitQuelle<double>? stromarbeitspreisCtKWh,
    WertMitQuelle<double>? waermeGasArbeitspreisCtKWh,
    WertMitQuelle<double>? waermeStromArbeitspreisCtKWh,
    WertMitQuelle<double>? stromGrundpreisEuroMonat,
    WertMitQuelle<double>? waermeGrundpreisEuroJahr,
    WertMitQuelle<double>? waermeMesspreisEuroJahr,
    WertMitQuelle<double>? jahresarbeitszahl,
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