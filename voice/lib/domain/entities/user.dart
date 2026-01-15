import 'package:equatable/equatable.dart';

/// 用户实体
class User extends Equatable {
  final String id;
  final String email;
  final String? nickname;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.nickname,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, nickname, createdAt];
}
