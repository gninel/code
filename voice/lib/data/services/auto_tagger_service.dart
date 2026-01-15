import 'package:injectable/injectable.dart';

@lazySingleton
class AutoTaggerService {
  Future<List<String>> generateTags(String content) async {
    // 关键词匹配策略，支持多个标签
    // 后续可以接入 AI 服务进行更智能的标签生成
    final tags = <String>{};

    // ===== 教育阶段 =====
    // 小学
    if (content.contains('小学') ||
        content.contains('一年级') ||
        content.contains('二年级') ||
        content.contains('三年级') ||
        content.contains('四年级') ||
        content.contains('五年级') ||
        content.contains('六年级')) {
      tags.add('小学');
    }

    // 初中
    if (content.contains('初中') ||
        content.contains('中学') ||
        content.contains('初一') ||
        content.contains('初二') ||
        content.contains('初三') ||
        content.contains('七年级') ||
        content.contains('八年级') ||
        content.contains('九年级')) {
      tags.add('初中');
    }

    // 高中
    if (content.contains('高中') ||
        content.contains('高一') ||
        content.contains('高二') ||
        content.contains('高三') ||
        content.contains('高考') ||
        content.contains('文科') ||
        content.contains('理科') ||
        content.contains('住校') ||
        content.contains('晚自习')) {
      tags.add('高中');
    }

    // 大学
    if (content.contains('大学') ||
        content.contains('大一') ||
        content.contains('大二') ||
        content.contains('大三') ||
        content.contains('大四') ||
        content.contains('考研') ||
        content.contains('研究生') ||
        content.contains('本科') ||
        content.contains('专科') ||
        content.contains('毕业') ||
        content.contains('学位') ||
        content.contains('论文') ||
        content.contains('宿舍') ||
        content.contains('室友')) {
      tags.add('大学');
    }

    // ===== 人生阶段 =====
    // 童年
    if (content.contains('童年') ||
        content.contains('小时候') ||
        content.contains('儿时') ||
        content.contains('幼儿园') ||
        content.contains('玩耍') ||
        content.contains('零食') ||
        content.contains('动画片') ||
        content.contains('游戏机')) {
      tags.add('童年');
    }

    // 青年
    if (content.contains('青年') ||
        content.contains('年轻时') ||
        content.contains('刚工作') ||
        content.contains('工作初期') ||
        content.contains('第一份工作')) {
      tags.add('青年');
    }

    // ===== 职业相关 =====
    // 工作/职业
    if (content.contains('工作') ||
        content.contains('上班') ||
        content.contains('公司') ||
        content.contains('同事') ||
        content.contains('老板') ||
        content.contains('领导') ||
        content.contains('办公室') ||
        content.contains('加班') ||
        content.contains('出差') ||
        content.contains('项目') ||
        content.contains('业务') ||
        content.contains('客户') ||
        content.contains('工资') ||
        content.contains('薪水') ||
        content.contains('升职') ||
        content.contains('跳槽') ||
        content.contains('辞职') ||
        content.contains('入职')) {
      tags.add('职业');
    }

    // 创业
    if (content.contains('创业') ||
        content.contains('开店') ||
        content.contains('自己干') ||
        content.contains('生意') ||
        content.contains('做买卖') ||
        content.contains('开公司')) {
      tags.add('创业');
    }

    // 退休
    if (content.contains('退休') ||
        content.contains('退休后') ||
        content.contains('离职') && content.contains('年龄')) {
      tags.add('退休');
    }

    // ===== 家庭相关 =====
    // 父母/亲情
    if (content.contains('父母') ||
        content.contains('父亲') ||
        content.contains('母亲') ||
        content.contains('爸爸') ||
        content.contains('妈妈') ||
        content.contains('爸') ||
        content.contains('妈') ||
        content.contains('爷爷') ||
        content.contains('奶奶') ||
        content.contains('外公') ||
        content.contains('外婆')) {
      tags.add('亲情');
    }

    // 婚姻/爱情
    if (content.contains('恋爱') ||
        content.contains('结婚') ||
        content.contains('婚礼') ||
        content.contains('伴侣') ||
        content.contains('老公') ||
        content.contains('老婆') ||
        content.contains('丈夫') ||
        content.contains('妻子') ||
        content.contains('对象') ||
        content.contains('谈恋爱') ||
        content.contains('相亲') ||
        content.contains('约会')) {
      tags.add('爱情');
    }

    // 子女
    if (content.contains('孩子') ||
        content.contains('儿子') ||
        content.contains('女儿') ||
        content.contains('生孩子') ||
        content.contains('怀孕') ||
        content.contains('带孩子') ||
        content.contains('小孩') ||
        content.contains('宝宝')) {
      tags.add('子女');
    }

    // 孙辈
    if (content.contains('孙子') ||
        content.contains('孙女') ||
        content.contains('外孙') ||
        content.contains('外孙女') ||
        content.contains('带孙子')) {
      tags.add('孙辈');
    }

    // 兄弟姐妹
    if (content.contains('兄弟') ||
        content.contains('姐妹') ||
        content.contains('哥哥') ||
        content.contains('弟弟') ||
        content.contains('姐姐') ||
        content.contains('妹妹')) {
      tags.add('兄弟姐妹');
    }

    // ===== 社交相关 =====
    // 友情
    if (content.contains('朋友') ||
        content.contains('好友') ||
        content.contains('闺蜜') ||
        content.contains('兄弟') ||
        content.contains('哥们') ||
        content.contains('死党') ||
        content.contains('发小')) {
      tags.add('友情');
    }

    // 老师/同学
    if (content.contains('老师') ||
        content.contains('同学') ||
        content.contains('班主任') ||
        content.contains('教授') ||
        content.contains('班级') ||
        content.contains('同桌')) {
      tags.add('师生');
    }

    // ===== 生活主题 =====
    // 旅行
    if (content.contains('旅游') ||
        content.contains('旅行') ||
        content.contains('出游') ||
        content.contains('风景') ||
        content.contains('景点') ||
        content.contains('去过') ||
        content.contains('飞机') ||
        content.contains('火车') ||
        content.contains('自驾')) {
      tags.add('旅行');
    }

    // 家乡
    if (content.contains('家乡') ||
        content.contains('老家') ||
        content.contains('故乡') ||
        content.contains('农村') ||
        content.contains('村子') ||
        content.contains('镇上') ||
        content.contains('县城') ||
        content.contains('回老家')) {
      tags.add('家乡');
    }

    // 健康/医疗
    if (content.contains('生病') ||
        content.contains('住院') ||
        content.contains('手术') ||
        content.contains('医院') ||
        content.contains('看病') ||
        content.contains('治疗') ||
        content.contains('身体') ||
        content.contains('健康')) {
      tags.add('健康');
    }

    // 兴趣爱好
    if (content.contains('爱好') ||
        content.contains('兴趣') ||
        content.contains('喜欢') ||
        content.contains('运动') ||
        content.contains('打球') ||
        content.contains('跑步') ||
        content.contains('音乐') ||
        content.contains('唱歌') ||
        content.contains('跳舞') ||
        content.contains('读书') ||
        content.contains('看书') ||
        content.contains('写作') ||
        content.contains('画画') ||
        content.contains('摄影') ||
        content.contains('钓鱼')) {
      tags.add('兴趣爱好');
    }

    // ===== 情感相关 =====
    // 快乐/幸福
    if (content.contains('开心') ||
        content.contains('快乐') ||
        content.contains('幸福') ||
        content.contains('高兴') ||
        content.contains('欣慰')) {
      tags.add('快乐时光');
    }

    // 困难/挫折
    if (content.contains('困难') ||
        content.contains('挫折') ||
        content.contains('失败') ||
        content.contains('艰难') ||
        content.contains('坎坷') ||
        content.contains('不顺')) {
      tags.add('人生挫折');
    }

    // 成就
    if (content.contains('成功') ||
        content.contains('成就') ||
        content.contains('自豪') ||
        content.contains('获奖') ||
        content.contains('荣誉') ||
        content.contains('骄傲')) {
      tags.add('成就');
    }

    // 感悟/反思
    if (content.contains('遗憾') ||
        content.contains('后悔') ||
        content.contains('可惜') ||
        content.contains('感悟') ||
        content.contains('总结') ||
        content.contains('回顾') ||
        content.contains('教训') ||
        content.contains('经验')) {
      tags.add('人生感悟');
    }

    // ===== 特殊事件 =====
    // 军旅
    if (content.contains('当兵') ||
        content.contains('部队') ||
        content.contains('军队') ||
        content.contains('服役') ||
        content.contains('军人') ||
        content.contains('参军')) {
      tags.add('军旅');
    }

    // 历史事件
    if (content.contains('文革') ||
        content.contains('下乡') ||
        content.contains('知青') ||
        content.contains('改革开放') ||
        content.contains('下岗') ||
        content.contains('非典') ||
        content.contains('疫情')) {
      tags.add('历史时刻');
    }

    // 返回所有匹配的标签（不限制数量）
    return tags.toList();
  }
}
