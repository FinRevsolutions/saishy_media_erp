import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/user_model.dart';

// ── Auth State ─────────────────────────────────────────
class AuthState {
  final bool isLoggedIn;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({bool? isLoggedIn, UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Auth Notifier ──────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthState> {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _api = ApiService();

  @override
  Future<AuthState> build() async {
    return _restoreSession();
  }

  Future<AuthState> _restoreSession() async {
    try {
      final token    = await _storage.read(key: AppConstants.keyAuthToken);
      final id       = await _storage.read(key: AppConstants.keyUserId);
      final role     = await _storage.read(key: AppConstants.keyUserRole);
      final fullName = await _storage.read(key: AppConstants.keyUserFullName);

      if (token == null || id == null) return const AuthState(isLoggedIn: false);

      final user = UserModel(
        id: id,
        username: '',
        passwordHash: '',
        role: UserRoleExt.fromString(role ?? ''),
        fullName: fullName ?? '',
      );
      return AuthState(isLoggedIn: true, user: user);
    } catch (_) {
      return const AuthState(isLoggedIn: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncData(AuthState(isLoggedIn: false, isLoading: true));

    try {
      // Initialize API service with saved URL
      await _api.initialize();

      final hash   = sha256.convert(utf8.encode(password)).toString();
      final result = await _api.post(
        action: ApiConstants.actionLogin,
        data: {'username': username.trim(), 'password_hash': hash},
      );

      final user = UserModel.fromJson(result as Map<String, dynamic>);

      // Persist auth
      await _storage.write(key: AppConstants.keyAuthToken,    value: user.id);
      await _storage.write(key: AppConstants.keyUserId,       value: user.id);
      await _storage.write(key: AppConstants.keyUserRole,     value: user.role.label);
      await _storage.write(key: AppConstants.keyUserFullName, value: user.fullName);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserName, username.trim());

      // Trigger background sync
      SyncService.instance.syncAll();

      state = AsyncData(AuthState(isLoggedIn: true, user: user));
    } catch (e) {
      state = AsyncData(AuthState(
        isLoggedIn: false,
        error: e.toString().replaceAll('ApiException(400): ', ''),
      ));
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncData(AuthState(isLoggedIn: false));
  }

  UserModel? get currentUser => state.valueOrNull?.user;

  bool hasRole(UserRole role) {
    final user = currentUser;
    if (user == null) return false;
    return user.role == role || user.role == UserRole.superAdmin;
  }
}

// ── Providers ─────────────────────────────────────────
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.isLoggedIn ?? false;
});

final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(currentUserProvider)?.role ?? UserRole.operator;
});
