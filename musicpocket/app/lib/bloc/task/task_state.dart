import 'package:equatable/equatable.dart';
import '../../models/audio_task.dart';

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskDetecting extends TaskState {}

class TaskSubmitted extends TaskState {
  final AudioTask task;
  TaskSubmitted(this.task);

  @override
  List<Object?> get props => [task.taskId, task.status, task.progress];
}

class TaskProcessing extends TaskState {
  final AudioTask task;
  TaskProcessing(this.task);

  @override
  List<Object?> get props => [task.taskId, task.status, task.progress];
}

class TaskCompleted extends TaskState {
  final AudioTask task;
  TaskCompleted(this.task);

  @override
  List<Object?> get props => [task.taskId];
}

class TaskFailed extends TaskState {
  final String error;
  TaskFailed(this.error);

  @override
  List<Object?> get props => [error];
}
