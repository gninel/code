import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI生成状态持久化服务
/// 用于在应用切换到后台时保存生成状态，恢复时继续任务
@lazySingleton
class AiGenerationPersistenceService {
  static const String _keyIsGenerating = 'ai_generation_is_generating';
  static const String _keyGenerationType = 'ai_generation_type';
  static const String _keyVoiceRecordIds = 'ai_generation_voice_record_ids';
  static const String _keyCurrentAutobiographyId = 'ai_generation_current_autobiography_id';
  static const String _keyStartTime = 'ai_generation_start_time';
  static const String _keyGeneratedContent = 'ai_generation_generated_content';
  static const String _keyGeneratedTitle = 'ai_generation_generated_title';
  static const String _keyGeneratedSummary = 'ai_generation_generated_summary';
  static const String _keyStatus = 'ai_generation_status';

  final SharedPreferences _prefs;

  AiGenerationPersistenceService(this._prefs);

  /// 保存生成任务状态
  Future<void> saveGenerationState({
    required String generationType, // 'complete' or 'incremental'
    required List<String> voiceRecordIds,
    String? currentAutobiographyId,
    String? generatedContent,
    String? generatedTitle,
    String? generatedSummary,
    String? status,
  }) async {
    await _prefs.setBool(_keyIsGenerating, true);
    await _prefs.setString(_keyGenerationType, generationType);
    await _prefs.setStringList(_keyVoiceRecordIds, voiceRecordIds);
    if (currentAutobiographyId != null) {
      await _prefs.setString(_keyCurrentAutobiographyId, currentAutobiographyId);
    }
    await _prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);

    if (generatedContent != null) {
      await _prefs.setString(_keyGeneratedContent, generatedContent);
    }
    if (generatedTitle != null) {
      await _prefs.setString(_keyGeneratedTitle, generatedTitle);
    }
    if (generatedSummary != null) {
      await _prefs.setString(_keyGeneratedSummary, generatedSummary);
    }
    if (status != null) {
      await _prefs.setString(_keyStatus, status);
    }
  }

  /// 更新生成进度（部分内容）
  Future<void> updateGenerationProgress({
    String? generatedContent,
    String? generatedTitle,
    String? generatedSummary,
    String? status,
  }) async {
    if (generatedContent != null) {
      await _prefs.setString(_keyGeneratedContent, generatedContent);
    }
    if (generatedTitle != null) {
      await _prefs.setString(_keyGeneratedTitle, generatedTitle);
    }
    if (generatedSummary != null) {
      await _prefs.setString(_keyGeneratedSummary, generatedSummary);
    }
    if (status != null) {
      await _prefs.setString(_keyStatus, status);
    }
  }

  /// 检查是否有未完成的生成任务
  bool hasUnfinishedTask() {
    return _prefs.getBool(_keyIsGenerating) ?? false;
  }

  /// 获取未完成任务的信息
  Map<String, dynamic>? getUnfinishedTaskInfo() {
    if (!hasUnfinishedTask()) return null;

    return {
      'generationType': _prefs.getString(_keyGenerationType),
      'voiceRecordIds': _prefs.getStringList(_keyVoiceRecordIds) ?? [],
      'currentAutobiographyId': _prefs.getString(_keyCurrentAutobiographyId),
      'startTime': _prefs.getInt(_keyStartTime),
      'generatedContent': _prefs.getString(_keyGeneratedContent),
      'generatedTitle': _prefs.getString(_keyGeneratedTitle),
      'generatedSummary': _prefs.getString(_keyGeneratedSummary),
      'status': _prefs.getString(_keyStatus),
    };
  }

  /// 清除生成任务状态（任务完成或取消时调用）
  Future<void> clearGenerationState() async {
    await _prefs.remove(_keyIsGenerating);
    await _prefs.remove(_keyGenerationType);
    await _prefs.remove(_keyVoiceRecordIds);
    await _prefs.remove(_keyCurrentAutobiographyId);
    await _prefs.remove(_keyStartTime);
    await _prefs.remove(_keyGeneratedContent);
    await _prefs.remove(_keyGeneratedTitle);
    await _prefs.remove(_keyGeneratedSummary);
    await _prefs.remove(_keyStatus);
  }

  /// 检查任务是否超时（超过30分钟视为失败）
  bool isTaskTimeout() {
    final startTime = _prefs.getInt(_keyStartTime);
    if (startTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - startTime;
    const timeout = 30 * 60 * 1000; // 30分钟

    return elapsed > timeout;
  }
}
