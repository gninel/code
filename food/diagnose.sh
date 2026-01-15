#!/bin/bash

echo "🔧 Flutter问题诊断工具"
echo "===================="

# 检查Flutter安装
if command -v flutter &> /dev/null; then
    echo "✅ Flutter已安装"
    flutter --version
else
    echo "❌ Flutter未安装"
    echo "💡 解决方案："
    echo "1. 下载Flutter SDK: https://flutter.dev/docs/get-started/install"
    echo "2. 添加到PATH环境变量"
    exit 1
fi

# 检查项目
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 不是Flutter项目目录"
    echo "💡 解决方案："
    echo "1. cd food_calorie_app"
    echo "2. 或者检查项目路径"
    exit 1
fi

# 检查Web支持
echo ""
echo "📱 检查设备支持："
flutter devices

# 检查依赖
echo ""
echo "📦 检查依赖："
flutter pub get

# 检查代码
echo ""
echo "🔍 代码分析："
flutter analyze

# 尝试构建
echo ""
echo "🔨 尝试构建："
flutter build web --no-pub

echo ""
echo "✅ 诊断完成！"
echo "💡 如果仍有问题，请提供具体的错误信息"