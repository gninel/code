import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_autobiography_flutter/generated/app_localizations.dart';

import '../widgets/integrated_recording_widget.dart';
import '../widgets/interview_widget.dart';
import '../widgets/voice_records_list.dart';
import '../widgets/autobiographies_list.dart';
import '../widgets/profile_widget.dart';
import '../widgets/ai_generation_widget.dart';
import '../bloc/ai_generation/ai_generation_bloc.dart';
import '../bloc/ai_generation/ai_generation_state.dart';
import '../bloc/interview/interview_bloc.dart';
import '../bloc/interview/interview_event.dart';
import '../../data/services/ai_generation_persistence_service.dart';
import '../../core/utils/injection.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 移除硬编码的颜色
  // static const Color _backgroundColor = Color(0xFF121212);
  // static const Color _navBarColor = Color(0xFF1E1E1E);
  // static const Color _accentColor = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _checkUnfinishedTasks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 检查是否有未完成的 AI 生成任务
  Future<void> _checkUnfinishedTasks() async {
    final persistenceService = getIt<AiGenerationPersistenceService>();

    if (persistenceService.hasUnfinishedTask()) {
      final taskInfo = persistenceService.getUnfinishedTaskInfo();

      // 检查任务是否超时
      if (persistenceService.isTaskTimeout()) {
        // 超时任务直接清除
        await persistenceService.clearGenerationState();
        return;
      }

      // 如果有已生成的内容，显示恢复提示
      if (taskInfo?['generatedContent'] != null &&
          taskInfo!['status'] == 'completed') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showRestoreDialog(taskInfo);
          }
        });
      } else {
        // 生成中的任务已失败，清除状态
        await persistenceService.clearGenerationState();
      }
    }
  }

  /// 显示恢复对话框
  void _showRestoreDialog(Map<String, dynamic> taskInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.foundUnsavedAutobiography),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.restorePrompt,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 放弃恢复，清除状态
              final persistenceService =
                  getIt<AiGenerationPersistenceService>();
              await persistenceService.clearGenerationState();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.discard),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 切换到自传页面
              setState(() {
                _currentIndex = 2;
              });
              _pageController.animateToPage(
                2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              // 显示提示信息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.checkInAutobiography),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.continueEdit),
          ),
        ],
      ),
    );
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
    return BlocListener<AiGenerationBloc, AiGenerationState>(
      listener: (context, state) {
        // 当 AI 生成完成时，显示通知（仅在主页面，不在生成页面时）
        if (state.status == AiGenerationStatus.completed &&
            state.generationResult != null) {
          // 检查当前是否在生成页面（通过检查路由栈）
          final isOnGenerationPage =
              ModalRoute.of(context)?.settings.name?.contains('generation') ??
                  false;

          if (!isOnGenerationPage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.autobiographyGenerated),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: AppLocalizations.of(context)!.view,
                  textColor: Colors.white,
                  onPressed: () {
                    // 切换到自传页面
                    setState(() {
                      _currentIndex = 2;
                    });
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            );
          }
        }
      },
      child: BlocBuilder<AiGenerationBloc, AiGenerationState>(
        builder: (context, generationState) {
          return Scaffold(
            // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Default
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
                color:
                    Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 浅色阴影
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (generationState.isGenerating ||
                      generationState.isOptimizing ||
                      (generationState.hasGeneratedContent &&
                          !generationState.isIdle))
                    _buildGenerationStatus(context, generationState),
                  BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: _onTabTapped,
                    type: BottomNavigationBarType.fixed,
                    // properties taken from Theme if not specified, but we can be explicit
                    backgroundColor: Theme.of(context)
                        .bottomNavigationBarTheme
                        .backgroundColor,
                    selectedItemColor: Theme.of(context)
                        .bottomNavigationBarTheme
                        .selectedItemColor,
                    unselectedItemColor: Theme.of(context)
                        .bottomNavigationBarTheme
                        .unselectedItemColor,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.mic_none),
                        activeIcon: const Icon(Icons.mic),
                        label: AppLocalizations.of(context)!.tabDictation,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.folder_outlined),
                        activeIcon: const Icon(Icons.folder),
                        label: AppLocalizations.of(context)!.tabRecords,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.auto_stories_outlined),
                        activeIcon: const Icon(Icons.auto_stories),
                        label: AppLocalizations.of(context)!.tabAutobiography,
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.person_outline),
                        activeIcon: const Icon(Icons.person),
                        label: AppLocalizations.of(context)!.tabProfile,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenerationStatus(BuildContext context, AiGenerationState state) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title:
                    Text('自传生成', style: Theme.of(context).textTheme.titleLarge),
                leading: IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: AiGenerationWidget(
                voiceRecords: state.activeVoiceRecords,
                currentAutobiography: state.baseAutobiography,
              ),
            ),
          ),
        );
      },
      child: Container(
        // Status bar style adaptation
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                if (state.isGenerating || state.isOptimizing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                else if (state.isCompleted || state.isOptimized)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16)
                else if (state.hasError)
                  Icon(Icons.error,
                      color: Theme.of(context).colorScheme.error, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.isGenerating
                        ? '正在生成自传...'
                        : state.isOptimizing
                            ? '正在优化自传...'
                            : state.hasError
                                ? '自传生成失败'
                                : '自传生成完成，点击查看',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_up,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.5),
                    size: 20),
              ],
            ),
            if (state.isGenerating || state.isOptimizing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Theme.of(context).dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 口述标签页（录音）
class RecordingTab extends StatefulWidget {
  const RecordingTab({super.key});

  @override
  State<RecordingTab> createState() => _RecordingTabState();
}

class _RecordingTabState extends State<RecordingTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const String _tabIndexKey = 'recording_tab_index';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedTabIndex();

    // 监听 tab 变化并保存
    _tabController.addListener(_saveTabIndex);
  }

  Future<void> _loadSavedTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_tabIndexKey) ?? 0;
    if (mounted && savedIndex != _tabController.index) {
      _tabController.index = savedIndex;
    }
  }

  Future<void> _saveTabIndex() async {
    if (_tabController.indexIsChanging) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabIndexKey, _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_saveTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '口述',
          style: Theme.of(context).textTheme.titleLarge, // 使用titleLarge与记录页面一致
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 2,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          labelStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(text: '自主录音'),
            Tab(text: 'AI采访'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 自主录音模式
          IntegratedRecordingWidget(),
          // AI采访模式
          InterviewModeTab(),
        ],
      ),
    );
  }
}

/// AI采访模式标签页
class InterviewModeTab extends StatefulWidget {
  const InterviewModeTab({super.key});

  @override
  State<InterviewModeTab> createState() => _InterviewModeTabState();
}

class _InterviewModeTabState extends State<InterviewModeTab> {
  @override
  void initState() {
    super.initState();
    // 延迟加载上次的会话，避免在 build 阶段触发事件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InterviewBloc>().add(const LoadLastInterviewSession());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const InterviewWidget();
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
