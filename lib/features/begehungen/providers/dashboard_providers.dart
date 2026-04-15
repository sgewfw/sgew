import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/abteilung_model.dart';
import '../models/user_model.dart';
import '../services/abteilung_service.dart';
import 'auth_providers.dart';

final abteilungServiceProvider = Provider<AbteilungService>((ref) {
  return AbteilungService();
});

// ═══════════════════════════════════════════════════════════════
// GUARD: Alle Streams prüfen ob ein aktiver User geladen ist.
// Ohne diesen Guard starten Streams sofort wenn authStateProvider
// feuert, aber BEVOR currentBegehungUserProvider den User geladen
// hat → isAktiverSuewagUser() in den Rules schlägt fehl.
// ═══════════════════════════════════════════════════════════════
bool _istBereit(Ref ref) {
  if (ref.watch(isLoggingOutProvider)) return false;
  final user = ref.watch(currentBegehungUserProvider).valueOrNull;
  return user != null && user.istAktiv;
}

final abteilungenProvider = StreamProvider<List<Abteilung>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(abteilungServiceProvider).watchAbteilungen();
});

final abteilungRankingProvider = Provider<List<Abteilung>>((ref) {
  return ref.watch(abteilungenProvider).when(
    data: (list) {
      final s = List<Abteilung>.from(list);
      s.sort((a, b) => b.begehungenDiesesJahr.compareTo(a.begehungenDiesesJahr));
      return s;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final gesamtOffeneMaengelProvider = Provider<int>((ref) {
  return ref.watch(abteilungenProvider).when(
    data: (list) => list.fold<int>(0, (s, a) => s + a.offeneMaengel),
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final gesamtBegehungenProvider = Provider<int>((ref) {
  return ref.watch(abteilungenProvider).when(
    data: (list) => list.fold<int>(0, (s, a) => s + a.begehungenDiesesJahr),
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final alleUsersProvider = StreamProvider<List<BegehungUser>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(userServiceProvider).watchUsers();
});

final userRankingProvider = Provider<List<BegehungUser>>((ref) {
  return ref.watch(alleUsersProvider).when(
    data: (list) {
      final s = List<BegehungUser>.from(list);
      s.sort((a, b) => b.begehungenDiesesJahr.compareTo(a.begehungenDiesesJahr));
      return s;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final pendingUsersProvider = StreamProvider<List<BegehungUser>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(userServiceProvider).watchPendingUsers();
});

final pendingCountProvider = StreamProvider<int>((ref) {
  if (!_istBereit(ref)) return Stream.value(0);
  return ref.watch(userServiceProvider).watchPendingCount();
});

final allUsersSortedProvider = StreamProvider<List<BegehungUser>>((ref) {
  if (!_istBereit(ref)) return Stream.value([]);
  return ref.watch(userServiceProvider).watchAllUsersSorted();
});