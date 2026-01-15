import 'package:dio/dio.dart';

/// 测试豆包AI API连接
void main() async {
  print('=== 测试豆包AI API连接 ===\n');

  final dio = Dio(BaseOptions(
    baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 405fe7f2-f603-4c4c-b04b-bdea5d441319',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  try {
    print('📤 发送测试请求到豆包AI...\n');

    final response = await dio.post(
      '/chat/completions',
      data: {
        'model': 'doubao-seed-1-6-251015',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个测试助手',
          },
          {
            'role': 'user',
            'content': '说"测试成功"',
          }
        ],
        'max_completion_tokens': 100,
      },
    );

    print('\n✅ 连接成功！');
    print('状态码: ${response.statusCode}');
    print('响应: ${response.data}');
  } on DioException catch (e) {
    print('\n❌ 连接失败！');
    print('错误类型: ${e.type}');
    print('错误信息: ${e.message}');
    if (e.response != null) {
      print('状态码: ${e.response?.statusCode}');
      print('响应数据: ${e.response?.data}');
    }
  } catch (e) {
    print('\n❌ 未知错误: $e');
  }
}
