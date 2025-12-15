# Flutter 编译调试指南

## 📋 环境要求

### 系统要求
- **macOS**: 10.14+ (Catalina 或更高)
- **Xcode**: 13.0+ (iOS开发)
- **Android Studio**: 最新版本 (Android开发)
- **Flutter SDK**: 3.19.0 或更高版本

### 检查当前环境
```bash
# 检查系统信息
system_profiler SPSoftwareDataType
# 或
sw_vers

# 检查是否安装了Homebrew
brew --version

# 检查Git
git --version
```

## 🔧 Flutter SDK 安装

### 方法1: 官方安装（推荐）
```bash
# 下载Flutter SDK压缩包
cd ~/Development
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/flutter_macos_3.19.0-stable.zip

# 解压
unzip flutter_macos_3.19.0-stable.zip

# 添加到PATH（将下面的行添加到 ~/.zshrc 或 ~/.bash_profile）
export PATH="$PATH:~/Development/flutter/bin"

# 重新加载配置
source ~/.zshrc
# 或
source ~/.bash_profile
```

### 方法2: 使用Homebrew安装
```bash
# 安装Flutter
brew install --cask flutter

# 或者安装最新版本
brew install --cask flutter --HEAD
```

### 方法3: 使用FVM（Flutter版本管理器）
```bash
# 安装FVM
dart pub global activate fvm

# 安装Flutter
fvm install 3.19.0

# 使用指定版本
fvm use 3.19.0

# 添加到PATH
echo 'export PATH="$PATH:$HOME/.fvm/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

## 🛠️ 开发工具配置

### Xcode（iOS开发）
```bash
# 从App Store安装Xcode
# 或从Apple Developer网站下载

# 安装Command Line Tools
xcode-select --install

# 检查安装
xcode-select --print-path
```

### Android Studio（Android开发）
```bash
# 下载并安装Android Studio
# https://developer.android.com/studio

# 启用开发者选项（在Android设备上）
# 设置 -> 关于手机 -> 连续点击版本号7次

# 启用USB调试
# 开发者选项 -> USB调试
```

## 📱 项目配置检查

### 1. 进入项目目录
```bash
cd /Users/zhb/code/abg/voice_autobiography_flutter
```

### 2. 检查Flutter环境
```bash
# 检查Flutter安装
flutter doctor -v

# 检查Flutter版本
flutter --version

# 检查Dart版本
dart --version
```

### 3. 修复依赖问题
首先，我需要修复项目中的一些依赖问题：

#### 修复pubspec.yaml中的问题：
```yaml
# 移除retrofit依赖（没有正确使用）
# 移除web_socket_channel依赖（Flutter内置）
# 移除convert依赖（已弃用）

dependencies:
  flutter:
    sdk: flutter
    flutter_localizations:
    sdk: flutter

  # UI框架
  cupertino_icons: ^1.0.2
  material_color_utilities: ^0.8.0

  # 状态管理
  flutter_bloc: ^8.1.3
  provider: ^6.0.5
  equatable: ^2.0.5

  # 网络请求
  dio: ^5.3.2
  json_annotation: ^4.8.1

  # 数据库
  sqflite: ^2.3.0
  path_provider: ^2.1.1

  # 音频处理
  record: ^5.0.4
  just_audio: ^0.9.36
  audio_session: ^0.1.16
  permission_handler: ^11.0.1

  # 文件处理
  path: ^1.8.3
  file_picker: ^6.1.1

  # 国际化
  intl: ^0.18.1

  # 工具库
  logger: ^2.0.2+1
  uuid: ^4.2.1
  get_it: ^7.6.4
  injectable: ^2.3.2
  dartz: ^0.10.1

  # WebSocket支持
  # web_socket_channel: ^2.4.0  # Flutter内置，不需要

  # 加密
  crypto: ^3.0.3
  convert: ^3.1.1

  # Shared Preferences
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # 代码生成
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
  injectable_generator: ^2.4.1
  retrofit_generator: ^8.0.4

  # 测试工具
  bloc_test: ^9.1.0
  mockito: ^5.4.2
```

## 🔧 编译前修复

### 1. 修复导入问题
创建缺失的文件和修复导入：

```bash
# 创建缺失的文件
mkdir -p lib/data/repositories
mkdir -p lib/presentation/bloc/voice_record
mkdir -p lib/presentation/bloc/autobiography

# 创建空的基础文件
touch lib/presentation/bloc/voice_record/voice_record_bloc.dart
touch lib/presentation/bloc/voice_record/voice_record_event.dart
touch lib/presentation/bloc/voice_record/voice_record_state.dart
touch lib/presentation/bloc/autobiography/autobiography_bloc.dart
touch lib/presentation/bloc/autobiography/autobiography_event.dart
touch lib/presentation/bloc/autobiography/autobiography_state.dart
```

### 2. 生成代码
```bash
# 运行代码生成
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 🚀 编译和运行

### 1. 依赖获取
```bash
# 获取依赖
flutter pub get

# 检查依赖
flutter pub deps
```

### 2. 代码分析
```bash
# 静态分析
flutter analyze

# 格式化代码
dart format .

# 代码检查
dart analyze
```

### 3. 编译应用

#### 编译APK（Android）
```bash
# 构建调试版本APK
flutter build apk --debug

# 构建发布版本APK
flutter build apk --release

# 构建App Bundle（推荐）
flutter build appbundle --release
```

#### 编译iOS应用
```bash
# 编译iOS应用
flutter build ios --debug

# 编译发布版本
flutter build ios --release
```

### 4. 运行调试

#### 在模拟器中运行
```bash
# 启动Android模拟器
emulator -list-avds
emulator -avd <模拟器名称>

# 在Android模拟器中运行
flutter run

# 在iOS模拟器中运行
flutter run -d "iPhone 14"
```

#### 在物理设备中运行
```bash
# 列出连接的设备
flutter devices

# 在指定设备中运行
flutter run -d <设备ID>

# 在所有连接的设备中运行
flutter run
```

## 🐛 调试技巧

### 1. 热重载/快速刷新
```bash
# 在运行时使用热重载（在命令行按 'r'）
flutter run --hot

# 或使用以下命令
flutter run --debug --hot
```

### 2. 断点调试
```bash
# 启动调试模式
flutter run --debug

# 或在IDE中设置断点后运行
```

### 3. 日志调试
```bash
# 查看详细日志
flutter run --verbose

# 启动日志
flutter logs
```

### 4. 性能分析
```bash
# 性能分析
flutter run --profile

# 性能查看
flutter run --trace-startup --profile
```

## 🐛 常见问题解决

### 1. Flutter Doctor问题
```bash
# 检查所有问题
flutter doctor -v

# Android工具链问题
flutter doctor --android-licenses
flutter doctor --verbose

# iOS工具链问题
sudo xcode-select --install
```

### 2. 依赖冲突
```bash
# 清理缓存
flutter clean
flutter pub cache clean

# 重新获取依赖
flutter pub get
```

### 3. 编译错误
```bash
# 清理并重新编译
flutter clean
flutter pub get
flutter build apk
```

### 4. 权限问题
```bash
# 检查权限设置
flutter devices --verbose

# 手动授予权（在设备上）
```

### 5. 网络问题
```bash
# 检查网络连接
ping google.com

# 代理设置（如果需要）
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

## 🔧 IDE配置

### VS Code配置
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "~/Development/flutter",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "always"
  },
  "[dart]": {
    "editor.defaultFormatter": "dart-code",
    "editor.rulers": [80]
  }
}
```

### Android Studio配置
1. 打开Android Studio
2. 选择 "Open an existing project"
3. 选择 `/Users/zhb/code/abg/voice_autobiography_flutter`
4. 等待项目同步完成
5. 配置Flutter插件（如果提示）

### VS Code插件推荐
- **Flutter**
- **Dart**
- **Flutter Hot Reload**
- **Flutter Snippets**
- **Flutter Widget Snippets**

## 📱 测试

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/services/xunfei_asr_service_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 性能测试
```bash
# 集成测试
flutter test integration_test/

# Widget测试
flutter test test/widget/
```

## 📱 部署

### Web部署
```bash
# 构建Web版本
flutter build web

# 本地运行Web版本
flutter run -d chrome
```

### Windows桌面部署
```bash
# 构建Windows版本
flutter build windows

# 运行Windows版本
flutter run -d windows
```

### macOS桌面部署
```bash
# 构建macOS版本
flutter build macos

# 运行macOS版本
flutter run -d macos
```

## 📚 参考资源

- [Flutter官方文档](https://flutter.dev/docs)
- [Flutter开发指南](https://flutter.dev/docs/cookbook)
- [Android Studio配置](https://developer.android.com/studio/intro/index.html)
- [Xcode配置](https://developer.apple.com/xcode/)

---

*最后更新: 2025-11-23*