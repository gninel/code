#!/bin/bash

# Flutter Web构建脚本

echo "🚀 开始构建Flutter Web应用..."

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装，请先安装Flutter SDK"
    exit 1
fi

# 检查当前目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在Flutter项目根目录运行此脚本"
    exit 1
fi

# 获取Flutter版本
echo "📋 Flutter版本信息："
flutter --version

# 清理项目
echo "🧹 清理项目..."
flutter clean

# 获取依赖
echo "📦 获取依赖..."
flutter pub get

# 构建Web版本
echo "🔨 构建Web版本..."
flutter build web --web-renderer canvaskit --no-sound-null-safety

# 检查构建结果
if [ -d "build/web" ]; then
    echo "✅ Web构建成功！"
    echo "📁 构建文件位置: build/web/"

    # 显示构建信息
    echo ""
    echo "📊 构建信息："
    echo "- 构建模式: Release"
    echo "- Web渲染器: CanvasKit"
    echo "- 输出目录: build/web/"
    echo "- 主文件: build/web/index.html"

    # 启动本地服务器
    echo ""
    echo "🌐 启动本地开发服务器..."
    echo "访问地址: http://localhost:8080"

    # 使用Python启动简单HTTP服务器
    if command -v python3 &> /dev/null; then
        cd build/web
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        cd build/web
        python -m SimpleHTTPServer 8080
    else
        echo "❌ 未找到Python，无法启动HTTP服务器"
        echo "请手动使用其他HTTP服务器工具或运行:"
        echo "cd build/web && python -m http.server 8080"
    fi
else
    echo "❌ Web构建失败！"
    exit 1
fi