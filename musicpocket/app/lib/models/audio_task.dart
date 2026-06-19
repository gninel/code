class AudioTask {
  final String taskId;
  final String originalUrl;
  final String platform;
  String status;
  int progress;
  String? title;
  String? author;
  String? coverUrl;
  int? durationSeconds;
  String? audioFormat;
  String? downloadUrl;
  String? localPath;
  int? fileSize;
  String? errorMessage;
  DateTime createdAt;

  AudioTask({
    required this.taskId,
    required this.originalUrl,
    required this.platform,
    this.status = 'pending',
    this.progress = 0,
    this.title,
    this.author,
    this.coverUrl,
    this.durationSeconds,
    this.audioFormat,
    this.downloadUrl,
    this.localPath,
    this.fileSize,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => !isCompleted && !isFailed;
  bool get isDownloaded => localPath != null;

  String get displayTitle => title ?? '解析中...';
  String get displayAuthor => author ?? '';

  String get durationText {
    if (durationSeconds == null) return '--:--';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get fileSizeText {
    if (fileSize == null) return '';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSize! / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'task_id': taskId,
      'original_url': originalUrl,
      'platform': platform,
      'status': status,
      'progress': progress,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'duration_seconds': durationSeconds,
      'audio_format': audioFormat,
      'download_url': downloadUrl,
      'local_path': localPath,
      'file_size': fileSize,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AudioTask.fromMap(Map<String, dynamic> map) {
    return AudioTask(
      taskId: map['task_id'] as String,
      originalUrl: map['original_url'] as String,
      platform: map['platform'] as String,
      status: map['status'] as String? ?? 'pending',
      progress: map['progress'] as int? ?? 0,
      title: map['title'] as String?,
      author: map['author'] as String?,
      coverUrl: map['cover_url'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      audioFormat: map['audio_format'] as String?,
      downloadUrl: map['download_url'] as String?,
      localPath: map['local_path'] as String?,
      fileSize: map['file_size'] as int?,
      errorMessage: map['error_message'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory AudioTask.fromApiResponse(Map<String, dynamic> json, String url, String platform) {
    return AudioTask(
      taskId: json['task_id'] as String,
      originalUrl: url,
      platform: platform,
      status: json['status'] as String? ?? 'pending',
    );
  }

  void updateFromApi(Map<String, dynamic> json) {
    status = json['status'] as String? ?? status;
    progress = json['progress'] as int? ?? progress;
    title = json['title'] as String? ?? title;
    author = json['author'] as String? ?? author;
    coverUrl = json['cover_url'] as String? ?? coverUrl;
    durationSeconds = json['duration_seconds'] as int? ?? durationSeconds;
    audioFormat = json['audio_format'] as String? ?? audioFormat;
    downloadUrl = json['download_url'] as String? ?? downloadUrl;
    fileSize = json['file_size'] as int? ?? fileSize;
    errorMessage = json['error_message'] as String? ?? errorMessage;
  }
}
