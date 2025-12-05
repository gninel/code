import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/widgets/daily_summary.dart';

void main() {
  group('DailySummary Widget Tests', () {
    testWidgets('should display total calories correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 500,
              mealCalories: {
                'breakfast': 150,
                'lunch': 300,
                'dinner': 50,
                'other': 0,
              },
            ),
          ),
        ),
      );

      expect(find.text('500 千卡'), findsOneWidget);
      expect(find.text('今日总热量'), findsOneWidget);
    });

    testWidgets('should display recommended calories when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 1500,
              mealCalories: {'breakfast': 500, 'lunch': 700, 'dinner': 300},
              recommendedCalories: 2000,
            ),
          ),
        ),
      );

      expect(find.text('建议: 2000 千卡'), findsOneWidget);
    });

    testWidgets('should show correct progress percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 1000,
              mealCalories: {'breakfast': 300, 'lunch': 500, 'dinner': 200},
              recommendedCalories: 2000,
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('完成度'), findsOneWidget);
    });

    testWidgets('should display meal details when showDetails is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 800,
              mealCalories: {
                'breakfast': 200,
                'lunch': 400,
                'dinner': 150,
                'other': 50,
              },
              showDetails: true,
            ),
          ),
        ),
      );

      expect(find.text('餐次分布'), findsOneWidget);
      expect(find.text('早餐'), findsOneWidget);
      expect(find.text('午餐'), findsOneWidget);
      expect(find.text('晚餐'), findsOneWidget);
      expect(find.text('其他'), findsOneWidget);
    });

    testWidgets('should hide meal details when showDetails is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 800,
              mealCalories: {
                'breakfast': 200,
                'lunch': 400,
                'dinner': 150,
                'other': 50,
              },
              showDetails: false,
            ),
          ),
        ),
      );

      expect(find.text('餐次分布'), findsNothing);
    });

    testWidgets('should display correct status for low calorie intake', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 1200,
              mealCalories: {'breakfast': 400, 'lunch': 500, 'dinner': 300},
              recommendedCalories: 2000,
            ),
          ),
        ),
      );

      expect(find.text('热量摄入偏低，建议适量增加'), findsOneWidget);
    });

    testWidgets('should display correct status for high calorie intake', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 2500,
              mealCalories: {'breakfast': 800, 'lunch': 1000, 'dinner': 700},
              recommendedCalories: 2000,
            ),
          ),
        ),
      );

      expect(find.text('热量摄入偏高，建议适当控制'), findsOneWidget);
    });

    testWidgets('should display correct status for normal calorie intake', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 1800,
              mealCalories: {'breakfast': 500, 'lunch': 800, 'dinner': 500},
              recommendedCalories: 2000,
            ),
          ),
        ),
      );

      expect(find.text('热量摄入正常，继续保持'), findsOneWidget);
    });

    testWidgets('should display correct meal calories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 900,
              mealCalories: {
                'breakfast': 200,
                'lunch': 400,
                'dinner': 250,
                'other': 50,
              },
              showDetails: true,
            ),
          ),
        ),
      );

      expect(find.text('200 千卡'), findsOneWidget);
      expect(find.text('400 千卡'), findsOneWidget);
      expect(find.text('250 千卡'), findsOneWidget);
      expect(find.text('50 千卡'), findsOneWidget);
    });

    testWidgets('should handle zero meal calories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailySummary(
              totalCalories: 0,
              mealCalories: {
                'breakfast': 0,
                'lunch': 0,
                'dinner': 0,
                'other': 0,
              },
              showDetails: true,
            ),
          ),
        ),
      );

      expect(find.text('0 千卡'), findsOneWidget);
      expect(find.text('今日总热量'), findsOneWidget);
    });
  });
}