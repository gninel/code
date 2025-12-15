import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/autobiography/autobiography_event.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/presentation/widgets/ai_generation_widget.dart';

class AutobiographiesList extends StatefulWidget {
  const AutobiographiesList({super.key});

  @override
  State<AutobiographiesList> createState() => _AutobiographiesListState();
}

class _AutobiographiesListState extends State<AutobiographiesList> {
  // 深色主题颜色
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _accentColor = Color(0xFF00BCD4);

  String _selectedChapter = '';
  final ScrollController _scrollController = ScrollController();

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
        'title': '我的故事',
        'content': content.trim(),
      });
    }
    
    return chapters;
  }

  // 提取短标签名
  String _getShortLabel(String chapterTitle) {
    // "第一章：无忧无虑的童年" -> "童年时光"
    if (chapterTitle.contains('童年')) return '童年时光';
    if (chapterTitle.contains('少年') || chapterTitle.contains('求学') || chapterTitle.contains('小学')) return '少年求学';
    if (chapterTitle.contains('大学')) return '大学岁月';
    if (chapterTitle.contains('工作') || chapterTitle.contains('生涯')) return '工作生涯';
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '我的自传',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: () {
              final state = context.read<AutobiographyBloc>().state;
              if (state.autobiographies.isNotEmpty) {
                _showExportOptions(context, state.autobiographies.first);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _showCreateAutobiographyDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AutobiographyBloc, AutobiographyState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
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
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '加载失败',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AutobiographyBloc>().add(const LoadAutobiographies());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
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
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无自传',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从您的语音记录生成第一篇自传吧',
                    style: TextStyle(
                      color: Colors.grey[400],
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
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            _selectedChapter = _getShortLabel(chapters.first['title'] ?? '');
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
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ),

              // 章节标签导航
              if (chapters.isNotEmpty)
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
                                  color: isSelected ? _accentColor : Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isSelected)
                                Container(
                                  width: 20,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: _accentColor,
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
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    String title,
    String content,
    int sourceCount,
    DateTime date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 章节标题
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 章节内容
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 来源录音链接
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('来源录音: $sourceCount 条'),
                      backgroundColor: _cardColor,
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: _accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '查看来源录音',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sourceCount段录音',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('yyyy年M月d日').format(date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAutobiographyDialog(BuildContext context) async {
    final voiceRecordBloc = context.read<VoiceRecordBloc>();
    final allRecords = voiceRecordBloc.state.records;

    final validRecords = allRecords.where((record) =>
      record.transcription != null && record.transcription!.isNotEmpty
    ).toList();

    if (validRecords.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _cardColor,
          title: const Text('无法生成自传', style: TextStyle(color: Colors.white)),
          content: Text(
            '请先录制语音并生成转写内容',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('知道了', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DefaultTabController.of(context).animateTo(0);
              },
              child: Text('去录音', style: TextStyle(color: _accentColor)),
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
      recordsToGenerate = validRecords.where((record) =>
        !includedRecordIds.contains(record.id)
      ).toList();

      if (recordsToGenerate.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cardColor,
            title: const Text('没有新记录', style: TextStyle(color: Colors.white)),
            content: Text(
              '所有语音记录都已包含在现有自传中',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('知道了', style: TextStyle(color: Colors.grey[400])),
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
        backgroundColor: _cardColor,
        title: Text(dialogTitle, style: const TextStyle(color: Colors.white)),
        content: Text(dialogContent, style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('开始生成', style: TextStyle(color: _accentColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _showGenerationPage(
        context, 
        recordsToGenerate, 
        autobiography: existingAutobiographies.isNotEmpty ? existingAutobiographies.first : null,
      );
    }
  }

  void _showExportOptions(BuildContext context, Autobiography autobiography) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '导出选项',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.white),
              title: const Text('导出为文本', style: TextStyle(color: Colors.white)),
              onTap: () {
                _exportAsText(context, autobiography);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('分享', style: TextStyle(color: Colors.white)),
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
        backgroundColor: _cardColor,
      ),
    );
  }

  void _shareAutobiography(BuildContext context, Autobiography autobiography) {
    final text = autobiography.content;
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('自传内容已复制到剪贴板，可以分享给他人'),
        backgroundColor: _cardColor,
      ),
    );
  }

  void _showGenerationPage(BuildContext context, List<VoiceRecord> records, {Autobiography? autobiography}) {
    // 捕获 AutobiographyBloc，因为 showModalBottomSheet 的 context 不包含它
    final autobiographyBloc = context.read<AutobiographyBloc>();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (modalContext) => BlocProvider.value(
          value: autobiographyBloc,
          child: Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              backgroundColor: _backgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(modalContext).pop(),
              ),
              title: Text(
                autobiography != null ? 'AI增量更新自传' : 'AI生成自传',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            body: AiGenerationWidget(
              voiceRecords: records,
              currentAutobiography: autobiography,
            ),
          ),
        ),
      ),
    );
  }
}