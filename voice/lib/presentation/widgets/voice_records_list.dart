import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_bloc.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_state.dart';
import 'package:voice_autobiography_flutter/presentation/bloc/voice_record/voice_record_event.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/presentation/pages/voice_record_detail_page.dart';
import 'package:voice_autobiography_flutter/generated/app_localizations.dart';

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

  // 标签颜色 - 保持原有颜色，但可能需要稍微调整以配合羊皮纸风格，不过原有颜色比较鲜艳，应该可以
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
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // default
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: _isSelecting
            ? Text(
                AppLocalizations.of(context)!
                    .selectedCount(_selectedRecordIds.length),
                style: Theme.of(context).textTheme.titleLarge,
              )
            : Text(
                AppLocalizations.of(context)!.recordsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
        actions: _isSelecting
            ? [
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: _selectedRecordIds.isEmpty
                      ? null
                      : () => _showBatchDeleteConfirmation(context),
                  tooltip: AppLocalizations.of(context)!.batchDelete,
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: _cancelSelection,
                  tooltip: AppLocalizations.of(context)!.cancelSelection,
                ),
              ]
            : const [],
      ),
      body: BlocBuilder<VoiceRecordBloc, VoiceRecordState>(
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
                    AppLocalizations.of(context)!.loadFailed,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<VoiceRecordBloc>()
                          .add(const LoadVoiceRecords());
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
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
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noRecords,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.startRecordingHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6),
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
                        height: 38,
                        decoration: const BoxDecoration(
                            // color: Theme.of(context).cardColor, // Use TextField's fillColor
                            // borderRadius: BorderRadius.circular(8),
                            // border: Border.all(
                            //   color:
                            //       Theme.of(context).dividerColor.withOpacity(0.5),
                            // ),
                            ),
                        child: TextField(
                          controller: _searchController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.searchRecordsHint,
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.5),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(Icons.search,
                                color: Theme.of(context)
                                    .iconTheme
                                    .color
                                    ?.withOpacity(0.5),
                                size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onChanged: (query) {
                            context
                                .read<VoiceRecordBloc>()
                                .add(SearchVoiceRecords(query));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune,
                            color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => _showFilterOptions(context),
                      ),
                    ),
                  ],
                ),
              ),

              // 标签筛选
              if (allTags.isNotEmpty)
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: sortedTags.length + 1,
                    itemBuilder: (context, index) {
                      final tag = index == 0 ? '' : sortedTags[index - 1];
                      final isSelected = _selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTag = isSelected ? '' : tag;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Theme.of(context).dividerColor,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              index == 0
                                  ? AppLocalizations.of(context)!.allTags
                                  : tag,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                fontSize: 12,
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
                    if (_selectedTag.isNotEmpty &&
                        !record.tags.contains(_selectedTag)) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              Text(
                AppLocalizations.of(context)!.filterOptions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.access_time,
                    color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.sortDateDesc,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  context
                      .read<VoiceRecordBloc>()
                      .add(const SortVoiceRecords(SortType.dateDesc));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time_filled,
                    color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.sortDateAsc,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  context
                      .read<VoiceRecordBloc>()
                      .add(const SortVoiceRecords(SortType.dateAsc));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.timer, color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.sortDurationDesc,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  context
                      .read<VoiceRecordBloc>()
                      .add(const SortVoiceRecords(SortType.durationDesc));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.timer_outlined,
                    color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.sortDurationAsc,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  context
                      .read<VoiceRecordBloc>()
                      .add(const SortVoiceRecords(SortType.durationAsc));
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
        title: Text(AppLocalizations.of(context)!.deleteRecordTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteRecordConfirm(record.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VoiceRecordBloc>().add(DeleteVoiceRecord(record.id));
            },
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        title: Text(AppLocalizations.of(context)!.batchDeleteTitle),
        content: Text(
          AppLocalizations.of(context)!
              .batchDeleteConfirm(_selectedRecordIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final recordId in _selectedRecordIds) {
                context
                    .read<VoiceRecordBloc>()
                    .add(DeleteVoiceRecord(recordId));
              }
              _cancelSelection();
            },
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDuration(record.duration),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showMoreOptions(context);
                    },
                    child: Icon(
                      Icons.more_vert,
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 日期时间
              Text(
                DateFormat('yyyy年M月d日 HH:mm').format(record.timestamp),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 12),
              ),

              // 转写内容
              if (record.transcription != null &&
                  record.transcription!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  record.transcription!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  children: record.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: getTagColor(tag).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: getTagColor(tag).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: getTagColor(tag), // Keep tag color
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
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
              ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.edit,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(Icons.share_outlined,
                    color: Theme.of(context).iconTheme.color),
                title: Text(AppLocalizations.of(context)!.share,
                    style: Theme.of(context).textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(AppLocalizations.of(context)!.delete,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
