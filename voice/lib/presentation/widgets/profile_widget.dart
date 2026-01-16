import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_state.dart';
import 'package:voice_autobiography_flutter/presentation/pages/phone_auth_page.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/language/language_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/language/language_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/language/language_state.dart';
import 'package:voice_autobiography_flutter/generated/app_localizations.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  // 模拟设置值
  final String _recordingQuality = '高质量';
  final String _asrProvider = '讯飞';
  final String _aiProvider = '豆包';
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Default from theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.profileTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: Theme.of(context).iconTheme.color),
            onPressed: () {
              // 更多设置
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // 显示同步结果
          if (state.syncStatus == SyncStatus.success &&
              state.syncMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.syncMessage!),
                backgroundColor: Colors.green[700],
              ),
            );
            // 刷新数据
            context.read<VoiceRecordBloc>().add(const LoadVoiceRecords());
            context.read<AutobiographyBloc>().add(const LoadAutobiographies());
          } else if (state.syncStatus == SyncStatus.error &&
              state.syncMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.syncMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 用户头像和信息
              _buildUserProfile(),

              const SizedBox(height: 24),

              // 统计信息
              _buildStatistics(),

              const SizedBox(height: 24),

              // 设置选项
              _buildSettingsSection(),

              const SizedBox(height: 24),

              // 其他选项
              _buildOtherSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoggedIn = state.isLoggedIn;
        final user = state.user;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // 头像
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLoggedIn ? Icons.person : Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),

              const SizedBox(width: 16),

              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn
                          ? (user?.nickname ??
                              user?.email ??
                              AppLocalizations.of(context)!.user)
                          : AppLocalizations.of(context)!.notLoggedIn,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? user?.email ?? '' : '登录后可同步数据到云端',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 登录/退出按钮
              GestureDetector(
                onTap: () {
                  if (isLoggedIn) {
                    _showLogoutDialog(context);
                  } else {
                    _showLoginDialog(context);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLoggedIn
                        ? Theme.of(context).cardColor
                        : Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isLoggedIn
                        ? Border.all(color: Theme.of(context).dividerColor)
                        : null,
                  ),
                  child: Text(
                    isLoggedIn
                        ? AppLocalizations.of(context)!.logout
                        : AppLocalizations.of(context)!.login,
                    style: TextStyle(
                      color: isLoggedIn
                          ? Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.onPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    final voiceRecordState = context.watch<VoiceRecordBloc>().state;
    final autobiographyState = context.watch<AutobiographyBloc>().state;

    final recordCount = voiceRecordState.records.length;

    // 计算总时长
    int totalDuration = 0;
    for (final record in voiceRecordState.records) {
      totalDuration += record.duration;
    }
    final totalMinutes = (totalDuration / 1000 / 60).round();

    // 计算自传字数
    int totalWords = 0;
    for (final autobiography in autobiographyState.autobiographies) {
      totalWords += autobiography.content.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(AppLocalizations.of(context)!.recordCount,
                  '$recordCount', '条'),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildStatItem(AppLocalizations.of(context)!.totalDuration,
                  '$totalMinutes', '分钟'),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _buildStatItem(
                  AppLocalizations.of(context)!.wordCount, '$totalWords', '字'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // 仅保留自动备份设置
            _buildSwitchItem(
              icon: Icons.cloud_upload,
              title: AppLocalizations.of(context)!.autoBackup,
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
            ),
            _buildDivider(),
            BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, state) {
                return _buildSettingItem(
                  icon: Icons.language,
                  title: AppLocalizations.of(context)!.language,
                  value: state.locale.languageCode == 'zh' ? '中文' : 'English',
                  onTap: () {
                    _showLanguageDialog(context, state.locale);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, Locale currentLocale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Language / 选择语言',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('中文'),
                trailing: currentLocale.languageCode == 'zh'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  context
                      .read<LanguageBloc>()
                      .add(const ChangeLanguage(Locale('zh')));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: currentLocale.languageCode == 'en'
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  context
                      .read<LanguageBloc>()
                      .add(const ChangeLanguage(Locale('en')));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtherSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.info_outline,
              title: AppLocalizations.of(context)!.aboutApp,
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.cleaning_services,
              title: AppLocalizations.of(context)!.clearCache,
              onTap: () {
                _showClearCacheDialog();
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.feedback_outlined,
              title: AppLocalizations.of(context)!.feedback,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('感谢您的反馈！'),
                    backgroundColor:
                        Theme.of(context).snackBarTheme.backgroundColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Switch(
                value: value,
                onChanged: (newValue) {
                  // 检查是否登录
                  if (!state.isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('请先登录后才能使用自动备份功能'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        action: SnackBarAction(
                          label: '去登录',
                          textColor: Colors.white,
                          onPressed: () {
                            _showLoginDialog(context);
                          },
                        ),
                      ),
                    );
                    return;
                  }
                  onChanged(newValue);
                },
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        height: 1,
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '选择登录方式',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneAuthPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_android),
                  label: const Text('手机号登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEmailLoginDialog(context);
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('邮箱登录'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showEmailLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegister = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isRegister ? '邮箱注册' : '邮箱登录',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: '邮箱',
                  labelStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    isRegister = !isRegister;
                  });
                },
                child: Text(
                  isRegister ? '已有账号？去登录' : '没有账号？去注册',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;
                return TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final email = emailController.text.trim();
                          final password = passwordController.text;

                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请填写邮箱和密码')),
                            );
                            return;
                          }

                          if (isRegister) {
                            context.read<AuthBloc>().add(Register(
                                  email: email,
                                  password: password,
                                ));
                          } else {
                            context.read<AuthBloc>().add(Login(
                                  email: email,
                                  password: password,
                                ));
                          }
                          Navigator.pop(dialogContext);
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor),
                        )
                      : Text(
                          isRegister ? '注册' : '登录',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(
          AppLocalizations.of(context)!.confirmLogout,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const Logout());
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context)!.logout,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(
    String title,
    List<String> options,
    String currentValue,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: option == currentValue
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: option == currentValue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: option == currentValue
                        ? Icon(Icons.check,
                            color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '关于语音自传',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本: 1.0.0',
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              '语音自传是一款帮助用户通过语音记录人生经历并自动生成个人自传的智能应用。',
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              'Copyright © 2025 语音自传团队',
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.4)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '确定',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '清除缓存',
        ),
        content: const Text(
          '确定要清除所有缓存吗？此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('缓存已清除'),
                  backgroundColor:
                      Theme.of(context).snackBarTheme.backgroundColor,
                ),
              );
            },
            child: Text(
              '清除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
