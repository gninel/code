<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# 牛顿第二定律实验室 - 豆包大模型版

这是一个基于豆包大模型（火山引擎）的交互式物理实验学习平台，专门用于演示和讲解牛顿第二定律（F=ma）。

## 🚀 功能特色

- **🤖 豆包AI物理助教**: 基于豆包大模型的智能对话系统，实时解答物理实验相关问题
- **📊 实时数据可视化**: 显示力、质量、加速度、速度、位移等物理参数
- **🎯 交互式实验**: 通过滑块调节参数，观察物理现象变化
- **💬 智能问答**: AI助教根据当前实验状态提供个性化解释

## 📋 技术栈

- **前端**: React 19 + TypeScript + Vite
- **UI框架**: Tailwind CSS + Lucide Icons
- **AI服务**: 豆包大模型（火山引擎）
- **图表**: Recharts
- **部署**: 支持Vercel、Docker、传统服务器等多种部署方式

## 🛠️ 本地运行

**环境要求:** Node.js 18+

### 1. 克隆项目
```bash
git clone <your-repository-url>
cd niu2
```

### 2. 安装依赖
```bash
npm install
```

### 3. 配置环境变量
创建 `.env.local` 文件并配置豆包API密钥：
```bash
cp .env.example .env.local
# 编辑 .env.local，确保包含以下配置：
DOUBAO_API_KEY=405fe7f2-f603-4c4c-b04b-bdea5d441319
```

### 4. 启动开发服务器
```bash
npm run dev
```
访问 http://localhost:3000 查看应用

## 🌐 部署指南

### 方案一：Vercel 部署（推荐）

```bash
# 安装 Vercel CLI
npm install -g vercel

# 登录并部署
vercel login
vercel --prod

# 设置环境变量
vercel env add DOUBAO_API_KEY production
```

### 方案二：传统服务器部署

1. 服务器准备：Node.js 18+ + Nginx
2. 构建项目：`npm run build`
3. 使用 PM2 启动：`pm2 start ecosystem.config.js`
4. 配置 Nginx 反向代理（参考 nginx.conf）

### 方案三：Docker 部署

```bash
docker-compose up -d --build
```

## 🔧 豆包大模型配置

### API 端点信息
- **服务商**: 火山引擎
- **模型**: 豆包大模型
- **Endpoint ID**: ep-20251112223504-j8pvh
- **API Base URL**: https://ark.cn-beijing.volces.com/api/v3

### 环境变量配置
```bash
# 必需的环境变量
DOUBAO_API_KEY=your_doubao_api_key_here
NODE_ENV=production  # 生产环境
```

### API 健康检查
项目内置了豆包API的健康检查功能：
```typescript
import { checkDoubaoApiHealth } from './services/doubaoService';

// 检查API可用性
const isHealthy = await checkDoubaoApiHealth();
```

## 📚 使用说明

### 实验操作
1. **调节参数**: 使用滑块调节力（Force）和质量（Mass）
2. **运行实验**: 点击开始按钮观察物理现象
3. **数据观察**: 查看实时更新的加速度、速度、位移等数据
4. **AI问答**: 向豆包AI助教询问相关问题

### 示例问题
- "为什么物体运动得更快了？"
- "如果增加质量会发生什么？"
- "当前加速度是多少？"
- "解释一下力与加速度的关系"

## 🔒 安全说明

⚠️ **重要提醒**:
- 当前版本API密钥配置用于演示目的
- 生产环境建议通过后端服务代理API调用
- 建议设置API使用量限制和监控

## 🐛 故障排除

### 常见问题

**1. API调用失败**
- 检查 `DOUBAO_API_KEY` 是否正确配置
- 确认网络连接正常
- 验证Endpoint ID是否有效

**2. 构建失败**
```bash
# 清理缓存重新安装
rm -rf node_modules package-lock.json
npm install
npm run build
```

**3. 部署后环境变量丢失**
- 确认部署平台的环境变量配置
- 检查 `.env.production` 文件
- 验证变量名称拼写正确

## 📈 监控和维护

### 日志查看
```bash
# PM2 日志
pm2 logs newton-lab

# Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 性能监控
- API响应时间监控
- 内存使用情况检查
- 错误日志分析

## 🤝 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🆘 技术支持

如遇到问题，请：
1. 查看 [Issues](../../issues) 页面
2. 创建新的 Issue 描述问题
3. 联系技术团队获取支持

---

*基于豆包大模型构建的智能物理教育平台* 🚀
