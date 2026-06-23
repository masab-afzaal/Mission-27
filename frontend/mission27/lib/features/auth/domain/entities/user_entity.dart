import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final bool isActive;
  final bool isVerified;
  final int xpTotal;
  final int level;
  final String timezone;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.xpTotal,
    required this.level,
    required this.timezone,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, username];
}
