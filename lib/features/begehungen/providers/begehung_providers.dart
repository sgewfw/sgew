import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/begehung_model.dart';
import '../models/mangel_model.dart';
import '../services/begehung_service.dart';
import '../services/mangel_service.dart';
import 'auth_providers.dart';

final begehungServiceProvider = Provider<BegehungService>((ref) {
  return BegehungService();
});

final mangelServiceProvider = Provider<MangelService>((ref) {
  return MangelService();
});

final syncStateProvider =
StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  return SyncStateNotifier(ref.watch(begehungServiceProvider));
});

class SyncState {
  final bool isLoading;
  final SyncResult? lastResult;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isLoading = false,
    this.lastResult,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isLoading,
    SyncResult? lastResult,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      lastResult: lastResult ?? this.lastResult,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final BegehungService _service;
  SyncStateNotifier(this._service) : super(const SyncState());

  Future<SyncResult> sync() async {
    if (state.isLoading) {
      return SyncResult(
          success: false, imported: 0, skipped: 0, errors: 0,
          errorMessage: 'Sync läuft bereits.');
    }
    state = state.copyWith(isLoading: true);
    try {
      final result = await _service.syncFromSmapOne();
      state = state.copyWith(
          isLoading: false, lastResult: result, lastSyncTime: DateTime.now());
      return result;
    } catch (e) {
      final result = SyncResult(
          success: false, imported: 0, skipped: 0, errors: 1,
          errorMessage: e.toString());
      state = state.copyWith(isLoading: false, lastResult: result);
      return result;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// GUARD: Streams starten erst wenn ein aktiver User geladen ist.
// Verhindert Permission Denied beim Login-Übergang.
// ═══════════════════════════════════════════════════════════════
bool _istBereit(Ref ref) {
  if (ref.watch(isLoggingOutProvider)) return false;
  final user = ref.watch(currentBegehungUserProvider).valueOrNull;
  return user != null && user.istAktiv;
}

final begehungenProvider = StreamProvider<List<Begehung>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(begehungServiceProvider).watchBegehungen();
});

final begehungenNachAbteilungProvider =
StreamProvider.family<List<Begehung>, String>((ref, abteilung) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(begehungServiceProvider).watchBegehungen(abteilung: abteilung);
});

final begehungenNachStandortProvider =
StreamProvider.family<List<Begehung>, String>((ref, standort) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(begehungServiceProvider).watchBegehungen(standort: standort);
});

final maengelProvider =
StreamProvider.family<List<Mangel>, String>((ref, begehungId) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(begehungServiceProvider).watchMaengel(begehungId);
});

final alleOffenenMaengelProvider = StreamProvider<List<Mangel>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(mangelServiceProvider).watchAlleOffenenMaengel();
});

final meineMaengelProvider =
StreamProvider.family<List<Mangel>, String>((ref, uid) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(mangelServiceProvider).watchOffeneMaengelFuerUser(uid);
});