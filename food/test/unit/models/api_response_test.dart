import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_app/models/api_response.dart';

void main() {
  group('ApiResponse Tests', () {
    test('should create success response', () {
      final foodAnalysis = FoodAnalysis(
        foodName: '米饭',
        foodNameEn: 'Rice',
        ingredients: ['米', '水'],
        ingredientsEn: ['Rice', 'Water'],
        calories: 116,
        weight: 100.0,
        mealType: 'lunch',
        nutritionInfo: '碳水化合物为主',
        nutritionInfoEn: 'Mainly carbohydrates',
        confidence: 0.95,
        tags: ['主食'],
        tagsEn: ['Starch'],
      );

      final response = ApiResponse.success(foodAnalysis);

      expect(response.success, isTrue);
      expect(response.message, equals('识别成功'));
      expect(response.data, equals(foodAnalysis));
      expect(response.statusCode, isNull);
    });

    test('should create error response', () {
      final response = ApiResponse.error('网络错误', statusCode: 500);

      expect(response.success, isFalse);
      expect(response.message, equals('网络错误'));
      expect(response.data, isNull);
      expect(response.statusCode, equals(500));
    });

    test('should include raw response in success', () {
      final foodAnalysis = FoodAnalysis(
        foodName: '苹果',
        calories: 52,
        ingredients: ['苹果'],
      );

      final rawResponse = {'raw': 'data'};
      final response = ApiResponse.success(foodAnalysis, rawResponse: rawResponse);

      expect(response.rawResponse, equals(rawResponse));
    });

    test('should include raw response in error', () {
      final rawResponse = {'error': 'details'};
      final response = ApiResponse.error('API错误', rawResponse: rawResponse);

      expect(response.rawResponse, equals(rawResponse));
    });

    test('toString should provide useful information', () {
      final foodAnalysis = FoodAnalysis(
        foodName: '测试食物',
        calories: 100,
        ingredients: ['成分'],
      );

      final response = ApiResponse.success(foodAnalysis);

      final result = response.toString();
      expect(result, contains('ApiResponse'));
      expect(result, contains('true'));
      expect(result, contains('识别成功'));
    });
  });

  group('FoodAnalysis Tests', () {
    test('should create FoodAnalysis with all fields', () {
      final analysis = FoodAnalysis(
        foodName: '鸡胸肉',
        foodNameEn: 'Chicken Breast',
        ingredients: ['鸡胸肉', '调料'],
        ingredientsEn: ['Chicken Breast', 'Seasoning'],
        calories: 165,
        weight: 150.0,
        mealType: 'dinner',
        nutritionInfo: '高蛋白低脂肪',
        nutritionInfoEn: 'High protein low fat',
        confidence: 0.92,
        tags: ['高蛋白', '低脂'],
        tagsEn: ['High-protein', 'Low-fat'],
        isAdjusted: true,
        originalWeight: 200.0,
      );

      expect(analysis.foodName, equals('鸡胸肉'));
      expect(analysis.foodNameEn, equals('Chicken Breast'));
      expect(analysis.ingredients.length, equals(2));
      expect(analysis.ingredientsEn.length, equals(2));
      expect(analysis.calories, equals(165));
      expect(analysis.weight, equals(150.0));
      expect(analysis.mealType, equals('dinner'));
      expect(analysis.nutritionInfo, equals('高蛋白低脂肪'));
      expect(analysis.nutritionInfoEn, equals('High protein low fat'));
      expect(analysis.confidence, equals(0.92));
      expect(analysis.tags.length, equals(2));
      expect(analysis.tagsEn.length, equals(2));
      expect(analysis.isAdjusted, isTrue);
      expect(analysis.originalWeight, equals(200.0));
    });

    test('should create FoodAnalysis from map', () {
      final map = {
        'food_name': '三文鱼',
        'food_name_en': 'Salmon',
        'ingredients': ['三文鱼', '柠檬'],
        'ingredients_en': ['Salmon', 'Lemon'],
        'calories': 208,
        'weight': 120.0,
        'meal_type': 'dinner',
        'nutrition_info': '富含Omega-3',
        'nutrition_info_en': 'Rich in Omega-3',
        'confidence': 0.88,
        'tags': ['海鲜', '高蛋白'],
        'tags_en': ['Seafood', 'High-protein'],
      };

      final analysis = FoodAnalysis.fromMap(map);

      expect(analysis.foodName, equals('三文鱼'));
      expect(analysis.foodNameEn, equals('Salmon'));
      expect(analysis.ingredients.length, equals(2));
      expect(analysis.ingredientsEn.length, equals(2));
      expect(analysis.calories, equals(208));
      expect(analysis.weight, equals(120.0));
      expect(analysis.mealType, equals('dinner'));
      expect(analysis.nutritionInfo, equals('富含Omega-3'));
      expect(analysis.nutritionInfoEn, equals('Rich in Omega-3'));
      expect(analysis.confidence, equals(0.88));
      expect(analysis.tags.length, equals(2));
      expect(analysis.tagsEn.length, equals(2));
      expect(analysis.isAdjusted, isFalse);
    });

    test('should handle null and missing fields in fromMap', () {
      final map = {
        'food_name': '测试食物',
        'calories': 100,
      };

      final analysis = FoodAnalysis.fromMap(map);

      expect(analysis.foodName, equals('测试食物'));
      expect(analysis.foodNameEn, isEmpty);
      expect(analysis.ingredients, isEmpty);
      expect(analysis.ingredientsEn, isEmpty);
      expect(analysis.calories, equals(100));
      expect(analysis.weight, equals(100.0));
      expect(analysis.mealType, equals('other'));
      expect(analysis.nutritionInfo, isEmpty);
      expect(analysis.nutritionInfoEn, isEmpty);
      expect(analysis.confidence, equals(0.0));
      expect(analysis.tags, isEmpty);
      expect(analysis.tagsEn, isEmpty);
      expect(analysis.isAdjusted, isFalse);
    });

    test('should convert FoodAnalysis to map', () {
      final analysis = FoodAnalysis(
        foodName: '西兰花',
        foodNameEn: 'Broccoli',
        ingredients: ['西兰花', '蒜蓉'],
        ingredientsEn: ['Broccoli', 'Garlic'],
        calories: 34,
        weight: 100.0,
        mealType: 'lunch',
        nutritionInfo: '富含维生素C',
        nutritionInfoEn: 'Rich in Vitamin C',
        confidence: 0.90,
        tags: ['蔬菜', '健康'],
        tagsEn: ['Vegetable', 'Healthy'],
      );

      final map = analysis.toMap();

      expect(map['food_name'], equals('西兰花'));
      expect(map['food_name_en'], equals('Broccoli'));
      expect(map['ingredients'], equals(['西兰花', '蒜蓉']));
      expect(map['ingredients_en'], equals(['Broccoli', 'Garlic']));
      expect(map['calories'], equals(34));
      expect(map['weight'], equals(100.0));
      expect(map['meal_type'], equals('lunch'));
      expect(map['nutrition_info'], equals('富含维生素C'));
      expect(map['nutrition_info_en'], equals('Rich in Vitamin C'));
      expect(map['confidence'], equals(0.90));
      expect(map['tags'], equals(['蔬菜', '健康']));
      expect(map['tags_en'], equals(['Vegetable', 'Healthy']));
    });

    test('should calculate calorie density correctly', () {
      final analysis = FoodAnalysis(
        foodName: '牛油果',
        calories: 160,
        weight: 100.0,
        ingredients: ['牛油果'],
      );

      expect(analysis.calorieDensity, equals(160.0));

      final analysis2 = analysis.copyWith(weight: 200.0, calories: 320);
      expect(analysis2.calorieDensity, equals(160.0));
    });

    test('should handle zero weight in calorie density', () {
      final analysis = FoodAnalysis(
        foodName: '测试食物',
        calories: 100,
        weight: 0.0,
        ingredients: ['成分'],
      );

      expect(analysis.calorieDensity, equals(0.0));
    });

    test('should get main ingredients correctly', () {
      final analysis = FoodAnalysis(
        foodName: '蔬菜沙拉',
        calories: 100,
        ingredients: ['生菜', '番茄', '黄瓜', '胡萝卜', '洋葱', '青椒'],
        ingredientsEn: ['Lettuce', 'Tomato', 'Cucumber', 'Carrot', 'Onion', 'Pepper'],
      );

      final mainIngredients = analysis.mainIngredients;
      expect(mainIngredients.length, equals(3));
      expect(mainIngredients, contains('生菜'));
      expect(mainIngredients, isNot(contains('青椒')));
    });

    test('should get meal type display name correctly', () {
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], mealType: 'breakfast')
            .mealTypeDisplayName,
        equals('早餐'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], mealType: 'lunch')
            .mealTypeDisplayName,
        equals('午餐'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], mealType: 'dinner')
            .mealTypeDisplayName,
        equals('晚餐'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], mealType: 'other')
            .mealTypeDisplayName,
        equals('其他'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], mealType: 'snack')
            .mealTypeDisplayName,
        equals('其他'),
      );
    });

    test('should get confidence level correctly', () {
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], confidence: 0.95)
            .confidenceLevel,
        equals('很高'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], confidence: 0.75)
            .confidenceLevel,
        equals('高'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], confidence: 0.55)
            .confidenceLevel,
        equals('中等'),
      );
      expect(
        FoodAnalysis(foodName: '测试', calories: 100, ingredients: ['a'], confidence: 0.35)
            .confidenceLevel,
        equals('低'),
      );
    });

    test('copyWith should create new instance with updated fields', () {
      final original = FoodAnalysis(
        foodName: '香蕉',
        foodNameEn: 'Banana',
        ingredients: ['香蕉'],
        ingredientsEn: ['Banana'],
        calories: 89,
        weight: 100.0,
        mealType: 'other',
        nutritionInfo: '富含钾',
        nutritionInfoEn: 'Rich in potassium',
        confidence: 0.90,
        tags: ['水果'],
        tagsEn: ['Fruit'],
      );

      final modified = original.copyWith(
        calories: 95,
        weight: 120.0,
        mealType: 'breakfast',
        foodNameEn: 'Yellow Banana',
        isAdjusted: true,
        originalWeight: 100.0,
      );

      expect(modified.foodName, equals(original.foodName));
      expect(modified.foodNameEn, equals('Yellow Banana'));
      expect(modified.ingredients, equals(original.ingredients));
      expect(modified.ingredientsEn, equals(original.ingredientsEn));
      expect(modified.calories, equals(95));
      expect(modified.weight, equals(120.0));
      expect(modified.mealType, equals('breakfast'));
      expect(modified.nutritionInfo, equals(original.nutritionInfo));
      expect(modified.nutritionInfoEn, equals(original.nutritionInfoEn));
      expect(modified.confidence, equals(original.confidence));
      expect(modified.tags, equals(original.tags));
      expect(modified.tagsEn, equals(original.tagsEn));
      expect(modified.isAdjusted, isTrue);
      expect(modified.originalWeight, equals(100.0));
    });

    test('equality should work correctly', () {
      final analysis1 = FoodAnalysis(
        foodName: '米饭',
        calories: 116,
        ingredients: ['米'],
      );

      final analysis2 = FoodAnalysis(
        foodName: '米饭',
        calories: 150, // 不同的热量
        ingredients: ['米', '水'],
      );

      final analysis3 = FoodAnalysis(
        foodName: '面条',
        calories: 116,
        ingredients: ['面粉'],
      );

      expect(analysis1, equals(analysis2)); // foodName相同
      expect(analysis1, isNot(equals(analysis3))); // foodName不同
    });

    test('hashCode should be consistent', () {
      final analysis = FoodAnalysis(
        foodName: '测试食物',
        calories: 100,
        ingredients: ['成分'],
      );

      final hashCode1 = analysis.hashCode;
      final hashCode2 = analysis.hashCode;
      expect(hashCode1, equals(hashCode2));
    });

    test('toString should provide useful information', () {
      final analysis = FoodAnalysis(
        foodName: '测试食物',
        calories: 100,
        ingredients: ['成分'],
        confidence: 0.85,
      );

      final result = analysis.toString();
      expect(result, contains('FoodAnalysis'));
      expect(result, contains('测试食物'));
      expect(result, contains('100'));
      expect(result, contains('0.85'));
    });
  });

  group('ApiError Tests', () {
    test('should create network error', () {
      final error = ApiError.network('网络连接失败');

      expect(error.type, equals(ApiErrorType.networkError));
      expect(error.message, equals('网络连接失败'));
      expect(error.statusCode, isNull);
      expect(error.userFriendlyMessage, equals('网络连接失败，请检查网络设置'));
    });

    test('should create API error', () {
      final error = ApiError.api('API调用失败', statusCode: 400);

      expect(error.type, equals(ApiErrorType.apiError));
      expect(error.message, equals('API调用失败'));
      expect(error.statusCode, equals(400));
      expect(error.userFriendlyMessage, equals('API调用失败，请稍后重试'));
    });

    test('should create parse error', () {
      final error = ApiError.parse('JSON解析失败');

      expect(error.type, equals(ApiErrorType.parseError));
      expect(error.message, equals('JSON解析失败'));
      expect(error.userFriendlyMessage, equals('数据解析失败，请重新拍照'));
    });

    test('should create rate limit error', () {
      final error = ApiError.rateLimit('请求过于频繁');

      expect(error.type, equals(ApiErrorType.rateLimitError));
      expect(error.message, equals('请求过于频繁'));
      expect(error.userFriendlyMessage, equals('请求过于频繁，请稍后再试'));
    });

    test('should create auth error', () {
      final error = ApiError.auth('认证失败');

      expect(error.type, equals(ApiErrorType.authError));
      expect(error.message, equals('认证失败'));
      expect(error.userFriendlyMessage, equals('认证失败，请联系技术支持'));
    });

    test('should create server error', () {
      final error = ApiError.server('服务器错误', statusCode: 500);

      expect(error.type, equals(ApiErrorType.serverError));
      expect(error.message, equals('服务器错误'));
      expect(error.statusCode, equals(500));
      expect(error.userFriendlyMessage, equals('服务器错误，请稍后重试'));
    });

    test('should create unknown error', () {
      final error = ApiError.unknown('未知错误');

      expect(error.type, equals(ApiErrorType.unknown));
      expect(error.message, equals('未知错误'));
      expect(error.userFriendlyMessage, equals('未知错误，请重试'));
    });

    test('should create API error with status code', () {
      final error = ApiError.api('API 请求失败', statusCode: 400);

      expect(error.type, equals(ApiErrorType.apiError));
      expect(error.message, equals('API 请求失败'));
      expect(error.statusCode, equals(400));
    });

    test('toString should provide useful information', () {
      final error = ApiError.network('网络错误');

      final result = error.toString();
      expect(result, contains('ApiError'));
      expect(result, contains('networkError'));
      expect(result, contains('网络错误'));
    });

    test('all error types should have user friendly messages', () {
      final errors = [
        ApiError.network('msg'),
        ApiError.api('msg'),
        ApiError.parse('msg'),
        ApiError.rateLimit('msg'),
        ApiError.auth('msg'),
        ApiError.server('msg'),
        ApiError.unknown('msg'),
      ];

      for (final error in errors) {
        expect(error.userFriendlyMessage, isNotEmpty);
        expect(error.userFriendlyMessage, isNot(contains('ApiErrorType')));
      }
    });
  });
}
