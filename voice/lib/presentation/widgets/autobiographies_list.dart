import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/ai_generation/ai_generation_state.dart';

import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/presentation/widgets/ai_generation_widget.dart';
import 'package:voice_autobiography_flutter/presentation/pages/autobiography_versions_page.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography_version/autobiography_version_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography_version/autobiography_version_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography_version/autobiography_version_state.dart';

class AutobiographiesList extends StatefulWidget {
  const AutobiographiesList({super.key});

  @override
  State<AutobiographiesList> createState() => _AutobiographiesListState();
}

class _AutobiographiesListState extends State<AutobiographiesList>
    with AutomaticKeepAliveClientMixin {
  // 移除硬编码的深色主题颜色
  // static const Color _backgroundColor = Color(0xFF121212);
  // static const Color _cardColor = Color(0xFF1E1E1E);
  // static const Color _accentColor = Color(0xFF00BCD4);

  String _selectedChapter = '';
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 确保组件初始化时加载数据
    context.read<AutobiographyBloc>().add(const LoadAutobiographies());

    // 检查是否有已完成但未保存的生成结果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingGenerationResult();
    });
  }

  /// 检查是否有待保存的生成结果
  void _checkPendingGenerationResult() {
    final aiState = context.read<AiGenerationBloc>().state;
    if (aiState.status == AiGenerationStatus.completed &&
        aiState.generationResult != null) {
      // 显示提示，引导用户保存
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('您有一个已生成的自传尚未保存，请点击下方按钮保存'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              // 重新打开生成页面查看结果
              final voiceRecordBloc = context.read<VoiceRecordBloc>();
              final autobiographyBloc = context.read<AutobiographyBloc>();
              final aiGenerationBloc = context.read<AiGenerationBloc>();

              // 使用空的 voice records 和现有的 autobiography
              final existingAutobiographies =
                  autobiographyBloc.state.autobiographies;

              _showGenerationPage(
                context,
                aiState.activeVoiceRecords ?? [],
                autobiographyBloc: autobiographyBloc,
                aiGenerationBloc: aiGenerationBloc,
                autobiography: existingAutobiographies.isNotEmpty
                    ? existingAutobiographies.first
                    : null,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 从自传内容中解析章节
  List<Map<String, String>> _parseChapters(String content) {
    final chapters = <Map<String, String>>[];
    final lines = content.split('\n');
    String currentTitle = '';
    StringBuffer currentContent = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('第') && line.contains('章')) {
        // 保存上一个章节
        if (currentTitle.isNotEmpty) {
          chapters.add({
            'title': currentTitle,
            'content': currentContent.toString().trim(),
          });
        }
        // 开始新章节
        currentTitle = line;
        currentContent = StringBuffer();
      } else {
        currentContent.writeln(line);
      }
    }

    // 保存最后一个章节
    if (currentTitle.isNotEmpty) {
      chapters.add({
        'title': currentTitle,
        'content': currentContent.toString().trim(),
      });
    }

    // 如果没有解析到章节，将整个内容作为一个默认章节
    if (chapters.isEmpty && content.trim().isNotEmpty) {
      chapters.add({
        'title': '正文',
        'content': content.trim(),
      });
    }

    return chapters;
  }

  // 提取短标签名
  String _getShortLabel(String chapterTitle) {
    // "第一章：无忧无虑的童年" -> "童年时光"
    if (chapterTitle == '正文') return '正文';
    if (chapterTitle.contains('童年')) return '童年时光';
    if (chapterTitle.contains('少年') ||
        chapterTitle.contains('求学') ||
        chapterTitle.contains('小学')) {
      return '少年求学';
    }
    if (chapterTitle.contains('大学')) return '大学岁月';
    if (chapterTitle.contains('工作') || chapterTitle.contains('生涯')) {
      return '工作生涯';
    }
    if (chapterTitle.contains('家庭')) return '家庭生活';
    // 尝试提取冒号后面的内容
    if (chapterTitle.contains('：')) {
      final parts = chapterTitle.split('：');
      if (parts.length > 1) {
        return parts[1].substring(0, parts[1].length.clamp(0, 4));
      }
    }
    return chapterTitle.substring(0, chapterTitle.length.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin required
    return Scaffold(
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Default
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '我的自传',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          // 版本管理按钮
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).iconTheme.color),
            tooltip: '版本管理',
            onPressed: () {
              final state = context.read<AutobiographyBloc>().state;
              if (state.autobiographies.isNotEmpty) {
                _showVersionManagement(context, state.autobiographies.first);
              }
            },
          ),
          IconButton(
            icon:
                Icon(Icons.ios_share, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              final state = context.read<AutobiographyBloc>().state;
              if (state.autobiographies.isNotEmpty) {
                _showExportOptions(context, state.autobiographies.first);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              _showUpdateOptions(context);
            },
          ),
        ],
      ),
      body: BlocListener<AutobiographyBloc, AutobiographyState>(
        listenWhen: (previous, current) =>
            previous.autobiographies != current.autobiographies,
        listener: (context, state) {
          // 当自传列表发生变化时,清空选中的章节,让其重新选择第一个
          if (mounted) {
            setState(() {
              _selectedChapter = '';
            });
          }
        },
        child: BlocListener<AiGenerationBloc, AiGenerationState>(
          listener: (context, state) {
            if (state.status == AiGenerationStatus.completed &&
                state.generationResult != null) {
              // 检查是否是刚恢复的状态（不是即时生成的）
              // 这里简化处理，只要completed都提示（如果已经在AI页面则不会有影响）
              _checkPendingGenerationResult();
            } else if (state.status == AiGenerationStatus.error &&
                state.error != null &&
                state.error!.contains('后台生成任务')) {
              // 显示后台任务错误
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  action: SnackBarAction(
                    label: '重试',
                    textColor: Colors.white,
                    onPressed: () {
                      // 可以添加重试逻辑，或者引导用户去生成页面
                      _showCreateAutobiographyDialog(context);
                    },
                  ),
                ),
              );
            }
          },
          child: BlocBuilder<AutobiographyBloc, AutobiographyState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor),
                );
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<AutobiographyBloc>()
                              .add(const LoadAutobiographies());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              if (state.autobiographies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无自传',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '从您的语音记录生成第一篇自传吧',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showCreateAutobiographyDialog(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('创建自传'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 显示第一篇自传
              final autobiography = state.autobiographies.first;
              final chapters = _parseChapters(autobiography.content);

              // 如果没有选中章节，默认选中第一个
              if (_selectedChapter.isEmpty && chapters.isNotEmpty) {
                _selectedChapter =
                    _getShortLabel(chapters.first['title'] ?? '');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 最后更新时间
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      '最后更新: ${DateFormat('yyyy年M月d日 HH:mm').format(autobiography.lastModifiedAt)}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // 章节标签导航 - 只有多个章节且不是"正文"时才显示
                  if (chapters.length > 1 ||
                      (chapters.length == 1 &&
                          _getShortLabel(chapters.first['title'] ?? '') !=
                              '正文'))
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          final label = _getShortLabel(chapter['title'] ?? '');
                          final isSelected = _selectedChapter == label;

                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedChapter = label;
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isSelected)
                                    Container(
                                      width: 20,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (chapters.length > 1 ||
                      (chapters.length == 1 &&
                          _getShortLabel(chapters.first['title'] ?? '') !=
                              '正文'))
                    const SizedBox(height: 16),

                  // 章节内容
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        return _buildChapterCard(
                          context,
                          chapter['title'] ?? '',
                          chapter['content'] ?? '',
                          autobiography.voiceRecordIds.length,
                          autobiography.lastModifiedAt,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ), // End BlocBuilder
        ), // End Inner BlocListener
      ), // End Outer BlocListener
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    String title,
    String content,
    int sourceCount,
    DateTime date,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // 复古内红/棕线
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 章节内容（移除标题显示）
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8, // 增加行高，像书本一样
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
            ),

            const SizedBox(height: 20),
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
            const SizedBox(height: 8),

            // 来源录音链接
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('来源录音: $sourceCount 条'),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '查看来源录音',
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sourceCount段录音',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy年M月d日').format(date),
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateOptions(BuildContext context) async {
    final autobiographyBloc = context.read<AutobiographyBloc>();
    final existingAutobiographies = autobiographyBloc.state.autobiographies;

    // 如果没有现有自传，直接调用创建自传对话框
    if (existingAutobiographies.isEmpty) {
      _showCreateAutobiographyDialog(context);
      return;
    }

    // 保存 widget 的 context，因为 BottomSheet 关闭后其 context 会失效
    final widgetContext = context;

    // 显示更新选项菜单
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(bottomSheetContext).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '更新自传',
              style: Theme.of(bottomSheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.add_circle_outline,
                  color: Theme.of(bottomSheetContext).primaryColor),
              title: Text('增量更新',
                  style: Theme.of(bottomSheetContext).textTheme.bodyLarge),
              subtitle: Text(
                '基于新增的语音记录更新现有自传',
                style: Theme.of(bottomSheetContext).textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // 使用 widget 的 context，而不是 BottomSheet 的 context
                _showCreateAutobiographyDialog(widgetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: Text('完整重新生成',
                  style: Theme.of(bottomSheetContext).textTheme.bodyLarge),
              subtitle: Text(
                '删除现有自传，基于所有语音记录重新生成',
                style: Theme.of(bottomSheetContext).textTheme.bodySmall,
              ),
              onTap: () {
                print('UI: Clicked Regenerate Complete option');
                Navigator.of(bottomSheetContext).pop();
                // 使用 widget 的 context
                _showRegenerateCompleteDialog(widgetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAutobiographyDialog(BuildContext context) async {
    final voiceRecordBloc = context.read<VoiceRecordBloc>();
    final allRecords = voiceRecordBloc.state.records;

    final validRecords = allRecords
        .where((record) =>
            (record.content.isNotEmpty) ||
            (record.transcription != null && record.transcription!.isNotEmpty))
        .toList();

    if (validRecords.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          // backgroundColor: default -> theme dialog color
          title: const Text('无法生成自传'),
          content: const Text(
            '请先录制语音并生成转写内容',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DefaultTabController.of(context).animateTo(0);
              },
              child: Text('去录音',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      );
      return;
    }

    final autobiographyBloc = context.read<AutobiographyBloc>();
    final existingAutobiographies = autobiographyBloc.state.autobiographies;

    final Set<String> includedRecordIds = existingAutobiographies
        .map((auto) => auto.voiceRecordIds)
        .expand((ids) => ids)
        .toSet();

    List<VoiceRecord> recordsToGenerate;
    String dialogTitle;
    String dialogContent;

    if (existingAutobiographies.isEmpty) {
      recordsToGenerate = validRecords;
      dialogTitle = '创建自传';
      dialogContent = '将基于您的 ${validRecords.length} 条语音记录生成自传';
    } else {
      recordsToGenerate = validRecords
          .where((record) => !includedRecordIds.contains(record.id))
          .toList();

      if (recordsToGenerate.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('没有新记录'),
            content: const Text(
              '所有语音记录都已包含在现有自传中',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
        return;
      }

      dialogTitle = '增量更新自传';
      dialogContent = '发现 ${recordsToGenerate.length} 条新记录，将增量更新您的自传';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('开始生成',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );

    print(
        'DEBUG: Dialog result: confirmed=$confirmed, context.mounted=${context.mounted}');
    if (confirmed == true && context.mounted) {
      print(
          'DEBUG: Calling _showGenerationPage with ${recordsToGenerate.length} records');
      print(
          'DEBUG: autobiography is ${existingAutobiographies.isNotEmpty ? "present" : "null"}');
      _showGenerationPage(
        context,
        recordsToGenerate,
        autobiographyBloc: autobiographyBloc,
        aiGenerationBloc: context.read<AiGenerationBloc>(),
        autobiography: existingAutobiographies.isNotEmpty
            ? existingAutobiographies.first
            : null,
      );
    }
  }

  void _showExportOptions(BuildContext context, Autobiography autobiography) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
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
              '导出选项',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.text_snippet,
                  color: Theme.of(context).iconTheme.color),
              title:
                  Text('导出为文本', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                _exportAsText(context, autobiography);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.share, color: Theme.of(context).iconTheme.color),
              title: Text('分享', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                _shareAutobiography(context, autobiography);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsText(BuildContext context, Autobiography autobiography) {
    final text = autobiography.content;
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('自传内容已复制到剪贴板'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _shareAutobiography(BuildContext context, Autobiography autobiography) {
    final text = autobiography.content;
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('自传内容已复制到剪贴板，可以分享给他人'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showRegenerateCompleteDialog(BuildContext context) async {
    final voiceRecordBloc = context.read<VoiceRecordBloc>();
    final allRecords = voiceRecordBloc.state.records;

    final validRecords = allRecords
        .where((record) =>
            (record.content.isNotEmpty) ||
            (record.transcription != null && record.transcription!.isNotEmpty))
        .toList();

    if (validRecords.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('无法生成自传'),
          content: const Text(
            '请先录制语音并生成转写内容',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DefaultTabController.of(context).animateTo(0);
              },
              child: Text('去录音',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      );
      return;
    }

    final autobiographyBloc = context.read<AutobiographyBloc>();
    final aiGenerationBloc = context.read<AiGenerationBloc>();
    final existingAutobiographies = autobiographyBloc.state.autobiographies;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完整重新生成自传'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '将基于所有 ${validRecords.length} 条语音记录重新生成自传',
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7)),
            ),
            if (existingAutobiographies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '现有自传将被删除，此操作不可撤销',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              print('UI: Clicked Confirm Regenerate button');
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('确认重新生成'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('UI: Calling _showGenerationPage');
      _showGenerationPage(context, validRecords,
          autobiographyBloc: autobiographyBloc,
          aiGenerationBloc: aiGenerationBloc,
          autobiography: null);
    }
  }

  void _showGenerationPage(BuildContext context, List<VoiceRecord> records,
      {required AutobiographyBloc autobiographyBloc,
      required AiGenerationBloc aiGenerationBloc,
      Autobiography? autobiography}) {
    print('DEBUG: _showGenerationPage entered');
    print('DEBUG: records count: ${records.length}');
    print('DEBUG: autobiography: ${autobiography?.id ?? "null"}');
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (modalContext) => BlocProvider.value(
          value: autobiographyBloc,
          child: BlocProvider.value(
            value: aiGenerationBloc,
            child: Scaffold(
              // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: BlocBuilder<AiGenerationBloc, AiGenerationState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        // 如果正在生成，显示确认对话框
                        if (state.isGenerating || state.isOptimizing) {
                          showDialog(
                            context: modalContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('确认关闭'),
                              content: const Text(
                                'AI 正在生成自传，关闭后生成将在后台继续。\n\n'
                                '生成完成后，您可以在应用重新打开时看到恢复提示。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('继续等待'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(modalContext).pop();
                                  },
                                  child: const Text('后台生成'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Navigator.of(modalContext).pop();
                        }
                      },
                    );
                  },
                ),
                title: Text(
                  autobiography != null ? 'AI增量更新自传' : 'AI生成自传',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              body: AiGenerationWidget(
                voiceRecords: records,
                currentAutobiography: autobiography,
                skipAutoTrigger: aiGenerationBloc.state.hasGeneratedContent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示版本管理菜单
  void _showVersionManagement(
      BuildContext context, Autobiography autobiography) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.save, color: Theme.of(context).primaryColor),
              title: const Text('保存当前版本'),
              subtitle: const Text('保存当前自传为历史快照'),
              onTap: () {
                Navigator.pop(context);
                _showSaveVersionDialog(context, autobiography);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.restore, color: Theme.of(context).primaryColor),
              title: const Text('恢复历史版本'),
              subtitle: const Text('从历史快照中恢复自传'),
              onTap: () {
                Navigator.pop(context);
                _navigateToVersionsList(context, autobiography);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 显示保存版本对话框
  void _showSaveVersionDialog(
      BuildContext context, Autobiography autobiography) {
    final TextEditingController nameController = TextEditingController();
    final now = DateTime.now();
    final defaultName = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    nameController.text = defaultName;

    showDialog(
      context: context,
      barrierDismissible: false, // 防止保存过程中误触关闭
      builder: (dialogContext) =>
          BlocListener<AutobiographyVersionBloc, AutobiographyVersionState>(
        listener: (context, state) {
          if (state.hasSuccess) {
            // 保存成功
            Navigator.pop(dialogContext); // 关闭对话框

            if (mounted) {
              ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('版本已保存'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state.hasError) {
            // 保存失败
            Navigator.pop(dialogContext); // 关闭对话框

            if (mounted) {
              ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? '保存失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: AlertDialog(
          title: const Text('保存版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入版本名称:'),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: '版本名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text(
                '当前字数: ${autobiography.wordCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            BlocBuilder<AutobiographyVersionBloc, AutobiographyVersionState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return ElevatedButton(
                  onPressed: () {
                    final versionName = nameController.text.trim();
                    if (versionName.isEmpty) return;

                    // 保存版本
                    final versionBloc =
                        context.read<AutobiographyVersionBloc>();
                    print(
                        '[UI] Dispatching SaveCurrentVersion for autoId: ${autobiography.id}');

                    versionBloc.add(SaveCurrentVersion(
                      autobiography: autobiography,
                      customName: versionName,
                    ));
                  },
                  child: const Text('保存'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到版本列表页面
  void _navigateToVersionsList(
      BuildContext dialogContext, Autobiography autobiography) async {
    final result = await Navigator.push(
      dialogContext,
      MaterialPageRoute(
        builder: (context) => AutobiographyVersionsPage(
          autobiography: autobiography,
          onRestore: (content, chapters) {
            // 使用widget的context而不是dialog的context
            if (mounted) {
              _restoreVersion(this.context, autobiography, content, chapters);
            }
          },
        ),
      ),
    );

    // 如果恢复了版本,刷新自传列表
    if (result == true && mounted) {
      context.read<AutobiographyBloc>().add(const LoadAutobiographies());
    }
  }

  /// 恢复版本
  void _restoreVersion(
    BuildContext context,
    Autobiography autobiography,
    String content,
    List<Map<String, dynamic>> chaptersData,
  ) {
    // 转换章节数据
    final chapters = chaptersData.map((data) {
      return Chapter(
        id: data['id'] as String,
        title: data['title'] as String,
        content: data['content'] as String,
        order: data['order'] as int,
        sourceRecordIds:
            (data['sourceRecordIds'] as List<dynamic>).cast<String>(),
        lastModifiedAt:
            DateTime.fromMillisecondsSinceEpoch(data['lastModifiedAt'] as int),
      );
    }).toList();

    // 更新自传
    final updatedAutobiography = autobiography.copyWith(
      content: content,
      chapters: chapters,
      lastModifiedAt: DateTime.now(),
    );

    print('[UI] Restoring version for ID: ${updatedAutobiography.id}');

    // 保存更新
    context.read<AutobiographyBloc>().add(
          UpdateAutobiography(updatedAutobiography),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('版本已恢复'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
