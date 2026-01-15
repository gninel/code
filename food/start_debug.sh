#!/bin/bash

# 🚀 Flutter Web一键调试启动脚本
# 使用方法: ./start_debug.sh

echo "🚀 Flutter Web应用启动器"
echo "======================"

# 检查并进入项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 显示菜单
show_menu() {
    echo ""
    echo "📋 选择调试模式:"
    echo "1) 🔍 开发调试模式 (推荐)"
    echo "2) ⚡ 性能分析模式"
    echo "3) 🚀 发布模式测试"
    echo "4) 🔧 高级调试模式"
    echo "5) 🔨 构建Web版本"
    echo "6) 🧪 运行测试"
    echo "7) 📊 代码分析"
    echo "8) 🧹 清理项目"
    echo "9) 📋 显示设备信息"
    echo "0) 🚪 退出"
    echo ""
}

# 执行命令
execute_command() {
    local choice=$1

    case $choice in
        1)
            echo "🔍 启动开发调试模式..."
            echo "📝 访问地址: http://localhost:8080"
            echo "💡 调试快捷键: r=热重载, R=热重启, q=退出"
            flutter run -d chrome --web-port=8080
            ;;
        2)
            echo "⚡ 启动性能分析模式..."
            flutter run -d chrome --web-port=8080 --profile
            ;;
        3)
            echo "🚀 启动发布模式..."
            flutter run -d chrome --web-port=8080 --release
            ;;
        4)
            echo "🔧 启动高级调试模式..."
            flutter run -d chrome --web-port=8080 --debug --start-paused
            ;;
        5)
            echo "🔨 构建Web版本..."
            flutter build web --web-renderer canvaskit

            if [ -d "build/web" ]; then
                echo "✅ 构建成功!"
                echo "📁 文件位置: $(pwd)/build/web/"

                # 询问是否启动服务器
                echo ""
                read -p "🌐 是否启动HTTP服务器? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "🌐 启动HTTP服务器..."
                    cd build/web

                    if command -v python3 &> /dev/null; then
                        python3 -m http.server 8080
                    elif command -v python &> /dev/null; then
                        python -m SimpleHTTPServer 8080
                    else
                        echo "❌ 未找到Python，请手动启动HTTP服务器"
                        echo "💡 命令: cd build/web && python3 -m http.server 8080"
                    fi
                fi
            else
                echo "❌ 构建失败!"
            fi
            ;;
        6)
            echo "🧪 运行测试..."
            flutter test
            ;;
        7)
            echo "📊 代码分析..."
            flutter analyze
            ;;
        8)
            echo "🧹 清理项目..."
            flutter clean
            echo "✅ 清理完成!"
            ;;
        9)
            echo "📋 Flutter信息:"
            echo "=================="
            flutter --version
            echo ""
            echo "📱 可用设备:"
            flutter devices
            ;;
        0)
            echo "👋 再见!"
            exit 0
            ;;
        *)
            echo "❌ 无效选择: $choice"
            ;;
    esac
}

# 检查Flutter环境
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter未安装或不在PATH中"
        echo "💡 请访问 https://flutter.dev/docs/get-started/install 安装Flutter"
        exit 1
    fi

    if [ ! -f "pubspec.yaml" ]; then
        echo "❌ 请在Flutter项目根目录运行此脚本"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    echo "📦 检查依赖..."
    flutter pub get
}

# 主程序
main() {
    check_flutter

    # 检查命令行参数
    if [ $# -eq 1 ]; then
        execute_command $1
        return
    fi

    # 检查依赖
    check_dependencies

    # 显示菜单
    while true; do
        show_menu
        read -p "请选择 (0-9): " -n 1 -r
        echo

        execute_command $REPLY

        echo ""
        read -p "按回车键继续..." -r
    done
}

# 运行主程序
main "$@"