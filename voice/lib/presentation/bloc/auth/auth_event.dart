import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化认证状态
class InitAuth extends AuthEvent {
  const InitAuth();
}

/// 登录
class Login extends AuthEvent {
  final String email;
  final String password;

  const Login({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// 注册
class Register extends AuthEvent {
  final String email;
  final String password;
  final String? nickname;

  const Register({
    required this.email, 
    required this.password, 
    this.nickname,
  });

  @override
  List<Object?> get props => [email, password, nickname];
}

/// 退出登录
class Logout extends AuthEvent {
  const Logout();
}

/// 上传数据
class UploadData extends AuthEvent {
  const UploadData();
}

/// 下载/恢复数据
class DownloadData extends AuthEvent {
  const DownloadData();
}
