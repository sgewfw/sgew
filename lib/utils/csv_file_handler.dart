// lib/utils/csv_file_handler.dart
// Conditional import: wählt automatisch die richtige Implementierung

export 'csv_file_handler_stub.dart'
    if (dart.library.html) 'csv_file_handler_web.dart'
    if (dart.library.io) 'csv_file_handler_mobile.dart';
