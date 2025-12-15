import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/auth/auth_state.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  // 深色主题颜色
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _accentColor = Color(0xFF00BCD4);

  // 模拟设置值
  String _recordingQuality = '高质量';
  String _asrProvider = '讯飞';
  String _aiProvider = '豆包';
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '个人中心',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // 更多设置
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // 显示同步结果
          if (state.syncStatus == SyncStatus.success && state.syncMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.syncMessage!),
                backgroundColor: Colors.green[700],
              ),
            );
            // 刷新数据
            context.read<VoiceRecordBloc>().add(const LoadVoiceRecords());
            context.read<AutobiographyBloc>().add(const LoadAutobiographies());
          } else if (state.syncStatus == SyncStatus.error && state.syncMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.syncMessage!),
                backgroundColor: Colors.red[700],
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
              
              // 云同步功能区
              _buildCloudSyncSection(),
              
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
                      ? _accentColor.withOpacity(0.3)
                      : _accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLoggedIn ? Icons.person : Icons.person_outline,
                  color: _accentColor,
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
                      isLoggedIn ? (user?.nickname ?? user?.email ?? '用户') : '未登录',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? user?.email ?? '' : '登录后可同步数据到云端',
                      style: TextStyle(
                        color: Colors.grey[500],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLoggedIn ? _cardColor : _accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLoggedIn ? '退出' : '登录',
                    style: TextStyle(
                      color: isLoggedIn ? Colors.grey[400] : Colors.white,
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

  Widget _buildCloudSyncSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoggedIn = state.isLoggedIn;
        final isSyncing = state.syncStatus == SyncStatus.uploading || 
                          state.syncStatus == SyncStatus.downloading;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: _accentColor, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '云端同步',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (!isLoggedIn)
                  Text(
                    '登录账号后可将数据同步到云端，换手机不丢失',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSyncing ? null : () {
                            context.read<AuthBloc>().add(const UploadData());
                          },
                          icon: state.syncStatus == SyncStatus.uploading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload, size: 18),
                          label: const Text('上传数据'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSyncing ? null : () {
                            _showRestoreConfirmDialog(context);
                          },
                          icon: state.syncStatus == SyncStatus.downloading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _accentColor,
                                  ),
                                )
                              : const Icon(Icons.cloud_download, size: 18),
                          label: const Text('恢复数据'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentColor,
                            side: const BorderSide(color: _accentColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('录音数量', '$recordCount', '条'),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            _buildStatItem('总时长', '$totalMinutes', '分钟'),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            _buildStatItem('自传字数', '$totalWords', '字'),
          ],
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
              style: const TextStyle(
                color: _accentColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.high_quality,
              title: '录音质量',
              value: _recordingQuality,
              onTap: () {
                _showOptionsDialog(
                  '录音质量',
                  ['高质量', '中质量', '低质量'],
                  _recordingQuality,
                  (value) {
                    setState(() {
                      _recordingQuality = value;
                    });
                  },
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.record_voice_over,
              title: '语音识别服务',
              value: _asrProvider,
              onTap: () {
                _showOptionsDialog(
                  '语音识别服务',
                  ['讯飞', '阿里云', '腾讯云', 'Google Cloud'],
                  _asrProvider,
                  (value) {
                    setState(() {
                      _asrProvider = value;
                    });
                  },
                );
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.psychology,
              title: 'AI生成服务',
              value: _aiProvider,
              onTap: () {
                _showOptionsDialog(
                  'AI生成服务',
                  ['豆包', 'OpenAI', '通义千问', '文心一言', 'Claude'],
                  _aiProvider,
                  (value) {
                    setState(() {
                      _aiProvider = value;
                    });
                  },
                );
              },
            ),
            _buildDivider(),
            _buildSwitchItem(
              icon: Icons.cloud_upload,
              title: '自动备份',
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.info_outline,
              title: '关于应用',
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.cleaning_services,
              title: '清除缓存',
              onTap: () {
                _showClearCacheDialog();
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.feedback_outlined,
              title: '意见反馈',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('感谢您的反馈！'),
                    backgroundColor: _cardColor,
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
            Icon(icon, color: Colors.grey[400], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: Colors.grey[800],
        height: 1,
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isRegister = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            isRegister ? '注册账号' : '登录账号',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '邮箱',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _accentColor),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _accentColor),
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
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('取消', style: TextStyle(color: Colors.grey[400])),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;
                return TextButton(
                  onPressed: isLoading ? null : () {
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
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isRegister ? '注册' : '登录',
                          style: const TextStyle(color: _accentColor),
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
        backgroundColor: _cardColor,
        title: const Text('退出登录', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要退出登录吗？',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const Logout());
              Navigator.pop(dialogContext);
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('恢复数据', style: TextStyle(color: Colors.white)),
        content: Text(
          '从云端恢复数据会覆盖本地相同ID的数据，确定继续吗？',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const DownloadData());
              Navigator.pop(dialogContext);
            },
            child: const Text('恢复', style: TextStyle(color: _accentColor)),
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
      backgroundColor: _cardColor,
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
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    color: option == currentValue ? _accentColor : Colors.white,
                  ),
                ),
                trailing: option == currentValue
                    ? const Icon(Icons.check, color: _accentColor)
                    : null,
                onTap: () {
                  onSelected(option);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
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
        backgroundColor: _cardColor,
        title: const Text(
          '关于语音自传',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本: 1.0.0',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            Text(
              '语音自传是一款帮助用户通过语音记录人生经历并自动生成个人自传的智能应用。',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Copyright © 2025 语音自传团队',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '确定',
              style: TextStyle(color: _accentColor),
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
        backgroundColor: _cardColor,
        title: const Text(
          '清除缓存',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要清除所有缓存吗？此操作不可恢复。',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('缓存已清除'),
                  backgroundColor: _cardColor,
                ),
              );
            },
            child: const Text(
              '清除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
