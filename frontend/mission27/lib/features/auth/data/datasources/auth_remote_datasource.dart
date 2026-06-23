import 'package:dio/dio.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<({UserModel user, TokenModel tokens})> login({
    required String email,
    required String password,
  });

  Future<({UserModel user, TokenModel tokens})> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String timezone,
  });

  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<({UserModel user, TokenModel tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<({UserModel user, TokenModel tokens})> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String timezone,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
      'full_name': fullName,
      'timezone': timezone,
    });
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  ({UserModel user, TokenModel tokens}) _parseAuthResponse(Map<String, dynamic> data) {
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      tokens: TokenModel.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }
}
