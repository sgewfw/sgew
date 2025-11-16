// // lib/screens/admin/tabs/grunddaten_tab.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../constants/suewag_colors.dart';
// import '../../../constants/suewag_text_styles.dart';
// import '../../../models/kostenvergleich_data.dart';
//
// class GrunddatenTab extends StatelessWidget {
//   final KostenvergleichJahr stammdaten;
//   final Function(KostenvergleichJahr) onChanged;
//
//   const GrunddatenTab({
//     Key? key,
//     required this.stammdaten,
//     required this.onChanged,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Block 1: GEBÄUDEDATEN
//           _buildSection(
//             title: 'Gebäudedaten',
//             icon: Icons.home,
//             children: [
//               _buildNumberFieldMitQuelle(
//                 label: 'Fläche',
//                 einheit: 'm²',
//                 wertMitQuelle: stammdaten.grunddaten.beheizteFlaeche,
//                 nachkommastellen: 2,
//                 onChanged: (neuerWert) {
//                   final neueGrunddaten = GrunddatenKostenvergleich(
//                     beheizteFlaeche: neuerWert,
//                     spezHeizenergiebedarf: stammdaten.grunddaten.spezHeizenergiebedarf,
//                     heizenergiebedarf: WertMitQuelle(
//                       wert: neuerWert.wert * stammdaten.grunddaten.spezHeizenergiebedarf.wert,
//                       quelle: stammdaten.grunddaten.heizenergiebedarf.quelle,
//                     ),
//                   );
//                   onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildNumberFieldMitQuelle(
//                 label: 'Spez. Bedarf',
//                 einheit: 'kWh/m²a',
//                 wertMitQuelle: stammdaten.grunddaten.spezHeizenergiebedarf,
//                 nachkommastellen: 1,
//                 onChanged: (neuerWert) {
//                   final neueGrunddaten = GrunddatenKostenvergleich(
//                     beheizteFlaeche: stammdaten.grunddaten.beheizteFlaeche,
//                     spezHeizenergiebedarf: neuerWert,
//                     heizenergiebedarf: WertMitQuelle(
//                       wert: stammdaten.grunddaten.beheizteFlaeche.wert * neuerWert.wert,
//                       quelle: stammdaten.grunddaten.heizenergiebedarf.quelle,
//                     ),
//                   );
//                   onChanged(stammdaten.copyWith(grunddaten: neueGrunddaten));
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildReadOnlyFieldMitQuelle(
//                 label: 'Gesamt',
//                 einheit: 'kWh/a',
//                 wertMitQuelle: stammdaten.grunddaten.heizenergiebedarf,
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 20),
//
//           // Block 2: FINANZIERUNG
//           _buildSection(
//             title: 'Finanzierung',
//             icon: Icons.account_balance,
//             children: [
//               _buildNumberFieldMitQuelle(
//                 label: 'Zinssatz',
//                 einheit: '%',
//                 wertMitQuelle: stammdaten.finanzierung.zinssatz,
//                 nachkommastellen: 3,
//                 onChanged: (neuerWert) {
//                   final neueFinanzierung = FinanzierungsDaten(
//                     zinssatz: neuerWert,
//                     laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
//                     foerderungBEG: stammdaten.finanzierung.foerderungBEG,
//                     foerderungBEW: stammdaten.finanzierung.foerderungBEW,
//                   );
//                   onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildIntFieldMitQuelle(
//                 label: 'Laufzeit',
//                 einheit: 'Jahre',
//                 wertMitQuelle: stammdaten.finanzierung.laufzeitJahre,
//                 onChanged: (neuerWert) {
//                   final neueFinanzierung = FinanzierungsDaten(
//                     zinssatz: stammdaten.finanzierung.zinssatz,
//                     laufzeitJahre: neuerWert,
//                     foerderungBEG: stammdaten.finanzierung.foerderungBEG,
//                     foerderungBEW: stammdaten.finanzierung.foerderungBEW,
//                   );
//                   onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
//                 },
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 20),
//
//           // Block 3: FÖRDERQUOTEN
//           _buildSection(
//             title: 'Förderquoten',
//             icon: Icons.euro,
//             children: [
//               _buildPercentFieldMitQuelle(
//                 label: 'BEG',
//                 wertMitQuelle: stammdaten.finanzierung.foerderungBEG,
//                 onChanged: (neuerWert) {
//                   final neueFinanzierung = FinanzierungsDaten(
//                     zinssatz: stammdaten.finanzierung.zinssatz,
//                     laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
//                     foerderungBEG: neuerWert,
//                     foerderungBEW: stammdaten.finanzierung.foerderungBEW,
//                   );
//                   onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildPercentFieldMitQuelle(
//                 label: 'BEW',
//                 wertMitQuelle: stammdaten.finanzierung.foerderungBEW,
//                 onChanged: (neuerWert) {
//                   final neueFinanzierung = FinanzierungsDaten(
//                     zinssatz: stammdaten.finanzierung.zinssatz,
//                     laufzeitJahre: stammdaten.finanzierung.laufzeitJahre,
//                     foerderungBEG: stammdaten.finanzierung.foerderungBEG,
//                     foerderungBEW: neuerWert,
//                   );
//                   onChanged(stammdaten.copyWith(finanzierung: neueFinanzierung));
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSection({
//     required String title,
//     required IconData icon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: SuewagColors.divider),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: SuewagColors.primary, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }
//
//   // Zahlenfeld mit Quelle
//   Widget _buildNumberFieldMitQuelle({
//     required String label,
//     required String einheit,
//     required WertMitQuelle<double> wertMitQuelle,
//     required Function(WertMitQuelle<double>) onChanged,
//     int nachkommastellen = 2,
//   }) {
//     final controller = TextEditingController(
//       text: wertMitQuelle.wert.toStringAsFixed(nachkommastellen),
//     );
//
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             inputFormatters: [
//               FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
//             ],
//             style: const TextStyle(fontSize: 16),
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(fontSize: 14),
//               suffixText: einheit,
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             onChanged: (text) {
//               final parsed = double.tryParse(text);
//               if (parsed != null) {
//                 onChanged(WertMitQuelle(
//                   wert: parsed,
//                   quelle: wertMitQuelle.quelle,
//                 ));
//               }
//             },
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildInfoButton(wertMitQuelle.quelle),
//         const SizedBox(width: 8),
//         _buildEditQuelleButton(
//           quelle: wertMitQuelle.quelle,
//           onQuelleChanged: (neueQuelle) {
//             onChanged(WertMitQuelle(
//               wert: wertMitQuelle.wert,
//               quelle: neueQuelle,
//             ));
//           },
//         ),
//       ],
//     );
//   }
//
//   // Int-Feld mit Quelle
//   Widget _buildIntFieldMitQuelle({
//     required String label,
//     required String einheit,
//     required WertMitQuelle<int> wertMitQuelle,
//     required Function(WertMitQuelle<int>) onChanged,
//   }) {
//     final controller = TextEditingController(
//       text: wertMitQuelle.wert.toString(),
//     );
//
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//             ],
//             style: const TextStyle(fontSize: 16),
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(fontSize: 14),
//               suffixText: einheit,
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             onChanged: (text) {
//               final parsed = int.tryParse(text);
//               if (parsed != null) {
//                 onChanged(WertMitQuelle(
//                   wert: parsed,
//                   quelle: wertMitQuelle.quelle,
//                 ));
//               }
//             },
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildInfoButton(wertMitQuelle.quelle),
//         const SizedBox(width: 8),
//         _buildEditQuelleButton(
//           quelle: wertMitQuelle.quelle,
//           onQuelleChanged: (neueQuelle) {
//             onChanged(WertMitQuelle(
//               wert: wertMitQuelle.wert,
//               quelle: neueQuelle,
//             ));
//           },
//         ),
//       ],
//     );
//   }
//
//   // Prozent-Feld mit Quelle
//   Widget _buildPercentFieldMitQuelle({
//     required String label,
//     required WertMitQuelle<double> wertMitQuelle,
//     required Function(WertMitQuelle<double>) onChanged,
//   }) {
//     final controller = TextEditingController(
//       text: (wertMitQuelle.wert * 100).toStringAsFixed(0),
//     );
//
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//             ],
//             style: const TextStyle(fontSize: 16),
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(fontSize: 14),
//               suffixText: '%',
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             onChanged: (text) {
//               final parsed = int.tryParse(text);
//               if (parsed != null) {
//                 onChanged(WertMitQuelle(
//                   wert: parsed / 100.0,
//                   quelle: wertMitQuelle.quelle,
//                 ));
//               }
//             },
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildInfoButton(wertMitQuelle.quelle),
//         const SizedBox(width: 8),
//         _buildEditQuelleButton(
//           quelle: wertMitQuelle.quelle,
//           onQuelleChanged: (neueQuelle) {
//             onChanged(WertMitQuelle(
//               wert: wertMitQuelle.wert,
//               quelle: neueQuelle,
//             ));
//           },
//         ),
//       ],
//     );
//   }
//
//   // Read-Only Feld mit Quelle
//   Widget _buildReadOnlyFieldMitQuelle({
//     required String label,
//     required String einheit,
//     required WertMitQuelle<double> wertMitQuelle,
//   }) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: TextEditingController(
//               text: wertMitQuelle.wert.toStringAsFixed(0),
//             ),
//             style: const TextStyle(fontSize: 16),
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(fontSize: 14),
//               suffixText: einheit,
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               filled: true,
//               fillColor: SuewagColors.background,
//             ),
//             enabled: false,
//           ),
//         ),
//         const SizedBox(width: 8),
//         _buildInfoButton(wertMitQuelle.quelle),
//         const SizedBox(width: 8),
//         _buildEditQuelleButton(
//           quelle: wertMitQuelle.quelle,
//           onQuelleChanged: (_) {}, // Read-only, keine Änderung
//         ),
//       ],
//     );
//   }
//
//   // Info-Button (zeigt Quelle an)
//   Widget _buildInfoButton(QuellenInfo quelle) {
//     return Builder(
//       builder: (context) => InkWell(
//         onTap: () => _zeigeQuellenDialog(context, quelle),
//         child: Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             color: SuewagColors.primary.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Icon(
//             Icons.info_outline,
//             size: 18,
//             color: SuewagColors.primary,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Edit-Button (bearbeitet Quelle)
//   Widget _buildEditQuelleButton({
//     required QuellenInfo quelle,
//     required Function(QuellenInfo) onQuelleChanged,
//   }) {
//     return Builder(
//       builder: (context) => InkWell(
//         onTap: () => _zeigeQuelleBearbeitenDialog(context, quelle, onQuelleChanged),
//         child: Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             color: SuewagColors.verkehrsorange.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Icon(
//             Icons.edit,
//             size: 18,
//             color: SuewagColors.verkehrsorange,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Dialog: Quelle anzeigen
//   void _zeigeQuellenDialog(BuildContext context, QuellenInfo quelle) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(quelle.titel),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(quelle.beschreibung),
//               if (quelle.link != null) ...[
//                 const SizedBox(height: 12),
//                 InkWell(
//                   onTap: () {
//                     // Link öffnen (url_launcher)
//                     // TODO: Implementierung mit url_launcher
//                   },
//                   child: Row(
//                     children: [
//                       Icon(Icons.link, size: 16, color: SuewagColors.primary),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           quelle.link!,
//                           style: TextStyle(
//                             color: SuewagColors.primary,
//                             decoration: TextDecoration.underline,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Schließen'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Dialog: Quelle bearbeiten
//   void _zeigeQuelleBearbeitenDialog(
//       BuildContext context,
//       QuellenInfo quelle,
//       Function(QuellenInfo) onQuelleChanged,
//       ) {
//     final titelController = TextEditingController(text: quelle.titel);
//     final beschreibungController = TextEditingController(text: quelle.beschreibung);
//     final linkController = TextEditingController(text: quelle.link ?? '');
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Quelle bearbeiten'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titelController,
//                 decoration: const InputDecoration(
//                   labelText: 'Titel',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: beschreibungController,
//                 decoration: const InputDecoration(
//                   labelText: 'Beschreibung',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 5,
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: linkController,
//                 decoration: const InputDecoration(
//                   labelText: 'Link (optional)',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Abbrechen'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final neueQuelle = QuellenInfo(
//                 titel: titelController.text,
//                 beschreibung: beschreibungController.text,
//                 link: linkController.text.isEmpty ? null : linkController.text,
//               );
//               onQuelleChanged(neueQuelle);
//               Navigator.pop(context);
//             },
//             child: const Text('Speichern'),
//           ),
//         ],
//       ),
//     );
//   }
// }