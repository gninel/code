import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../utils/image_utils.dart';

/// 豆包多模态API服务
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  // API配置
  static const String _baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';
  static const String _apiKey = '405fe7f2-f603-4c4c-b04b-bdea5d441319';
  static const String _model = 'doubao-seed-1-6-vision-250815';
  static const Duration _timeout = Duration(seconds: 60);

  // 请求限制
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxRetries = 3;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'Connection': 'close', // 禁用持久连接
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) {
        debugPrint('API: $obj');
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  /// 识别食物图片
  /// [languageCode] - 语言代码 ('en' 或 'zh')
  Future<ApiResponse> recognizeFood(String imagePath, {String languageCode = 'zh'}) async {
    try {
      debugPrint('开始识别食物: $imagePath');

      // 检查文件
      final file = File(imagePath);
      if (!await file.exists()) {
        return ApiResponse.error('图片文件不存在');
      }

      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        return ApiResponse.error('图片文件过大，请选择小于10MB的图片');
      }

      // 转换图片为Base64
      final base64Image = await _imageToBase64(imagePath);
      if (base64Image == null) {
        return ApiResponse.error('图片格式不支持');
      }

      // 构建请求（根据语言选择prompt）
      final requestData = _buildRequestData(base64Image, languageCode: languageCode);

      // 发送请求
      final response = await _sendRequest(requestData);

      // 解析响应
      if (response.data == null) {
        return ApiResponse.error('API响应为空');
      }
      final analysis = _parseResponse(response.data!);

      return ApiResponse.success(analysis, rawResponse: response.data);

    } on DioException catch (e) {
      debugPrint('Dio Error: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('Unknown Error: $e');
      return ApiResponse.error('识别失败: ${e.toString()}');
    }
  }

  /// 将图片转换为Base64
  Future<String?> _imageToBase64(String imagePath) async {
    try {
      // 压缩图片，降低质量以减小体积
      final stopwatch = Stopwatch()..start();
      debugPrint('开始压缩图片...');
      final resizedPath = await ImageUtils.resizeImage(imagePath, 512, 512); // 降低分辨率以加速识别
      debugPrint('图片压缩耗时: ${stopwatch.elapsedMilliseconds}ms');
      
      final file = File(resizedPath ?? imagePath);
      final fileSize = await file.length();
      debugPrint('压缩后图片大小: ${(fileSize / 1024).toStringAsFixed(2)}KB');

      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      stopwatch.stop();
      
      // 如果是临时压缩文件，使用后删除
      if (resizedPath != null && resizedPath != imagePath) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('删除临时压缩文件失败: $e');
        }
      }
      
      return 'data:image/jpeg;base64,$base64';
    } catch (e) {
      debugPrint('图片转换失败: $e');
      return null;
    }
  }

  /// 构建请求数据（始终返回中英双语结果）
  Map<String, dynamic> _buildRequestData(String base64Image, {String languageCode = 'zh'}) {
    final prompt = '''
请作为一位经验丰富的专业营养师，仔细分析这张图片中的食物，并返回JSON格式的分析结果。

**核心任务：精准估算重量和热量**

1. **重量估算策略**：
   - **寻找参照物**：利用餐具（碗、盘、勺）、包装袋或背景物体的大小来推断食物的实际体积。
   - **区分密度**：注意区分蓬松食物（如叶菜、爆米花）和致密食物（如肉类、米饭、根茎类）。
   - **常见分量参考**：
     - 一碗米饭约 150-200g
     - 一个汉堡约 200-300g
     - 一份牛排约 150-250g
     - 一份炒菜约 200-300g

2. **热量密度检查（关键）**：
   - 在给出热量前，请务必在内部计算 `热量 / 重量`（即热量密度），并检查其合理性。
   - **参考范围**：
     - 蔬菜/水果：20-60 kcal/100g
     - 米饭/面食：110-150 kcal/100g
     - 瘦肉/鱼类：100-200 kcal/100g
     - 油炸/烘焙/高脂肉类：250-500 kcal/100g
     - 坚果/纯油脂：500-900 kcal/100g
   - **警告**：如果普通饭菜的热量密度超过 300 kcal/100g，或者蔬菜超过 100 kcal/100g，请重新检查你的重量或热量估算，通常是重量估少了。

**输出要求**：
1. 识别图片中的主要食物名称（同时提供中英文版本）
2. 列出食物的主要成分（同时提供中英文版本）
3. 估算总热量（千卡）
4. 估算食物重量（克）
5. 根据食物类型判断餐次（breakfast/lunch/dinner/other）
6. 提供营养信息简述（同时提供中英文版本）
7. 给出识别置信度（0-1之间的小数）
8. 提供标签（同时提供中英文版本）

**返回格式（JSON only）- 必须同时提供中英文**：
{
  "food_name": "中文食物名称",
  "food_name_en": "English food name",
  "ingredients": ["中文成分1", "中文成分2", "中文成分3"],
  "ingredients_en": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
  "calories": 估算的热量数值（整数）,
  "weight": 估算的重量（数值）,
  "meal_type": "餐次类型",
  "nutrition_info": "中文营养信息简述",
  "nutrition_info_en": "Nutrition info in English",
  "confidence": 识别置信度（0.0-1.0）,
  "tags": ["中文标签1", "中文标签2"],
  "tags_en": ["Tag1", "Tag2"]
}

注意：只返回JSON格式的数据，不要包含其他文字。必须同时提供中英文版本。
''';

    return {
      'model': _model,
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
              'text': prompt,
            },
          ],
        },
      ],
      'max_tokens': 1500,
      'temperature': 0.1,
    };
  }

  /// 发送API请求
  Future<Response<Map<String, dynamic>>> _sendRequest(Map<String, dynamic> data) async {
    int retryCount = 0;
    DioException? lastError;

    while (retryCount < _maxRetries) {
      try {
        debugPrint('发送API请求 (尝试 ${retryCount + 1}/$_maxRetries)');

        final response = await _dio.post<Map<String, dynamic>>(
          '/chat/completions',
          data: data,
        );

        debugPrint('API响应成功: ${response.statusCode}');
        return response;

      } on DioException catch (e) {
        lastError = e;
        retryCount++;

        // 如果是网络错误且还有重试机会，则等待后重试
        if (_shouldRetry(e) && retryCount < _maxRetries) {
          debugPrint('API请求失败，等待后重试...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }

        // 其他错误直接抛出
        rethrow;
      }
    }

    throw lastError!;
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode != null && (statusCode >= 500 || statusCode == 429);
      default:
        return false;
    }
  }

  /// 解析API响应
  FoodAnalysis _parseResponse(Map<String, dynamic> responseData) {
    try {
      // 获取回复内容
      final choices = responseData['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('API响应格式错误：缺少choices字段');
      }

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw Exception('API响应格式错误：缺少message字段');
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('API响应内容为空');
      }

      debugPrint('API回复内容: $content');

      // 尝试解析JSON
      Map<String, dynamic> jsonData;
      try {
        // 提取JSON部分（处理可能的前后缀文本）
        final jsonStr = _extractJsonFromContent(content);
        jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON解析失败，尝试手动解析: $e');
        jsonData = _parseManualContent(content);
      }

      return FoodAnalysis.fromMap(jsonData);

    } catch (e) {
      debugPrint('解析响应失败: $e');

      // 返回默认分析结果
      return FoodAnalysis(
        foodName: '未识别食物',
        ingredients: [],
        calories: 0,
        confidence: 0.0,
        nutritionInfo: '无法识别食物，请重新拍照',
      );
    }
  }

  /// 从内容中提取JSON字符串
  String _extractJsonFromContent(String content) {
    // 查找JSON开始和结束位置
    final startIdx = content.indexOf('{');
    final endIdx = content.lastIndexOf('}');

    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      return content.substring(startIdx, endIdx + 1);
    }

    throw Exception('未找到有效的JSON格式');
  }

  /// 手动解析内容（当JSON解析失败时的备用方案）
  Map<String, dynamic> _parseManualContent(String content) {
    // 简单的文本解析逻辑
    final lines = content.split('\n');
    Map<String, dynamic> result = {
      'food_name': '未识别食物',
      'ingredients': [],
      'calories': 0,
      'weight': 100.0,
      'meal_type': 'other',
      'nutrition_info': content,
      'confidence': 0.3,
      'tags': [],
    };

    for (final line in lines) {
      if (line.toLowerCase().contains('食物') || line.toLowerCase().contains('food')) {
        result['food_name'] = line.split(':').last.trim();
      } else if (line.toLowerCase().contains('热量') || line.toLowerCase().contains('calories')) {
        final caloriesStr = RegExp(r'\d+').stringMatch(line);
        if (caloriesStr != null) {
          result['calories'] = int.tryParse(caloriesStr) ?? 0;
        }
      }
    }

    return result;
  }

  /// 处理Dio错误
  ApiResponse _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error('请求超时，请检查网络连接', statusCode: statusCode);

      case DioExceptionType.badResponse:
        return _handleHttpError(statusCode, error.response?.data);

      case DioExceptionType.cancel:
        return ApiResponse.error('请求已取消', statusCode: statusCode);

      case DioExceptionType.connectionError:
        return ApiResponse.error('网络连接失败，请检查网络设置', statusCode: statusCode);

      case DioExceptionType.unknown:
        return ApiResponse.error('网络错误: ${error.message}', statusCode: statusCode);

      default:
        return ApiResponse.error('未知网络错误', statusCode: statusCode);
    }
  }

  /// 处理HTTP错误
  ApiResponse _handleHttpError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return ApiResponse.error('请求参数错误', statusCode: statusCode);
      case 401:
        return ApiResponse.error('API密钥无效', statusCode: statusCode);
      case 403:
        return ApiResponse.error('访问被拒绝', statusCode: statusCode);
      case 429:
        return ApiResponse.error('请求过于频繁，请稍后重试', statusCode: statusCode);
      case 500:
        return ApiResponse.error('服务器内部错误', statusCode: statusCode);
      case 502:
      case 503:
      case 504:
        return ApiResponse.error('服务暂时不可用，请稍后重试', statusCode: statusCode);
      default:
        String message = 'HTTP错误: $statusCode';
        if (responseData is Map && responseData.containsKey('error')) {
          final errorInfo = responseData['error'];
          if (errorInfo is Map && errorInfo.containsKey('message')) {
            message = errorInfo['message'].toString();
          }
        }
        return ApiResponse.error(message, statusCode: statusCode);
    }
  }

  /// 测试API连接
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API连接测试失败: $e');
      return false;
    }
  }

  /// 取消所有请求
  void cancelRequests() {
    _dio.close(force: true);
  }

  /// 获取API状态
  Future<Map<String, dynamic>> getApiStatus() async {
    try {
      final response = await _dio.get('/models');
      return {
        'status': 'connected',
        'statusCode': response.statusCode,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'disconnected',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}