import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/utils/calorie_calculator.dart';

void main() {
  group('CalorieCalculator Tests', () {
    group('estimateCaloriesByFoodName', () {
      test('should return correct calories for known foods', () {
        expect(CalorieCalculator.estimateCaloriesByFoodName('米饭'), equals(116));
        expect(CalorieCalculator.estimateCaloriesByFoodName('鸡肉'), equals(167));
        expect(CalorieCalculator.estimateCaloriesByFoodName('苹果'), equals(52));
      });

      test('should adjust calories based on weight', () {
        // 100克米饭是116千卡，200克应该是232千卡
        expect(CalorieCalculator.estimateCaloriesByFoodName('米饭', weight: 200), equals(232));
      });

      test('should return estimated calories for unknown foods', () {
        final result = CalorieCalculator.estimateCaloriesByFoodName('未知食物');
        expect(result, greaterThan(0));
      });

      test('should handle fuzzy matching', () {
        expect(CalorieCalculator.estimateCaloriesByFoodName('白米饭'), greaterThan(0));
        expect(CalorieCalculator.estimateCaloriesByFoodName('炒鸡肉'), greaterThan(0));
      });
    });

    group('calculateTotalCalories', () {
      test('should sum calories from multiple ingredients', () {
        final ingredients = ['米饭', '鸡肉', '青菜'];
        final result = CalorieCalculator.calculateTotalCalories(ingredients);
        expect(result, greaterThan(0));
      });

      test('should return 0 for empty ingredients list', () {
        expect(CalorieCalculator.calculateTotalCalories([]), equals(0));
      });

      test('should handle unknown ingredients gracefully', () {
        final ingredients = ['未知食物1', '未知食物2'];
        final result = CalorieCalculator.calculateTotalCalories(ingredients);
        expect(result, greaterThan(0));
      });
    });

    group('adjustCaloriesByMealType', () {
      test('should adjust calories based on meal type', () {
        expect(CalorieCalculator.adjustCaloriesByMealType(100, 'breakfast'), greaterThan(0));
        expect(CalculatorCalculator.adjustCaloriesByMealType(100, 'lunch'), greaterThan(0));
        expect(CalculatorCalculator.adjustCaloriesByMealType(100, 'dinner'), greaterThan(0));
      });

      test('should return original calories for unknown meal type', () {
        expect(CalculatorCalculator.adjustCaloriesByMealType(100, 'unknown'), equals(100));
      });
    });

    group('calculateDailyRecommendedCalories', () {
      test('should calculate recommended calories for male', () {
        final result = CalorieCalculator.calculateDailyRecommendedCalories(
          age: 30,
          gender: 'male',
          height: 175,
          weight: 70,
        );
        expect(result, greaterThan(1500));
        expect(result, lessThan(3000));
      });

      test('should calculate recommended calories for female', () {
        final result = CalorieCalculator.calculateDailyRecommendedCalories(
          age: 30,
          gender: 'female',
          height: 165,
          weight: 55,
        );
        expect(result, greaterThan(1200));
        expect(result, lessThan(2500));
      });
    });

    group('calculateWeightManagementCalories', () {
      test('should provide different calorie levels', () {
        final maintenance = 2000;
        final goals = CalorieCalculator.calculateWeightManagementCalories(maintenance);

        expect(goals['减重（每周0.5kg）'], lessThan(maintenance));
        expect(goals['维持体重'], equals(maintenance));
        expect(goals['增重（每周0.5kg）'], greaterThan(maintenance));
      });
    });

    group('getCalorieLevel', () {
      test('should return correct calorie levels', () {
        expect(CalorieCalculator.getCalorieLevel(25), equals('低热量'));
        expect(CalorieCalculator.getCalorieLevel(100), equals('中等热量'));
        expect(CalorieCalculator.getCalorieLevel(200), equals('较高热量'));
        expect(CalorieCalculator.getCalorieLevel(400), equals('高热量'));
      });
    });

    group('getCalorieColor', () {
      test('should return appropriate colors', () {
        expect(CalorieCalculator.getCalorieColor(25), equals('#4CAF50'));  // 绿色
        expect(CalorieCalculator.getCalorieColor(100), equals('#FF9800')); // 橙色
        expect(CalorieCalculator.getCalorieColor(200), equals('#FF5722')); // 深橙色
        expect(CalorieCalculator.getCalorieColor(400), equals('#F44336')); // 红色
      });
    });
  });
}