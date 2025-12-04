/// 热量计算工具类
class CalorieCalculator {
  // 基础食物热量数据库（每100克热量）
  static const Map<String, int> _baseFoodCalories = {
    // 主食类
    '米饭': 116,
    '面条': 110,
    '馒头': 221,
    '面包': 265,
    '饺子': 250,
    '包子': 230,
    '粥': 46,

    // 肉类
    '猪肉': 143,
    '牛肉': 125,
    '鸡肉': 167,
    '鸭肉': 240,
    '鱼': 85,
    '虾': 85,
    '蟹': 95,
    '鸡蛋': 144,

    // 蔬菜类
    '白菜': 13,
    '菠菜': 24,
    '萝卜': 21,
    '西红柿': 15,
    '黄瓜': 15,
    '土豆': 76,
    '茄子': 23,
    '青椒': 22,
    '洋葱': 39,
    '胡萝卜': 37,

    // 水果类
    '苹果': 52,
    '香蕉': 89,
    '橙子': 47,
    '葡萄': 43,
    '西瓜': 30,
    '桃子': 48,
    '梨': 51,

    // 豆制品
    '豆腐': 76,
    '豆浆': 14,
    '豆芽': 18,

    // 油脂类
    '植物油': 899,
    '动物油': 897,

    // 坚果类
    '花生': 298,
    '核桃': 627,
    '杏仁': 578,

    // 饮料类
    '牛奶': 54,
    '可乐': 43,
    '果汁': 45,

    // 零食类
    '薯片': 536,
    '巧克力': 546,
    '冰淇淋': 127,
  };

  // 餐次热量分配比例
  static const Map<String, double> _mealDistribution = {
    'breakfast': 0.3,  // 早餐 30%
    'lunch': 0.4,      // 午餐 40%
    'dinner': 0.3,     // 晚餐 30%
    'other': 0.0,      // 其他 0%
  };

  /// 根据食物名称估算热量
  static int estimateCaloriesByFoodName(String foodName, {double weight = 100}) {
    // 清理食物名称
    String cleanName = _cleanFoodName(foodName);

    // 直接匹配
    if (_baseFoodCalories.containsKey(cleanName)) {
      return (_baseFoodCalories[cleanName]! * weight / 100).round();
    }

    // 模糊匹配
    for (final entry in _baseFoodCalories.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return (entry.value * weight / 100).round();
      }
    }

    // 根据食物类型估算
    final typeCalories = _estimateByFoodType(cleanName);
    return (typeCalories * weight / 100).round();
  }

  /// 根据成分列表计算总热量
  static int calculateTotalCalories(List<String> ingredients, {double totalWeight = 100}) {
    if (ingredients.isEmpty) return 0;

    int totalCalories = 0;
    int knownIngredients = 0;

    for (final ingredient in ingredients) {
      final calories = estimateCaloriesByFoodName(ingredient);
      if (calories > 0) {
        totalCalories += calories;
        knownIngredients++;
      }
    }

    // 如果没有已知成分，使用平均估算
    if (knownIngredients == 0) {
      return _averageMealCalories(ingredients.length);
    }

    // 根据已知成分比例调整
    final ratio = ingredients.length / knownIngredients;
    return (totalCalories * ratio).round();
  }

  /// 根据餐次类型调整热量估算
  static int adjustCaloriesByMealType(int baseCalories, String mealType) {
    final distribution = _mealDistribution[mealType.toLowerCase()] ?? 0.0;

    if (distribution == 0.0) return baseCalories;

    // 基于标准日摄入量2000千卡调整
    final standardDailyIntake = 2000;
    final expectedMealCalories = standardDailyIntake * distribution;

    // 如果基础热量与预期相差太大，进行调整
    if (baseCalories < expectedMealCalories * 0.5) {
      return (expectedMealCalories * 0.7).round();
    } else if (baseCalories > expectedMealCalories * 2.0) {
      return (expectedMealCalories * 1.5).round();
    }

    return baseCalories;
  }

  /// 根据重量调整热量
  static int adjustCaloriesByWeight(int baseCalories, double weight) {
    return (baseCalories * weight / 100).round();
  }

  /// 计算每日建议摄入热量
  static int calculateDailyRecommendedCalories({
    required int age,
    required String gender,
    required double height,  // cm
    required double weight,  // kg
    String activityLevel = 'moderate', // sedentary, light, moderate, active, very_active
  }) {
    // 使用Mifflin-St Jeor公式计算基础代谢率
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // 根据活动水平调整
    final activityMultiplier = _getActivityMultiplier(activityLevel);
    final totalDailyEnergyExpenditure = bmr * activityMultiplier;

    return totalDailyEnergyExpenditure.round();
  }

  /// 计算体重管理目标热量
  static Map<String, int> calculateWeightManagementCalories(int maintenanceCalories) {
    return {
      '减重（每周0.5kg）': (maintenanceCalories * 0.8).round(),    // 减少20%
      '减重（每周1kg）': (maintenanceCalories * 0.6).round(),      // 减少40%
      '维持体重': maintenanceCalories,
      '增重（每周0.5kg）': (maintenanceCalories * 1.2).round(),    // 增加20%
      '增重（每周1kg）': (maintenanceCalories * 1.4).round(),      // 增加40%
    };
  }

  /// 分析热量分布
  static Map<String, dynamic> analyzeCalorieDistribution(Map<String, int> mealCalories) {
    final totalCalories = mealCalories.values.fold(0, (sum, calories) => sum + calories);

    Map<String, double> percentages = {};
    mealCalories.forEach((meal, calories) {
      percentages[meal] = totalCalories > 0 ? (calories / totalCalories * 100) : 0.0;
    });

    return {
      'totalCalories': totalCalories,
      'percentages': percentages,
      'distribution': _evaluateDistribution(percentages),
    };
  }

  /// 生成营养建议
  static List<String> generateNutritionAdvice({
    required int dailyCalories,
    required Map<String, int> mealCalories,
    int age = 25,
    String gender = 'male',
  }) {
    List<String> advice = [];

    final totalIntake = mealCalories.values.fold(0, (sum, calories) => sum + calories);
    final recommended = calculateDailyRecommendedCalories(
      age: age,
      gender: gender,
      height: 170,
      weight: 65,
    );

    // 总热量建议
    if (totalIntake < recommended * 0.8) {
      advice.add('今日热量摄入偏低，建议适量增加营养摄入');
    } else if (totalIntake > recommended * 1.2) {
      advice.add('今日热量摄入偏高，建议适当控制饮食');
    } else {
      advice.add('今日热量摄入合理，继续保持');
    }

    // 餐次分布建议
    final breakfastCalories = mealCalories['breakfast'] ?? 0;
    final lunchCalories = mealCalories['lunch'] ?? 0;
    final dinnerCalories = mealCalories['dinner'] ?? 0;

    if (breakfastCalories < totalIntake * 0.2) {
      advice.add('早餐热量占比较低，建议增加早餐摄入');
    }
    if (dinnerCalories > totalIntake * 0.5) {
      advice.add('晚餐热量占比较高，建议减少晚餐摄入');
    }

    // 营养均衡建议
    advice.add('建议保持蔬菜、蛋白质、主食的均衡搭配');
    advice.add('适量运动有助于维持健康体重');

    return advice;
  }

  /// 获取食物热量等级
  static String getCalorieLevel(int calories) {
    if (calories < 50) return '低热量';
    if (calories < 150) return '中等热量';
    if (calories < 300) return '较高热量';
    return '高热量';
  }

  /// 获取热量颜色
  static String getCalorieColor(int calories) {
    if (calories < 50) return '#4CAF50';  // 绿色
    if (calories < 150) return '#FF9800'; // 橙色
    if (calories < 300) return '#FF5722'; // 深橙色
    return '#F44336';  // 红色
  }

  // 私有辅助方法

  static String _cleanFoodName(String foodName) {
    return foodName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '') // 只保留字母数字和中文
        .trim();
  }

  static int _estimateByFoodType(String foodName) {
    // 肉类
    if (_containsKeywords(foodName, ['肉', '鸡', '鸭', '鱼', '虾', '蟹', '牛', '羊', '猪'])) {
      return 120;
    }

    // 蔬菜类
    if (_containsKeywords(foodName, ['菜', '瓜', '萝卜', '菠菜', '白菜', '番茄', '黄瓜'])) {
      return 25;
    }

    // 水果类
    if (_containsKeywords(foodName, ['果', '苹果', '香蕉', '橙', '葡萄', '西瓜'])) {
      return 50;
    }

    // 主食类
    if (_containsKeywords(foodName, ['饭', '面', '馒头', '包子', '饺子', '面包'])) {
      return 200;
    }

    // 豆制品
    if (_containsKeywords(foodName, ['豆腐', '豆', '豆浆'])) {
      return 80;
    }

    // 油炸食品
    if (_containsKeywords(foodName, ['炸', '烤', '煎'])) {
      return 250;
    }

    // 甜品类
    if (_containsKeywords(foodName, ['蛋糕', '冰淇淋', '巧克力', '糖'])) {
      return 300;
    }

    // 默认值
    return 100;
  }

  static bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  static int _averageMealCalories(int ingredientCount) {
    // 基于成分数量估算平均热量
    switch (ingredientCount) {
      case 1:
        return 150;
      case 2:
        return 250;
      case 3:
        return 350;
      case 4:
        return 450;
      default:
        return 400;
    }
  }

  static double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'very_active':
        return 1.9;
      default:
        return 1.55;
    }
  }

  static String _evaluateDistribution(Map<String, double> percentages) {
    final breakfast = percentages['breakfast'] ?? 0.0;
    final lunch = percentages['lunch'] ?? 0.0;
    final dinner = percentages['dinner'] ?? 0.0;

    if (breakfast >= 25 && breakfast <= 35 &&
        lunch >= 35 && lunch <= 45 &&
        dinner >= 25 && dinner <= 35) {
      return 'excellent';  // 优秀
    } else if (breakfast >= 20 && breakfast <= 40 &&
               lunch >= 30 && lunch <= 50 &&
               dinner >= 20 && dinner <= 40) {
      return 'good';       // 良好
    } else if (breakfast >= 10 && lunch >= 20 && dinner >= 10) {
      return 'fair';       // 一般
    } else {
      return 'poor';       // 较差
    }
  }
}