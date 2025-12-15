import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_event.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/presentation/pages/voice_record_detail_page.dart';

class VoiceRecordsList extends StatefulWidget {
  const VoiceRecordsList({super.key});

  @override
  State<VoiceRecordsList> createState() => _VoiceRecordsListState();
}

class _VoiceRecordsListState extends State<VoiceRecordsList> {
  bool _isSelecting = false;
  final Set<String> _selectedRecordIds = {};
  String _selectedTag = '';
  final TextEditingController _searchController = TextEditingController();

  // 深色主题颜色
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _searchBarColor = Color(0xFF2A2A2A);

  // 标签颜色
  static const List<Color> _tagColors = [
    Color(0xFF00BCD4), // 青色
    Color(0xFFFF7043), // 橙红色
    Color(0xFF66BB6A), // 绿色
    Color(0xFFAB47BC), // 紫色
    Color(0xFFFFCA28), // 黄色
    Color(0xFF42A5F5), // 蓝色
  ];

  Color _getTagColor(String tag) {
    final index = tag.hashCode.abs() % _tagColors.length;
    return _tagColors[index];
  }

  @override
  void initState() {
    super.initState();
    context.read<VoiceRecordBloc>().add(const LoadVoiceRecords());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: _isSelecting 
            ? Text(
                '已选择 ${_selectedRecordIds.length} 项',
                style: const TextStyle(color: Colors.white),
              )
            : const Text(
                '我的记录',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
        actions: _isSelecting
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _selectedRecordIds.isEmpty
                      ? null
                      : () => _showBatchDeleteConfirmation(context),
                  tooltip: '批量删除',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelSelection,
                  tooltip: '取消选择',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    // 搜索功能已在下方搜索框实现
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () {
                    _showFilterOptions(context);
                  },
                ),
              ],
      ),
      body: BlocBuilder<VoiceRecordBloc, VoiceRecordState>(
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
                      context.read<VoiceRecordBloc>().add(const LoadVoiceRecords());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (state.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic_none,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无语音记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击下方麦克风开始录音',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // 获取所有标签
          final allTags = <String>{};
          for (final record in state.records) {
            allTags.addAll(record.tags);
          }
          final sortedTags = allTags.toList()..sort();

          return Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _searchBarColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '搜索录音记录',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (query) {
                            context.read<VoiceRecordBloc>().add(SearchVoiceRecords(query));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                        onPressed: () => _showFilterOptions(context),
                      ),
                    ),
                  ],
                ),
              ),

              // 标签筛选
              if (allTags.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: sortedTags.length + 1,
                    itemBuilder: (context, index) {
                      final tag = index == 0 ? '' : sortedTags[index - 1];
                      final isSelected = _selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTag = isSelected ? '' : tag;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00BCD4) : _cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              index == 0 ? '全部' : tag,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // 记录列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: state.filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = state.filteredRecords[index];
                    // 按标签筛选
                    if (_selectedTag.isNotEmpty && !record.tags.contains(_selectedTag)) {
                      return const SizedBox.shrink();
                    }
                    return VoiceRecordCard(
                      record: record,
                      tagColors: _tagColors,
                      getTagColor: _getTagColor,
                      onTap: _isSelecting
                          ? () => _toggleRecordSelection(record.id)
                          : () => _showVoiceRecordDetails(context, record),
                      onDelete: () => _showDeleteConfirmation(context, record),
                      isSelected: _selectedRecordIds.contains(record.id),
                      onLongPress: () {
                        _startSelection();
                        _toggleRecordSelection(record.id);
                      },
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

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '筛选选项',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.white),
                title: const Text('按时间排序', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('按时长排序', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.label_outline, color: Colors.white),
                title: const Text('按标签筛选', style: TextStyle(color: Colors.white)),
                onTap: () {
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

  void _showVoiceRecordDetails(BuildContext context, VoiceRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceRecordDetailPage(record: record),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VoiceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('删除语音记录', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除语音记录"${record.title}"吗？此操作不可撤销。',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VoiceRecordBloc>().add(DeleteVoiceRecord(record.id));
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('批量删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除选中的 ${_selectedRecordIds.length} 条语音记录吗？此操作不可撤销。',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final recordId in _selectedRecordIds) {
                context.read<VoiceRecordBloc>().add(DeleteVoiceRecord(recordId));
              }
              _cancelSelection();
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _startSelection() {
    setState(() {
      _isSelecting = true;
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelecting = false;
      _selectedRecordIds.clear();
    });
  }

  void _toggleRecordSelection(String recordId) {
    setState(() {
      if (_selectedRecordIds.contains(recordId)) {
        _selectedRecordIds.remove(recordId);
      } else {
        _selectedRecordIds.add(recordId);
      }
      
      // 如果没有选中任何项，退出选择模式
      if (_selectedRecordIds.isEmpty) {
        _isSelecting = false;
      }
    });
  }
}

class VoiceRecordCard extends StatelessWidget {
  final VoiceRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final List<Color> tagColors;
  final Color Function(String) getTagColor;

  static const Color _cardColor = Color(0xFF1E1E1E);

  const VoiceRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
    this.onLongPress,
    required this.tagColors,
    required this.getTagColor,
  });

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF00BCD4), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDuration(record.duration),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showMoreOptions(context);
                    },
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // 日期时间
              Text(
                DateFormat('yyyy年M月d日 HH:mm').format(record.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              
              // 转写内容
              if (record.transcription != null && record.transcription!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  record.transcription!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // 标签
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: record.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getTagColor(tag).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: getTagColor(tag),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
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
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('编辑', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('分享', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

