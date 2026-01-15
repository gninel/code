import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/models/food_item.dart';

void main() {
  group('FoodItem Tests', () {
    test('should create FoodItem from map', () {
      final map = {
        'id': 1,
        'food_name': '米饭',
        'food_name_en': 'Rice',
        'ingredients': '米,水',
        'ingredients_en': 'Rice,Water',
        'calories': 116,
        'image_path': '/path/to/image.jpg',
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'lunch',
        'weight': 150.0,
        'tags': '主食,低脂',
        'tags_en': 'Starch,Low-fat',
      };

      final foodItem = FoodItem.fromMap(map);

      expect(foodItem.id, equals(1));
      expect(foodItem.foodName, equals('米饭'));
      expect(foodItem.foodNameEn, equals('Rice'));
      expect(foodItem.ingredients, equals(['米', '水']));
      expect(foodItem.ingredientsEn, equals(['Rice', 'Water']));
      expect(foodItem.calories, equals(116));
      expect(foodItem.imagePath, equals('/path/to/image.jpg'));
      expect(foodItem.mealType, equals('lunch'));
      expect(foodItem.weight, equals(150.0));
      expect(foodItem.tags, equals(['主食', '低脂']));
      expect(foodItem.tagsEn, equals(['Starch', 'Low-fat']));
    });

    test('should convert FoodItem to map', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '鸡肉',
        foodNameEn: 'Chicken',
        ingredients: ['鸡肉', '调料'],
        ingredientsEn: ['Chicken', 'Seasoning'],
        calories: 167,
        imagePath: '/path/to/chicken.jpg',
        createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
        mealType: 'dinner',
        weight: 200.0,
        tags: ['高蛋白'],
        tagsEn: ['High-protein'],
      );

      final map = foodItem.toMap();

      expect(map['id'], equals(1));
      expect(map['food_name'], equals('鸡肉'));
      expect(map['food_name_en'], equals('Chicken'));
      expect(map['ingredients'], equals('鸡肉,调料'));
      expect(map['ingredients_en'], equals('Chicken,Seasoning'));
      expect(map['calories'], equals(167));
      expect(map['image_path'], equals('/path/to/chicken.jpg'));
      expect(map['meal_type'], equals('dinner'));
      expect(map['weight'], equals(200.0));
      expect(map['tags'], equals('高蛋白'));
      expect(map['tags_en'], equals('High-protein'));
    });

    test('should copy with modifications', () {
      final original = FoodItem(
        foodName: '苹果',
        foodNameEn: 'Apple',
        ingredients: ['苹果'],
        ingredientsEn: ['Apple'],
        calories: 52,
        imagePath: '/path/to/apple.jpg',
        createdAt: DateTime.now(),
        mealType: 'other',
        weight: 100.0,
        tags: ['水果'],
        tagsEn: ['Fruit'],
      );

      final modified = original.copyWith(
        calories: 60,
        mealType: 'breakfast',
        weight: 150.0,
        foodNameEn: 'Green Apple',
      );

      expect(modified.foodName, equals(original.foodName));
      expect(modified.calories, equals(60));
      expect(modified.mealType, equals('breakfast'));
      expect(modified.weight, equals(150.0));
      expect(modified.foodNameEn, equals('Green Apple'));
      expect(modified.ingredients, equals(original.ingredients));
      expect(modified.tags, equals(original.tags));
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
      expect(foodItem.ingredientsEn, isEmpty);
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

    test('should handle weight field correctly', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分'],
        calories: 100,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'other',
        weight: 250.5,
      );

      expect(foodItem.weight, equals(250.5));

      final modified = foodItem.copyWith(weight: 300.0);
      expect(modified.weight, equals(300.0));
    });

    test('should handle tags field correctly', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分'],
        calories: 100,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'other',
        tags: ['低热量', '高蛋白', '素食'],
        tagsEn: ['Low-calorie', 'High-protein', 'Vegetarian'],
      );

      expect(foodItem.tags.length, equals(3));
      expect(foodItem.tags, contains('低热量'));
      expect(foodItem.tagsEn, contains('Low-calorie'));

      final modified = foodItem.copyWith(
        tags: ['低热量', '高蛋白', '素食', '无糖'],
        tagsEn: ['Low-calorie', 'High-protein', 'Vegetarian', 'Sugar-free'],
      );
      expect(modified.tags.length, equals(4));
      expect(modified.tagsEn.last, equals('Sugar-free'));
    });

    test('should handle bilingual fields', () {
      final map = {
        'id': 1,
        'food_name': '饺子',
        'food_name_en': 'Dumplings',
        'ingredients': '面粉,猪肉,韭菜',
        'ingredients_en': 'Flour,Pork,Chives',
        'calories': 250,
        'image_path': '',
        'created_at': '2023-01-01T12:00:00.000Z',
        'meal_type': 'lunch',
        'weight': 200.0,
        'tags': '主食,肉馅',
        'tags_en': 'Starch,Meat-filled',
      };

      final foodItem = FoodItem.fromMap(map);

      expect(foodItem.foodName, equals('饺子'));
      expect(foodItem.foodNameEn, equals('Dumplings'));
      expect(foodItem.ingredients.length, equals(3));
      expect(foodItem.ingredientsEn.length, equals(3));
      expect(foodItem.tags.length, equals(2));
      expect(foodItem.tagsEn.length, equals(2));

      final serialized = foodItem.toMap();
      expect(serialized['food_name_en'], equals('Dumplings'));
      expect(serialized['ingredients_en'], equals('Flour,Pork,Chives'));
      expect(serialized['tags_en'], equals('Starch,Meat-filled'));
    });

    test('should handle default values for new fields', () {
      final foodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分'],
        calories: 100,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'other',
      );

      expect(foodItem.foodNameEn, isEmpty);
      expect(foodItem.ingredientsEn, isEmpty);
      expect(foodItem.weight, equals(100.0));
      expect(foodItem.tags, isEmpty);
      expect(foodItem.tagsEn, isEmpty);
    });
  });
}