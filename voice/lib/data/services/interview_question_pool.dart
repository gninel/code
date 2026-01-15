import 'package:injectable/injectable.dart';

/// 采访问题池管理服务
///
/// 提供预加载的通用采访问题，避免用户等待AI生成
@singleton
class InterviewQuestionPool {
  // 问题池缓存
  final List<String> _questionPool = [];

  // 是否已初始化
  bool _isInitialized = false;

  // 已使用的问题索引
  final Set<int> _usedIndices = {};

  /// 通用的采访问题模板
  /// 设计理念：
  /// 1. 混合填补空白型和深化细节型问题，避免模式化
  /// 2. 像自传作家对话一样，用具体、有温度的问题引导回忆
  /// 3. 问题风格多样化，有的直接，有的迂回，有的感性，有的理性
  static const List<String> _defaultQuestions = [
    // 开场与基础(自然开启对话)
    '咱们从最开始聊起吧，你最早的记忆是什么？',
    '你是在哪里长大的？那个地方对你来说意味着什么？',

    // 童年片段(混合宏观与微观)
    '小时候的家是什么样子？有没有哪个角落是你特别喜欢待的？',
    '你和父母的关系怎么样？有没有某个瞬间让你觉得特别温暖或者特别委屈？',
    '说说你童年时最要好的朋友吧，你们是怎么认识的？',
    '你还记得第一次离开家的经历吗？',

    // 学生时代(关注具体事件和感受)
    '上学第一天的情景还记得吗？',
    '有没有哪位老师对你影响特别大？他/她做过什么让你印象深刻的事？',
    '中学时代有什么特别难忘的事吗？可能是一次活动，一个决定，或者一段友谊？',
    '你第一次喜欢上一个人是什么时候？那是种什么样的感觉？',
    '有没有经历过什么挫折或失败，但现在回头看反而很重要？',

    // 成长转折(挖掘关键时刻)
    '什么时候你觉得自己真正长大了？',
    '做过什么决定，让你觉得"人生从此不一样了"？',
    '有没有哪个瞬间，让你突然理解了某件事或某个人？',
    '你经历过让自己感到骄傲的时刻吗？',

    // 情感关系(聚焦具体场景)
    '说说你生命中特别重要的那个人吧，你们是怎么遇见的？',
    '你经历过告别吗？分别时的场景还记得吗？',
    '收到过最让你感动的礼物或者话语是什么？',
    '有没有一段友情让你特别珍惜？',

    // 工作人生(第一次和转折点)
    '第一次工作是什么时候？还记得第一天的心情吗？',
    '工作中有没有让你特别有成就感或者特别沮丧的时刻？',
    '你做过最大胆的职业选择是什么？',

    // 生活细节(引导具体描述)
    '有什么地方去过之后，觉得"这辈子一定要来一次"？',
    '你的兴趣爱好是怎么培养起来的？',
    '生活中有什么小习惯或小仪式感，是你一直保持的？',

    // 深层反思(但语气轻松)
    '回头看看走过的路，哪段经历对现在的你影响最深？',
    '如果能穿越回去，你最想对年轻时的自己说什么？',
    '在你看来，什么样的瞬间值得被记住？',
    '有什么话或者道理，是你想留给后来人的？',
  ];

  InterviewQuestionPool() {
    // 构造函数中初始化问题池
    _initializePool();
  }

  /// 初始化问题池
  void _initializePool() {
    if (_isInitialized) return;

    // 将默认问题加入问题池
    _questionPool.addAll(_defaultQuestions);
    _isInitialized = true;

    print('[InterviewQuestionPool] Initialized with ${_questionPool.length} questions');
  }

  /// 获取一个未使用的问题
  String? getNextQuestion() {
    _initializePool();

    // 如果所有问题都用过了，重置使用记录
    if (_usedIndices.length >= _questionPool.length) {
      print('[InterviewQuestionPool] All questions used, resetting...');
      _usedIndices.clear();
    }

    // 找到一个未使用的问题
    for (int i = 0; i < _questionPool.length; i++) {
      if (!_usedIndices.contains(i)) {
        _usedIndices.add(i);
        print('[InterviewQuestionPool] Returning question $i: ${_questionPool[i]}');
        return _questionPool[i];
      }
    }

    return null;
  }

  /// 批量获取多个问题
  List<String> getQuestions(int count) {
    _initializePool();

    final List<String> questions = [];
    for (int i = 0; i < count; i++) {
      final question = getNextQuestion();
      if (question != null) {
        questions.add(question);
      } else {
        // 如果问题池耗尽，使用默认问题
        questions.add('请继续分享你的人生故事。');
        break;
      }
    }

    return questions;
  }

  /// 重置问题池（开始新会话时调用）
  void reset() {
    _usedIndices.clear();
    print('[InterviewQuestionPool] Reset, ${_questionPool.length} questions available');
  }

  /// 添加自定义问题到问题池
  void addCustomQuestions(List<String> questions) {
    _questionPool.addAll(questions);
    print('[InterviewQuestionPool] Added ${questions.length} custom questions, total: ${_questionPool.length}');
  }

  /// 获取问题池状态
  Map<String, dynamic> getStatus() {
    return {
      'total': _questionPool.length,
      'used': _usedIndices.length,
      'remaining': _questionPool.length - _usedIndices.length,
    };
  }
}
