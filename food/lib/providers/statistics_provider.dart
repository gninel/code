import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/daily_record.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../utils/calorie_calculator.dart';

/// 统计数据状态管理
class StatisticsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // 统计数据
  Map<String, dynamic> _statistics = {};
  List<DailyRecord> _weeklyRecords = [];
  List<DailyRecord> _monthlyRecords = [];
  Map<String, int> _foodTypeDistribution = {};
  List<Map<String, dynamic>> _calorieTrend = [];
  Map<String, dynamic> _recommendations = {};

  // 状态
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get statistics => Map.unmodifiable(_statistics);
  List<DailyRecord> get weeklyRecords => List.unmodifiable(_weeklyRecords);
  List<DailyRecord> get monthlyRecords => List.unmodifiable(_monthlyRecords);
  Map<String, int> get foodTypeDistribution => Map.unmodifiable(_foodTypeDistribution);
  List<Map<String, dynamic>> get calorieTrend => List.unmodifiable(_calorieTrend);
  Map<String, dynamic> get recommendations => Map.unmodifiable(_recommendations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化统计数据
  Future<void> initialize() async {
    await loadStatistics();
  }

  /// 加载所有统计数据
  Future<void> loadStatistics() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.wait([
        _loadBasicStatistics(),
        _loadWeeklyRecords(),
        _loadMonthlyRecords(),
        _loadFoodTypeDistribution(),
        _loadCalorieTrend(),
        _generateRecommendations(),
      ]);

    } catch (e) {
      _setError('加载统计数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载基础统计
  Future<void> _loadBasicStatistics() async {
    final totalItems = await _databaseService.getFoodItemCount();
    final totalCalories = await _databaseService.getTotalCalories();
    final averageCalories = await _databaseService.getAverageDailyCalories(days: 30);

    _statistics = {
      'totalFoodItems': totalItems,
      'totalCalories': totalCalories,
      'averageDailyCalories': averageCalories.round(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// 加载周记录
  Future<void> _loadWeeklyRecords() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));
    _weeklyRecords = await _databaseService.getDailyRecords(days: 7);
  }

  /// 加载月记录
  Future<void> _loadMonthlyRecords() async {
    _monthlyRecords = await _databaseService.getDailyRecords(days: 30);
  }

  /// 加载食物类型分布
  Future<void> _loadFoodTypeDistribution() async {
    final allItems = await _databaseService.getAllFoodItems();

    _foodTypeDistribution.clear();

    // 根据食物名称分类
    for (final item in allItems) {
      final category = _categorizeFood(item.foodName);
      _foodTypeDistribution[category] = (_foodTypeDistribution[category] ?? 0) + item.calories;
    }
  }

  /// 加载热量趋势
  Future<void> _loadCalorieTrend() async {
    _calorieTrend.clear();

    // 最近30天的趋势
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final items = await _databaseService.getFoodItemsByDate(date);

      final totalCalories = items.fold<int>(0, (sum, item) => sum + item.calories);
      final mealCalories = {
        'breakfast': items.where((item) => item.mealType == 'breakfast')
            .fold<int>(0, (sum, item) => sum + item.calories),
        'lunch': items.where((item) => item.mealType == 'lunch')
            .fold<int>(0, (sum, item) => sum + item.calories),
        'dinner': items.where((item) => item.mealType == 'dinner')
            .fold<int>(0, (sum, item) => sum + item.calories),
        'other': items.where((item) => !['breakfast', 'lunch', 'dinner'].contains(item.mealType))
            .fold<int>(0, (sum, item) => sum + item.calories),
      };

      _calorieTrend.add({
        'date': date.toIso8601String(),
        'dateString': '${date.month}/${date.day}',
        'totalCalories': totalCalories,
        'mealCalories': mealCalories,
        'itemCount': items.length,
      });
    }
  }

  /// 生成营养建议
  Future<void> _generateRecommendations() async {
    final dailyCalories = await _databaseService.getTotalCalories(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );

    final averageDaily = dailyCalories / 7;
    final recommendedDaily = CalorieCalculator.calculateDailyRecommendedCalories(
      age: 25,
      gender: 'male',
      height: 170,
      weight: 65,
    );

    final advice = CalorieCalculator.generateNutritionAdvice(
      dailyCalories: averageDaily.round(),
      mealCalories: await _getMealCalories(),
    );

    _recommendations = {
      'averageDailyIntake': averageDaily.round(),
      'recommendedDailyIntake': recommendedDaily,
      'intakePercentage': (averageDaily / recommendedDaily * 100).round(),
      'advice': advice,
      'status': _getHealthStatus(averageDaily, recommendedDaily.toDouble()),
    };
  }

  /// 获取餐次热量
  Future<Map<String, int>> _getMealCalories() async {
    final today = DateTime.now();
    final todayItems = await _databaseService.getFoodItemsByDate(today);

    return {
      'breakfast': todayItems.where((item) => item.mealType == 'breakfast')
          .fold<int>(0, (sum, item) => sum + item.calories),
      'lunch': todayItems.where((item) => item.mealType == 'lunch')
          .fold<int>(0, (sum, item) => sum + item.calories),
      'dinner': todayItems.where((item) => item.mealType == 'dinner')
          .fold<int>(0, (sum, item) => sum + item.calories),
    };
  }

  /// 获取健康状态
  String _getHealthStatus(double actual, double recommended) {
    final ratio = actual / recommended;

    if (ratio < 0.8) return '热量摄入不足';
    if (ratio > 1.2) return '热量摄入超标';
    return '热量摄入正常';
  }

  /// 食物分类
  String _categorizeFood(String foodName) {
    final name = foodName.toLowerCase();

    if (_containsKeywords(name, ['肉', '鸡', '鸭', '鱼', '虾', '蟹', '牛', '羊', '猪'])) {
      return '肉类';
    } else if (_containsKeywords(name, ['菜', '瓜', '萝卜', '菠菜', '白菜', '番茄', '黄瓜', '茄子'])) {
      return '蔬菜';
    } else if (_containsKeywords(name, ['果', '苹果', '香蕉', '橙', '葡萄', '西瓜', '桃'])) {
      return '水果';
    } else if (_containsKeywords(name, ['饭', '面', '馒头', '包子', '饺子', '面包', '粥'])) {
      return '主食';
    } else if (_containsKeywords(name, ['豆腐', '豆', '豆浆'])) {
      return '豆制品';
    } else if (_containsKeywords(name, ['炸', '烤', '煎', '薯条', '汉堡'])) {
      return '油炸食品';
    } else if (_containsKeywords(name, ['蛋糕', '冰淇淋', '巧克力', '糖', '甜点'])) {
      return '甜品';
    } else if (_containsKeywords(name, ['奶', '酸奶', '奶酪'])) {
      return '乳制品';
    } else if (_containsKeywords(name, ['饮料', '可乐', '果汁', '咖啡', '茶'])) {
      return '饮料';
    } else {
      return '其他';
    }
  }

  bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// 获取热量趋势分析
  Map<String, dynamic> getCalorieTrendAnalysis() {
    if (_calorieTrend.isEmpty) {
      return {
        'trend': 'insufficient_data',
        'change': 0,
        'changePercent': 0,
        'analysis': '数据不足，无法分析趋势',
      };
    }

    final recentDays = _calorieTrend.take(3).toList();
    final previousDays = _calorieTrend.skip(3).take(3).toList();

    if (previousDays.isEmpty) {
      return {
        'trend': 'insufficient_data',
        'change': 0,
        'changePercent': 0,
        'analysis': '数据不足，无法分析趋势',
      };
    }

    final recentAverage = recentDays.map((day) => day['totalCalories'] as int).reduce((a, b) => a + b) / recentDays.length;
    final previousAverage = previousDays.map((day) => day['totalCalories'] as int).reduce((a, b) => a + b) / previousDays.length;

    final change = recentAverage - previousAverage;
    final changePercent = previousAverage > 0 ? (change / previousAverage * 100) : 0;

    String trend;
    String analysis;

    if (change.abs() < 50) {
      trend = 'stable';
      analysis = '热量摄入保持稳定';
    } else if (change > 0) {
      trend = 'increasing';
      analysis = '热量摄入呈上升趋势，建议注意控制';
    } else {
      trend = 'decreasing';
      analysis = '热量摄入呈下降趋势';
    }

    return {
      'trend': trend,
      'change': change.round(),
      'changePercent': changePercent.round(),
      'recentAverage': recentAverage.round(),
      'previousAverage': previousAverage.round(),
      'analysis': analysis,
    };
  }

  /// 获取食物偏好分析
  List<Map<String, dynamic>> getFoodPreferenceAnalysis() {
    if (_foodTypeDistribution.isEmpty) return [];

    final totalCalories = _foodTypeDistribution.values.fold(0, (sum, calories) => sum + calories);

    return _foodTypeDistribution.entries
        .map((entry) => {
              'category': entry.key,
              'calories': entry.value,
              'percentage': totalCalories > 0 ? (entry.value / totalCalories * 100).round() : 0,
              'level': _getPreferenceLevel(entry.value, totalCalories),
            })
        .toList()
      ..sort((a, b) => (b['calories'] as int).compareTo(a['calories'] as int));
  }

  String _getPreferenceLevel(int calories, int totalCalories) {
    final percentage = totalCalories > 0 ? calories / totalCalories : 0;

    if (percentage >= 0.3) return '偏好';
    if (percentage >= 0.15) return '适中';
    return '较少';
  }

  /// 获取餐次分布分析
  Map<String, dynamic> getMealDistributionAnalysis() {
    Map<String, int> mealTotals = {
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'other': 0,
    };

    for (final record in _weeklyRecords) {
      final mealCalories = record.mealCalories;
      mealTotals['breakfast'] = (mealTotals['breakfast'] ?? 0) + (mealCalories['breakfast'] ?? 0);
      mealTotals['lunch'] = (mealTotals['lunch'] ?? 0) + (mealCalories['lunch'] ?? 0);
      mealTotals['dinner'] = (mealTotals['dinner'] ?? 0) + (mealCalories['dinner'] ?? 0);
      mealTotals['other'] = (mealTotals['other'] ?? 0) + (mealCalories['other'] ?? 0);
    }

    final total = mealTotals.values.fold(0, (sum, calories) => sum + calories);

    Map<String, double> percentages = {};
    mealTotals.forEach((meal, calories) {
      percentages[meal] = total > 0 ? (calories / total * 100) : 0;
    });

    return CalorieCalculator.analyzeCalorieDistribution(mealTotals);
  }

  /// 刷新统计数据
  Future<void> refresh() async {
    await loadStatistics();
  }

  /// 导出统计数据
  Map<String, dynamic> exportStatistics() {
    return {
      'statistics': _statistics,
      'weeklyRecords': _weeklyRecords.map((record) => record.toMap()).toList(),
      'monthlyRecords': _monthlyRecords.map((record) => record.toMap()).toList(),
      'foodTypeDistribution': _foodTypeDistribution,
      'calorieTrend': _calorieTrend,
      'recommendations': _recommendations,
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  // 私有辅助方法

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}