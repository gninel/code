import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/interview_session.dart';
import '../../domain/entities/interview_question.dart';
import '../../domain/entities/voice_record.dart';
import '../../domain/repositories/voice_record_repository.dart';
import 'doubao_ai_service.dart';
import 'database_service.dart';
import 'interview_question_pool.dart';

/// 采访会话管理服务
@singleton
class InterviewService {
  final DoubaoAiService _aiService;
  final VoiceRecordRepository _voiceRecordRepository;
  final DatabaseService _databaseService;
  final InterviewQuestionPool _questionPool;
  final Uuid _uuid;

  InterviewSession? _currentSession;

  InterviewService(
    this._aiService,
    this._voiceRecordRepository,
    this._databaseService,
    this._questionPool,
  ) : _uuid = const Uuid();

  /// 获取当前会话
  InterviewSession? get currentSession => _currentSession;

  /// 开始新的采访会话
  Future<InterviewSession> startNewSession() async {
    print('[InterviewService] Starting new session with question pool...');

    // 重置问题池，开始新会话
    _questionPool.reset();

    // 从问题池获取初始问题（5个）
    const initialCount = 5;
    final poolQuestions = _questionPool.getQuestions(initialCount);

    print('[InterviewService] Got ${poolQuestions.length} questions from pool');
    print('[InterviewService] Question pool status: ${_questionPool.getStatus()}');

    // 将问题池的问题转换为InterviewQuestion对象
    final List<InterviewQuestion> preloadedQuestions = [];
    for (int i = 0; i < poolQuestions.length; i++) {
      preloadedQuestions.add(InterviewQuestion(
        id: _uuid.v4(),
        question: poolQuestions[i],
        order: i,
        createdAt: DateTime.now(),
      ));
    }

    print('[InterviewService] Successfully prepared ${preloadedQuestions.length} questions');

    // 创建新会话
    final session = InterviewSession(
      id: _uuid.v4(),
      questions: preloadedQuestions,
      currentQuestionIndex: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    _currentSession = session;

    // 保存到数据库
    await _saveSessionToDatabase(session);

    return session;
  }

  /// 回答当前问题
  Future<InterviewSession> answerCurrentQuestion(String answerText,
      {String? audioFilePath, int? duration}) async {
    print('[InterviewService] answerCurrentQuestion START');
    print(
        '  - Current session questions: ${_currentSession?.questions.length}');
    print(
        '  - Current question index: ${_currentSession?.currentQuestionIndex}');

    if (_currentSession == null) {
      throw Exception('没有活跃的采访会话');
    }

    final currentQuestion = _currentSession!.currentQuestion;
    if (currentQuestion == null) {
      throw Exception('没有当前问题');
    }

    print('[InterviewService] Current question: ${currentQuestion.question}');

    // 更新问题的回答
    final updatedQuestion = currentQuestion.copyWith(
      answer: answerText,
      isAnswered: true,
    );

    // 更新会话的问题列表
    final updatedQuestions =
        List<InterviewQuestion>.from(_currentSession!.questions);
    updatedQuestions[_currentSession!.currentQuestionIndex] = updatedQuestion;

    print(
        '[InterviewService] Updated question list length: ${updatedQuestions.length}');

    final nextIndex = _currentSession!.currentQuestionIndex + 1;
    final remainingQuestions = updatedQuestions.length - nextIndex;

    print(
        '[InterviewService] Next index: $nextIndex, Remaining preloaded questions: $remainingQuestions');

    // 如果预加载的问题快用完了（剩余小于等于2个），从问题池补充新问题
    if (remainingQuestions <= 2) {
      print(
          '[InterviewService] Preloaded questions running low, getting new question from pool...');

      // 从问题池获取下一个问题
      final nextQuestionText = _questionPool.getNextQuestion();

      if (nextQuestionText != null) {
        print('[InterviewService] Got question from pool: $nextQuestionText');

        // 添加新问题到列表
        updatedQuestions.add(InterviewQuestion(
          id: _uuid.v4(),
          question: nextQuestionText,
          order: updatedQuestions.length,
          createdAt: DateTime.now(),
        ));

        print('[InterviewService] Added new question to list');
        print('  - Total questions now: ${updatedQuestions.length}');
        print('  - Question pool status: ${_questionPool.getStatus()}');
      } else {
        print('[InterviewService] Question pool exhausted, no new question added');
      }
    } else {
      print(
          '[InterviewService] Using preloaded question, no need to get new one');
    }

    print('  - New current index will be: $nextIndex');

    // 更新会话
    final updatedSession = _currentSession!.copyWith(
      questions: updatedQuestions,
      currentQuestionIndex: nextIndex,
      updatedAt: DateTime.now(),
    );

    print('[InterviewService] Created updated session:');
    print('  - Questions: ${updatedSession.questions.length}');
    print('  - Current index: ${updatedSession.currentQuestionIndex}');
    print('  - Current question: ${updatedSession.currentQuestion?.question}');

    _currentSession = updatedSession;

    // 保存到数据库
    await _saveSessionToDatabase(updatedSession);

    print('[InterviewService] Saved session to database');

    // 如果有音频文件，保存为语音记录
    if (audioFilePath != null) {
      await _saveAnswerAsVoiceRecord(
          updatedQuestion, answerText, audioFilePath, duration ?? 0);
    }

    print(
        '[InterviewService] answerCurrentQuestion END - returning updated session');
    return updatedSession;
  }

  /// 跳过当前问题
  Future<InterviewSession> skipCurrentQuestion() async {
    if (_currentSession == null) {
      throw Exception('没有活跃的采访会话');
    }

    final currentQuestion = _currentSession!.currentQuestion;
    if (currentQuestion == null) {
      throw Exception('没有当前问题');
    }

    // 标记问题为已跳过
    final updatedQuestion = currentQuestion.copyWith(
      isSkipped: true,
    );

    // 更新会话的问题列表
    final updatedQuestions =
        List<InterviewQuestion>.from(_currentSession!.questions);
    updatedQuestions[_currentSession!.currentQuestionIndex] = updatedQuestion;

    final nextIndex = _currentSession!.currentQuestionIndex + 1;
    final remainingQuestions = updatedQuestions.length - nextIndex;

    print(
        '[SkipQuestion] Next index: $nextIndex, Remaining preloaded questions: $remainingQuestions');

    // 如果预加载的问题快用完了（剩余小于等于2个），从问题池补充新问题
    if (remainingQuestions <= 2) {
      print(
          '[SkipQuestion] Preloaded questions running low, getting new question from pool...');

      // 从问题池获取下一个问题
      final nextQuestionText = _questionPool.getNextQuestion();

      if (nextQuestionText != null) {
        print('[SkipQuestion] Got question from pool: $nextQuestionText');

        // 添加新问题到列表
        updatedQuestions.add(InterviewQuestion(
          id: _uuid.v4(),
          question: nextQuestionText,
          order: updatedQuestions.length,
          createdAt: DateTime.now(),
        ));

        print('[SkipQuestion] Added new question to list');
      }
    } else {
      print(
          '[SkipQuestion] Using preloaded question, no need to get new one');
    }

    // 更新会话
    final updatedSession = _currentSession!.copyWith(
      questions: updatedQuestions,
      currentQuestionIndex: nextIndex,
      updatedAt: DateTime.now(),
    );

    _currentSession = updatedSession;

    // 保存到数据库
    await _saveSessionToDatabase(updatedSession);

    return updatedSession;
  }

  /// 结束当前会话
  Future<void> endSession() async {
    if (_currentSession == null) {
      return;
    }

    final updatedSession = _currentSession!.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    await _saveSessionToDatabase(updatedSession);
    _currentSession = null;
  }

  /// 加载上次的会话
  Future<InterviewSession?> loadLastSession() async {
    try {
      final result = await _databaseService.querySingle(
        'interview_sessions',
        orderBy: 'created_at DESC',
      );

      if (result == null) {
        return null;
      }

      // 从数据库加载问题
      final questionsResult = await _databaseService.query(
        'interview_questions',
        where: 'session_id = ?',
        whereArgs: [result['id']],
        orderBy: 'order_index ASC',
      );

      final questions = questionsResult.map((qJson) {
        return InterviewQuestion(
          id: qJson['id'] as String,
          question: qJson['question'] as String,
          answer: qJson['answer'] as String?,
          order: qJson['order_index'] as int,
          isAnswered: (qJson['is_answered'] as int) == 1,
          isSkipped: (qJson['is_skipped'] as int) == 1,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(qJson['created_at'] as int),
        );
      }).toList();

      var currentIndex = result['current_question_index'] as int;

      // 修正索引越界问题：如果索引超出范围，调整为最后一个未回答的问题
      if (currentIndex >= questions.length) {
        print(
            '[InterviewService] WARNING: currentQuestionIndex ($currentIndex) >= questions.length (${questions.length})');
        print(
            '[InterviewService] Adjusting index to last unanswered question or 0');

        // 查找第一个未回答的问题
        final unansweredIndex = questions.indexWhere((q) => !q.isAnswered);
        currentIndex = unansweredIndex >= 0 ? unansweredIndex : 0;

        print(
            '[InterviewService] Adjusted currentQuestionIndex to: $currentIndex');
      }

      final session = InterviewSession(
        id: result['id'] as String,
        questions: questions,
        currentQuestionIndex: currentIndex,
        isActive: (result['is_active'] as int) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(result['created_at'] as int),
        updatedAt: result['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(result['updated_at'] as int)
            : null,
      );

      print('[InterviewService] Loaded session:');
      print('  - Questions: ${session.questions.length}');
      print('  - Current index: ${session.currentQuestionIndex}');
      print('  - Current question: ${session.currentQuestion?.question}');

      // 只恢复活跃的会话
      if (session.isActive) {
        _currentSession = session;
        return session;
      }

      return null;
    } catch (e) {
      print('InterviewService: Error loading last session: $e');
      return null;
    }
  }

  /// 构建用户内容摘要
  String _buildContentSummary(List<VoiceRecord> voiceRecords) {
    if (voiceRecords.isEmpty) {
      return '用户还没有任何录音记录。';
    }

    final summaries = voiceRecords.take(10).map((record) {
      final content = record.transcription ?? record.content;
      final preview =
          content.length > 100 ? '${content.substring(0, 100)}...' : content;
      return '- ${record.title}: $preview';
    }).join('\n');

    final count = voiceRecords.length;
    return '用户共有 $count 条录音记录。\n\n最近的录音内容：\n$summaries';
  }

  /// 保存会话到数据库
  Future<void> _saveSessionToDatabase(InterviewSession session) async {
    try {
      await _databaseService.transaction((txn) async {
        // 保存或更新会话
        final sessionData = {
          'id': session.id,
          'current_question_index': session.currentQuestionIndex,
          'is_active': session.isActive ? 1 : 0,
          'created_at': session.createdAt.millisecondsSinceEpoch,
          'updated_at': session.updatedAt?.millisecondsSinceEpoch,
        };

        // 检查会话是否已存在
        final existing = await txn.query(
          'interview_sessions',
          where: 'id = ?',
          whereArgs: [session.id],
        );

        if (existing.isNotEmpty) {
          await txn.update(
            'interview_sessions',
            sessionData,
            where: 'id = ?',
            whereArgs: [session.id],
          );
        } else {
          await txn.insert('interview_sessions', sessionData);
        }

        // 删除旧的问题记录
        await txn.delete(
          'interview_questions',
          where: 'session_id = ?',
          whereArgs: [session.id],
        );

        // 保存问题
        for (final question in session.questions) {
          await txn.insert('interview_questions', {
            'id': question.id,
            'session_id': session.id,
            'question': question.question,
            'answer': question.answer,
            'order_index': question.order,
            'is_answered': question.isAnswered ? 1 : 0,
            'is_skipped': question.isSkipped ? 1 : 0,
            'created_at': question.createdAt.millisecondsSinceEpoch,
          });
        }
      });
    } catch (e) {
      print('InterviewService: Error saving session: $e');
    }
  }

  /// 从问题和回答中提取关键词标签
  List<String> _extractTagsFromContent(String question, String answer) {
    final tags = <String>['采访']; // 保留"采访"标签

    // 定义关键词映射
    final keywordMap = {
      '童年|幼儿|小时候|孩提': '童年',
      '学生|上学|读书|毕业|大学|中学|小学': '求学',
      '工作|职业|事业|公司': '职业',
      '爱情|恋爱|结婚|婚姻|伴侣': '情感',
      '家庭|父母|孩子|亲人': '家庭',
      '旅行|旅游|出国': '旅行',
      '爱好|兴趣|喜欢': '爱好',
      '困难|挫折|失败|痛苦': '挫折',
      '成功|成就|荣誉|骄傲': '成就',
      '朋友|友情|同学': '友情',
    };

    final combinedText = '$question $answer';
    for (final entry in keywordMap.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(combinedText)) {
        tags.add(entry.value);
      }
    }

    // 如果没有提取到任何主题标签，添加"生活"作为默认标签
    if (tags.length == 1) {
      tags.add('生活');
    }

    return tags;
  }

  /// 将回答保存为语音记录
  Future<void> _saveAnswerAsVoiceRecord(InterviewQuestion question,
      String answerText, String audioFilePath, int duration) async {
    try {
      print('[InterviewService] _saveAnswerAsVoiceRecord called:');
      print('  - question: ${question.question}');
      print('  - answerText: $answerText');
      print('  - audioFilePath: $audioFilePath');
      print('  - duration: $duration ms');

      // 提取内容相关标签
      final contentTags = _extractTagsFromContent(question.question, answerText);
      print('[InterviewService] Extracted tags: $contentTags');

      final voiceRecord = VoiceRecord(
        id: _uuid.v4(),
        title: '采访回答：${question.question}',
        content: '【问题】${question.question}\n\n【回答】$answerText', // 包含提问内容和回答
        audioFilePath: audioFilePath,
        duration: duration,
        timestamp: DateTime.now(),
        isProcessed: true,
        tags: contentTags, // 使用提取的内容相关标签
        transcription: answerText,
        isIncludedInBio: false,
      );

      print('[InterviewService] Created voice record: ${voiceRecord.id}');
      print('[InterviewService] Saving to repository...');

      // 调用 VoiceRecordRepository 保存语音记录
      final result =
          await _voiceRecordRepository.insertVoiceRecord(voiceRecord);

      result.fold(
        (failure) {
          print(
              '[InterviewService] ERROR: Failed to save voice record: $failure');
          throw Exception('保存语音记录失败: $failure');
        },
        (_) {
          print(
              '[InterviewService] SUCCESS: Voice record saved: ${voiceRecord.id}');
          print('  - Title: ${voiceRecord.title}');
          print('  - Content length: ${voiceRecord.content.length} chars');
        },
      );
    } catch (e) {
      print('[InterviewService] ERROR saving voice record: $e');
      print('[InterviewService] Stack trace: ${StackTrace.current}');
      // 不抛出异常，只记录错误，避免影响采访流程
    }
  }
}
