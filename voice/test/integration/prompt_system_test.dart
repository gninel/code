import 'package:flutter_test/flutter_test.dart';
import 'package:voice_autobiography_flutter/core/services/prompt_loader_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';

/// Prompt配置系统专项测试
///
/// 这个测试验证提示词解耦配置系统的核心功能
void main() {
  // 初始化Flutter测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt解耦配置系统测试', () {
    late PromptLoaderService promptLoader;

    setUp(() {
      promptLoader = PromptLoaderService();
    });

    test('✅ 1.1 应该能成功加载YAML配置文件', () async {
      // 执行
      await promptLoader.init();

      // 验证: 初始化后应该能获取提示词
      expect(() => promptLoader.getChapterGenerationSystemPrompt(),
          returnsNormally);

      print('✓ YAML配置文件加载成功');
    });

    test('✅ 1.2 章节生成系统提示词应该包含关键内容', () async {
      await promptLoader.init();

      // 执行
      final systemPrompt = promptLoader.getChapterGenerationSystemPrompt();

      // 验证: 应该包含专业自传作家角色定义
      expect(systemPrompt, contains('专业的自传作家'));
      expect(systemPrompt, contains('纪实性优先'));
      expect(systemPrompt, contains('具体而微'));
      expect(systemPrompt, contains('克制表达'));
      expect(systemPrompt, contains('严禁虚构'));

      // 验证: 应该包含文风示例
      expect(systemPrompt, contains('文风示例对比'));
      expect(systemPrompt, contains('❌'));
      expect(systemPrompt, contains('✓'));

      print('✓ 章节生成系统提示词格式正确');
      print('  - 包含角色定义');
      print('  - 包含写作要求');
      print('  - 包含文风示例');
    });

    test('✅ 1.3 新章节提示词应该正确替换变量', () async {
      await promptLoader.init();

      // 执行
      const testContent = '这是测试语音内容：我记得小时候在学校的操场上玩耍。';
      final userPrompt = promptLoader.getNewChapterPrompt(testContent);

      // 验证: 应该包含测试内容
      expect(userPrompt, contains(testContent));
      expect(userPrompt, contains('新的语音记录'));
      expect(userPrompt, contains('自传章节'));

      print('✓ 新章节提示词正确替换变量');
      print('  - 语音内容已插入: "$testContent"');
    });

    test('✅ 1.4 合并章节提示词应该包含原内容和新内容', () async {
      await promptLoader.init();

      // 执行
      const originalContent = '1985年，我出生在一个普通的工人家庭。';
      const newContent = '我记得父亲经常带我去公园玩。';
      final userPrompt = promptLoader.getMergeChapterPrompt(
        originalContent,
        newContent,
      );

      // 验证
      expect(userPrompt, contains(originalContent));
      expect(userPrompt, contains(newContent));
      expect(userPrompt, contains('现有自传内容'));
      expect(userPrompt, contains('新增语音记录'));
      expect(userPrompt, contains('融合'));
      expect(userPrompt, contains('时间线'));

      print('✓ 合并章节提示词格式正确');
      print('  - 包含原有内容');
      print('  - 包含新增内容');
      print('  - 包含融合指导');
    });

    test('✅ 1.5 结构分析提示词应该正确格式化章节信息', () async {
      await promptLoader.init();

      // 执行
      const chaptersDesc = '''Index: 0, Title: 童年, Summary: 童年回忆
Index: 1, Title: 求学时代, Summary: 学生时代经历''';
      const newContent = '我记得大学时期的一次重要比赛';
      final userPrompt = promptLoader.getStructureAnalysisPrompt(
        chaptersDesc,
        newContent,
      );

      // 验证
      expect(userPrompt, contains(chaptersDesc));
      expect(userPrompt, contains(newContent));
      expect(userPrompt, contains('现有章节结构'));
      expect(userPrompt, contains('新的语音内容'));
      expect(userPrompt, contains('JSON'));
      expect(userPrompt, contains('createNew'));
      expect(userPrompt, contains('updateExisting'));

      print('✓ 结构分析提示词格式正确');
      print('  - 章节信息已格式化');
      print('  - JSON输出格式已说明');
    });

    test('✅ 1.6 自传生成应该支持所有风格类型', () async {
      await promptLoader.init();

      const testContent = '这是我的人生故事';

      // 测试所有风格
      final styles = [
        (AutobiographyStyle.narrative, '按时间或事件顺序'),
        (AutobiographyStyle.emotional, '适当保留情感表达'),
        (AutobiographyStyle.achievement, '突出重要的人生节点'),
        (AutobiographyStyle.chronological, '严格按照时间顺序'),
        (AutobiographyStyle.reflection, '记录当时或事后的思考'),
      ];

      print('✓ 测试所有自传风格:');
      for (final (style, expectedText) in styles) {
        final prompt = promptLoader.getAutobiographyGenerationPrompt(
          combinedContent: testContent,
          style: style,
          targetWordCount: 1000,
        );

        expect(prompt, contains(testContent));
        expect(prompt, contains(expectedText));
        print('  - ${style.name}: $expectedText ✓');
      }
    });

    test('✅ 1.7 标题生成应该返回系统和用户提示词元组', () async {
      await promptLoader.init();

      // 执行
      const content = '这是一篇关于我童年经历的自传内容...';
      final (systemPrompt, userPrompt) =
          promptLoader.getTitleGenerationPrompt(content);

      // 验证
      expect(systemPrompt, isNotEmpty);
      expect(systemPrompt, contains('标题'));
      expect(systemPrompt, contains('专家'));
      expect(userPrompt, contains(content));
      expect(userPrompt, contains('不超过20字'));

      print('✓ 标题生成提示词正确');
      print('  - 系统提示词长度: ${systemPrompt.length}');
      print('  - 用户提示词包含内容: ✓');
    });

    test('✅ 1.8 摘要生成应该返回系统和用户提示词元组', () async {
      await promptLoader.init();

      // 执行
      const content = '这是一篇很长的自传内容...';
      final (systemPrompt, userPrompt) =
          promptLoader.getSummaryGenerationPrompt(content);

      // 验证
      expect(systemPrompt, isNotEmpty);
      expect(systemPrompt, contains('摘要'));
      expect(userPrompt, contains(content));
      expect(userPrompt, contains('100-150字'));

      print('✓ 摘要生成提示词正确');
      print('  - 字数要求: 100-150字 ✓');
    });

    test('✅ 1.9 采访问题生成应该区分早期和后期阶段', () async {
      await promptLoader.init();

      // 早期阶段测试(少于5个问题)
      final (earlySystem, earlyUser) =
          promptLoader.getInterviewQuestionPrompt(
        userContentSummary: '用户谈到了童年和父母',
        answeredQuestions: ['你的童年是怎样的？', '你的父母是做什么的？'],
      );

      expect(earlyUser, contains('初期'));
      expect(earlyUser, contains('填补空白'));
      expect(earlySystem, contains('自传作家'));

      print('✓ 早期阶段采访问题正确');
      print('  - 问题数: 2 -> 识别为初期 ✓');

      // 后期阶段测试(5个或更多问题)
      final (lateSystem, lateUser) =
          promptLoader.getInterviewQuestionPrompt(
        userContentSummary: '用户已经谈了很多内容',
        answeredQuestions: [
          '问题1',
          '问题2',
          '问题3',
          '问题4',
          '问题5',
          '问题6'
        ],
      );

      expect(lateUser, contains('中后期'));
      expect(lateUser, contains('深化细节'));

      print('✓ 后期阶段采访问题正确');
      print('  - 问题数: 6 -> 识别为中后期 ✓');
    });

    test('✅ 1.10 内容优化应该支持所有优化类型', () async {
      await promptLoader.init();

      const content = '需要优化的自传内容';

      final optimizationTypes = [
        ('clarity', '清晰度'),
        ('fluency', '流畅性'),
        ('style', '写作风格'),
        ('structure', '结构'),
        ('conciseness', '精简'),
      ];

      print('✓ 测试所有优化类型:');
      for (final (type, expectedText) in optimizationTypes) {
        final (systemPrompt, userPrompt) =
            promptLoader.getContentOptimizationPrompt(
          content: content,
          optimizationType: type,
        );

        expect(systemPrompt, isNotEmpty);
        expect(userPrompt, contains(content));
        expect(userPrompt, contains(expectedText));
        print('  - $type: $expectedText ✓');
      }
    });

    test('✅ 1.11 验证提示词中不包含虚构指导', () async {
      await promptLoader.init();

      // 获取所有主要提示词
      final chapterSystemPrompt =
          promptLoader.getChapterGenerationSystemPrompt();
      final autoSystemPrompt =
          promptLoader.getAutobiographyGenerationSystemPrompt();
      final structSystemPrompt =
          promptLoader.getStructureAnalysisSystemPrompt();

      // 验证所有提示词都明确禁止虚构
      expect(chapterSystemPrompt, contains('严禁虚构'));
      expect(autoSystemPrompt, contains('严禁虚构'));
      expect(structSystemPrompt, contains('严禁虚构'));

      // 验证强调纪实性
      expect(chapterSystemPrompt, contains('纪实'));
      expect(autoSystemPrompt, contains('纪实'));

      print('✓ 所有提示词都明确禁止虚构');
      print('  - 章节生成: 严禁虚构 ✓');
      print('  - 自传生成: 严禁虚构 ✓');
      print('  - 结构分析: 严禁虚构 ✓');
    });

    test('✅ 1.12 验证文风要求：克制表达，避免感叹', () async {
      await promptLoader.init();

      final chapterSystemPrompt =
          promptLoader.getChapterGenerationSystemPrompt();
      final autoSystemPrompt =
          promptLoader.getAutobiographyGenerationSystemPrompt();

      // 验证克制表达要求
      expect(chapterSystemPrompt, contains('克制'));
      expect(autoSystemPrompt, contains('克制'));

      // 验证避免感叹词
      expect(chapterSystemPrompt, contains('避免感叹'));
      expect(autoSystemPrompt, contains('程度副词'));

      print('✓ 文风要求正确');
      print('  - 克制表达 ✓');
      print('  - 避免感叹词 ✓');
      print('  - 避免程度副词 ✓');
    });

    test('✅ 1.13 性能测试：多次加载提示词应该很快', () async {
      await promptLoader.init();

      final stopwatch = Stopwatch()..start();

      // 连续获取100次提示词
      for (int i = 0; i < 100; i++) {
        promptLoader.getChapterGenerationSystemPrompt();
        promptLoader.getNewChapterPrompt('测试内容');
        promptLoader.getAutobiographyGenerationPrompt(
          combinedContent: '测试',
          style: AutobiographyStyle.narrative,
          targetWordCount: 1000,
        );
      }

      stopwatch.stop();
      final milliseconds = stopwatch.elapsedMilliseconds;

      // 验证性能: 100次调用应该在100ms内完成
      expect(milliseconds, lessThan(100));

      print('✓ 性能测试通过');
      print('  - 100次提示词获取耗时: ${milliseconds}ms');
      print('  - 平均每次: ${milliseconds / 100}ms');
    });
  });
}
