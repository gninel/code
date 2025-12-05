import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/models/daily_record.dart';
import 'package:food_calorie_app/models/food_item.dart';

void main() {
  group('DailyRecord Tests', () {
    late FoodItem breakfastItem;
    late FoodItem lunchItem;
    late FoodItem dinnerItem;
    late FoodItem otherItem;

    setUp(() {
      breakfastItem = FoodItem(
        id: 1,
        foodName: '燕麦粥',
        ingredients: ['燕麦', '牛奶'],
        calories: 150,
        imagePath: '/path/to/oatmeal.jpg',
        createdAt: DateTime.now(),
        mealType: 'breakfast',
      );

      lunchItem = FoodItem(
        id: 2,
        foodName: '鸡胸肉沙拉',
        ingredients: ['鸡肉', '生菜', '番茄'],
        calories: 300,
        imagePath: '/path/to/salad.jpg',
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );

      dinnerItem = FoodItem(
        id: 3,
        foodName: '清炒时蔬',
        ingredients: ['青菜', '胡萝卜'],
        calories: 120,
        imagePath: '/path/to/vegetables.jpg',
        createdAt: DateTime.now(),
        mealType: 'dinner',
      );

      otherItem = FoodItem(
        id: 4,
        foodName: '苹果',
        ingredients: ['苹果'],
        calories: 52,
        imagePath: '/path/to/apple.jpg',
        createdAt: DateTime.now(),
        mealType: 'other',
      );
    });

    test('should create empty DailyRecord', () {
      final date = DateTime.now();
      final record = DailyRecord(date: date);

      expect(record.date, equals(date));
      expect(record.breakfastItems, isEmpty);
      expect(record.lunchItems, isEmpty);
      expect(record.dinnerItems, isEmpty);
      expect(record.otherItems, isEmpty);
      expect(record.totalCalories, equals(0));
    });

    test('should calculate total calories correctly', () {
      final record = DailyRecord(
        date: DateTime.now(),
        breakfastItems: [breakfastItem],
        lunchItems: [lunchItem],
        dinnerItems: [dinnerItem],
        otherItems: [otherItem],
      );

      expect(record.totalCalories, equals(622)); // 150 + 300 + 120 + 52
    });

    test('should calculate meal calories correctly', () {
      final record = DailyRecord(
        date: DateTime.now(),
        breakfastItems: [breakfastItem],
        lunchItems: [lunchItem],
        dinnerItems: [dinnerItem],
        otherItems: [otherItem],
      );

      final mealCalories = record.mealCalories;
      expect(mealCalories['breakfast'], equals(150));
      expect(mealCalories['lunch'], equals(300));
      expect(mealCalories['dinner'], equals(120));
      expect(mealCalories['other'], equals(52));
    });

    test('should get all items correctly', () {
      final record = DailyRecord(
        date: DateTime.now(),
        breakfastItems: [breakfastItem],
        lunchItems: [lunchItem],
        dinnerItems: [dinnerItem],
        otherItems: [otherItem],
      );

      final allItems = record.allItems;
      expect(allItems.length, equals(4));
      expect(allItems, contains(breakfastItem));
      expect(allItems, contains(lunchItem));
      expect(allItems, contains(dinnerItem));
      expect(allItems, contains(otherItem));
    });

    test('should add food item to correct meal type', () {
      var record = DailyRecord(date: DateTime.now());

      record = record.addFoodItem(breakfastItem);
      expect(record.breakfastItems, contains(breakfastItem));
      expect(record.lunchItems, isEmpty);

      record = record.addFoodItem(lunchItem);
      expect(record.lunchItems, contains(lunchItem));
      expect(record.breakfastItems, contains(breakfastItem));
    });

    test('should add unknown meal type to other items', () {
      var record = DailyRecord(date: DateTime.now());
      final unknownMealItem = FoodItem(
        id: 5,
        foodName: '未知食物',
        ingredients: ['成分'],
        calories: 100,
        imagePath: '/path/to/unknown.jpg',
        createdAt: DateTime.now(),
        mealType: 'unknown_meal',
      );

      record = record.addFoodItem(unknownMealItem);
      expect(record.otherItems, contains(unknownMealItem));
      expect(record.breakfastItems, isEmpty);
      expect(record.lunchItems, isEmpty);
      expect(record.dinnerItems, isEmpty);
    });

    test('should remove food item correctly', () {
      var record = DailyRecord(
        date: DateTime.now(),
        breakfastItems: [breakfastItem],
        lunchItems: [lunchItem],
        dinnerItems: [dinnerItem],
        otherItems: [otherItem],
      );

      record = record.removeFoodItem(lunchItem.id!);
      expect(record.lunchItems, isEmpty);
      expect(record.breakfastItems, contains(breakfastItem));
      expect(record.dinnerItems, contains(dinnerItem));
      expect(record.otherItems, contains(otherItem));
      expect(record.totalCalories, equals(322)); // 150 + 120 + 52
    });

    test('should format date string correctly', () {
      final date = DateTime(2023, 1, 15, 14, 30, 0);
      final record = DailyRecord(date: date);

      expect(record.dateString, equals('2023-01-15'));
    });

    test('should provide friendly date names', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      final otherDay = today.subtract(const Duration(days: 5));

      expect(DailyRecord(date: today).friendlyDate, equals('今天'));
      expect(DailyRecord(date: yesterday).friendlyDate, equals('昨天'));
      expect(DailyRecord(date: tomorrow).friendlyDate, equals('明天'));
      expect(DailyRecord(date: otherDay).friendlyDate, equals('${otherDay.month}月${otherDay.day}日'));
    });

    test('should handle empty meals correctly', () {
      final record = DailyRecord(date: DateTime.now());

      expect(record.totalCalories, equals(0));
      expect(record.mealCalories['breakfast'], equals(0));
      expect(record.mealCalories['lunch'], equals(0));
      expect(record.mealCalories['dinner'], equals(0));
      expect(record.mealCalories['other'], equals(0));
      expect(record.allItems, isEmpty);
    });

    test('equality should work correctly', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 2);

      final record1 = DailyRecord(date: date1);
      final record2 = DailyRecord(date: date1);
      final record3 = DailyRecord(date: date2);

      expect(record1, equals(record2)); // 相同日期
      expect(record1, isNot(equals(record3))); // 不同日期
    });

    test('hashCode should be consistent', () {
      final date = DateTime(2023, 1, 1);
      final record = DailyRecord(date: date);

      final hashCode1 = record.hashCode;
      final hashCode2 = record.hashCode;
      expect(hashCode1, equals(hashCode2));
    });

    test('toString should provide useful information', () {
      final date = DateTime(2023, 1, 1);
      final record = DailyRecord(
        date: date,
        breakfastItems: [breakfastItem],
      );

      final result = record.toString();
      expect(result, contains('DailyRecord'));
      expect(result, contains(date.toString()));
      expect(result, contains('150'));
      expect(result, contains('1'));
    });

    test('should handle multiple items in same meal', () {
      final secondBreakfastItem = FoodItem(
        id: 6,
        foodName: '鸡蛋',
        ingredients: ['鸡蛋'],
        calories: 70,
        imagePath: '/path/to/egg.jpg',
        createdAt: DateTime.now(),
        mealType: 'breakfast',
      );

      final record = DailyRecord(
        date: DateTime.now(),
        breakfastItems: [breakfastItem, secondBreakfastItem],
      );

      expect(record.breakfastItems.length, equals(2));
      expect(record.totalCalories, equals(220)); // 150 + 70
      expect(record.mealCalories['breakfast'], equals(220));
    });

    test('should get main ingredients correctly', () {
      final foodWithManyIngredients = FoodItem(
        id: 7,
        foodName: '复杂菜肴',
        ingredients: ['成分1', '成分2', '成分3', '成分4', '成分5'],
        calories: 200,
        imagePath: '/path/to/complex.jpg',
        createdAt: DateTime.now(),
        mealType: 'dinner',
      );

      final record = DailyRecord(
        date: DateTime.now(),
        dinnerItems: [foodWithManyIngredients],
      );

      expect(record.dinnerItems.first.ingredients.length, equals(5));
      expect(record.dinnerItems.first.ingredients, contains('成分1'));
      expect(record.dinnerItems.first.ingredients, contains('成分5'));
    });
  });
}