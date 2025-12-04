/// API响应数据模型
class ApiResponse {
  final bool success;
  final String message;
  final FoodAnalysis? data;
  final int? statusCode;
  final Map<String, dynamic>? rawResponse;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.rawResponse,
  });

  factory ApiResponse.success(FoodAnalysis data, {Map<String, dynamic>? rawResponse}) {
    return ApiResponse(
      success: true,
      message: '识别成功',
      data: data,
      rawResponse: rawResponse,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? rawResponse}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      rawResponse: rawResponse,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, data: $data}';
  }
}

/// 食物分析结果
class FoodAnalysis {
  final String foodName;
  final String foodNameEn; // 英文食物名称
  final List<String> ingredients;
  final List<String> ingredientsEn; // 英文成分
  final int calories;
  final double weight; // 重量（克）
  final String mealType; // 餐次类型
  final String nutritionInfo; // 营养信息
  final String nutritionInfoEn; // 英文营养信息
  final double confidence; // 识别置信度
  final List<String> tags; // 标签
  final List<String> tagsEn; // 英文标签
  final bool isAdjusted; // 数据是否已调整
  final double? originalWeight; // 原始重量（若已调整）

  FoodAnalysis({
    required this.foodName,
    this.foodNameEn = '',
    required this.ingredients,
    this.ingredientsEn = const [],
    required this.calories,
    this.weight = 100.0,
    this.mealType = 'other',
    this.nutritionInfo = '',
    this.nutritionInfoEn = '',
    this.confidence = 0.0,
    this.tags = const [],
    this.tagsEn = const [],
    this.isAdjusted = false,
    this.originalWeight,
  });

  factory FoodAnalysis.fromMap(Map<String, dynamic> map) {
    return FoodAnalysis(
      foodName: map['food_name'] as String? ?? '',
      foodNameEn: map['food_name_en'] as String? ?? '',
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ingredientsEn: (map['ingredients_en'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 100.0,
      mealType: map['meal_type'] as String? ?? 'other',
      nutritionInfo: map['nutrition_info'] as String? ?? '',
      nutritionInfoEn: map['nutrition_info_en'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tagsEn: (map['tags_en'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'food_name': foodName,
      'food_name_en': foodNameEn,
      'ingredients': ingredients,
      'ingredients_en': ingredientsEn,
      'calories': calories,
      'weight': weight,
      'meal_type': mealType,
      'nutrition_info': nutritionInfo,
      'nutrition_info_en': nutritionInfoEn,
      'confidence': confidence,
      'tags': tags,
      'tags_en': tagsEn,
    };
  }

  /// 获取热量密度（每100克热量）
  double get calorieDensity => weight > 0 ? calories / weight * 100 : 0;

  /// 获取主要成分（前3个）
  List<String> get mainIngredients => ingredients.take(3).toList();

  /// 获取餐次显示名称
  String get mealTypeDisplayName {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      default:
        return '其他';
    }
  }

  /// 获取置信度等级
  String get confidenceLevel {
    if (confidence >= 0.9) return '很高';
    if (confidence >= 0.7) return '高';
    if (confidence >= 0.5) return '中等';
    return '低';
  }

  FoodAnalysis copyWith({
    String? foodName,
    String? foodNameEn,
    List<String>? ingredients,
    List<String>? ingredientsEn,
    int? calories,
    double? weight,
    String? mealType,
    String? nutritionInfo,
    String? nutritionInfoEn,
    double? confidence,
    List<String>? tags,
    List<String>? tagsEn,
    bool? isAdjusted,
    double? originalWeight,
  }) {
    return FoodAnalysis(
      foodName: foodName ?? this.foodName,
      foodNameEn: foodNameEn ?? this.foodNameEn,
      ingredients: ingredients ?? this.ingredients,
      ingredientsEn: ingredientsEn ?? this.ingredientsEn,
      calories: calories ?? this.calories,
      weight: weight ?? this.weight,
      mealType: mealType ?? this.mealType,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      nutritionInfoEn: nutritionInfoEn ?? this.nutritionInfoEn,
      confidence: confidence ?? this.confidence,
      tags: tags ?? this.tags,
      tagsEn: tagsEn ?? this.tagsEn,
      isAdjusted: isAdjusted ?? this.isAdjusted,
      originalWeight: originalWeight ?? this.originalWeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodAnalysis &&
          runtimeType == other.runtimeType &&
          foodName == other.foodName &&
          calories == other.calories;

  @override
  int get hashCode => foodName.hashCode ^ calories.hashCode;

  @override
  String toString() {
    return 'FoodAnalysis{foodName: $foodName, calories: $calories, confidence: $confidence}';
  }
}

/// API错误类型
enum ApiErrorType {
  networkError,
  apiError,
  parseError,
  rateLimitError,
  authError,
  serverError,
  unknown,
}

/// API错误信息
class ApiError {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiError.network(String message) {
    return ApiError(type: ApiErrorType.networkError, message: message);
  }

  factory ApiError.api(String message, {int? statusCode}) {
    return ApiError(
      type: ApiErrorType.apiError,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiError.parse(String message) {
    return ApiError(type: ApiErrorType.parseError, message: message);
  }

  factory ApiError.rateLimit(String message) {
    return ApiError(type: ApiErrorType.rateLimitError, message: message);
  }

  factory ApiError.auth(String message) {
    return ApiError(type: ApiErrorType.authError, message: message);
  }

  factory ApiError.server(String message, {int? statusCode}) {
    return ApiError(
      type: ApiErrorType.serverError,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiError.unknown(String message) {
    return ApiError(type: ApiErrorType.unknown, message: message);
  }

  /// 获取用户友好的错误消息
  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.networkError:
        return '网络连接失败，请检查网络设置';
      case ApiErrorType.apiError:
        return 'API调用失败，请稍后重试';
      case ApiErrorType.parseError:
        return '数据解析失败，请重新拍照';
      case ApiErrorType.rateLimitError:
        return '请求过于频繁，请稍后再试';
      case ApiErrorType.authError:
        return '认证失败，请联系技术支持';
      case ApiErrorType.serverError:
        return '服务器错误，请稍后重试';
      case ApiErrorType.unknown:
        return '未知错误，请重试';
    }
  }

  @override
  String toString() {
    return 'ApiError{type: $type, message: $message, statusCode: $statusCode}';
  }
}