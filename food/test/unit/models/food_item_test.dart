import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/models/food_item.dart';

void main() {
  group('FoodItem Tests', () {
    test('should create FoodItem from map', () {
      final map = {
        'id': 1,
        'food_name': '米饭',
        'ingredients': '米,水',
        'calories': 116,
        'image_path': '/path/to/image.jpg',
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'lunch',
      };

      final foodItem = FoodItem.fromMap(map);

      expect(foodItem.id, equals(1));
      expect(foodItem.foodName, equals('米饭'));
      expect(foodItem.ingredients, equals(['米', '水']));
      expect(foodItem.calories, equals(116));
      expect(foodItem.imagePath, equals('/path/to/image.jpg'));
      expect(foodItem.mealType, equals('lunch'));
    });

    test('should convert FoodItem to map', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '鸡肉',
        ingredients: ['鸡肉', '调料'],
        calories: 167,
        imagePath: '/path/to/chicken.jpg',
        createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
        mealType: 'dinner',
      );

      final map = foodItem.toMap();

      expect(map['id'], equals(1));
      expect(map['food_name'], equals('鸡肉'));
      expect(map['ingredients'], equals('鸡肉,调料'));
      expect(map['calories'], equals(167));
      expect(map['image_path'], equals('/path/to/chicken.jpg'));
      expect(map['meal_type'], equals('dinner'));
    });

    test('should copy with modifications', () {
      final original = FoodItem(
        foodName: '苹果',
        ingredients: ['苹果'],
        calories: 52,
        imagePath: '/path/to/apple.jpg',
        createdAt: DateTime.now(),
        mealType: 'other',
      );

      final modified = original.copyWith(
        calories: 60,
        mealType: 'breakfast',
      );

      expect(modified.foodName, equals(original.foodName));
      expect(modified.calories, equals(60));
      expect(modified.mealType, equals('breakfast'));
    });

    test('should handle empty ingredients string', () {
      final map = {
        'id': 1,
        'food_name': '测试食物',
        'ingredients': '',
        'calories': 100,
        'image_path': '',
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'other',
      };

      final foodItem = FoodItem.fromMap(map);
      expect(foodItem.ingredients, isEmpty);
    });

    test('should handle null ingredients', () {
      final map = {
        'id': 1,
        'food_name': '测试食物',
        'calories': 100,
        'image_path': '',
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'other',
      };

      final foodItem = FoodItem.fromMap(map);
      expect(foodItem.ingredients, isEmpty);
    });

    test('should handle null image_path', () {
      final map = {
        'id': 1,
        'food_name': '测试食物',
        'ingredients': '成分1,成分2',
        'calories': 100,
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'other',
      };

      final foodItem = FoodItem.fromMap(map);
      expect(foodItem.imagePath, isEmpty);
    });

    test('should handle null meal_type', () {
      final map = {
        'id': 1,
        'food_name': '测试食物',
        'ingredients': '成分1,成分2',
        'calories': 100,
        'image_path': '/path/to/image.jpg',
        'created_at': '2023-01-01T12:00:00.000Z',
      };

      final foodItem = FoodItem.fromMap(map);
      expect(foodItem.mealType, equals('other'));
    });

    test('equality should work correctly', () {
      final food1 = FoodItem(
        id: 1,
        foodName: '米饭',
        ingredients: ['米'],
        calories: 116,
        imagePath: '/path/to/rice.jpg',
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );

      final food2 = FoodItem(
        id: 1,
        foodName: '米饭',
        ingredients: ['米', '水'],
        calories: 120, // 不同的热量值
        imagePath: '/path/to/rice.jpg',
        createdAt: DateTime.now(),
        mealType: 'dinner', // 不同的餐次
      );

      final food3 = FoodItem(
        id: 2,
        foodName: '米饭',
        ingredients: ['米'],
        calories: 116,
        imagePath: '/path/to/rice.jpg',
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );

      expect(food1, equals(food2)); // id和foodName相同
      expect(food1, isNot(equals(food3))); // id不同
    });

    test('hashCode should be consistent', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分1'],
        calories: 100,
        imagePath: '/path/to/test.jpg',
        createdAt: DateTime.now(),
        mealType: 'other',
      );

      final hashCode1 = foodItem.hashCode;
      final hashCode2 = foodItem.hashCode;
      expect(hashCode1, equals(hashCode2));
    });

    test('toString should provide useful information', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分1'],
        calories: 100,
        imagePath: '/path/to/test.jpg',
        createdAt: DateTime.now(),
        mealType: 'other',
      );

      final result = foodItem.toString();
      expect(result, contains('FoodItem'));
      expect(result, contains('1'));
      expect(result, contains('测试食物'));
      expect(result, contains('100'));
      expect(result, contains('other'));
    });
  });
}