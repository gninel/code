import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';

import 'package:voice_autobiography_flutter/core/services/prompt_loader_service.dart';
import 'package:voice_autobiography_flutter/data/services/doubao_ai_service.dart';
import 'package:voice_autobiography_flutter/data/services/cloud_sync_service.dart';
import 'package:voice_autobiography_flutter/data/services/auto_sync_service.dart';
import 'package:voice_autobiography_flutter/domain/entities/autobiography.dart';
import 'package:voice_autobiography_flutter/domain/entities/voice_record.dart';
import 'package:voice_autobiography_flutter/domain/repositories/voice_record_repository.dart';
import 'package:voice_autobiography_flutter/domain/repositories/autobiography_repository.dart';

@GenerateMocks([
  Dio,
  VoiceRecordRepository,
  AutobiographyRepository,
])
import 'core_features_integration_test.mocks.dart';

/// 核心功能集成测试
///
/// 测试范围:
/// 1. Prompt解耦配置系统
/// 2. 手机号注册登录功能
/// 3. 云端数据同步功能
void main() {
  group('核心功能集成测试', () {
    // ==================== Prompt配置系统测试 ====================
    group('1. Prompt解耦配置系统', () {
      late PromptLoaderService promptLoader;

      setUp(() {
        promptLoader = PromptLoaderService();
      });

      test('1.1 应该能成功加载YAML配置文件', () async {
        // 执行
        await promptLoader.init();

        // 验证: 初始化后应该能获取提示词
        expect(() => promptLoader.getChapterGenerationSystemPrompt(),
            returnsNormally);
      });

      test('1.2 章节生成系统提示词应该包含关键内容', () async {
        await promptLoader.init();

        // 执行
        final systemPrompt = promptLoader.getChapterGenerationSystemPrompt();

        // 验证: 应该包含专业自传作家角色定义
        expect(systemPrompt, contains('专业的自传作家'));
        expect(systemPrompt, contains('纪实性优先'));
        expect(systemPrompt, contains('具体而微'));
        expect(systemPrompt, contains('克制表达'));
        expect(systemPrompt, contains('严禁虚构'));
      });

      test('1.3 新章节提示词应该正确替换变量', () async {
        await promptLoader.init();

        // 执行
        const testContent = '这是测试内容';
        final userPrompt = promptLoader.getNewChapterPrompt(testContent);

        // 验证: 应该包含测试内容
        expect(userPrompt, contains(testContent));
        expect(userPrompt, contains('新的语音记录'));
      });

      test('1.4 合并章节提示词应该包含原内容和新内容', () async {
        await promptLoader.init();

        // 执行
        const originalContent = '原有内容';
        const newContent = '新增内容';
        final userPrompt = promptLoader.getMergeChapterPrompt(
          originalContent,
          newContent,
        );

        // 验证
        expect(userPrompt, contains(originalContent));
        expect(userPrompt, contains(newContent));
        expect(userPrompt, contains('融合'));
        expect(userPrompt, contains('时间线'));
      });

      test('1.5 结构分析提示词应该正确格式化章节信息', () async {
        await promptLoader.init();

        // 执行
        const chaptersDesc = 'Index: 0, Title: 童年, Summary: 童年回忆';
        const newContent = '新的回忆片段';
        final userPrompt = promptLoader.getStructureAnalysisPrompt(
          chaptersDesc,
          newContent,
        );

        // 验证
        expect(userPrompt, contains(chaptersDesc));
        expect(userPrompt, contains(newContent));
        expect(userPrompt, contains('JSON'));
      });

      test('1.6 自传生成提示词应该支持不同风格', () async {
        await promptLoader.init();

        // 测试叙事风格
        final narrativePrompt = promptLoader.getAutobiographyGenerationPrompt(
          combinedContent: '测试内容',
          style: AutobiographyStyle.narrative,
          targetWordCount: 1000,
        );
        expect(narrativePrompt, contains('按时间或事件顺序'));

        // 测试情感风格
        final emotionalPrompt = promptLoader.getAutobiographyGenerationPrompt(
          combinedContent: '测试内容',
          style: AutobiographyStyle.emotional,
          targetWordCount: 1000,
        );
        expect(emotionalPrompt, contains('适当保留情感表达'));
      });

      test('1.7 标题生成应该返回系统和用户提示词', () async {
        await promptLoader.init();

        // 执行
        const content = '这是一篇自传内容';
        final (systemPrompt, userPrompt) =
            promptLoader.getTitleGenerationPrompt(content);

        // 验证
        expect(systemPrompt, isNotEmpty);
        expect(systemPrompt, contains('标题'));
        expect(userPrompt, contains(content));
      });

      test('1.8 采访问题生成应该区分不同阶段', () async {
        await promptLoader.init();

        // 早期阶段(少于5个问题)
        final (earlySystem, earlyUser) =
            promptLoader.getInterviewQuestionPrompt(
          userContentSummary: '用户简要内容',
          answeredQuestions: ['问题1', '问题2'],
        );
        expect(earlyUser, contains('初期'));

        // 后期阶段(5个或更多问题)
        final (lateSystem, lateUser) = promptLoader.getInterviewQuestionPrompt(
          userContentSummary: '用户简要内容',
          answeredQuestions: ['问题1', '问题2', '问题3', '问题4', '问题5'],
        );
        expect(lateUser, contains('中后期'));
      });

      test('1.9 内容优化应该支持不同优化类型', () async {
        await promptLoader.init();

        const content = '需要优化的内容';

        // 测试清晰度优化
        final (claritySystem, clarityUser) =
            promptLoader.getContentOptimizationPrompt(
          content: content,
          optimizationType: 'clarity',
        );
        expect(clarityUser, contains('清晰度'));
        expect(clarityUser, contains(content));

        // 测试流畅性优化
        final (fluencySystem, fluencyUser) =
            promptLoader.getContentOptimizationPrompt(
          content: content,
          optimizationType: 'fluency',
        );
        expect(fluencyUser, contains('流畅性'));
      });

      test('1.10 DoubaoAiService应该正确使用PromptLoader', () async {
        // 准备
        await promptLoader.init();
        final mockDio = MockDio();
        final aiService = DoubaoAiService(promptLoader, dio: mockDio);

        // Mock API响应
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'choices': [
                  {
                    'message': {'content': '生成的章节内容'}
                  }
                ]
              },
            ));

        // 执行: 调用生成章节方法
        final result = await aiService.generateChapterContent(
          originalContent: null,
          newVoiceContent: '这是新的语音内容',
        );

        // 验证: 应该成功生成内容
        expect(result, isNotEmpty);
        expect(result, equals('生成的章节内容'));

        // 验证: 应该调用了API
        verify(mockDio.post(any, data: anyNamed('data'))).called(1);
      });
    });

    // ==================== 手机号注册登录测试 ====================
    group('2. 手机号注册登录功能', () {
      late CloudSyncService cloudSyncService;
      late MockDio mockDio;

      setUp(() {
        mockDio = MockDio();
        cloudSyncService = CloudSyncService(dio: mockDio);
      });

      test('2.1 应该能发送验证码', () async {
        // Mock API响应
        when(mockDio.post(
          '/auth/send-code',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'message': '验证码已发送'},
            ));

        // 执行
        await cloudSyncService.sendVerificationCode('13800138000');

        // 验证: 应该调用了发送验证码API
        verify(mockDio.post(
          '/auth/send-code',
          data: {'phone': '13800138000'},
        )).called(1);
      });

      test('2.2 应该能使用手机号和验证码注册', () async {
        // Mock API响应
        when(mockDio.post(
          '/auth/phone/register',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token_123',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_001',
                  'phone': '13800138000',
                  'nickname': '测试用户',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        // 执行
        final user = await cloudSyncService.registerWithPhone(
          '13800138000',
          '123456',
          nickname: '测试用户',
        );

        // 验证
        expect(user.id, equals('user_001'));
        expect(user.phone, equals('13800138000'));
        expect(user.nickname, equals('测试用户'));
        expect(cloudSyncService.isLoggedIn, isTrue);
        expect(cloudSyncService.currentUser, equals(user));
      });

      test('2.3 应该能使用手机号和验证码登录', () async {
        // Mock API响应
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token_456',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_002',
                  'phone': '13900139000',
                  'nickname': '老用户',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        // 执行
        final user = await cloudSyncService.loginWithPhone(
          '13900139000',
          '654321',
        );

        // 验证
        expect(user.id, equals('user_002'));
        expect(user.phone, equals('13900139000'));
        expect(cloudSyncService.isLoggedIn, isTrue);
      });

      test('2.4 验证码错误应该抛出异常', () async {
        // Mock API错误响应
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {'detail': '验证码错误'},
          ),
        ));

        // 执行并验证: 应该抛出异常
        expect(
          () => cloudSyncService.loginWithPhone('13800138000', '000000'),
          throwsA(isA<Exception>()),
        );
      });

      test('2.5 退出登录应该清除用户状态', () async {
        // 先登录
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_003',
                  'phone': '13800138000',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        await cloudSyncService.loginWithPhone('13800138000', '123456');
        expect(cloudSyncService.isLoggedIn, isTrue);

        // 执行: 退出登录
        await cloudSyncService.logout();

        // 验证: 应该清除登录状态
        expect(cloudSyncService.isLoggedIn, isFalse);
        expect(cloudSyncService.currentUser, isNull);
      });
    });

    // ==================== 云端数据同步测试 ====================
    group('3. 云端数据同步功能', () {
      late CloudSyncService cloudSyncService;
      late AutoSyncService autoSyncService;
      late MockDio mockDio;
      late MockVoiceRecordRepository mockVoiceRecordRepo;
      late MockAutobiographyRepository mockAutobiographyRepo;

      setUp(() {
        mockDio = MockDio();
        mockVoiceRecordRepo = MockVoiceRecordRepository();
        mockAutobiographyRepo = MockAutobiographyRepository();
        cloudSyncService = CloudSyncService(dio: mockDio);
        autoSyncService = AutoSyncService(
          cloudSyncService,
          mockVoiceRecordRepo,
          mockAutobiographyRepo,
        );
      });

      test('3.1 应该能上传语音记录和自传到云端', () async {
        // Mock登录状态
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_001',
                  'phone': '13800138000',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        await cloudSyncService.loginWithPhone('13800138000', '123456');

        // Mock上传API响应
        when(mockDio.post(
          '/sync/upload',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'message': '上传成功', 'count': 2},
            ));

        // 准备测试数据
        final testRecords = [
          VoiceRecord(
            id: 'record_001',
            title: '测试录音1',
            content: '这是测试录音内容',
            timestamp: DateTime.now(),
          ),
        ];

        final testAutobiographies = [
          Autobiography(
            id: 'auto_001',
            title: '我的自传',
            content: '这是自传内容',
            generatedAt: DateTime.now(),
            lastModifiedAt: DateTime.now(),
          ),
        ];

        // 执行上传
        await cloudSyncService.uploadData(
          voiceRecords: testRecords,
          autobiographies: testAutobiographies,
        );

        // 验证: 应该调用了上传API
        verify(mockDio.post(
          '/sync/upload',
          data: argThat(
            predicate<Map<String, dynamic>>((data) {
              return data['voice_records'] != null &&
                  data['autobiographies'] != null;
            }),
            named: 'data',
          ),
        )).called(1);
      });

      test('3.2 应该能从云端下载数据', () async {
        // Mock登录
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_001',
                  'phone': '13800138000',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        await cloudSyncService.loginWithPhone('13800138000', '123456');

        // Mock下载API响应
        when(mockDio.get('/sync/download')).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'voice_records': [
                  {
                    'id': 'record_002',
                    'title': '云端录音',
                    'content': '云端录音内容',
                    'timestamp': DateTime.now().toIso8601String(),
                  }
                ],
                'autobiographies': [
                  {
                    'id': 'auto_002',
                    'title': '云端自传',
                    'content': '云端自传内容',
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }
                ],
              },
            ));

        // 执行下载
        final data = await cloudSyncService.downloadData();

        // 验证
        expect(data.voiceRecords, hasLength(1));
        expect(data.voiceRecords.first.id, equals('record_002'));
        expect(data.autobiographies, hasLength(1));
        expect(data.autobiographies.first.id, equals('auto_002'));
      });

      test('3.3 未登录时上传应该抛出异常', () async {
        // 确保未登录
        expect(cloudSyncService.isLoggedIn, isFalse);

        // 执行并验证: 应该抛出异常
        expect(
          () => cloudSyncService.uploadData(
            voiceRecords: [],
            autobiographies: [],
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('3.4 自动同步服务应该在启用时定期同步', () async {
        // Mock登录
        when(mockDio.post(
          '/auth/phone/login',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'test_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 'user_001',
                  'phone': '13800138000',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        await cloudSyncService.loginWithPhone('13800138000', '123456');

        // Mock repository返回空数据
        when(mockVoiceRecordRepo.getAllVoiceRecords())
            .thenAnswer((_) async => const Right([]));
        when(mockAutobiographyRepo.getAllAutobiographies())
            .thenAnswer((_) async => const Right([]));

        // Mock上传API
        when(mockDio.post(
          '/sync/upload',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'message': '同步成功'},
            ));

        // 执行: 启用自动同步
        autoSyncService.enableAutoSync();

        // 等待一小段时间
        await Future.delayed(const Duration(milliseconds: 100));

        // 执行立即同步
        await autoSyncService.syncNow();

        // 验证: 应该调用了仓库的方法
        verify(mockVoiceRecordRepo.getAllVoiceRecords()).called(greaterThan(0));
        verify(mockAutobiographyRepo.getAllAutobiographies())
            .called(greaterThan(0));

        // 清理: 禁用自动同步
        autoSyncService.disableAutoSync();
      });
    });

    // ==================== 端到端集成测试 ====================
    group('4. 端到端集成流程', () {
      late PromptLoaderService promptLoader;
      late CloudSyncService cloudSyncService;
      late DoubaoAiService aiService;
      late MockDio mockCloudDio;
      late MockDio mockAiDio;

      setUp(() async {
        promptLoader = PromptLoaderService();
        await promptLoader.init();

        mockCloudDio = MockDio();
        mockAiDio = MockDio();

        cloudSyncService = CloudSyncService(dio: mockCloudDio);
        aiService = DoubaoAiService(promptLoader, dio: mockAiDio);
      });

      test('4.1 完整流程: 注册 -> AI生成 -> 云端同步', () async {
        // 步骤1: 手机号注册
        when(mockCloudDio.post(
          '/auth/send-code',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'message': '验证码已发送'},
            ));

        await cloudSyncService.sendVerificationCode('13800138000');

        when(mockCloudDio.post(
          '/auth/phone/register',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'access_token': 'integration_test_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 'integration_user',
                  'phone': '13800138000',
                  'nickname': '集成测试用户',
                  'created_at': DateTime.now().toIso8601String(),
                }
              },
            ));

        final user = await cloudSyncService.registerWithPhone(
          '13800138000',
          '123456',
          nickname: '集成测试用户',
        );

        expect(user.nickname, equals('集成测试用户'));
        expect(cloudSyncService.isLoggedIn, isTrue);

        // 步骤2: 使用AI生成章节
        when(mockAiDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {
                'choices': [
                  {
                    'message': {'content': '1985年4月的一个下午，我在学校操场见到了王老师。'}
                  }
                ]
              },
            ));

        final generatedContent = await aiService.generateChapterContent(
          originalContent: null,
          newVoiceContent: '我记得小时候见到王老师',
        );

        expect(generatedContent, isNotEmpty);
        expect(generatedContent, contains('王老师'));

        // 步骤3: 上传到云端
        when(mockCloudDio.post(
          '/sync/upload',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: {'message': '上传成功'},
            ));

        final autobiography = Autobiography(
          id: 'auto_integration',
          title: '我的童年',
          content: generatedContent,
          generatedAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        );

        await cloudSyncService.uploadData(
          voiceRecords: [],
          autobiographies: [autobiography],
        );

        // 验证整个流程
        verify(mockCloudDio.post('/auth/send-code', data: anyNamed('data')))
            .called(1);
        verify(mockCloudDio.post('/auth/phone/register',
                data: anyNamed('data')))
            .called(1);
        verify(mockAiDio.post(any, data: anyNamed('data'))).called(1);
        verify(mockCloudDio.post('/sync/upload', data: anyNamed('data')))
            .called(1);
      });

      test('4.2 Prompt配置应该影响AI生成结果', () async {
        // 验证: 系统提示词包含纪实性要求
        final systemPrompt = promptLoader.getChapterGenerationSystemPrompt();
        expect(systemPrompt, contains('纪实性优先'));
        expect(systemPrompt, contains('严禁虚构'));

        // Mock AI响应
        when(mockAiDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((invocation) {
          // 获取发送的请求数据
          final data = invocation.namedArguments[const Symbol('data')]
              as Map<String, dynamic>;
          final messages = data['messages'] as List;
          final systemMessage = messages[0] as Map<String, dynamic>;

          // 验证系统提示词被正确使用
          expect(systemMessage['content'], contains('专业的自传作家'));

          return Future.value(Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': '专业的传记风格内容'}
                }
              ]
            },
          ));
        });

        // 生成内容
        await aiService.generateChapterContent(
          originalContent: null,
          newVoiceContent: '测试内容',
        );

        // 验证请求被正确发送
        verify(mockAiDio.post(any, data: anyNamed('data'))).called(1);
      });
    });
  });
}
