import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AppStorage _storage;

  const AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _persistSession(result.user, result.tokens);
      return Right(result.user);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    String timezone = 'UTC',
  }) async {
    try {
      final result = await _remote.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
        timezone: timezone,
      );
      await _persistSession(result.user, result.tokens);
      return Right(result.user);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final cached = await _storage.read(key: AppConstants.userKey);
      if (cached != null) {
        return Right(UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>));
      }
      final user = await _remote.getMe();
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      return Right(user);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await _storage.deleteAll();
    return const Right(null);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  Future<void> _persistSession(UserModel user, TokenModel tokens) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: tokens.accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: tokens.refreshToken),
      _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson())),
    ]);
  }
}
