#!/bin/bash

# 语音自传后端一键部署脚本
# 使用方法: ./deploy.sh

set -e

echo "=========================================="
echo "  语音自传后端部署脚本"
echo "=========================================="

# 检查Python版本
echo "检查Python版本..."
python3 --version

# 创建虚拟环境
echo "创建虚拟环境..."
python3 -m venv venv

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "安装依赖..."
pip install -r requirements.txt

# 检查.env文件
if [ ! -f ".env" ]; then
    echo "警告: .env 文件不存在，请从 .env.example 复制并配置"
    cp .env.example .env
    echo "已创建 .env 文件，请编辑配置后重新运行"
    exit 1
fi

# 启动服务
echo "启动服务..."
echo "服务将在 http://0.0.0.0:8000 运行"
echo "API文档: http://0.0.0.0:8000/docs"
echo ""
echo "按 Ctrl+C 停止服务"

uvicorn app.main:app --host 0.0.0.0 --port 8000
