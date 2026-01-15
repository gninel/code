import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/daily_record.dart';
import '../models/api_response.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../utils/calorie_calculator.dart';

/// 食物数据状态管理
class FoodProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ApiService _apiService = ApiService();
  final CameraService _cameraService = CameraService();

  // 状态变量
  List<FoodItem> _foodItems = [];
  List<DailyRecord> _dailyRecords = [];
  DailyRecord? _todayRecord;
  bool _isLoading = false;
  String? _error;
  int? _currentTotalCalories;
  Map<String, int> _mealCalories = {};

  // Getters
  List<FoodItem> get foodItems => List.unmodifiable(_foodItems);
  List<DailyRecord> get dailyRecords => List.unmodifiable(_dailyRecords);
  DailyRecord? get todayRecord => _todayRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentTotalCalories => _currentTotalCalories ?? 0;
  Map<String, int> get mealCalories => Map.unmodifiable(_mealCalories);

  /// 初始化数据
  Future<void> initialize() async {
    await _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    try {
      _setLoading(true);
      _clearError();

      // 并行加载数据
      final futures = await Future.wait([
        _loadFoodItems(),
        _loadDailyRecords(),
      ]);

      _calculateTodayStats();

    } catch (e) {
      _setError('加载数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载食物记录
  Future<void> _loadFoodItems() async {
    debugPrint('开始加载食物记录...');
    _foodItems = await _databaseService.getAllFoodItems();
    debugPrint('加载完成，共 ${_foodItems.length} 条记录');
  }

  /// 加载每日记录
  Future<void> _loadDailyRecords() async {
    _dailyRecords = await _databaseService.getDailyRecords(days: 30);
    final today = DateTime.now();
    _todayRecord = _dailyRecords.firstWhere(
      (record) => _isSameDay(record.date, today),
      orElse: () => DailyRecord(date: today),
    );
  }

  /// 计算今日统计
  void _calculateTodayStats() {
    if (_todayRecord == null) return;

    _currentTotalCalories = _todayRecord!.totalCalories;
    _mealCalories = _todayRecord!.mealCalories;
  }

  /// 拍照识别食物
  Future<ApiResponse> recognizeFoodFromCamera() async {
    try {
      _clearError();
      _setLoading(true);

      // 检查相机权限
      final hasPermission = await _cameraService.checkCameraPermission();
      if (!hasPermission) {
        final granted = await _cameraService.requestCameraPermission();
        if (!granted) {
          return ApiResponse.error('需要相机权限才能拍照');
        }
      }

      // 初始化相机
      final success = await _cameraService.initializeCamera();
      if (!success) {
        return ApiResponse.error('相机初始化失败');
      }

      // 注意：这里需要在UI层处理拍照，这里只提供API调用
      // 实际的拍照流程需要与UI层配合
      return ApiResponse.error('请在相机界面拍照');

    } catch (e) {
      return ApiResponse.error('相机操作失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 识别食物图片
  /// [languageCode] - 语言代码 ('en' 或 'zh')
  Future<ApiResponse> recognizeFoodFromImage(String imagePath, {String languageCode = 'zh'}) async {
    try {
      debugPrint('开始识别食物图片: $imagePath, 语言: $languageCode');
      _clearError();
      _setLoading(true);

      // 调用API识别（传递语言参数）
      final response = await _apiService.recognizeFood(imagePath, languageCode: languageCode);
      debugPrint('API识别完成，success: ${response.success}');

      if (response.success && response.data != null) {
        // 验证和调整识别结果
        final adjustedAnalysis = _adjustFoodAnalysis(response.data!);
        debugPrint('处理识别结果完成');
        return ApiResponse.success(adjustedAnalysis, rawResponse: response.rawResponse);
      }

      return response;

    } catch (e, stackTrace) {
      debugPrint('识别失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return ApiResponse.error('识别失败: $e');
    } finally {
      debugPrint('设置loading为false');
      _setLoading(false);
    }
  }

  /// 调整食物分析结果
  FoodAnalysis _adjustFoodAnalysis(FoodAnalysis analysis) {
    debugPrint('调整食物分析结果: ${analysis.foodName}, 热量: ${analysis.calories}, 重量: ${analysis.weight}');
    
    double adjustedWeight = analysis.weight;
    bool isAdjusted = false;
    double? originalWeight;
    
    // Step 1: 验证热量密度的合理性
    final calorieDensity = analysis.weight > 0 ? analysis.calories / analysis.weight * 100 : 0;
    debugPrint('热量密度: $calorieDensity 千卡/100g');
    
    // 热量密度上限：纯脂肪约 900 千卡/100g
    const double maxCalorieDensity = 900.0;
    
    if (calorieDensity > maxCalorieDensity) {
      debugPrint('热量密度异常（$calorieDensity > $maxCalorieDensity），推断重量估算错误');
      
      // 保存原始重量
      originalWeight = analysis.weight;
      
      // 假设合理的热量密度为 300 千卡/100g（中等偏高）
      // 修正重量 = 总热量 / 3
      adjustedWeight = analysis.calories / 3.0;
      isAdjusted = true;
      
      final newDensity = analysis.calories / adjustedWeight * 100;
      debugPrint('调整重量: $originalWeight -> $adjustedWeight 克');
      debugPrint('新热量密度: $newDensity 千卡/100g');
    }
    
    // Step 2: 验证热量合理性
    int adjustedCalories = analysis.calories;

    // 如果热量过低，使用热量计算器重新估算
    if (analysis.calories < 20) {
      adjustedCalories = CalorieCalculator.estimateCaloriesByFoodName(
        analysis.foodName,
        weight: adjustedWeight,
      );
    }

    // 如果仍然过低，使用成分估算
    if (adjustedCalories < 20 && analysis.ingredients.isNotEmpty) {
      adjustedCalories = CalorieCalculator.calculateTotalCalories(
        analysis.ingredients,
        totalWeight: adjustedWeight,
      );
    }

    // 根据餐次调整
    final mealTypeCalories = CalorieCalculator.adjustCaloriesByMealType(
      adjustedCalories,
      analysis.mealType,
    );

    return analysis.copyWith(
      calories: mealTypeCalories > 0 ? mealTypeCalories : adjustedCalories,
      weight: adjustedWeight,
      isAdjusted: isAdjusted,
      originalWeight: originalWeight,
      confidence: _adjustConfidence(analysis.confidence, adjustedCalories, mealTypeCalories),
    );
  }

  /// 调整置信度
  double _adjustConfidence(double originalConfidence, int originalCalories, int adjustedCalories) {
    if (originalCalories == adjustedCalories) {
      return originalConfidence;
    }

    // 如果调整幅度很大，降低置信度
    final adjustmentRatio = (adjustedCalories - originalCalories).abs() / originalCalories.clamp(1, double.infinity);
    if (adjustmentRatio > 1.0) {
      return (originalConfidence * 0.5).clamp(0.0, 1.0);
    } else if (adjustmentRatio > 0.5) {
      return (originalConfidence * 0.7).clamp(0.0, 1.0);
    } else if (adjustmentRatio > 0.2) {
      return (originalConfidence * 0.9).clamp(0.0, 1.0);
    }

    return originalConfidence;
  }

  /// 保存食物记录
  Future<bool> saveFoodRecord({
    required String foodName,
    String foodNameEn = '',
    required List<String> ingredients,
    List<String> ingredientsEn = const [],
    required int calories,
    required String imagePath,
    required String mealType,
    double weight = 100.0,
    String nutritionInfo = '',
    double confidence = 0.0,
    List<String> tags = const [],
    List<String> tagsEn = const [],
  }) async {
    try {
      debugPrint('开始保存食物记录: $foodName, 热量: $calories, 重量: $weight');
      _clearError();
      _setLoading(true);

      // 将图片保存到应用持久化目录
      String savedImagePath = imagePath;
      try {
        final persistedPath = await _cameraService.saveImageToAppDirectory(imagePath);
        if (persistedPath != null) {
          savedImagePath = persistedPath;
          debugPrint('图片已持久化到: $savedImagePath');
        } else {
          debugPrint('图片持久化失败，使用原始路径');
        }
      } catch (e) {
        debugPrint('图片持久化异常: $e');
      }

      final foodItem = FoodItem(
        foodName: foodName,
        foodNameEn: foodNameEn,
        ingredients: ingredients,
        ingredientsEn: ingredientsEn,
        calories: calories,
        imagePath: savedImagePath,
        createdAt: DateTime.now(),
        mealType: mealType,
        weight: weight,
        tags: tags,
        tagsEn: tagsEn,
      );

      debugPrint('调用数据库插入操作...');
      final id = await _databaseService.insertFoodItem(foodItem);
      debugPrint('数据库插入成功，ID: $id');
      
      final savedItem = foodItem.copyWith(id: id);

      // 更新本地数据
      _foodItems.insert(0, savedItem);
      debugPrint('更新本地数据列表，当前共 ${_foodItems.length} 条记录');

      // 更新今日记录
      if (_todayRecord != null) {
        _todayRecord = _todayRecord!.addFoodItem(savedItem);
        _calculateTodayStats();
      }

      notifyListeners();
      debugPrint('食物记录保存完成');
      return true;

    } catch (e, stackTrace) {
      debugPrint('保存记录失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      _setError('保存记录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }



  /// 删除食物记录
  Future<bool> deleteFoodRecord(int id) async {
    try {
      _clearError();

      await _databaseService.deleteFoodItem(id);

      // 更新本地数据
      _foodItems.removeWhere((item) => item.id == id);

      // 更新今日记录
      if (_todayRecord != null) {
        _todayRecord = _todayRecord!.removeFoodItem(id);
        _calculateTodayStats();
      }

      notifyListeners();
      return true;

    } catch (e) {
      _setError('删除记录失败: $e');
      return false;
    }
  }

  /// 更新食物记录
  Future<bool> updateFoodRecord(FoodItem foodItem) async {
    try {
      _clearError();

      await _databaseService.updateFoodItem(foodItem);

      // 更新本地数据
      final index = _foodItems.indexWhere((item) => item.id == foodItem.id);
      if (index != -1) {
        _foodItems[index] = foodItem;

        // 重新计算今日记录
        await _loadDailyRecords();
        _calculateTodayStats();
      }

      notifyListeners();
      return true;

    } catch (e) {
      _setError('更新记录失败: $e');
      return false;
    }
  }

  /// 获取指定日期的记录
  Future<DailyRecord?> getDailyRecord(DateTime date) async {
    try {
      final items = await _databaseService.getFoodItemsByDate(date);

      final breakfastItems = items.where((item) => item.mealType == 'breakfast').toList();
      final lunchItems = items.where((item) => item.mealType == 'lunch').toList();
      final dinnerItems = items.where((item) => item.mealType == 'dinner').toList();
      final otherItems = items.where((item) => !['breakfast', 'lunch', 'dinner'].contains(item.mealType)).toList();

      return DailyRecord(
        date: date,
        breakfastItems: breakfastItems,
        lunchItems: lunchItems,
        dinnerItems: dinnerItems,
        otherItems: otherItems,
      );

    } catch (e) {
      _setError('获取日期记录失败: $e');
      return null;
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await _loadData();
  }

  /// 清空所有数据
  Future<bool> clearAllData() async {
    try {
      _clearError();
      _setLoading(true);

      await _databaseService.clearAllData();

      _foodItems.clear();
      _dailyRecords.clear();
      _todayRecord = null;
      _currentTotalCalories = 0;
      _mealCalories.clear();

      notifyListeners();
      return true;

    } catch (e) {
      _setError('清空数据失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 筛选食物记录
  List<FoodItem> filterFoodItems({
    DateTime? startDate,
    DateTime? endDate,
    String? mealType,
  }) {
    final filtered = _foodItems.where((item) {
      bool matchesDate = true;
      bool matchesMealType = true;

      if (startDate != null) {
        matchesDate = matchesDate && item.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1)));
      }
      if (endDate != null) {
        matchesDate = matchesDate && item.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }

      if (mealType != null && mealType != 'all') {
        matchesMealType = item.mealType == mealType;
      }

      return matchesDate && matchesMealType;
    }).toList();
    
    // 确保按时间由新到旧排序
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    if (_dailyRecords.isEmpty) {
      return {
        'averageDailyCalories': 0,
        'totalFoodItems': 0,
        'daysWithData': 0,
        'highestCalorieDay': null,
        'lowestCalorieDay': null,
      };
    }

    final totalCalories = _dailyRecords.map((record) => record.totalCalories).reduce((a, b) => a + b);
    final averageCalories = totalCalories / _dailyRecords.length;

    final recordsWithCalories = _dailyRecords.where((record) => record.totalCalories > 0).toList();
    final highestDay = recordsWithCalories.isNotEmpty
        ? recordsWithCalories.reduce((a, b) => a.totalCalories > b.totalCalories ? a : b)
        : null;
    final lowestDay = recordsWithCalories.isNotEmpty
        ? recordsWithCalories.reduce((a, b) => a.totalCalories < b.totalCalories ? a : b)
        : null;

    return {
      'averageDailyCalories': averageCalories.round(),
      'totalFoodItems': _foodItems.length,
      'daysWithData': recordsWithCalories.length,
      'highestCalorieDay': highestDay,
      'lowestCalorieDay': lowestDay,
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 测试方法：添加测试数据
  Future<bool> addTestData() async {
    debugPrint('添加测试数据...');
    return await saveFoodRecord(
      foodName: '测试食物 - ${DateTime.now().hour}:${DateTime.now().minute}',
      ingredients: ['测试成分1', '测试成分2'],
      calories: 500,
      imagePath: '/tmp/test.jpg',
      mealType: 'lunch',
      weight: 200.0,
      nutritionInfo: '测试营养信息',
      confidence: 0.95,
      tags: ['测试'],
    );
  }
}