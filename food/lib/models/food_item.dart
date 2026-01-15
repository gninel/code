/// 食物数据模型
class FoodItem {
  final int? id;
  final String foodName;
  final String foodNameEn; // 英文食物名称
  final List<String> ingredients;
  final List<String> ingredientsEn; // 英文成分
  final int calories;
  final String imagePath;
  final DateTime createdAt;
  final String mealType; // breakfast, lunch, dinner
  final double weight; // 食物重量（克）
  final List<String> tags;
  final List<String> tagsEn;

  FoodItem({
    this.id,
    required this.foodName,
    this.foodNameEn = '',
    required this.ingredients,
    this.ingredientsEn = const [],
    required this.calories,
    required this.imagePath,
    required this.createdAt,
    required this.mealType,
    this.weight = 100.0,
    this.tags = const [],
    this.tagsEn = const [],
  });

  /// 从数据库记录创建FoodItem对象
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      foodName: map['food_name'] as String,
      foodNameEn: map['food_name_en'] as String? ?? '',
      ingredients: (map['ingredients'] as String?)?.split(',') ?? [],
      ingredientsEn: (map['ingredients_en'] as String?)?.split(',') ?? [],
      calories: map['calories'] as int,
      imagePath: map['image_path'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      mealType: map['meal_type'] as String? ?? 'other',
      weight: (map['weight'] as num?)?.toDouble() ?? 100.0,
      tags: (map['tags'] as String?)?.split(',') ?? [],
      tagsEn: (map['tags_en'] as String?)?.split(',') ?? [],
    );
  }

  /// 转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'food_name_en': foodNameEn,
      'ingredients': ingredients.join(','),
      'ingredients_en': ingredientsEn.join(','),
      'calories': calories,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'meal_type': mealType,
      'weight': weight,
      'tags': tags.join(','),
      'tags_en': tagsEn.join(','),
    };
  }

  /// 复制对象并更新部分字段
  FoodItem copyWith({
    int? id,
    String? foodName,
    String? foodNameEn,
    List<String>? ingredients,
    List<String>? ingredientsEn,
    int? calories,
    String? imagePath,
    DateTime? createdAt,
    String? mealType,
    double? weight,
    List<String>? tags,
    List<String>? tagsEn,
  }) {
    return FoodItem(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      foodNameEn: foodNameEn ?? this.foodNameEn,
      ingredients: ingredients ?? this.ingredients,
      ingredientsEn: ingredientsEn ?? this.ingredientsEn,
      calories: calories ?? this.calories,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      mealType: mealType ?? this.mealType,
      weight: weight ?? this.weight,
      tags: tags ?? this.tags,
      tagsEn: tagsEn ?? this.tagsEn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          foodName == other.foodName &&
          calories == other.calories;

  @override
  int get hashCode => id.hashCode ^ foodName.hashCode ^ calories.hashCode;

  @override
  String toString() {
    return 'FoodItem{id: $id, foodName: $foodName, calories: $calories, mealType: $mealType}';
  }
}