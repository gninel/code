# Web开发调试指南

## 🌐 浏览器运行和调试

### 方式1: VSCode调试 (推荐)

1. **安装必要插件**
   - Flutter 插件
   - Dart 插件

2. **配置launch.json**
   ```json
   {
     "name": "Flutter: Web Debug",
     "type": "dart",
     "request": "launch",
     "program": "lib/main.dart",
     "args": [
       "-d",
       "chrome",
       "--web-port=8080"
     ]
   }
   ```

3. **启动调试**
   - 按 F5 或点击运行按钮
   - 选择 "Flutter: Web Debug" 配置
   - 自动打开Chrome浏览器

### 方式2: 命令行运行

```bash
# 进入项目目录
cd food_calorie_app

# 启动Web开发服务器
flutter run -d chrome --web-port=8080
```

### 方式3: 构建后运行

```bash
# 构建Web版本
./build_web.sh

# 或手动构建
flutter build web --web-renderer canvaskit

# 启动HTTP服务器
cd build/web
python3 -m http.server 8080
```

## 🔧 Chrome调试技巧

### 1. 开发者工具
- 按 F12 或右键 → 检查
- 切换到 "Console" 标签查看日志
- 使用 "Network" 标签监控网络请求
- "Application" 标签查看本地存储

### 2. Flutter调试工具
- 在Chrome中按 `Ctrl+Shift+P` (Windows) 或 `Cmd+Shift+P` (Mac)
- 输入 "Flutter DevTools"
- 或访问 http://localhost:8080/?flutter_devtools

### 3. 断点调试
- 在VSCode中设置断点
- 使用F5启动调试
- 断点处会自动暂停

## 📱 Web平台特殊适配

### 相机功能
由于Web浏览器限制，相机功能替换为文件上传：

```dart
// 使用平台适配
final cameraService = PlatformService.getCameraService();

// Web平台将使用文件选择器
final imagePath = await cameraService.selectImage();
```

### 本地存储
- 使用SQLite通过WebSQL兼容层
- 支持IndexedDB作为后备
- 浏览器存储限制请注意

### 网络请求
- CORS配置要求
- HTTPS部署要求相机API

## 🐛 常见问题和解决

### 1. 构建失败
```bash
# 清理项目
flutter clean

# 重新获取依赖
flutter pub get

# 重新构建
flutter build web
```

### 2. 图片上传问题
- 检查文件格式支持 (jpg, png, webp)
- 验证文件大小限制
- 查看浏览器控制台错误信息

### 3. 性能优化
- 使用CanvasKit渲染器
- 启用代码分割
- 优化图片大小

### 4. 浏览器兼容性
- Chrome: 完全支持
- Safari: 部分功能受限
- Firefox: 基本功能支持
- Edge: 基本功能支持

## 🚀 部署准备

### 生产构建
```bash
# 生产模式构建
flutter build web --release --web-renderer canvaskit

# 构建产物在 build/web/ 目录
```

### 部署选项
1. **GitHub Pages**
2. **Netlify**
3. **Firebase Hosting**
4. **Vercel**
5. **自建HTTP服务器`

### 环境配置
```bash
# 设置生产环境变量
export FLUTTER_WEB_RENDERER=canvaskit
export FLUTTER_WEB_CANVASKIT_URL=canvaskit.js
```

## 📊 性能监控

### 1. 开发工具性能面板
- Performance标签页
- Memory标签页
- Network标签页

### 2. Flutter性能工具
```dart
// 在main.dart中启用性能监控
import 'package:flutter/foundation.dart' show debugProfileBuilds;

void main() {
  debugProfileBuildsEnabled = true;
  runApp(FoodCalorieApp());
}
```

## 🔍 调试技巧

### 1. 日志输出
```dart
// 使用debugPrint进行调试输出
debugPrint('调试信息: ${variable}');

// 使用developer.log获取更多控制
import 'dart:developer' as developer;
developer.log('详细信息', name: 'FoodApp');
```

### 2. 条件断点
```dart
// 仅在调试模式下执行
if (kDebugMode) {
  // 调试代码
  print('调试信息');
}
```

### 3. 热重载
- 修改代码后按 `r` 键进行热重载
- 按 `R` 键进行热重启
- 大幅提高开发效率

## 🎯 测试策略

### 1. 单元测试
```bash
flutter test test/unit/
```

### 2. Widget测试
```bash
flutter test test/widget/
```

### 3. 集成测试
```bash
flutter test test/integration/
```

### 4. Web特定测试
```bash
flutter test --platform chrome
```

---

## 📞 获取帮助

- [Flutter Web文档](https://flutter.dev/web)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/)
- [Flutter调试指南](https://flutter.dev/docs/development/tools/debugging)

现在您可以开始Web开发和调试了！🚀