import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../models/begehung_enums.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'begehung_providers.dart';

final isLoggingOutProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  if (ref.watch(isLoggingOutProvider)) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final currentBegehungUserProvider = StreamProvider<BegehungUser?>((ref) {
  if (ref.watch(isLoggingOutProvider)) return Stream.value(null);
  final authState = ref.watch(authStateProvider);
  final userService = ref.watch(userServiceProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return userService.watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final userRolleProvider = Provider<UserRolle>((ref) {
  final userAsync = ref.watch(currentBegehungUserProvider);
  return userAsync.when(
    data: (user) => user?.rolle ?? UserRolle.mitarbeiter,
    loading: () => UserRolle.mitarbeiter,
    error: (_, __) => UserRolle.mitarbeiter,
  );
});

final istEingeloggtProvider = Provider<bool>((ref) {
  if (ref.watch(isLoggingOutProvider)) return false;
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

final userStatusProvider = Provider<UserStatus?>((ref) {
  final userAsync = ref.watch(currentBegehungUserProvider);
  return userAsync.when(
    data: (user) => user?.status,
    loading: () => null,
    error: (_, __) => null,
  );
});

final istAktiverUserProvider = Provider<bool>((ref) {
  final status = ref.watch(userStatusProvider);
  return status == UserStatus.aktiv;
});

final istFuehrungskraftProvider = Provider<bool>((ref) {
  return ref.watch(userRolleProvider).istFuehrungskraft;
});

final darkModeProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentBegehungUserProvider);
  return userAsync.when(
    data: (user) => user?.darkMode ?? true,
    loading: () => true,
    error: (_, __) => true,
  );
});

final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 200));
    await FirebaseAuth.instance.signOut();
    ref.invalidate(begehungenProvider);
    ref.invalidate(alleOffenenMaengelProvider);
    ref.invalidate(currentBegehungUserProvider);
    ref.invalidate(syncStateProvider);
    ref.invalidate(authStateProvider);
    ref.read(isLoggingOutProvider.notifier).state = false;
  };
});