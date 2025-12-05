# 命令行调试指南

## 🚀 快速开始

### 基本调试命令
```bash
# 进入项目目录
cd food_calorie_app

# 启动调试模式 (默认)
flutter run -d chrome

# 指定端口
flutter run -d chrome --web-port=8080

# 详细调试信息
flutter run -d chrome --debug --start-paused
```

### 📋 所有调试模式

#### 1. 🔍 开发模式 (推荐日常使用)
```bash
flutter run -d chrome --web-port=8080
```
- 启用热重载
- 快速编译
- 详细错误信息
- 支持断点调试

#### 2. ⚡ 性能分析模式
```bash
flutter run -d chrome --web-port=8080 --profile
```
- 启用性能监控
- 显示重绘区域
- 内存使用分析
- CPU使用统计

#### 3. 🚀 发布模式测试
```bash
flutter run -d chrome --web-port=8080 --release
```
- 优化性能
- 压缩代码
- 生产环境测试

#### 4. 🔧 高级调试模式
```bash
flutter run -d chrome --web-port=8080 --debug --start-paused
```
- 启动时暂停
- 详细调试信息
- 支持断点
- 变量监视

### 🛠️ 项目管理命令

#### 依赖管理
```bash
# 获取依赖
flutter pub get

# 升级依赖
flutter pub upgrade

# 分析依赖
flutter pub deps
```

#### 项目清理
```bash
# 清理构建文件
flutter clean

# 重新构建
flutter clean && flutter pub get && flutter run -d chrome
```

#### 代码质量检查
```bash
# 代码分析
flutter analyze

# 代码格式化
dart format .

# 代码格式检查
dart format --set-exit-if-changed .
```

### 🧪 测试命令

#### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/calculator_calculator_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 🔨 构建命令

#### Web构建
```bash
# 构建Web版本 (CanvasKit渲染器)
flutter build web --web-renderer canvaskit

# 构建Web版本 (HTML渲染器)
flutter build web --web-renderer html

# 构建生产版本
flutter build web --release --web-renderer canvaskit
```

### 🌐 Web服务器启动

#### Python HTTP服务器
```bash
# 构建后启动服务器
cd build/web

# Python 3
python3 -m http.server 8080

# Python 2
python -m SimpleHTTPServer 8080
```

#### Node.js服务器 (如果安装)
```bash
# 使用http-server包
npm install -g http-server
cd build/web
http-server -p 8080

# 使用serve包
npm install -g serve
cd build/web
serve -p 8080
```

### 🔧 高级调试选项

#### 环境变量设置
```bash
# 设置Web渲染器
export FLUTTER_WEB_RENDERER=canvaskit

# 设置CanvasKit URL
export FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/canvaskit.js

# 启动应用
flutter run -d chrome
```

#### 调试参数
```bash
# 启用所有调试选项
flutter run -d chrome \
    --web-port=8080 \
    --debug \
    --start-paused \
    --no-sound-null-safety \
    --verbose

# 禁用热重载
flutter run -d chrome --no-hot-reload

# 指定主机名
flutter run -d chrome --web-hostname=127.0.0.1
```

### 📊 性能监控

#### 启用性能分析
```bash
# 性能模式启动
flutter run -d chrome --profile

# 生成性能跟踪
flutter run -d chrome --profile --trace-startup
```

#### 内存监控
```bash
# 内存分析模式
flutter run -d chrome --profile --dump-memory-on-exit
```

### 🔍 故障排除

#### 常见问题解决
```bash
# 检查Flutter版本
flutter doctor -v

# 检查可用设备
flutter devices

# 检查Web支持
flutter config

# 启用Web支持
flutter config --enable-web

# 更新Flutter
flutter upgrade
```

#### 权限问题
```bash
# Linux权限问题
chmod +x flutter_debug.sh

# macOS权限问题
sudo chown -R $(whoami) flutter
```

### 💡 实用技巧

#### 快速重启循环
```bash
# 开发循环脚本
while true; do
    echo "🔄 重新启动..."
    flutter run -d chrome --web-port=8080
    echo "⏹️  应用已停止，5秒后重启..."
    sleep 5
done
```

#### 批量操作
```bash
# 一键清理、获取依赖、运行
flutter clean && flutter pub get && flutter run -d chrome --web-port=8080

# 分析、格式化、测试
flutter analyze && dart format . && flutter test
```

### 📱 快速启动别名 (可选)

#### 添加到 .bashrc 或 .zshrc
```bash
# Flutter快速命令
alias fd="cd food_calorie_app && flutter run -d chrome --web-port=8080"
alias fc="cd food_calorie_app && flutter clean && flutter pub get"
alias ft="cd food_calorie_app && flutter test"
alias fa="cd food_calorie_app && flutter analyze"

# Web调试别名
alias web-debug="cd food_calorie_app && flutter run -d chrome --debug --start-paused"
alias web-profile="cd food_calorie_app && flutter run -d chrome --profile"
alias web-build="cd food_calorie_app && flutter build web --web-renderer canvaskit"
```

#### 使用别名
```bash
# 启动调试
fd

# 清理和更新
fc

# 运行测试
ft

# 代码分析
fa
```

---

## 🎯 推荐工作流程

### 日常开发
```bash
cd food_calorie_app
flutter run -d chrome --web-port=8080
# 使用 'r' 热重载，'R' 热重启
```

### 性能优化
```bash
flutter run -d chrome --profile --web-port=8080
# 使用Chrome DevTools分析性能
```

### 问题排查
```bash
flutter run -d chrome --debug --start-paused
# 设置断点后继续执行
```

### 发布测试
```bash
flutter build web --release --web-renderer canvaskit
cd build/web && python3 -m http.server 8080
```

现在您可以直接使用命令行进行Flutter Web调试了！🚀