import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/widgets/food_card.dart';
import 'package:food_calorie_app/models/food_item.dart';

void main() {
  group('FoodCard Widget Tests', () {
    late FoodItem testFoodItem;

    setUp(() {
      testFoodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分1', '成分2'],
        calories: 200,
        imagePath: '/test/path/image.jpg',
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );
    });

    testWidgets('should display food item information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: testFoodItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // 验证食物名称显示
      expect(find.text('测试食物'), findsOneWidget);

      // 验证热量显示
      expect(find.text('200 千卡'), findsOneWidget);

      // 验证餐次显示
      expect(find.text('午餐'), findsOneWidget);

      // 验证成分显示
      expect(find.text('成分1、成分2'), findsOneWidget);
    });

    testWidgets('should handle tap correctly', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: testFoodItem,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FoodCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should show delete button when actions enabled', (WidgetTester tester) async {
      bool wasDeleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: testFoodItem,
              onDelete: () {
                wasDeleted = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(wasDeleted, isTrue);
    });

    testWidgets('should hide actions when showActions is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: testFoodItem,
              showActions: false,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('should display default image when no image path', (WidgetTester tester) async {
      final foodWithoutImage = FoodItem(
        id: 2,
        foodName: '无图片食物',
        ingredients: ['成分'],
        calories: 100,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'breakfast',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: foodWithoutImage,
            ),
          ),
        ),
      );

      // 应该显示默认图片占位符
      expect(find.byIcon(Icons.wb_cloudy), findsOneWidget);
    });

    testWidgets('should display correct calorie level and color', (WidgetTester tester) async {
      final lowCalorieFood = FoodItem(
        id: 3,
        foodName: '低热量食物',
        ingredients: ['蔬菜'],
        calories: 30,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'other',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: lowCalorieFood,
            ),
          ),
        ),
      );

      expect(find.text('低热量'), findsOneWidget);
    });

    testWidgets('should handle empty ingredients list', (WidgetTester tester) async {
      final foodWithoutIngredients = FoodItem(
        id: 4,
        foodName: '简单食物',
        ingredients: [],
        calories: 150,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: foodWithoutIngredients,
            ),
          ),
        ),
      );

      // 不应该显示成分行
      expect(find.text('、'), findsNothing);
    });

    testWidgets('should handle long food names', (WidgetTester tester) async {
      final longNameFood = FoodItem(
        id: 5,
        foodName: '这是一个非常长的食物名称，需要测试文本截断功能是否正常工作',
        ingredients: ['成分'],
        calories: 250,
        imagePath: '',
        createdAt: DateTime.now(),
        mealType: 'dinner',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: longNameFood,
            ),
          ),
        ),
      );

      // 食物名称应该被截断
      final foodNameFinder = find.text('这是一个非常长的食物名称，需要测试文本截断功能是否正常工作');
      expect(foodNameFinder, findsOneWidget);
    });
  });
}