# 豆包多模态大模型 Prompt 设计文档

## 概述
本文档定义了调用豆包（Doubao）多模态大模型进行食物识别和热量估算时使用的 Prompt 模板。

---

## 核心 Prompt

### 版本 1.0（推荐使用）

```
你是一位专业的营养师和食物识别专家。请仔细分析这张食物照片，并提供以下信息：

1. **食物名称**：识别照片中的食物，给出准确的名称（如：宫保鸡丁盖饭、番茄炒蛋等）

2. **主要构成**：列出食物的主要组成部分，每个部分包括：
   - 食材名称（如：米饭、鸡肉、青椒等）
   - 估算份量（如：约200克、约150克等）
   - 单项热量（千卡）

3. **总热量**：估算这份食物的总热量值（千卡）

4. **置信度**：你对这次识别结果的置信度（0-1之间的数值）

请以 JSON 格式返回结果，格式如下：
{
  "food_name": "食物名称",
  "components": [
    {
      "name": "食材名称",
      "portion": "份量",
      "calories": 热量数值
    }
  ],
  "total_calories": 总热量数值,
  "confidence": 置信度数值,
  "notes": "补充说明（可选）"
}

注意事项：
- 热量估算要基于常见的食物份量和营养数据
- 如果照片模糊或无法准确识别，请在 notes 中说明
- 如果照片中没有食物，请在 notes 中说明并将 confidence 设为 0
- 考虑烹饪方式对热量的影响（如油炸会增加热量）
```

---

## Prompt 变体

### 版本 2.0（详细版 - 包含营养成分）

```
你是一位专业的营养师和食物识别专家。请仔细分析这张食物照片，并提供详细的营养信息。

任务要求：
1. 识别食物名称和主要构成
2. 估算每个组成部分的份量和热量
3. 分析三大营养素（蛋白质、脂肪、碳水化合物）的含量
4. 给出总热量和营养评估

请以 JSON 格式返回：
{
  "food_name": "食物名称",
  "components": [
    {
      "name": "食材名称",
      "portion": "份量（克）",
      "calories": 热量（千卡）,
      "protein": 蛋白质（克）,
      "fat": 脂肪（克）,
      "carbs": 碳水化合物（克）
    }
  ],
  "total_calories": 总热量,
  "total_protein": 总蛋白质,
  "total_fat": 总脂肪,
  "total_carbs": 总碳水化合物,
  "health_score": 健康评分（1-10）,
  "confidence": 置信度（0-1）,
  "suggestions": "饮食建议"
}

估算依据：
- 使用中国食物成分表作为参考
- 考虑烹饪方式（蒸、煮、炒、炸等）
- 参考标准餐具份量（碗、盘、勺等）
```

### 版本 3.0（简化版 - 快速识别）

```
请识别这张照片中的食物，并估算热量。

返回 JSON 格式：
{
  "food_name": "食物名称",
  "total_calories": 总热量（千卡）,
  "confidence": 置信度（0-1）
}

要求：
- 快速识别，给出合理的热量估算
- 如果无法识别，confidence 设为 0
```

---

## 使用场景说明

### 场景 1：标准拍照识别
**推荐版本**：版本 1.0  
**适用情况**：用户拍摄单份食物（如一碗面、一份盖饭等）  
**预期响应时间**：3-5 秒

### 场景 2：复杂食物分析
**推荐版本**：版本 2.0  
**适用情况**：需要详细营养成分分析，或多种食物组合  
**预期响应时间**：5-8 秒

### 场景 3：快速记录
**推荐版本**：版本 3.0  
**适用情况**：用户只需要快速记录热量，不关心详细成分  
**预期响应时间**：2-3 秒

---

## Prompt 优化建议

### 提高准确率的技巧
1. **提供参考物**：建议用户在拍照时包含常见参考物（如筷子、勺子等）
2. **强调烹饪方式**：在 Prompt 中明确要求考虑烹饪方式对热量的影响
3. **地域化调整**：根据目标用户群体，可以指定使用特定地区的食物成分表

### 错误处理
在 Prompt 中明确要求 AI 在以下情况下的处理方式：
- 照片模糊不清 → confidence < 0.3
- 无法识别为食物 → confidence = 0，notes 说明原因
- 存在多份食物 → 分别列出或提示用户重新拍摄

---

## 示例对话

### 示例 1：成功识别

**输入**：照片（一碗西红柿鸡蛋面）  
**Prompt**：使用版本 1.0

**输出**：
```json
{
  "food_name": "西红柿鸡蛋面",
  "components": [
    {
      "name": "面条",
      "portion": "约150克",
      "calories": 210
    },
    {
      "name": "鸡蛋",
      "portion": "约1个（50克）",
      "calories": 75
    },
    {
      "name": "西红柿",
      "portion": "约100克",
      "calories": 18
    },
    {
      "name": "食用油",
      "portion": "约10克",
      "calories": 90
    }
  ],
  "total_calories": 393,
  "confidence": 0.92,
  "notes": "热量估算基于标准份量，实际可能因面条粗细和油量而有所不同"
}
```

### 示例 2：模糊照片

**输入**：照片（模糊）  
**Prompt**：使用版本 1.0

**输出**：
```json
{
  "food_name": "无法准确识别",
  "components": [],
  "total_calories": 0,
  "confidence": 0.15,
  "notes": "照片较为模糊，建议重新拍摄清晰的照片以获得准确的热量估算"
}
```

### 示例 3：非食物照片

**输入**：照片（一只猫）  
**Prompt**：使用版本 1.0

**输出**：
```json
{
  "food_name": "非食物",
  "components": [],
  "total_calories": 0,
  "confidence": 0,
  "notes": "照片中未检测到食物，请拍摄食物照片"
}
```

---

## API 调用示例

### Dart 代码示例

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DoubaoFoodAnalyzer {
  final String apiKey;
  final String apiUrl = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  
  DoubaoFoodAnalyzer(this.apiKey);
  
  Future<Map<String, dynamic>> analyzeFoodImage(String base64Image) async {
    final prompt = '''
你是一位专业的营养师和食物识别专家。请仔细分析这张食物照片，并提供以下信息：

1. **食物名称**：识别照片中的食物，给出准确的名称（如：宫保鸡丁盖饭、番茄炒蛋等）

2. **主要构成**：列出食物的主要组成部分，每个部分包括：
   - 食材名称（如：米饭、鸡肉、青椒等）
   - 估算份量（如：约200克、约150克等）
   - 单项热量（千卡）

3. **总热量**：估算这份食物的总热量值（千卡）

4. **置信度**：你对这次识别结果的置信度（0-1之间的数值）

请以 JSON 格式返回结果，格式如下：
{
  "food_name": "食物名称",
  "components": [
    {
      "name": "食材名称",
      "portion": "份量",
      "calories": 热量数值
    }
  ],
  "total_calories": 总热量数值,
  "confidence": 置信度数值,
  "notes": "补充说明（可选）"
}

注意事项：
- 热量估算要基于常见的食物份量和营养数据
- 如果照片模糊或无法准确识别，请在 notes 中说明
- 如果照片中没有食物，请在 notes 中说明并将 confidence 设为 0
- 考虑烹饪方式对热量的影响（如油炸会增加热量）
''';
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'doubao-vision-pro',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              },
              {
                'type': 'text',
                'text': prompt
              }
            ]
          }
        ],
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      // 解析 JSON 结果
      final result = jsonDecode(content);
      return result;
    } else {
      throw Exception('API 调用失败: ${response.statusCode}');
    }
  }
}
```

### 使用示例

```dart
void main() async {
  final analyzer = DoubaoFoodAnalyzer('your_api_key_here');
  
  // 读取图片并转换为 base64
  final imageBytes = await File('food_image.jpg').readAsBytes();
  final base64Image = base64Encode(imageBytes);
  
  // 调用分析
  try {
    final result = await analyzer.analyzeFoodImage(base64Image);
    
    print('食物名称: ${result['food_name']}');
    print('总热量: ${result['total_calories']} 千卡');
    print('置信度: ${result['confidence']}');
    
    print('\n主要构成:');
    for (var component in result['components']) {
      print('- ${component['name']}: ${component['portion']}, ${component['calories']}千卡');
    }
  } catch (e) {
    print('识别失败: $e');
  }
}
```

---

## Prompt 迭代记录

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| 1.0 | 2025-11-24 | 初始版本，包含基础食物识别和热量估算 |
| 2.0 | 待定 | 添加详细营养成分分析 |
| 3.0 | 待定 | 简化版快速识别 |

---

## 性能优化建议

1. **批量处理**：如果用户连续拍摄多张照片，考虑批量调用以减少请求次数
2. **缓存机制**：相似食物的识别结果可以缓存，减少 API 调用
3. **本地预处理**：在调用 API 前进行图片压缩和质量检测
4. **超时处理**：设置合理的超时时间（建议 10 秒）

---

## 成本控制

- **API 调用频率限制**：建议每用户每天不超过 100 次调用
- **图片大小限制**：压缩图片至 1MB 以下，既能保证识别准确率又能降低成本
- **错误重试机制**：失败后最多重试 2 次，避免无效消耗

---

## 相关链接

- [豆包 AI 官方文档](https://www.volcengine.com/docs/82379)
- [中国食物成分表](http://www.chinanutri.cn/)
- [营养热量计算标准](https://www.who.int/nutrition)
