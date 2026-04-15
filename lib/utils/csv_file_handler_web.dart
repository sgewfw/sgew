// lib/utils/csv_file_handler_web.dart
// Nur für Flutter Web – nutzt dart:html

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

Future<void> exportCSV(String csv, String fileName) async {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<({String content, String name})?> importCSV() async {
  final input = html.FileUploadInputElement()..accept = '.csv';
  input.click();

  await input.onChange.first;
  if (input.files == null || input.files!.isEmpty) return null;

  final file = input.files!.first;
  final reader = html.FileReader();
  reader.readAsText(file);
  await reader.onLoadEnd.first;

  return (content: reader.result as String, name: file.name);
}
