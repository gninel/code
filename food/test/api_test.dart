import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';

/// 简化的 API 测试脚本
/// 直接调用豆包 API 测试识别功能
void main() async {
  print('\n====================================');
  print('   豆包 API 食物识别测试');
  print('====================================\n');
  
  final imagePath = 'test_images/breakfast_sample.jpg';
  
  // 检查图片
  final file = File(imagePath);
  if (!await file.exists()) {
    print('❌ 图片不存在: $imagePath');
    exit(1);
  }
  
  final fileSize = await file.length();
  print('📷 测试图片: $imagePath');
  print('📦 文件大小: ${(fileSize / 1024).toStringAsFixed(2)} KB\n');
  
  // 转换为 Base64
  print('🔄 正在转换图片为 Base64...');
  final bytes = await file.readAsBytes();
  final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  print('✓ Base64 编码完成\n');
  
  // 构建请求
  final dio = Dio(BaseOptions(
    baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 405fe7f2-f603-4c4c-b04b-bdea5d441319',
    },
  ));
  
  final requestData = {
    'model': 'doubao-seed-1-6-vision-250815',
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {
              'url': base64Image,
            },
          },
          {
            'type': 'text',
            'text': '''请仔细分析这张图片中的食物，并返回JSON格式的分析结果。

要求：
1. 识别图片中的主要食物名称
2. 列出食物的主要成分
3. 估算总热量（千卡）
4. 估算食物重量（克）
5. 根据食物类型判断餐次（breakfast/lunch/dinner/other）
6. 提供营养信息简述
7. 给出识别置信度（0-1之间的小数）

返回格式：
{
  "food_name": "具体的食物名称",
  "ingredients": ["主要成分1", "主要成分2", "主要成分3"],
  "calories": 估算的热量数值（整数）,
  "weight": 估算的重量（数值）,
  "meal_type": "餐次类型",
  "nutrition_info": "营养信息简述",
  "confidence": 识别置信度（0.0-1.0）,
  "tags": ["标签1", "标签2", "标签3"]
}

注意：
- 热量要基于常见的营养标准估算
- 重量要考虑食物的实际分量
- 只返回JSON格式的数据，不要包含其他文字''',
          },
        ],
      },
    ],
    'max_tokens': 1000,
    'temperature': 0.1,
  };
  
  try {
    print('📡 正在调用豆包 API...');
    print('   端点: https://ark.cn-beijing.volces.com/api/v3/chat/completions');
    print('   模型: doubao-seed-1-6-vision-250815\n');
    
    final response = await dio.post('/chat/completions', data: requestData);
    
    print('✅ API 响应成功!\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 解析响应
    final choices = response.data['choices'] as List;
    final message = choices[0]['message'];
    final content = message['content'] as String;
    
    print('📝 原始响应:\n');
    print(content);
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // 提取 JSON
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    
    if (jsonStart != -1 && jsonEnd != -1) {
      final jsonStr = content.substring(jsonStart, jsonEnd + 1);
      final jsonData = json.decode(jsonStr);
      
      print('🍽️  解析结果:\n');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('食物名称: ${jsonData['food_name']}');
      print('总热量: ${jsonData['calories']} 千卡');
      print('重量: ${jsonData['weight']} 克');
      print('餐次: ${jsonData['meal_type']}');
      print('置信度: ${(jsonData['confidence'] * 100).toStringAsFixed(1)}%');
      
      if (jsonData['ingredients'] != null) {
        print('\n主要成分:');
        for (var ingredient in jsonData['ingredients']) {
          print('  • $ingredient');
        }
      }
      
      if (jsonData['tags'] != null) {
        print('\n标签: ${(jsonData['tags'] as List).join(", ")}');
      }
      
      if (jsonData['nutrition_info'] != null) {
        print('\n营养信息:\n  ${jsonData['nutrition_info']}');
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      print('✅ 测试完成！\n');
    } else {
      print('⚠️  无法提取 JSON 格式的数据\n');
    }
    
  } catch (e) {
    print('❌ API 调用失败: $e\n');
    if (e is DioException) {
      print('错误类型: ${e.type}');
      print('错误消息: ${e.message}');
      if (e.response != null) {
        print('响应状态码: ${e.response?.statusCode}');
        print('响应数据: ${e.response?.data}');
      }
    }
  }
}
