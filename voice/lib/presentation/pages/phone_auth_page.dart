import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../../core/constants/test_config.dart';
import 'package:voice_autobiography_flutter/generated/app_localizations.dart';

/// 手机号登录/注册页面
class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLogin = true; // true=登录, false=注册
  int _countdown = 0; // 验证码倒计时
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) {
      _showError(AppLocalizations.of(context)!.phoneErrorEmpty);
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneController.text)) {
      _showError(AppLocalizations.of(context)!.phoneErrorInvalid);
      return;
    }

    context.read<AuthBloc>().add(
          SendVerificationCode(phone: _phoneController.text),
        );

    _startCountdown();
    if (TestConfig.isTestMode) {
      _showSuccess('验证码已发送(测试: ${TestConfig.testVerificationCode})');
    } else {
      _showSuccess(AppLocalizations.of(context)!.codeSent);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLogin) {
      // 登录
      context.read<AuthBloc>().add(
            PhoneLogin(
              phone: _phoneController.text,
              code: _codeController.text,
            ),
          );
    } else {
      // 注册
      context.read<AuthBloc>().add(
            PhoneRegister(
              phone: _phoneController.text,
              code: _codeController.text,
              nickname: _nicknameController.text.isEmpty
                  ? null
                  : _nicknameController.text,
            ),
          );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin
            ? AppLocalizations.of(context)!.loginPhoneTitle
            : AppLocalizations.of(context)!.registerPhoneTitle),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // 登录成功，返回上一页
            Navigator.of(context).pop();
          } else if (state.status == AuthStatus.error && state.error != null) {
            _showError(state.error!);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Logo或标题
                  const Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin
                        ? AppLocalizations.of(context)!.welcomeBack
                        : AppLocalizations.of(context)!.createAccount,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 测试模式提示
                  if (TestConfig.isTestMode) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '测试模式:验证码统一为 ${TestConfig.testVerificationCode}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else
                    const SizedBox(height: 32),

                  // 手机号输入
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.phoneLabel,
                      hintText: AppLocalizations.of(context)!.phoneHint,
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.phoneErrorEmpty;
                      }
                      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                        return AppLocalizations.of(context)!.phoneErrorInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 验证码输入
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.codeLabel,
                            hintText: AppLocalizations.of(context)!.codeHint,
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .codeErrorEmpty;
                            }
                            if (value.length != 4) {
                              return AppLocalizations.of(context)!
                                  .codeErrorLength;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _countdown > 0 ? null : _sendCode,
                          child: Text(
                            _countdown > 0
                                ? '${_countdown}s'
                                : AppLocalizations.of(context)!.getCode,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 昵称输入（仅注册时显示）
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.nicknameLabel,
                        hintText: AppLocalizations.of(context)!.nicknameHint,
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 24),

                  // 提交按钮
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          state.status == AuthStatus.loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isLogin
                                  ? AppLocalizations.of(context)!.loginButton
                                  : AppLocalizations.of(context)!
                                      .registerButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切换登录/注册
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? AppLocalizations.of(context)!.noAccountRegister
                          : AppLocalizations.of(context)!.hasAccountLogin,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 用户协议提示
                  Text(
                    AppLocalizations.of(context)!.agreementText,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
