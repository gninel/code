import 'dart:io';
import 'package:food_calorie_app/services/api_service.dart';
import 'package:food_calorie_app/providers/food_provider.dart';

/// 测试图片识别功能
/// 使用命令运行: dart test_recognition.dart
void main() async {
  print('=== 开始测试食物识别功能 ===\n');
  
  // 测试图片路径
  final imagePath = 'test_images/breakfast_sample.jpg';
  
  // 检查图片是否存在
  final imageFile = File(imagePath);
  if (!await imageFile.exists()) {
    print('❌ 错误: 测试图片不存在: $imagePath');
    return;
  }
  
  final fileSizeKB = (await imageFile.length()) / 1024;
  print('📷 测试图片: $imagePath');
  print('📦 文件大小: ${fileSizeKB.toStringAsFixed(2)} KB\n');
  
  // 步骤1: 调用 API Service
  print('步骤1: 调用豆包 API 识别...');
  final apiService = ApiService();
  
  try {
    final response = await apiService.recognizeFood(imagePath);
    
    if (response.success && response.data != null) {
      final analysis = response.data!;
      
      print('\n✅ 识别成功！\n');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🍽️  食物名称: ${analysis.foodName}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 总热量: ${analysis.calories} 千卡');
      print('⚖️  重量: ${analysis.weight.toStringAsFixed(1)} 克');
      print('🍴 餐次: ${analysis.mealType}');
      print('📈 置信度: ${(analysis.confidence * 100).toStringAsFixed(1)}%');
      
      if (analysis.ingredients.isNotEmpty) {
        print('\n📋 主要成分:');
        for (var i = 0; i < analysis.ingredients.length; i++) {
          print('   ${i + 1}. ${analysis.ingredients[i]}');
        }
      }
      
      if (analysis.tags.isNotEmpty) {
        print('\n🏷️  标签: ${analysis.tags.join(", ")}');
      }
      
      if (analysis.nutritionInfo.isNotEmpty) {
        print('\n💡 营养信息:');
        print('   ${analysis.nutritionInfo}');
      }
      
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      // 步骤2: 使用 FoodProvider 调整结果
      print('步骤2: 验证和调整识别结果...');
      final foodProvider = FoodProvider();
      final adjustedResponse = await foodProvider.recognizeFoodFromImage(imagePath);
      
      if (adjustedResponse.success && adjustedResponse.data != null) {
        final adjusted = adjustedResponse.data!;
        
        if (adjusted.calories != analysis.calories) {
          print('⚠️  热量已调整: ${analysis.calories} → ${adjusted.calories} 千卡');
          print('   原因: 热量合理性验证');
        } else {
          print('✓ 热量验证通过，无需调整');
        }
        
        if (adjusted.confidence != analysis.confidence) {
          print('⚠️  置信度已调整: ${(analysis.confidence * 100).toStringAsFixed(1)}% → ${(adjusted.confidence * 100).toStringAsFixed(1)}%');
        }
        
        print('\n最终结果:');
        print('  食物: ${adjusted.foodName}');
        print('  热量: ${adjusted.calories} 千卡');
        print('  置信度: ${(adjusted.confidence * 100).toStringAsFixed(1)}%');
      }
      
      print('\n✅ 测试完成！');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
    } else {
      print('\n❌ 识别失败: ${response.message}');
      if (response.statusCode != null) {
        print('   HTTP 状态码: ${response.statusCode}');
      }
    }
    
  } catch (e) {
    print('\n❌ 发生错误: $e');
  }
}
