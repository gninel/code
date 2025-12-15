import 'package:flutter/material.dart';

import '../widgets/integrated_recording_widget.dart';
import '../widgets/voice_records_list.dart';
import '../widgets/autobiographies_list.dart';
import '../widgets/profile_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 深色主题颜色
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _navBarColor = Color(0xFF1E1E1E);
  static const Color _accentColor = Color(0xFF00BCD4);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          // 口述页面（录音）
          RecordingTab(),
          // 记录页面
          VoiceRecordsTab(),
          // 自传页面
          AutobiographiesTab(),
          // 个人页面
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBarColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _navBarColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: '口述',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: '记录',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: '自传',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '个人',
            ),
          ],
        ),
      ),
    );
  }
}

/// 口述标签页（录音）
class RecordingTab extends StatelessWidget {
  const RecordingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: IntegratedRecordingWidget(),
    );
  }
}

/// 记录标签页
class VoiceRecordsTab extends StatelessWidget {
  const VoiceRecordsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: VoiceRecordsList(),
    );
  }
}

/// 自传标签页
class AutobiographiesTab extends StatelessWidget {
  const AutobiographiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: AutobiographiesList(),
    );
  }
}

/// 个人标签页
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: ProfileWidget(),
    );
  }
}


/// 设置内容
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  // 模拟设置值
  String _recordingQuality = '高质量';
  String _audioFormat = 'AAC';
  String _asrProvider = '讯飞';
  String _aiProvider = '豆包';
  String _storageLocation = '应用专属目录';
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设置',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView(
            children: [
              // 录音设置
              _buildSettingsSection(
                context,
                '录音设置',
                [
                  _buildSettingsTile(
                    context,
                    '录音质量',
                    _recordingQuality,
                    Icons.high_quality,
                    onTap: () {
                      _showOptionsDialog(
                        context,
                        '录音质量',
                        ['高质量', '中质量', '低质量'],
                        _recordingQuality,
                        (value) {
                          setState(() {
                            _recordingQuality = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('录音质量已设置为: $value')),
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    '音频格式',
                    _audioFormat,
                    Icons.audio_file,
                    onTap: () {
                      _showOptionsDialog(
                        context,
                        '音频格式',
                        ['AAC', 'MP3', 'WAV'],
                        _audioFormat,
                        (value) {
                          setState(() {
                            _audioFormat = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('音频格式已设置为: $value')),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),

              // AI设置
              _buildSettingsSection(
                context,
                'AI设置',
                [
                  _buildSettingsTile(
                    context,
                    '语音识别服务商',
                    _asrProvider,
                    Icons.record_voice_over,
                    onTap: () {
                      _showOptionsDialog(
                        context,
                        '语音识别服务商',
                        ['讯飞', '阿里云', '腾讯云', 'Google Cloud'],
                        _asrProvider,
                        (value) {
                          setState(() {
                            _asrProvider = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('语音识别服务商已设置为: $value')),
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    'AI生成服务商',
                    _aiProvider,
                    Icons.psychology,
                    onTap: () {
                      _showOptionsDialog(
                        context,
                        'AI生成服务商',
                        ['豆包', 'OpenAI', '通义千问', '文心一言', 'Claude'],
                        _aiProvider,
                        (value) {
                          setState(() {
                            _aiProvider = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('AI生成服务商已设置为: $value')),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),

              // 存储设置
              _buildSettingsSection(
                context,
                '存储设置',
                [
                  _buildSettingsTile(
                    context,
                    '存储位置',
                    _storageLocation,
                    Icons.storage,
                    onTap: () {
                      _showOptionsDialog(
                        context,
                        '存储位置',
                        ['应用专属目录', 'SD卡'],
                        _storageLocation,
                        (value) {
                          setState(() {
                            _storageLocation = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('存储位置已设置为: $value')),
                          );
                        },
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('自动备份'),
                    subtitle: const Text('自动将录音备份到云端'),
                    value: _autoBackup,
                    onChanged: (value) {
                      setState(() {
                        _autoBackup = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('自动备份已${value ? '开启' : '关闭'}')),
                      );
                    },
                    secondary: const Icon(Icons.cloud_upload),
                  ),
                ],
              ),

              // 其他设置
              _buildSettingsSection(
                context,
                '其他',
                [
                  _buildSettingsTile(
                    context,
                    '关于应用',
                    '',
                    Icons.info,
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    '清除缓存',
                    '',
                    Icons.cleaning_services,
                    onTap: () {
                      _showClearCacheDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showOptionsDialog(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    Function(String) onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  onSelected(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于语音自传'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('语音自传是一款帮助用户通过语音记录人生经历并自动生成个人自传的智能应用。'),
            SizedBox(height: 8),
            Text('Copyright © 2025 语音自传团队'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 模拟清除缓存
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}