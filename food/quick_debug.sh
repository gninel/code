#!/bin/bash
# Android App 快速调试脚本
# 用法: ./quick_debug.sh [web|macos|android|apk]

PLATFORM=${1:-"web"}

echo "🚀 启动Food App快速调试 - 平台: $PLATFORM"

case $PLATFORM in
    "web"|"chrome"|"browser")
        echo "📱 启动Web调试..."
        flutter run -d chrome --web-renderer html
        ;;
    "macos"|"desktop")
        echo "🖥️ 启动macOS调试..."
        flutter run -d macos
        ;;
    "apk"|"device"|"real")
        echo "📱 启动真机APK调试..."
        echo "🔨 构建Debug APK (约142秒)..."
        start_time=$(date +%s)
        flutter build apk --debug --no-tree-shake-icons

        echo "🔍 检查连接的Android设备..."
        DEVICES=$(adb devices -l | grep -v "List of devices" | grep -v "emulator" | wc -l | tr -d ' ')

        if [ "$DEVICES" -eq 0 ]; then
            echo "❌ 未检测到真机设备！"
            echo "📝 请确保："
            echo "   1. 已开启USB调试"
            echo "   2. 已信任此电脑"
            echo "   3. 已安装相应驱动"
            echo "   4. 使用USB线连接设备"
            echo ""
            echo "🔍 可用设备："
            adb devices -l
            exit 1
        else
            echo "✅ 检测到 $DEVICES 台真机设备"
            adb devices -l | grep -v "List of devices" | grep -v "emulator"

            echo "📦 安装APK到设备..."
            end_time=$(date +%s)
            build_time=$((end_time - start_time))
            echo "⏱️ APK构建耗时: ${build_time}秒"

            install_start=$(date +%s)
            flutter install --debug
            install_end=$(date +%s)
            install_time=$((install_end - install_start))
            echo "⏱️ APK安装耗时: ${install_time}秒"
            total_time=$((build_time + install_time))
            echo "🎯 总耗时: ${total_time}秒"

            echo "🚀 启动应用..."
            echo "💡 提示：如需调试，请使用：flutter attach"
        fi
        ;;
    "android"|"emulator")
        echo "🤖 检查Android模拟器状态..."
        if adb devices | grep -q "emulator-5554"; then
            echo "✅ 模拟器已运行，直接启动..."
            flutter run -d emulator-5554
        else
            echo "🔧 启动模拟器..."
            flutter emulators --launch Medium_Phone_API_36.1 &
            sleep 10
            flutter run -d emulator-5554
        fi
        ;;
    "help"|"-h"|"--help")
        echo "用法: $0 [platform]"
        echo "可选平台:"
        echo "  web/chrome/browser - Web调试 (最快，<5秒)"
        echo "  macos/desktop      - macOS桌面调试 (约10秒)"
        echo "  apk/device/real    - 真机APK调试 (构建142s+安装)"
        echo "  android/emulator   - Android模拟器调试"
        echo ""
        echo "💡 真机调试优势："
        echo "  ✅ 构建一次，多次安装"
        echo "  ✅ 无需等待模拟器启动"
        echo "  ✅ 真实设备性能和体验"
        echo "  ✅ 可测试硬件相关功能(相机、GPS等)"
        ;;
    *)
        echo "❌ 未知平台: $PLATFORM"
        echo "使用 '$0 help' 查看可用选项"
        exit 1
        ;;
esac