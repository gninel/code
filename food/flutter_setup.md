# 🔧 Flutter环境设置指南

## 问题诊断

### 1. 检查Flutter是否安装
```bash
# 检查Flutter版本
flutter --version

# 检查Flutter是否在PATH中
which flutter

# 查看环境变量
echo $PATH
```

### 2. 如果Flutter未安装

#### macOS 安装
```bash
# 方法1: 使用Homebrew
brew install --cask flutter

# 方法2: 下载Flutter SDK
# 1. 访问 https://flutter.dev/docs/get-started/install/macos
# 2. 下载Flutter SDK压缩包
# 3. 解压到 ~/development/flutter
# 4. 添加到PATH

# 添加到PATH (临时)
export PATH="$PATH:$HOME/development/flutter/bin"

# 添加到PATH (永久)
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

#### Windows 安装
```powershell
# 方法1: 使用Chocolatey
choco install flutter

# 方法2: 下载Flutter SDK
# 1. 访问 https://flutter.dev/docs/get-started/install/windows
# 2. 下载Flutter SDK zip文件
# 3. 解压到 C:\flutter
# 4. 添加到系统环境变量PATH

# 添加到环境变量 (PowerShell)
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\flutter\bin", "User")
```

#### Linux 安装
```bash
# 下载Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz

# 解压
tar xf flutter_linux_3.19.6-stable.tar.xz

# 移动到安装目录
sudo mv flutter /usr/local/bin

# 添加到PATH
echo 'export PATH="$PATH:/usr/local/bin/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 3. 验证安装
```bash
# 检查Flutter版本
flutter --version

# 运行Flutter Doctor
flutter doctor

# 检查Web支持
flutter devices
```

### 4. 解决常见问题

#### 问题1: 权限问题
```bash
# macOS/Linux
chmod +x flutter

# Windows (以管理员身份运行PowerShell)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 问题2: 路径问题
```bash
# 查看当前Shell
echo $SHELL

# 根据Shell类型配置
# bash → ~/.bashrc
# zsh → ~/.zshrc
# fish → ~/.config/fish/config.fish
```

#### 问题3: 依赖问题
```bash
# 检查系统要求
flutter doctor -v

# 安装依赖
flutter doctor
```

### 5. 替代方案（如果不想安装Flutter）

#### 使用Flutter Web
```html
<!-- 直接在浏览器中打开build/web/index.html -->
<!-- 需要先构建Web版本 -->
```

#### 使用在线Flutter IDE
- [FlutterFlow](https://flutterflow.io/)
- [Flutter Playground](https://flutter.github.io/samples/web/)
- [Zapp](https://zapp.run/)

#### 使用Docker Flutter
```bash
# 拉取Flutter Docker镜像
docker pull cirrusci/flutter

# 运行Flutter命令
docker run -it --rm cirrusci/flutter flutter --version
```

## 🎯 推荐解决方案

### 最快解决方案 (macOS)
```bash
# 一键安装Flutter
brew install --cask flutter

# 验证安装
flutter doctor
```

### 最快解决方案 (Windows)
```powershell
# 使用Chocolatey安装
choco install flutter

# 验证安装
flutter doctor
```

### 手动安装步骤
1. 访问 [Flutter官网](https://flutter.dev/docs/get-started/install)
2. 下载对应平台的Flutter SDK
3. 解压到合适目录
4. 添加flutter/bin到PATH环境变量
5. 运行 `flutter doctor` 验证

### 验证命令
```bash
flutter --version
flutter doctor
flutter devices
```

---

## 💡 如果仍然有问题

1. **提供操作系统信息**：`uname -a` (Linux/macOS) 或 `ver` (Windows)
2. **提供错误信息**：完整的错误输出
3. **检查网络连接**：确保可以访问Flutter服务器
4. **尝试重新安装**：完全删除Flutter SDK重新安装

现在请告诉我您的操作系统，我可以提供具体的安装指导！