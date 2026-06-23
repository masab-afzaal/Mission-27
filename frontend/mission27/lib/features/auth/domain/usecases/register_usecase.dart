import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String email;
  final String username;
  final String password;
  final String fullName;
  final String timezone;

  const RegisterParams({
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
    this.timezone = 'UTC',
  });

  @override
  List<Object?> get props => [email, username];
}

class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      username: params.username,
      password: params.password,
      fullName: params.fullName,
      timezone: params.timezone,
    );
  }
}
