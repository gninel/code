import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/utils/injection.dart';
import '../../domain/entities/autobiography.dart';
import '../bloc/autobiography_version/autobiography_version_bloc.dart';
import '../bloc/autobiography_version/autobiography_version_event.dart';
import '../bloc/autobiography_version/autobiography_version_state.dart';

/// 自传版本列表页面
class AutobiographyVersionsPage extends StatelessWidget {
  final Autobiography autobiography;
  final Function(String content, List<Map<String, dynamic>> chapters)?
      onRestore;

  const AutobiographyVersionsPage({
    super.key,
    required this.autobiography,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AutobiographyVersionBloc>()
        ..add(LoadVersions(autobiography.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('历史版本'),
              Text(
                'ID: ${autobiography.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
          elevation: 0,
        ),
        body: BlocConsumer<AutobiographyVersionBloc, AutobiographyVersionState>(
          listener: (context, state) {
            if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (state.hasSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading && !state.hasVersions) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!state.hasVersions) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无历史版本',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击"保存版本"可以保存当前自传的快照',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.versions.length,
              itemBuilder: (context, index) {
                final version = state.versions[index];
                final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      version.versionName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${version.wordCount} 字',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(version.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 恢复按钮
                        IconButton(
                          icon: const Icon(Icons.restore),
                          color: Theme.of(context).primaryColor,
                          tooltip: '恢复此版本',
                          onPressed: () {
                            _showRestoreConfirmDialog(context, version.id);
                          },
                        ),
                        // 删除按钮
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: '删除版本',
                          onPressed: () {
                            _showDeleteConfirmDialog(
                              context,
                              version.id,
                              version.versionName,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _showVersionPreview(context, version.content);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 显示版本预览
  void _showVersionPreview(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '版本预览',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示恢复确认对话框
  void _showRestoreConfirmDialog(BuildContext context, String versionId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('恢复此版本将替换当前自传内容,此操作不可撤销。是否继续?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 关闭确认对话框
              Navigator.pop(dialogContext);

              // 选择版本进行恢复
              context
                  .read<AutobiographyVersionBloc>()
                  .add(SelectVersionForRestore(versionId));

              // 监听状态变化,获取版本详情后执行恢复
              final bloc = context.read<AutobiographyVersionBloc>();
              final subscription = bloc.stream.listen((state) {
                if (state.selectedVersion != null && onRestore != null) {
                  onRestore!(
                    state.selectedVersion!.content,
                    state.selectedVersion!.chapters,
                  );
                  // 返回上一页
                  Navigator.pop(context, true);
                }
              });

              // 清理订阅
              Future.delayed(const Duration(seconds: 5), () {
                subscription.cancel();
              });
            },
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(
    BuildContext context,
    String versionId,
    String versionName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除版本"$versionName"吗?此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              context
                  .read<AutobiographyVersionBloc>()
                  .add(DeleteVersion(versionId));
              Navigator.pop(dialogContext);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
