# 🚀 Flutter命令行快速调试指南

## ⚡ 最简单的启动方式

### 基础启动
```bash
cd food_calorie_app
flutter run -d chrome
```

这将：
- 自动打开Chrome浏览器
- 在 http://localhost:8080 运行应用
- 启用热重载功能
- 显示调试信息

## 🔧 常用调试命令

### 1. 开发调试模式（推荐日常使用）
```bash
flutter run -d chrome
# 或者指定端口
flutter run -d chrome --web-port=8080
```

**特点：**
- ✅ 快速编译
- ✅ 热重载支持
- ✅ 详细错误信息
- ✅ 自动打开浏览器

### 2. 性能分析模式
```bash
flutter run -d chrome --profile
```

**特点：**
- ✅ 性能监控
- ✅ 内存分析
- ✅ CPU使用统计
- ✅ 重绘区域显示

### 3. 发布模式测试
```bash
flutter run -d chrome --release
```

**特点：**
- ✅ 生产性能
- ✅ 代码压缩
- ✅ 优化渲染

### 4. 高级调试模式
```bash
flutter run -d chrome --debug --start-paused
```

**特点：**
- ✅ 启动时暂停（便于设置断点）
- ✅ 详细调试信息
- ✅ 变量监视

## 🎯 调试快捷键（在Flutter终端中）

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| **r** | 热重载 | 保存代码后按r，保持当前状态 |
| **R** | 热重启 | 重启应用，重新初始化状态 |
| **p** | 绘制网格 | 显示Widget重绘边界 |
| **o** | 平台切换 | 在不同平台间切换 |
| **w** | 窗口大小 | 调整应用窗口大小 |
| **q** | 退出调试 | 停止应用 |
| **d** | 断开 | 断开调试连接 |
| **c** | 清除控制台 | 清除终端输出 |
| **h** | 帮助 | 显示所有快捷键 |

## 🔍 常用开发命令

### 项目管理
```bash
# 获取依赖
flutter pub get

# 更新依赖
flutter pub upgrade

# 清理项目
flutter clean

# 代码分析
flutter analyze

# 代码格式化
dart format .
```

### 构建命令
```bash
# 构建Web版本
flutter build web

# 构建并指定渲染器
flutter build web --web-renderer canvaskit

# 构建发布版本
flutter build web --release
```

### 测试命令
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/

# 生成测试覆盖率
flutter test --coverage
```

## 🌐 浏览器调试

### Chrome DevTools（按F12打开）
- **Console**: 查看日志和错误
- **Network**: 监控网络请求
- **Performance**: 性能分析
- **Memory**: 内存使用分析
- **Elements**: 检查HTML结构

### Flutter DevTools
```bash
# 在另一个终端运行
flutter pub global run devtools

# 或在调试时自动打开
# 访问: http://localhost:8080/?flutter_devtools
```

## 📊 环境变量配置

```bash
# 设置Web渲染器
export FLUTTER_WEB_RENDERER=canvaskit

# 启动应用
flutter run -d chrome
```

## 🔧 高级选项

### 禁用热重载
```bash
flutter run -d chrome --no-hot-reload
```

### 详细输出
```bash
flutter run -d chrome --verbose
```

### 指定主机名
```bash
flutter run -d chrome --web-hostname=127.0.0.1
```

### 禁用声音安全检查
```bash
flutter run -d chrome --no-sound-null-safety
```

## 🚨 故障排除

### 常见问题

#### 1. Chrome设备未找到
```bash
# 检查可用设备
flutter devices

# 启用Web支持
flutter config --enable-web
```

#### 2. 端口被占用
```bash
# 使用不同端口
flutter run -d chrome --web-port=8081
```

#### 3. 编译错误
```bash
# 清理并重新获取依赖
flutter clean
flutter pub get
flutter run -d chrome
```

#### 4. 热重载失败
```bash
# 尝试热重启
# 按 R 键而不是 r 键
```

## 💡 实用技巧

### 1. 快速开发循环
```bash
# 在终端1中启动
flutter run -d chrome --web-port=8080

# 修改代码后，在终端按 r 热重载
```

### 2. 查看特定日志
```bash
flutter run -d chrome 2>&1 | grep "flutter:"
```

### 3. 后台运行
```bash
nohup flutter run -d chrome --web-port=8080 > app.log 2>&1 &
```

### 4. 监控文件变化
```bash
# 监控lib目录变化
watch -n 1 "flutter run -d chrome --no-hot-reload"
```

## 🎯 推荐工作流程

### 日常开发
```bash
cd food_calorie_app
flutter pub get
flutter run -d chrome --web-port=8080

# 在调试过程中：
# 1. 修改代码
# 2. 按 r 热重载
# 3. 在Chrome中测试
# 4. 按 F12 查看控制台
```

### 性能优化
```bash
cd food_calorie_app
flutter run -d chrome --profile --web-port=8080

# 在Chrome中：
# 1. 按 F12 打开DevTools
# 2. 进入 Performance 标签
# 3. 开始录制
# 4. 执行操作
# 5. 停止录制并分析
```

### 问题排查
```bash
cd food_calorie_app
flutter run -d chrome --debug --start-paused --web-port=8080

# 启动后：
# 1. 在Chrome DevTools中设置断点
# 2. 点击继续执行
# 3. 观察变量和执行流程
```

---

## 🚀 立即开始

```bash
# 只需要这三步！
cd food_calorie_app
flutter run -d chrome
# 享受调试吧！ 🎉
```