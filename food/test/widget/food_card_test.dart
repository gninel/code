import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/widgets/food_card.dart';
import 'package:food_calorie_app/models/food_item.dart';
import 'package:food_calorie_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('FoodCard Widget Tests', () {
    late FoodItem testFoodItem;

    setUp(() {
      testFoodItem = FoodItem(
        id: 1,
        foodName: '测试食物',
        ingredients: ['成分1', '成分2'],
        calories: 200,
        imagePath: '', // 使用空路径避免文件加载问题
        createdAt: DateTime.now(),
        mealType: 'lunch',
      );
    });

    // 创建包装 Material App 的辅助函数
    Widget makeTestWidget({required Widget child}) {
      return Localizations(
        locale: const Locale('zh'),
        delegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: Scaffold(
              body: child,
            ),
          ),
        ),
      );
    }

    testWidgets('should display food item information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        makeTestWidget(
          child: FoodCard(
            foodItem: testFoodItem,
            onTap: () {},
          ),
        ),
      );

      // 等待所有异步操作完成
      await tester.pumpAndSettle();

      // 验证 FoodCard 被渲染
      expect(find.byType(FoodCard), findsOneWidget);

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
        makeTestWidget(
          child: FoodCard(
            foodItem: testFoodItem,
            onTap: () {
              wasTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FoodCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should hide actions when showActions is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        makeTestWidget(
          child: FoodCard(
            foodItem: testFoodItem,
            showActions: false,
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // showActions 为 false 时不应该有 IconButton
      expect(find.byType(IconButton), findsNothing);
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
        makeTestWidget(
          child: FoodCard(
            foodItem: foodWithoutImage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // breakfast 的图标是 wb_sunny，应该至少出现一次
      // 可能在多个地方显示（图片占位符、餐次图标等）
      expect(find.byIcon(Icons.wb_sunny), findsAtLeastNWidgets(1));
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
        makeTestWidget(
          child: FoodCard(
            foodItem: lowCalorieFood,
          ),
        ),
      );
      await tester.pumpAndSettle();

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
        makeTestWidget(
          child: FoodCard(
            foodItem: foodWithoutIngredients,
          ),
        ),
      );
      await tester.pumpAndSettle();

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
        makeTestWidget(
          child: FoodCard(
            foodItem: longNameFood,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证 FoodCard 被渲染
      expect(find.byType(FoodCard), findsOneWidget);

      // 验证至少有文本被渲染
      final textFinder = find.byType(Text);
      expect(textFinder, findsWidgets);

      // 长文本可能会显示（取决于宽度），验证组件没有崩溃
      expect(find.text('这是一个非常长的食物名称，需要测试文本截断功能是否正常工作'), findsAtLeastNWidgets(1));
    });
  });
}