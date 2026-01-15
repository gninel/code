#!/bin/bash

# Flutter Web调试脚本
# 使用方法: ./flutter_debug.sh [模式]

echo "🚀 Flutter Web调试启动器"
echo "========================"

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装，请先安装Flutter SDK"
    echo "下载地址: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# 检查项目
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在Flutter项目根目录运行此脚本"
    exit 1
fi

# 显示Flutter版本
echo "📋 Flutter版本:"
flutter --version

# 检查Web支持
echo ""
echo "🌐 检查Web支持:"
flutter devices | grep -i chrome || echo "⚠️  Chrome设备未找到，请检查浏览器"

# 获取模式参数
MODE=${1:-"debug"}

echo ""
echo "🔧 调试模式: $MODE"

# 根据模式执行不同的命令
case $MODE in
    "debug"|"dev")
        echo "🔍 启动调试模式..."
        flutter run -d chrome --web-port=8080 --debug --start-paused
        ;;

    "release"|"prod")
        echo "🚀 启动发布模式..."
        flutter run -d chrome --web-port=8080 --release
        ;;

    "profile"|"perf")
        echo "⚡ 启动性能分析模式..."
        flutter run -d chrome --web-port=8080 --profile
        ;;

    "build"|"web")
        echo "🔨 构建Web版本..."
        flutter build web --web-renderer canvaskit
        echo "✅ 构建完成！文件位置: build/web/"
        echo "🌐 运行服务器: cd build/web && python3 -m http.server 8080"
        ;;

    "clean")
        echo "🧹 清理项目..."
        flutter clean
        echo "✅ 清理完成！"
        ;;

    "test")
        echo "🧪 运行测试..."
        flutter test
        ;;

    "analyze")
        echo "📊 代码分析..."
        flutter analyze
        ;;

    *)
        echo "❌ 未知模式: $MODE"
        echo ""
        echo "📋 可用模式:"
        echo "  debug, dev     - 调试模式 (默认)"
        echo "  release, prod  - 发布模式"
        echo "  profile, perf  - 性能分析模式"
        echo "  build, web     - 构建Web版本"
        echo "  clean          - 清理项目"
        echo "  test           - 运行测试"
        echo "  analyze        - 代码分析"
        exit 1
        ;;
esac