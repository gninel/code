import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_event.dart';
import '../bloc/task/task_state.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_state.dart';
import '../bloc/player/player_event.dart';
import '../models/audio_task.dart';
import 'library_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  int _currentTab = 0;
  String _selectedFormat = 'mp3';
  String _selectedBitrate = '192k';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildConvertTab(),
            const LibraryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniPlayer(),
          NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (i) => setState(() => _currentTab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.link),
                selectedIcon: Icon(Icons.link, color: Colors.red),
                label: '转换',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music, color: Colors.red),
                label: '音频库',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvertTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Logo
          Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 12),
              const Text(
                'MusicPocket',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '粘贴视频链接',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '支持 TikTok、抖音、B站、小红书',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // URL 输入框
          TextField(
            controller: _urlController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '粘贴分享链接或文本...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                onPressed: _pasteFromClipboard,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 格式选择
          Row(
            children: [
              _buildFormatChip('MP3', 'mp3'),
              const SizedBox(width: 8),
              _buildFormatChip('M4A', 'm4a'),
              const SizedBox(width: 8),
              _buildFormatChip('AAC', 'aac'),
              const Spacer(),
              _buildBitrateDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          // 转换按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onConvert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.equalizer, size: 20),
                  SizedBox(width: 8),
                  Text('开始转换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 任务状态
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskDetecting) {
                return _buildStatusCard('正在识别链接...', null, 0);
              }
              if (state is TaskSubmitted || state is TaskProcessing) {
                final task = state is TaskSubmitted
                    ? (state).task
                    : (state as TaskProcessing).task;
                return _buildStatusCard(
                  task.displayTitle,
                  _statusText(task.status),
                  task.progress / 100,
                );
              }
              if (state is TaskCompleted) {
                return _buildCompletedCard(state.task);
              }
              if (state is TaskFailed) {
                return _buildErrorCard(state.error);
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 32),
          // 使用流程
          _buildFlowSteps(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(width: 4, height: 10, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 4, height: 28, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 4, height: 6, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String label, String value) {
    final selected = _selectedFormat == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFormat = value),
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBitrateDropdown() {
    return DropdownButton<String>(
      value: _selectedBitrate,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: '128k', child: Text('128 kbps')),
        DropdownMenuItem(value: '192k', child: Text('192 kbps')),
        DropdownMenuItem(value: '320k', child: Text('320 kbps')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _selectedBitrate = v);
      },
    );
  }

  Widget _buildStatusCard(String title, String? subtitle, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Colors.black),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(AudioTask task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${task.displayAuthor}  ${task.durationText}  ${task.audioFormat?.toUpperCase()}  ${task.fileSizeText}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (task.isDownloaded) {
                      context.read<PlayerBloc>().add(PlayTrack(task));
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('播放'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<TaskBloc>().add(ClearCurrentTask());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('继续转换'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => context.read<TaskBloc>().add(ClearCurrentTask()),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowSteps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStep(Icons.link, '粘贴'),
        const Icon(Icons.chevron_right, color: Colors.grey),
        _buildStep(Icons.equalizer, '转换'),
        const Icon(Icons.chevron_right, color: Colors.grey),
        _buildStep(Icons.headphones, '离线听'),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state.currentTrack == null) return const SizedBox();
        final track = state.currentTrack!;
        return GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PlayerScreen())),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.displayTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.displayAuthor,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => context.read<PlayerBloc>().add(TogglePlayPause()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return '等待处理';
      case 'parsing':
        return '正在解析视频信息...';
      case 'downloading':
        return '正在下载...';
      case 'transcoding':
        return '正在转换音频...';
      default:
        return status;
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  void _onConvert() {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;
    context.read<TaskBloc>().add(SubmitUrl(
      text: text,
      format: _selectedFormat,
      bitrate: _selectedBitrate,
    ));
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
