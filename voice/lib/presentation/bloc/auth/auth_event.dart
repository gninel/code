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

/// 发送验证码
class SendVerificationCode extends AuthEvent {
  final String phone;

  const SendVerificationCode({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// 手机号注册
class PhoneRegister extends AuthEvent {
  final String phone;
  final String code;
  final String? password;
  final String? nickname;

  const PhoneRegister({
    required this.phone,
    required this.code,
    this.password,
    this.nickname,
  });

  @override
  List<Object?> get props => [phone, code, password, nickname];
}

/// 手机号登录
class PhoneLogin extends AuthEvent {
  final String phone;
  final String code;

  const PhoneLogin({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
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
