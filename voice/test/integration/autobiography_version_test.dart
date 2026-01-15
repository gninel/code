import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/core/constants/app_constants.dart';
import 'package:voice_autobiography_flutter/data/repositories/autobiography_version_repository_impl.dart';
import 'package:voice_autobiography_flutter/data/services/database_service.dart';

void main() {
  late DatabaseService databaseService;
  late AutobiographyVersionRepositoryImpl repository;

  setUp(() async {
    databaseService = DatabaseService();
    repository = AutobiographyVersionRepositoryImpl(databaseService);

    // 清理测试数据
    final db = await databaseService.database;
    await db.delete(DatabaseTables.autobiographyVersions);
    await db.delete(DatabaseTables.autobiographies);
  });

  tearDown(() async {
    final db = await databaseService.database;
    await db.delete(DatabaseTables.autobiographyVersions);
    await db.delete(DatabaseTables.autobiographies);
  });

  group('AutobiographyVersion - 保存功能测试', () {
    test('应该成功保存版本', () async {
      // 准备测试数据
      const autobiographyId = 'test-auto-001';
      const versionName = '测试版本 1';
      const content = '这是测试自传内容';
      final chapters = [
        {'id': 'ch1', 'title': '第一章', 'content': '第一章内容'},
      ];

      // 执行保存
      final result = await repository.saveVersion(
        autobiographyId: autobiographyId,
        versionName: versionName,
        content: content,
        chapters: chapters,
        wordCount: content.length,
        summary: '测试摘要',
      );

      // 验证结果
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('保存失败: ${failure.message}'),
        (version) {
          expect(version.autobiographyId, autobiographyId);
          expect(version.versionName, versionName);
          expect(version.content, content);
          expect(version.chapters.length, 1);
          expect(version.wordCount, content.length);
        },
      );
    });

    test('应该能保存带有特殊字符的版本名称', () async {
      final specialNames = [
        '版本@#%&*',
        '版本 with spaces',
        '版本\n换行',
        '版本 "引号"',
        "版本 '单引号'",
      ];

      for (final name in specialNames) {
        final result = await repository.saveVersion(
          autobiographyId: 'test-auto-001',
          versionName: name,
          content: '测试内容',
          chapters: [],
          wordCount: 4,
        );

        expect(result.isRight(), true, reason: '特殊字符版本名称: $name');
      }
    });

    test('应该能保存空内容的版本', () async {
      final result = await repository.saveVersion(
        autobiographyId: 'test-auto-001',
        versionName: '空内容版本',
        content: '',
        chapters: [],
        wordCount: 0,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('保存空内容失败'),
        (version) {
          expect(version.content, '');
          expect(version.wordCount, 0);
          expect(version.chapters, []);
        },
      );
    });

    test('应该能保存大量章节的版本', () async {
      final chapters = List.generate(
        100,
        (i) => {
          'id': 'ch$i',
          'title': '第${i + 1}章',
          'content': '章节内容 $i' * 100,
        },
      );

      final result = await repository.saveVersion(
        autobiographyId: 'test-auto-001',
        versionName: '大量章节版本',
        content: '总内容',
        chapters: chapters,
        wordCount: 100000,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('保存大量章节失败'),
        (version) {
          expect(version.chapters.length, 100);
        },
      );
    });
  });

  group('AutobiographyVersion - 查询功能测试', () {
    test('应该能正确查询版本列表', () async {
      const autobiographyId = 'test-auto-001';

      // 保存3个版本
      for (int i = 1; i <= 3; i++) {
        await repository.saveVersion(
          autobiographyId: autobiographyId,
          versionName: '版本 $i',
          content: '内容 $i',
          chapters: [],
          wordCount: 3,
        );
        // 确保时间戳不同
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 查询版本列表
      final result = await repository.getVersions(
        autobiographyId: autobiographyId,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('查询失败'),
        (versions) {
          expect(versions.length, 3);
          // 验证按创建时间倒序排列（最新的在前）
          expect(versions[0].versionName, '版本 3');
          expect(versions[1].versionName, '版本 2');
          expect(versions[2].versionName, '版本 1');
        },
      );
    });

    test('应该返回空列表当没有版本时', () async {
      final result = await repository.getVersions(
        autobiographyId: 'non-existent-id',
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('查询失败'),
        (versions) {
          expect(versions, []);
        },
      );
    });

    test('应该能正确获取版本数量', () async {
      const autobiographyId = 'test-auto-001';

      // 保存5个版本
      for (int i = 1; i <= 5; i++) {
        await repository.saveVersion(
          autobiographyId: autobiographyId,
          versionName: '版本 $i',
          content: '内容',
          chapters: [],
          wordCount: 2,
        );
      }

      final result = await repository.getVersionCount(
        autobiographyId: autobiographyId,
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('获取数量失败'),
        (count) {
          expect(count, 5);
        },
      );
    });
  });

  group('AutobiographyVersion - 删除功能测试', () {
    test('应该能成功删除版本', () async {
      // 保存一个版本
      final saveResult = await repository.saveVersion(
        autobiographyId: 'test-auto-001',
        versionName: '待删除版本',
        content: '内容',
        chapters: [],
        wordCount: 2,
      );

      String? versionId;
      saveResult.fold(
        (failure) => fail('保存失败'),
        (version) {
          versionId = version.id;
        },
      );

      // 删除版本
      final deleteResult = await repository.deleteVersion(versionId: versionId!);
      expect(deleteResult.isRight(), true);

      // 验证已删除
      final getResult = await repository.getVersion(versionId: versionId!);
      expect(getResult.isLeft(), true);
    });

    test('应该能删除最旧的版本', () async {
      const autobiographyId = 'test-auto-001';

      // 保存3个版本
      for (int i = 1; i <= 3; i++) {
        await repository.saveVersion(
          autobiographyId: autobiographyId,
          versionName: '版本 $i',
          content: '内容 $i',
          chapters: [],
          wordCount: 3,
        );
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 删除最旧的版本
      final deleteResult = await repository.deleteOldestVersion(
        autobiographyId: autobiographyId,
      );
      expect(deleteResult.isRight(), true);

      // 验证只剩2个版本
      final listResult = await repository.getVersions(
        autobiographyId: autobiographyId,
      );
      listResult.fold(
        (failure) => fail('查询失败'),
        (versions) {
          expect(versions.length, 2);
          // 最旧的"版本 1"应该被删除
          expect(versions.any((v) => v.versionName == '版本 1'), false);
          expect(versions.any((v) => v.versionName == '版本 2'), true);
          expect(versions.any((v) => v.versionName == '版本 3'), true);
        },
      );
    });
  });

  group('AutobiographyVersion - 版本限制测试', () {
    test('应该在达到20个版本时自动删除最旧的', () async {
      const autobiographyId = 'test-auto-001';

      // 保存21个版本
      for (int i = 1; i <= 21; i++) {
        await repository.saveVersion(
          autobiographyId: autobiographyId,
          versionName: '版本 $i',
          content: '内容 $i',
          chapters: [],
          wordCount: 3,
        );
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // 验证只保留20个版本
      final countResult = await repository.getVersionCount(
        autobiographyId: autobiographyId,
      );
      countResult.fold(
        (failure) => fail('获取数量失败'),
        (count) {
          expect(count, AppConstants.maxAutobiographyVersions);
        },
      );

      // 验证最旧的版本被删除
      final listResult = await repository.getVersions(
        autobiographyId: autobiographyId,
      );
      listResult.fold(
        (failure) => fail('查询失败'),
        (versions) {
          expect(versions.length, 20);
          // "版本 1"应该被删除
          expect(versions.any((v) => v.versionName == '版本 1'), false);
          // "版本 21"应该存在
          expect(versions.any((v) => v.versionName == '版本 21'), true);
        },
      );
    });
  });

  group('AutobiographyVersion - 数据完整性测试', () {
    test('保存和读取的数据应该完全一致', () async {
      final testChapters = [
        {
          'id': 'ch1',
          'title': '童年',
          'content': '我的童年在一个小镇度过...',
          'order': 0,
          'sourceRecordIds': ['rec1', 'rec2'],
          'lastModifiedAt': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'id': 'ch2',
          'title': '青年',
          'content': '青年时期我来到了大城市...',
          'order': 1,
          'sourceRecordIds': ['rec3'],
          'lastModifiedAt': DateTime.now().millisecondsSinceEpoch,
        },
      ];

      final saveResult = await repository.saveVersion(
        autobiographyId: 'test-auto-001',
        versionName: '完整数据测试',
        content: '完整的自传内容，包含多个章节...',
        chapters: testChapters,
        wordCount: 1234,
        summary: '这是一个包含童年和青年两个章节的自传',
      );

      String? versionId;
      saveResult.fold(
        (failure) => fail('保存失败'),
        (version) {
          versionId = version.id;
        },
      );

      // 重新读取
      final getResult = await repository.getVersion(versionId: versionId!);
      getResult.fold(
        (failure) => fail('读取失败'),
        (version) {
          expect(version.versionName, '完整数据测试');
          expect(version.content, '完整的自传内容，包含多个章节...');
          expect(version.chapters.length, 2);
          expect(version.wordCount, 1234);
          expect(version.summary, '这是一个包含童年和青年两个章节的自传');

          // 验证章节数据
          expect(version.chapters[0]['title'], '童年');
          expect(version.chapters[0]['order'], 0);
          expect((version.chapters[0]['sourceRecordIds'] as List).length, 2);
        },
      );
    });
  });
}
