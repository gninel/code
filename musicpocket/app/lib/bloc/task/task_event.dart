import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitUrl extends TaskEvent {
  final String text;
  final String format;
  final String bitrate;

  SubmitUrl({required this.text, this.format = 'mp3', this.bitrate = '192k'});

  @override
  List<Object?> get props => [text, format, bitrate];
}

class PollTaskStatus extends TaskEvent {
  final String taskId;
  PollTaskStatus(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class DownloadCompleted extends TaskEvent {
  final String taskId;
  final String localPath;
  DownloadCompleted({required this.taskId, required this.localPath});

  @override
  List<Object?> get props => [taskId, localPath];
}

class ClearCurrentTask extends TaskEvent {}
