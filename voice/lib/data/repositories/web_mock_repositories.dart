import 'package:dartz/dartz.dart';
import 'package:voice_autobiography_flutter/core/errors/failures.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography_version.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/entities/chapter.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_version_repository.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/repositories/ai_generation_repository.dart';
import 'package:voice_autobiography_flutter/domain/services/autobiography_structure_service.dart';

// ============================================================================
// Mock Autobiography Repository
// ============================================================================

class MockAutobiographyRepository implements AutobiographyRepository {
  static final List<Autobiography> _items = [];

  MockAutobiographyRepository() {
    if (_items.isEmpty) {
      _items.add(Autobiography(
        id: 'mock_auto_1',
        title: '我的测试自传',
        content: '这是一个测试内容。\n第1章：童年\n童年很快乐。',
        generatedAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        voiceRecordIds: const ['mock_rec_1'],
      ));
    }
  }

  @override
  Future<Either<Failure, List<Autobiography>>> getAllAutobiographies() async =>
      Right(_items);

  @override
  Future<Either<Failure, Autobiography>> getAutobiographyById(String id) async {
    try {
      return Right(_items.firstWhere((e) => e.id == id));
    } catch (e) {
      return Left(CacheFailure.cacheMiss());
    }
  }

  @override
  Future<Either<Failure, void>> insertAutobiography(
      Autobiography autobiography) async {
    _items.add(autobiography);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateAutobiography(
      Autobiography autobiography) async {
    final index = _items.indexWhere((e) => e.id == autobiography.id);
    if (index != -1) {
      _items[index] = autobiography;
      return const Right(null);
    }
    return Left(CacheFailure.cacheMiss());
  }

  @override
  Future<Either<Failure, void>> deleteAutobiography(String id) async {
    _items.removeWhere((e) => e.id == id);
    return const Right(null);
  }

  // Stubs
  @override
  Future<Either<Failure, String>> backupAutobiographies() async =>
      const Right('');
  @override
  Future<Either<Failure, void>> deleteAutobiographies(List<String> ids) async =>
      const Right(null);
  @override
  Future<Either<Failure, String>> exportAutobiography(
          String id, String format) async =>
      const Right('');
  @override
  Future<Either<Failure, List<Autobiography>>>
      getArchivedAutobiographies() async => const Right([]);
  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByDateRange(
          DateTime start, DateTime end) async =>
      const Right([]);
  @override
  Future<Either<Failure, List<Autobiography>>> getAutobiographiesByStatus(
          AutobiographyStatus status) async =>
      const Right([]);
  @override
  Future<Either<Failure, Map<String, dynamic>>>
      getAutobiographyStatistics() async => const Right({});
  @override
  Future<Either<Failure, List<Autobiography>>>
      getDraftAutobiographies() async => const Right([]);
  @override
  Future<Either<Failure, Autobiography?>> getLatestAutobiography() async =>
      const Right(null);
  @override
  Future<Either<Failure, List<Autobiography>>>
      getPublishedAutobiographies() async => const Right([]);
  @override
  Future<Either<Failure, Autobiography>> importAutobiography(
          String filePath) async =>
      Left(PlatformFailure.notSupported());
  @override
  Future<Either<Failure, void>> restoreAutobiographies(
          String backupPath) async =>
      const Right(null);
  @override
  Future<Either<Failure, List<Autobiography>>> searchAutobiographies(
          String query) async =>
      const Right([]);
  @override
  Future<Either<Failure, void>> updateAutobiographyStatus(
          String id, AutobiographyStatus status) async =>
      const Right(null);
}

// ============================================================================
// Mock Autobiography Version Repository
// ============================================================================

class MockAutobiographyVersionRepository
    implements AutobiographyVersionRepository {
  static final List<AutobiographyVersion> _versions = [];

  @override
  Future<Either<Failure, AutobiographyVersion>> saveVersion({
    required String autobiographyId,
    required String versionName,
    required String content,
    required List<Map<String, dynamic>> chapters,
    required int wordCount,
    String? summary,
  }) async {
    final version = AutobiographyVersion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      autobiographyId: autobiographyId,
      versionName: versionName,
      content: content,
      chapters: chapters,
      createdAt: DateTime.now(),
      wordCount: wordCount,
    );
    _versions.insert(0, version);
    return Right(version);
  }

  @override
  Future<Either<Failure, List<AutobiographyVersion>>> getVersions(
      {required String autobiographyId}) async {
    return Right(
        _versions.where((v) => v.autobiographyId == autobiographyId).toList());
  }

  @override
  Future<Either<Failure, AutobiographyVersion>> getVersion(
      {required String versionId}) async {
    try {
      return Right(_versions.firstWhere((e) => e.id == versionId));
    } catch (e) {
      return Left(CacheFailure.cacheMiss());
    }
  }

  @override
  Future<Either<Failure, void>> deleteVersion(
      {required String versionId}) async {
    _versions.removeWhere((v) => v.id == versionId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteOldestVersion(
          {required String autobiographyId}) async =>
      const Right(null);
  @override
  Future<Either<Failure, int>> getVersionCount(
          {required String autobiographyId}) async =>
      Right(
          _versions.where((v) => v.autobiographyId == autobiographyId).length);
}

// ============================================================================
// Mock Voice Record Repository
// ============================================================================

class MockVoiceRecordRepository implements VoiceRecordRepository {
  static final List<VoiceRecord> _records = [];

  MockVoiceRecordRepository() {
    if (_records.isEmpty) {
      _records.addAll([
        VoiceRecord(
          id: 'mock_rec_1',
          title: '测试录音 1',
          audioFilePath: '/mock/path/record1.m4a',
          duration: 150000, // 2分30秒 = 150000毫秒
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          transcription: '这是第一条测试录音的转录文本。',
          isProcessed: true,
        ),
        VoiceRecord(
          id: 'mock_rec_2',
          title: '测试录音 2',
          audioFilePath: '/mock/path/record2.m4a',
          duration: 315000, // 5分15秒 = 315000毫秒
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          transcription: '这是第二条测试录音的转录文本，内容更长一些。',
          isProcessed: false,
        ),
      ]);
    }
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getAllVoiceRecords() async =>
      Right(_records);

  @override
  Future<Either<Failure, VoiceRecord>> getVoiceRecordById(String id) async {
    try {
      return Right(_records.firstWhere((e) => e.id == id));
    } catch (e) {
      return Left(CacheFailure.cacheMiss());
    }
  }

  @override
  Future<Either<Failure, void>> insertVoiceRecord(
      VoiceRecord voiceRecord) async {
    _records.add(voiceRecord);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateVoiceRecord(
      VoiceRecord voiceRecord) async {
    final index = _records.indexWhere((e) => e.id == voiceRecord.id);
    if (index != -1) {
      _records[index] = voiceRecord;
      return const Right(null);
    }
    return Left(CacheFailure.cacheMiss());
  }

  @override
  Future<Either<Failure, void>> deleteVoiceRecord(String id) async {
    _records.removeWhere((e) => e.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> searchVoiceRecords(
      String query) async {
    final results = _records
        .where((r) =>
            (r.transcription?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            r.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Right(results);
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getVoiceRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final results = _records
        .where((r) =>
            r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate))
        .toList();
    return Right(results);
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>> getProcessedVoiceRecords() async {
    return Right(_records.where((r) => r.isProcessed).toList());
  }

  @override
  Future<Either<Failure, List<VoiceRecord>>>
      getUnprocessedVoiceRecords() async {
    return Right(_records.where((r) => !r.isProcessed).toList());
  }

  @override
  Future<Either<Failure, void>> markAsProcessed(String id) async {
    final index = _records.indexWhere((e) => e.id == id);
    if (index != -1) {
      _records[index] = _records[index].copyWith(isProcessed: true);
      return const Right(null);
    }
    return Left(CacheFailure.cacheMiss());
  }

  @override
  Future<Either<Failure, void>> markAsUnprocessed(String id) async {
    final index = _records.indexWhere((e) => e.id == id);
    if (index != -1) {
      _records[index] = _records[index].copyWith(isProcessed: false);
      return const Right(null);
    }
    return Left(CacheFailure.cacheMiss());
  }

  @override
  Future<Either<Failure, void>> deleteVoiceRecords(List<String> ids) async {
    _records.removeWhere((e) => ids.contains(e.id));
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRecordingStatistics() async {
    final totalDurationMs = _records.fold<int>(0, (sum, r) => sum + r.duration);
    return Right({
      'totalRecords': _records.length,
      'processedCount': _records.where((r) => r.isProcessed).length,
      'unprocessedCount': _records.where((r) => !r.isProcessed).length,
      'totalDurationMs': totalDurationMs,
    });
  }
}

// ============================================================================
// Mock AI Generation Repository
// ============================================================================

class MockAiGenerationRepository implements AiGenerationRepository {
  @override
  Future<Either<Failure, String>> generateAutobiography({
    required List<VoiceRecord> voiceRecords,
    AutobiographyStyle? style,
    int? wordCount,
  }) async {
    // Simulate AI delay
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right('''
这是一个由AI生成的测试自传内容。

第一章：童年时光

我出生在一个温馨的家庭，童年充满了欢乐与好奇。每一天都是新的探险，每一个发现都让我兴奋不已。

第二章：成长历程

随着年龄的增长，我开始理解世界的复杂与美好。学校的学习、朋友的陪伴，都成为我人生中宝贵的财富。
''');
  }

  @override
  Future<Either<Failure, String>> optimizeAutobiography({
    required String content,
    OptimizationType? optimizationType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Right('优化后的内容: $content（已优化）');
  }

  @override
  Future<Either<Failure, String>> generateTitle(
      {required String content}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right('我的人生旅程');
  }

  @override
  Future<Either<Failure, String>> generateSummary(
      {required String content}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right('这是一段关于成长、探索与自我发现的人生故事。');
  }

  @override
  Future<Either<Failure, StructureUpdatePlan>> analyzeStructure({
    required String newContent,
    required List<Chapter> currentChapters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Always suggest creating a new integrated chapter for mock
    return Right(StructureUpdatePlan(
      action: StructureAction.createNew,
      newChapterTitle: '新的章节',
      reasoning: 'Mock: 将新内容整合到新章节中。',
    ));
  }

  @override
  Future<Either<Failure, String>> generateChapterContent({
    String? originalContent,
    required String newVoiceContent,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final combined = originalContent != null
        ? '$originalContent\n\n---\n\n（以下是新增内容）\n\n$newVoiceContent这是AI根据您的新录音生成的内容，与之前的故事无缝衔接。'
        : '这是AI根据您的录音"$newVoiceContent"生成的自传章节内容。这段内容讲述了您的经历和感悟，文笔流畅，情感真挚。';
    return Right(combined);
  }
}
