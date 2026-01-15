#!/bin/bash
# 智能构建策略 - 避免重复构建
# 用法: ./smart_build.sh [build|install|run]

ACTION=${1:-"run"}

APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
BUILD_LOCK="/tmp/food_build.lock"

echo "🧠 Food App 智能构建策略"

check_apk_fresh() {
    if [ -f "$APK_PATH" ]; then
        # 获取APK的修改时间
        APK_TIME=$(stat -f %m "$APK_PATH" 2>/dev/null || stat -c %Y "$APK_PATH" 2>/dev/null)
        CURRENT_TIME=$(date +%s)

        # 如果APK是最近1小时内构建的，视为新鲜
        AGE=$((CURRENT_TIME - APK_TIME))
        if [ $AGE -lt 3600 ]; then
            return 0  # APK是新鲜的
        fi
    fi
    return 1  # APK不存在或过期
}

case $ACTION in
    "build"|"apk")
        echo "🔨 强制重新构建APK..."
        flutter build apk --debug --no-tree-shake-icons
        echo "✅ APK构建完成: $APK_PATH"
        ls -lh "$APK_PATH"
        ;;

    "install"|"deploy")
        if check_apk_fresh; then
            echo "✅ 使用现有APK ($(ls -lh "$APK_PATH" | awk '{print $5}'))"
        else
            echo "🔄 APK过期或不存在，开始构建..."
            flutter build apk --debug --no-tree-shake-icons
        fi

        echo "📱 检查真机设备..."
        REAL_DEVICES=$(adb devices -l | grep -v "List of devices" | grep -v "emulator" | wc -l | tr -d ' ')

        if [ "$REAL_DEVICES" -eq 0 ]; then
            echo "❌ 未检测到真机设备！"
            echo "📝 请确保："
            echo "   1. 已开启USB调试"
            echo "   2. 已信任此电脑"
            echo "   3. 使用USB线连接设备"
            adb devices -l
            exit 1
        fi

        echo "🚀 安装到真机设备..."
        flutter install --debug
        echo "✅ 安装完成！"
        ;;

    "run"|"start")
        echo "🚀 智能启动策略..."

        # 检查是否有真机连接
        REAL_DEVICES=$(adb devices -l | grep -v "List of devices" | grep -v "emulator" | wc -l | tr -d ' ')

        if [ "$REAL_DEVICES" -gt 0 ]; then
            echo "📱 检测到真机设备，使用智能安装..."

            if check_apk_fresh; then
                echo "⚡ 使用现有APK快速安装..."
                flutter install --debug
            else
                echo "🔄 构建并安装APK..."
                flutter build apk --debug --no-tree-shake-icons
                flutter install --debug
            fi
        else
            echo "💻 未检测到真机，使用Web调试..."
            flutter run -d chrome --web-renderer html
        fi
        ;;

    "clean"|"clear")
        echo "🧹 清理构建产物..."
        rm -rf build/
        rm -f "$BUILD_LOCK"
        echo "✅ 清理完成"
        ;;

    "status"|"check")
        echo "📊 检查当前状态..."

        echo ""
        echo "📱 设备状态:"
        adb devices -l

        if [ -f "$APK_PATH" ]; then
            echo ""
            echo "📦 APK状态: 存在 ($(ls -lh "$APK_PATH" | awk '{print $5}'))"
            APK_TIME=$(stat -f %Sm "$APK_PATH" 2>/dev/null || stat -c %y "$APK_PATH" 2>/dev/null)
            echo "🕒 构建时间: $APK_TIME"

            if check_apk_fresh; then
                echo "✅ APK状态: 新鲜 (1小时内)"
            else
                echo "⚠️ APK状态: 过期 (需要重新构建)"
            fi
        else
            echo ""
            echo "📦 APK状态: 不存在 (需要构建)"
        fi

        echo ""
        echo "💾 内存使用:"
        ps aux | grep qemu | grep -v grep | awk '{print "模拟器内存:", int($6/1024)"MB, PID:",$2}'
        ;;

    "help"|"-h"|"--help")
        echo "🧠 Food App 智能构建工具"
        echo ""
        echo "用法: $0 [action]"
        echo ""
        echo "操作:"
        echo "  build/apk     - 强制重新构建APK"
        echo "  install/deploy - 智能安装到真机 (推荐)"
        echo "  run/start      - 智能启动 (推荐日常使用)"
        echo "  clean/clear    - 清理构建产物"
        echo "  status/check   - 检查当前状态"
        echo ""
        echo "💡 推荐工作流:"
        echo "  1. 日常开发: ./quick_debug.sh web"
        echo "  2. 硬件测试: ./smart_build.sh install"
        echo "  3. 快速部署: ./smart_build.sh run"
        ;;

    *)
        echo "❌ 未知操作: $ACTION"
        echo "使用 '$0 help' 查看可用操作"
        exit 1
        ;;
esac