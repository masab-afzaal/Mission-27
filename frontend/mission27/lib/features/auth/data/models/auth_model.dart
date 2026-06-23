import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.fullName,
    required super.isActive,
    required super.isVerified,
    required super.xpTotal,
    required super.level,
    required super.timezone,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      xpTotal: json['xp_total'] as int,
      level: json['level'] as int,
      timezone: json['timezone'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'is_active': isActive,
        'is_verified': isVerified,
        'xp_total': xpTotal,
        'level': level,
        'timezone': timezone,
        'created_at': createdAt.toIso8601String(),
      };
}

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
    );
  }
}
