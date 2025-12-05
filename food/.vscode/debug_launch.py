#!/usr/bin/env python3
"""
VSCode Flutter Web调试辅助脚本
"""

import os
import sys
import subprocess
import webbrowser
import time

def main():
    print("🚀 VSCode Flutter Web调试启动器")
    print("=" * 50)

    # 检查Flutter是否安装
    try:
        subprocess.run(['flutter', '--version'], check=True, capture_output=True)
        print("✅ Flutter已安装")
    except subprocess.CalledProcessError:
        print("❌ Flutter未安装，请先安装Flutter SDK")
        return False
    except FileNotFoundError:
        print("❌ Flutter命令未找到，请确保Flutter在PATH中")
        return False

    # 检查项目结构
    if not os.path.exists('pubspec.yaml'):
        print("❌ 请在Flutter项目根目录运行此脚本")
        return False

    print("✅ 项目结构正确")

    # 获取依赖
    print("\n📦 获取依赖...")
    try:
        result = subprocess.run(['flutter', 'pub', 'get'], check=True)
        print("✅ 依赖获取完成")
    except subprocess.CalledProcessError:
        print("❌ 依赖获取失败")
        return False

    # 检查Web支持
    print("\n🌐 检查Web平台支持...")
    result = subprocess.run(['flutter', 'devices'], capture_output=True, text=True)
    if 'chrome' in result.stdout.lower() or 'web' in result.stdout.lower():
        print("✅ Web平台支持已启用")
    else:
        print("⚠️  需要启用Web平台支持")
        print("运行: flutter config --enable-web")

    # 提供调试选项
    print("\n🔧 调试选项:")
    print("1. 🚀 直接启动 (Chrome Debug)")
    print("2. 🔍 调试模式 (Debug Mode)")
    print("3. ⚡ 性能分析 (Profile)")
    print("4. 🔧 DevTools模式")
    print("5. 📋 显示VSCode命令")

    try:
        choice = input("\n请选择 (1-5): ").strip()

        if choice == '1':
            return launch_debug_mode("chrome_debug")
        elif choice == '2':
            return launch_debug_mode("debug_mode")
        elif choice == '3':
            return launch_debug_mode("profile")
        elif choice == '4':
            return launch_debug_mode("devtools")
        elif choice == '5':
            show_vscode_commands()
            return True
        else:
            print("❌ 无效选择")
            return False
    except KeyboardInterrupt:
        print("\n👋 已取消")
        return True

def launch_debug_mode(mode):
    """启动指定的调试模式"""
    commands = {
        "chrome_debug": [
            "flutter",
            "run",
            "-d",
            "chrome",
            "--web-port=8080",
            "--web-hostname=localhost"
        ],
        "debug_mode": [
            "flutter",
            "run",
            "-d",
            "chrome",
            "--web-port=8080",
            "--debug",
            "--start-paused"
        ],
        "profile": [
            "flutter",
            "run",
            "-d",
            "chrome",
            "--profile",
            "--web-port=8080"
        ],
        "devtools": [
            "flutter",
            "run",
            "-d",
            "chrome",
            "--web-port=8080",
            "--devtools"
        ]
    }

    command = commands.get(mode, commands["chrome_debug"])

    print(f"\n🚀 启动Flutter Web应用...")
    print(f"📋 命令: {' '.join(command)}")
    print(f"🌐 访问地址: http://localhost:8080")
    print(f"💡 按 Ctrl+C 停止应用")

    try:
        # 启动Flutter应用
        process = subprocess.Popen(command)

        # 等待应用启动
        time.sleep(3)

        # 自动打开浏览器（可选）
        if mode == "chrome_debug":
            print("🌐 正在打开Chrome浏览器...")
            webbrowser.open('http://localhost:8080')

        # 等待进程结束
        process.wait()

    except KeyboardInterrupt:
        print("\n👋 已停止Flutter应用")
        return True
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        return False

    return True

def show_vscode_commands():
    """显示VSCode调试命令"""
    print("\n📋 VSCode调试命令:")
    print("=" * 50)

    commands = [
        ("🚀 快速启动", "F5"),
        ("🔍 选择调试配置", "Ctrl+Shift+D → 选择配置 → F5"),
        ("🔧 打开调试面板", "Ctrl+Shift+D"),
        ("⚡ 热重载", "r"),
        ("🔄 热重启", "R"),
        ("🐛 切换断点", "F9"),
        ("⏭️ 单步执行", "F10"),
        ("⤵️ 进入函数", "F11"),
        ("⤴️ 跳出函数", "Shift+F11"),
        ("🏃 运行到光标", "Ctrl+F10"),
        ("📊 显示性能", "Ctrl+Shift+P → Flutter: Open Flutter DevTools")
    ]

    for description, shortcut in commands:
        print(f"  {description:<20} {shortcut}")

    print("\n💡 调试提示:")
    print("  • 在代码行号左侧点击设置断点")
    print("  • 使用Debug Console查看日志输出")
    print("  • Chrome DevTools按F12打开")
    print("  • Flutter DevTools: http://localhost:8080/?flutter_devtools")

    print("\n🎯 推荐调试配置:")
    print("  1. 🚀 Flutter: Web (Chrome Debug) - 日常开发")
    print("  2. 🔍 Flutter: Web (Debug Mode) - 详细调试")
    print("  3. ⚡ Flutter: Web (Profile) - 性能分析")
    print("  4. 🔧 Flutter: Web DevTools) - 开发工具")

if __name__ == "__main__":
    main()