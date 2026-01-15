// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '语音自传';

  @override
  String get tabDictation => '口述';

  @override
  String get tabRecords => '记录';

  @override
  String get tabAutobiography => '自传';

  @override
  String get tabProfile => '个人';

  @override
  String get profileTitle => '个人中心';

  @override
  String get settings => '设置';

  @override
  String get language => '多语言 / Language';

  @override
  String get aboutApp => '关于应用';

  @override
  String get clearCache => '清除缓存';

  @override
  String get feedback => '意见反馈';

  @override
  String get logout => '退出';

  @override
  String get login => '登录';

  @override
  String get user => '用户';

  @override
  String get notLoggedIn => '未登录';

  @override
  String get statistics => '统计信息';

  @override
  String get recordCount => '录音数量';

  @override
  String get totalDuration => '总时长';

  @override
  String get wordCount => '自传字数';

  @override
  String get autoBackup => '自动备份';

  @override
  String get confirmLogout => '确定要退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get foundUnsavedAutobiography => '发现未保存的自传';

  @override
  String get restorePrompt => '检测到您上次生成的自传还未保存，是否继续编辑？';

  @override
  String get discard => '放弃';

  @override
  String get continueEdit => '继续编辑';

  @override
  String get checkInAutobiography => '请在自传页面查看并保存生成的内容';

  @override
  String get autobiographyGenerated => '✓ 自传生成完成！请前往自传页面查看并保存';

  @override
  String get view => '查看';

  @override
  String get loginPhoneTitle => '手机号登录';

  @override
  String get registerPhoneTitle => '手机号注册';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get createAccount => '创建账号';

  @override
  String get phoneLabel => '手机号';

  @override
  String get phoneHint => '请输入11位手机号';

  @override
  String get phoneErrorEmpty => '请输入手机号';

  @override
  String get phoneErrorInvalid => '手机号格式不正确';

  @override
  String get codeLabel => '验证码';

  @override
  String get codeHint => '请输入4位验证码';

  @override
  String get codeErrorEmpty => '请输入验证码';

  @override
  String get codeErrorLength => '验证码为4位数字';

  @override
  String get getCode => '获取验证码';

  @override
  String get nicknameLabel => '昵称（可选）';

  @override
  String get nicknameHint => '请输入昵称';

  @override
  String get loginButton => '登录';

  @override
  String get registerButton => '注册';

  @override
  String get noAccountRegister => '还没有账号？立即注册';

  @override
  String get hasAccountLogin => '已有账号？立即登录';

  @override
  String get agreementText => '登录即表示同意《用户协议》和《隐私政策》';

  @override
  String get codeSent => '验证码已发送';

  @override
  String get recordsTitle => '我的记录';

  @override
  String selectedCount(Object count) {
    return '已选择 $count 项';
  }

  @override
  String get batchDelete => '批量删除';

  @override
  String get cancelSelection => '取消选择';

  @override
  String get loadFailed => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get noRecords => '暂无语音记录';

  @override
  String get startRecordingHint => '点击下方麦克风开始录音';

  @override
  String get searchRecordsHint => '搜索录音记录';

  @override
  String get allTags => '全部';

  @override
  String get filterOptions => '筛选选项';

  @override
  String get sortDateDesc => '时间倒序 (最新在前)';

  @override
  String get sortDateAsc => '时间正序 (最早在前)';

  @override
  String get sortDurationDesc => '时长倒序 (最长在前)';

  @override
  String get sortDurationAsc => '时长正序 (最短在前)';

  @override
  String get deleteRecordTitle => '删除语音记录';

  @override
  String deleteRecordConfirm(Object title) {
    return '确定要删除语音记录\"$title\"吗？此操作不可撤销。';
  }

  @override
  String get batchDeleteTitle => '批量删除';

  @override
  String batchDeleteConfirm(Object count) {
    return '确定要删除选中的 $count 条语音记录吗？此操作不可撤销。';
  }

  @override
  String get edit => '编辑';

  @override
  String get share => '分享';

  @override
  String get delete => '删除';
}
