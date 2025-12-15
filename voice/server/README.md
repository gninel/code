# 云端同步后端服务

基于 Python FastAPI 的后端服务，提供用户认证和数据同步功能。

## 快速开始

### 1. 安装依赖
```bash
pip install -r requirements.txt
```

### 2. 配置环境变量
复制 `.env.example` 为 `.env`，填入数据库配置。

### 3. 运行服务
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## API 文档

启动后访问 http://localhost:8000/docs 查看完整API文档。
