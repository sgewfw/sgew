import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/suewag_colors.dart';

enum AppErrorType { permissionDenied, notFound, network, validation, unknown }

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final String? technicalDetail;
  const AppException({required this.type, required this.message, this.technicalDetail});

  factory AppException.permissionDenied([String? d]) => AppException(type: AppErrorType.permissionDenied, message: 'Sie haben keine Berechtigung für diese Aktion.', technicalDetail: d);
  factory AppException.notFound(String was) => AppException(type: AppErrorType.notFound, message: '$was wurde nicht gefunden.');
  factory AppException.network() => const AppException(type: AppErrorType.network, message: 'Keine Verbindung zum Server.');
  factory AppException.validation(String msg) => AppException(type: AppErrorType.validation, message: msg);

  factory AppException.fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied': return AppException.permissionDenied(e.message);
      case 'not-found': return AppException.notFound('Dokument');
      case 'unavailable': return AppException.network();
      default: return AppException(type: AppErrorType.unknown, message: 'Ein Fehler ist aufgetreten.', technicalDetail: '${e.code}: ${e.message}');
    }
  }

  factory AppException.fromError(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseException) return AppException.fromFirebase(error);
    return AppException(type: AppErrorType.unknown, message: 'Ein unerwarteter Fehler ist aufgetreten.', technicalDetail: error.toString());
  }

  IconData get icon => switch (type) { AppErrorType.permissionDenied => Icons.lock_outlined, AppErrorType.notFound => Icons.search_off, AppErrorType.network => Icons.wifi_off, AppErrorType.validation => Icons.warning_amber_rounded, AppErrorType.unknown => Icons.error_outline };
  Color get color => switch (type) { AppErrorType.permissionDenied => SuewagColors.erdbeerrot, AppErrorType.notFound => SuewagColors.verkehrsorange, AppErrorType.network => SuewagColors.quartzgrau75, AppErrorType.validation => SuewagColors.dahliengelb, AppErrorType.unknown => SuewagColors.erdbeerrot };
  @override String toString() => 'AppException($type): $message';
}

void showAppError(BuildContext context, Object error) {
  final e = error is AppException ? error : AppException.fromError(error);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(e.icon, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(e.message))]), backgroundColor: e.color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 4)));
}

void showAppSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message))]), backgroundColor: SuewagColors.leuchtendgruen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 3)));
}
