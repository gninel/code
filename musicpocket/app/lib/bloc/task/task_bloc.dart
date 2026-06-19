import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/audio_task.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService api;
  final LocalStorageService storage;
  Timer? _pollTimer;

  TaskBloc({required this.api, required this.storage}) : super(TaskInitial()) {
    on<SubmitUrl>(_onSubmit);
    on<PollTaskStatus>(_onPoll);
    on<DownloadCompleted>(_onDownloadCompleted);
    on<ClearCurrentTask>(_onClear);
  }

  Future<void> _onSubmit(SubmitUrl event, Emitter<TaskState> emit) async {
    emit(TaskDetecting());

    try {
      final detection = await api.detectLink(event.text);
      if (detection['supported'] != true) {
        emit(TaskFailed(detection['error'] as String? ?? '不支持的链接'));
        return;
      }

      final result = await api.submitConvert(
        url: event.text,
        format: event.format,
        bitrate: event.bitrate,
      );

      final task = AudioTask.fromApiResponse(
        result,
        detection['url'] as String,
        detection['platform'] as String,
      );
      emit(TaskSubmitted(task));

      // 开始轮询
      _startPolling(task.taskId);
    } catch (e) {
      emit(TaskFailed(e.toString()));
    }
  }

  Future<void> _onPoll(PollTaskStatus event, Emitter<TaskState> emit) async {
    try {
      final data = await api.getTaskStatus(event.taskId);

      final currentState = state;
      AudioTask task;
      if (currentState is TaskSubmitted) {
        task = currentState.task;
      } else if (currentState is TaskProcessing) {
        task = currentState.task;
      } else {
        return;
      }

      task.updateFromApi(data);

      if (task.isCompleted) {
        _stopPolling();
        // 自动下载到本地
        try {
          final localPath = await api.downloadAudio(task);
          task.localPath = localPath;
          await storage.saveAudio(task);
        } catch (_) {
          // 下载失败不影响任务状态展示
        }
        emit(TaskCompleted(task));
      } else if (task.isFailed) {
        _stopPolling();
        emit(TaskFailed(task.errorMessage ?? '转换失败'));
      } else {
        emit(TaskProcessing(task));
      }
    } catch (e) {
      // 网络错误时继续轮询
    }
  }

  void _onDownloadCompleted(DownloadCompleted event, Emitter<TaskState> emit) {
    final currentState = state;
    if (currentState is TaskCompleted) {
      currentState.task.localPath = event.localPath;
    }
  }

  void _onClear(ClearCurrentTask event, Emitter<TaskState> emit) {
    _stopPolling();
    emit(TaskInitial());
  }

  void _startPolling(String taskId) {
    _stopPolling();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => add(PollTaskStatus(taskId)),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
