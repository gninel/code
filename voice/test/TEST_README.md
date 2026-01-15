# Voice Autobiography Flutter - 测试文档

## 概览

本项目的测试套件旨在达到 **90%+ 的代码覆盖率**,覆盖所有核心功能模块。

## 测试结构

```
test/
├── helpers/              # 测试辅助工具
│   └── test_helpers.dart
├── unit/                 # 单元测试
│   ├── entities/         # 实体测试
│   ├── models/           # 数据模型测试
│   ├── failures/         # 失败类型测试
│   ├── bloc/             # BLoC状态管理测试
│   └── usecases/         # 用例测试
└── integration/          # 集成测试
```

## 运行测试

### 运行所有测试

```bash
# 在项目根目录执行
flutter test

# 带覆盖率报告
flutter test --coverage

# 生成HTML覆盖率报告 (需要安装 lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 运行特定测试

```bash
# 只运行实体测试
flutter test test/unit/entities/

# 只运行BLoC测试
flutter test test/unit/bloc/

# 运行特定测试文件
flutter test test/unit/entities/voice_record_test.dart
```

### 运行测试并查看详细输出

```bash
flutter test --verbose

# 查看特定测试的输出
flutter test --plain-name "VoiceRecord"
```

## 测试覆盖率目标

| 模块 | 目标覆盖率 | 当前状态 |
|------|----------|---------|
| Entities (实体层) | 95%+ | ✅ 已完成 |
| Models (数据模型层) | 95%+ | ✅ 已完成 |
| Failures (错误处理) | 100% | ✅ 已完成 |
| BLoC (状态管理) | 90%+ | ✅ 进行中 |
| UseCases (用例) | 85%+ | 🔄 待完成 |
| Services (服务层) | 80%+ | 🔄 待完成 |
| Repositories (仓库) | 80%+ | 🔄 待完成 |
| **总计** | **90%+** | 🔄 进行中 |

## 测试编写规范

### 1. 测试文件命名

- 测试文件应与源文件同名,添加 `_test.dart` 后缀
- 例如: `voice_record.dart` → `voice_record_test.dart`

### 2. 测试结构

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassName', () {
    setUp(() {
      // 每个测试前的准备
    });

    tearDown(() {
      // 每个测试后的清理
    });

    group('methodName', () {
      test('应该做某某事', () {
        // Arrange
        // Act
        // Assert
      });

      test('应该处理边界情况', () {
        // 测试边界值、null、空列表等
      });
    });
  });
}
```

### 3. BLoC 测试规范

使用 `blocTest` 从 `bloc_test` 包:

```dart
blocTest<MyBloc, MyState>(
  '描述测试场景',
  build: () => bloc,
  act: (bloc) => bloc.add(SomeEvent()),
  expect: () => [expectedState1, expectedState2],
  verify: (_) {
    // 验证特定行为
  },
);
```

### 4. Mock 使用

使用 Mockito 创建 Mock 对象:

```dart
@GenerateMocks([MyService])
import 'my_test.mocks.dart';

// 在测试中使用
final mockService = MockMyService();
when(mockService.someMethod()).thenAnswer((_) async => Right(result));
```

## 测试覆盖率报告

### 查看覆盖率

运行以下命令生成覆盖率报告:

```bash
# 生成 lcov.info
flutter test --coverage

# 在终端查看覆盖率摘要
lcov --summary coverage/lcov.info

# 生成HTML报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 覆盖率阈值

项目配置了最小覆盖率要求:

- **语句覆盖率**: ≥ 90%
- **分支覆盖率**: ≥ 85%
- **函数覆盖率**: ≥ 90%
- **行覆盖率**: ≥ 90%

## 持续集成

CI/CD 流水线将自动运行所有测试并检查覆盖率:

```yaml
test:
  script:
    - flutter pub get
    - flutter test --coverage
    - lcov --summary coverage/lcov.info
  coverage: '/\d+\%\s*$/' # 提取覆盖率百分比
```

## 测试最佳实践

### DO ✅

- ✅ 每个单元测试只测试一个功能
- ✅ 使用描述性的测试名称
- ✅ 测试正常情况和边界情况
- ✅ 使用 Mock 隔离外部依赖
- ✅ 保持测试快速且独立
- ✅ 使用 `group` 组织相关测试

### DON'T ❌

- ❌ 不要在测试中使用随机数据
- ❌ 不要依赖测试执行顺序
- ❌ 不要在单元测试中访问真实文件系统或网络
- ❌ 不要忽略测试中的警告
- ❌ 不要写过于复杂的测试逻辑

## 常见问题

### Q: 如何测试异步代码?

A: 使用 `async`/`await` 或 `expectLater`:

```dart
test('异步操作测试', () async {
  final result = await asyncOperation();
  expect(result, isNotNull);
});
```

### Q: 如何Mock第三方库?

A: 使用 Mockito 的 `@GenerateMocks` 注解:

```dart
@GenerateMocks([SharedPreferences])
import 'my_test.mocks.dart';
```

### Q: 测试太慢怎么办?

A: 几种优化方法:
1. 使用假实现替代真实服务
2. 减少不必要的等待时间
3. 并行运行独立测试: `flutter test --concurrency`

### Q: 如何测试Widget?

A: 使用 `flutter_test` 的 Widget 测试功能:

```dart
testWidgets('MyWidget 显示正确', (tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

## 贡献指南

添加新功能时,请确保:

1. 为新功能编写测试
2. 保持测试覆盖率 ≥ 90%
3. 所有测试通过: `flutter test`
4. 更新相关文档

## 资源链接

- [Flutter Testing 文档](https://docs.flutter.dev/cookbook/testing)
- [bloc_test 包文档](https://bloclibrary.dev/#/testing)
- [Mockito 文档](https://pub.dev/packages/mockito)
- [测试覆盖率最佳实践](https://github.com/flutter/flutter/wiki/Test-Coverage)

---

**最后更新**: 2024年12月27日
**维护者**: Development Team
