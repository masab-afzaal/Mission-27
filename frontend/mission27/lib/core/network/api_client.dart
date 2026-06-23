import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../errors/failures.dart';
import '../storage/app_storage.dart';
import 'interceptors.dart';

// Initialized in main() before app starts — always sync-ready
final appStorageProvider = Provider<AppStorage>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(appStorageProvider);

  final rawDio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  rawDio.interceptors.add(AuthInterceptor(storage, rawDio));
  rawDio.interceptors.add(LoggingInterceptor());

  return rawDio;
});

extension DioFailure on DioException {
  Failure toFailure() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final code = response?.statusCode;
        final detail = response?.data?['detail'] as String? ?? 'Server error';
        if (code == 401) return const UnauthorizedFailure();
        if (code == 422) {
          return ValidationFailure(detail, errors: response?.data as Map<String, dynamic>?);
        }
        return ServerFailure(detail, statusCode: code);
      default:
        return const UnexpectedFailure();
    }
  }
}
