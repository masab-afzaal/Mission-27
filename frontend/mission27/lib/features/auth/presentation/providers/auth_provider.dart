import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_provider.g.dart';

// ── Repository & use-case providers ─────────────────────────────────────────

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioProvider));
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(appStorageProvider),
  );
}

@riverpod
LoginUseCase loginUseCase(Ref ref) => LoginUseCase(ref.watch(authRepositoryProvider));

@riverpod
RegisterUseCase registerUseCase(Ref ref) => RegisterUseCase(ref.watch(authRepositoryProvider));

// ── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserEntity? user, bool? isLoading, String? errorMessage, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  FutureOr<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final isAuth = await repo.isAuthenticated();
    if (!isAuth) return const AuthState();

    final result = await repo.getCurrentUser();
    return result.fold(
      (_) => const AuthState(),
      (user) => AuthState(user: user),
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUseCaseProvider).call(
      LoginParams(email: email, password: password),
    );
    state = result.fold(
      (failure) => AsyncData(AuthState(errorMessage: failure.message)),
      (user) => AsyncData(AuthState(user: user)),
    );
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    String timezone = 'UTC',
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(registerUseCaseProvider).call(
      RegisterParams(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
        timezone: timezone,
      ),
    );
    state = result.fold(
      (failure) => AsyncData(AuthState(errorMessage: failure.message)),
      (user) => AsyncData(AuthState(user: user)),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState());
  }
}
