import 'food_item.dart';

/// 每日记录数据模型
class DailyRecord {
  final DateTime date;
  final List<FoodItem> breakfastItems;
  final List<FoodItem> lunchItems;
  final List<FoodItem> dinnerItems;
  final List<FoodItem> otherItems;

  DailyRecord({
    required this.date,
    this.breakfastItems = const [],
    this.lunchItems = const [],
    this.dinnerItems = const [],
    this.otherItems = const [],
  });

  /// 获取当日总热量
  int get totalCalories {
    final breakfastCalories = breakfastItems.fold<int>(0, (sum, item) => sum + item.calories);
    final lunchCalories = lunchItems.fold<int>(0, (sum, item) => sum + item.calories);
    final dinnerCalories = dinnerItems.fold<int>(0, (sum, item) => sum + item.calories);
    final otherCalories = otherItems.fold<int>(0, (sum, item) => sum + item.calories);

    return breakfastCalories + lunchCalories + dinnerCalories + otherCalories;
  }

  /// 获取各餐热量
  Map<String, int> get mealCalories {
    return {
      'breakfast': breakfastItems.fold<int>(0, (sum, item) => sum + item.calories),
      'lunch': lunchItems.fold<int>(0, (sum, item) => sum + item.calories),
      'dinner': dinnerItems.fold<int>(0, (sum, item) => sum + item.calories),
      'other': otherItems.fold<int>(0, (sum, item) => sum + item.calories),
    };
  }

  /// 获取所有食物项
  List<FoodItem> get allItems => [
        ...breakfastItems,
        ...lunchItems,
        ...dinnerItems,
        ...otherItems,
      ];

  /// 添加食物项到对应餐次
  DailyRecord addFoodItem(FoodItem item) {
    final newRecord = DailyRecord(
      date: date,
      breakfastItems: List.from(breakfastItems),
      lunchItems: List.from(lunchItems),
      dinnerItems: List.from(dinnerItems),
      otherItems: List.from(otherItems),
    );

    switch (item.mealType.toLowerCase()) {
      case 'breakfast':
        newRecord.breakfastItems.add(item);
        break;
      case 'lunch':
        newRecord.lunchItems.add(item);
        break;
      case 'dinner':
        newRecord.dinnerItems.add(item);
        break;
      default:
        newRecord.otherItems.add(item);
        break;
    }

    return newRecord;
  }

  /// 删除食物项
  DailyRecord removeFoodItem(int itemId) {
    return DailyRecord(
      date: date,
      breakfastItems: breakfastItems.where((item) => item.id != itemId).toList(),
      lunchItems: lunchItems.where((item) => item.id != itemId).toList(),
      dinnerItems: dinnerItems.where((item) => item.id != itemId).toList(),
      otherItems: otherItems.where((item) => item.id != itemId).toList(),
    );
  }

  /// 获取日期字符串 (yyyy-MM-dd)
  String get dateString {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取友好的日期显示
  String get friendlyDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    final difference = recordDate.difference(today).inDays;

    switch (difference) {
      case 0:
        return '今天';
      case 1:
        return '明天';
      case -1:
        return '昨天';
      default:
        return '${date.month}月${date.day}日';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecord &&
          runtimeType == other.runtimeType &&
          date == other.date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() {
    return 'DailyRecord{date: $date, totalCalories: $totalCalories, items: ${allItems.length}}';
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'breakfastItems': breakfastItems.map((item) => item.toMap()).toList(),
      'lunchItems': lunchItems.map((item) => item.toMap()).toList(),
      'dinnerItems': dinnerItems.map((item) => item.toMap()).toList(),
      'otherItems': otherItems.map((item) => item.toMap()).toList(),
    };
  }
}