// lib/utils/csv_file_handler_mobile.dart
// Für Android & iOS – nutzt share_plus + file_picker + path_provider

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportCSV(String csv, String fileName) async {
  final bytes = utf8.encode(csv);
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: fileName,
  );
}

Future<({String content, String name})?> importCSV() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final content = utf8.decode(file.bytes!);
  return (content: content, name: file.name);
}
