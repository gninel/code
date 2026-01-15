# 教学 Agent（基于 Kimi API）

一个面向中小学教学问题的规划-检索-生成 Agent：
- 规划：生成结构化解决步骤
- 检索：DuckDuckGo 即时搜索要点
- 生成：调用 Kimi 模型综合回答

## 快速开始

1) 安装依赖

```bash
pip install -r requirements.txt
```

2) 配置环境变量（建议通过 shell 导出或创建 .env，本仓库未提交 .env）

```bash
export KIMI_API_KEY=你的KimiKey
export KIMI_MODEL=kimi-k2-0905-preview
export KIMI_API_BASE=https://api.moonshot.cn/v1
```

3) 运行

```bash
python -m autogpt.main "如何给五年级学生讲解分数加减？" --pretty
```

## 目录结构

```
autogpt/
  agent/
    __init__.py
    agent.py
    planner.py
    answerer.py
  tools/
    search.py
  config.py
  kimi_client.py
  requirements.txt
  README.md
```

## 说明
- 模型：默认 `kimi-k2-0905-preview`
- 检索：默认返回 6 条结果，可通过 `--results` 调整
- 输出：包含 `question`、`plan`、`search`、`answer` 字段

# 中小学教学智能助手 Agent

基于 AutoGPT 框架构建的智能教学助手，使用 Kimi K2-0905 模型，专门用于回答和处理中小学教学相关问题。

## 功能特性

### 🎯 核心功能

1. **问题解答**：专业回答中小学教学知识问题
2. **教学规划**：制定详细的教学方案和执行计划
3. **教案设计**：生成完整的课程教案
4. **问题诊断**：分析学生学习问题并提供解决方案
5. **知识检索**：快速查找相关教学资源

### 🔧 技术架构

- **框架**：AutoGPT
- **AI 模型**：Kimi K2-0905 Preview
- **API**：Moonshot API
- **Python 版本**：3.8+

## 安装与配置

### 1. 克隆项目

```bash
cd /Users/zhb/Documents/个人/code/autogpt
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 配置环境变量

项目已预配置 Kimi API 密钥，如需修改，可编辑以下配置：

- **方式 1**：编辑 `.env` 文件（如果系统支持）
- **方式 2**：直接修改 `config.py` 中的配置

```python
KIMI_API_KEY = "你的 API 密钥"
KIMI_MODEL = "kimi-k2-0905-preview"
KIMI_API_BASE = "https://api.moonshot.cn/v1"
```

## 使用方法

### 方式 1: 交互式对话

```bash
python main.py
```

然后开始提问，例如：
- "如何教小学生理解分数的概念？"
- "帮我制定一个关于函数性质的教学方案"
- "设计一个古诗鉴赏教案，适合六年级"

### 方式 2: 运行示例

```bash
python example.py
```

查看预设的使用示例。

### 方式 3: 编程调用

```python
from agent import EducationAgent

# 创建 Agent 实例
agent = EducationAgent()

# 提问
question = "如何教小学生理解分数的概念？"
response = agent.chat(question)
print(response)
```

## 项目结构

```
autogpt/
├── agent.py              # 核心 Agent 类
├── kimi_client.py        # Kimi API 客户端
├── search_tools.py       # 检索和分析工具
├── config.py             # 配置文件
├── main.py               # 主程序入口
├── example.py            # 使用示例
├── requirements.txt      # 依赖包列表
├── README.md             # 项目文档
└── .env                  # 环境变量配置（如果使用）
```

## 主要模块说明

### 1. `agent.py` - 核心 Agent

`EducationAgent` 类是系统的核心，负责：
- 意图识别和分类
- 任务路由和调度
- 对话管理
- 计划执行

### 2. `kimi_client.py` - Kimi 客户端

封装 Kimi API 调用，提供：
- `chat()`: 基础对话
- `plan()`: 生成执行计划
- `analyze()`: 分析问题
- `summarize()`: 内容总结

### 3. `search_tools.py` - 检索工具

提供教学相关工具：
- `search_knowledge()`: 知识库搜索
- `web_search()`: 网络搜索
- `analyze_learning_problem()`: 学习问题分析
- `design_lesson_plan()`: 教案设计

### 4. `config.py` - 配置管理

集中管理所有配置项：
- API 密钥和端点
- 模型参数
- 系统提示词
- 行为配置

## 使用场景示例

### 场景 1：知识问答

```
[你] > 如何教小学生理解分数的概念？
[Agent] > 教小学生理解分数概念需要从直观的实物入手...
```

### 场景 2：制定教学计划

```
[你] > 帮我制定一个关于"函数的性质"的教学方案，适合高二学生
[Agent] > **目标：** 帮助学生理解并掌握函数的基本性质...
```

### 场景 3：诊断学习问题

```
[你] > 我的学生是八年级，数学成绩一直上不去，特别是在解方程方面总是出错
[Agent] > **问题描述：** 八年级学生解方程能力不足...
```

### 场景 4：设计教案

```
[你] > 设计一个关于"古诗鉴赏"的教案，适合六年级学生，时长45分钟
[Agent] > **课程主题：** 古诗鉴赏...
```

## 高级功能

### 对话历史管理

```python
# 获取对话历史
history = agent.get_conversation_history()

# 清空对话历史
agent.clear_history()
```

### 计划执行

```python
# 创建计划后执行
agent.chat("制定一个教学计划")
agent.execute_plan(step_num=1)  # 执行第一步
```

## 注意事项

1. **API 费用**：使用 Kimi API 会产生费用，请注意用量
2. **响应时间**：网络延迟可能影响响应速度
3. **内容准确性**：AI 生成的内容需人工审核后使用
4. **学生隐私**：请勿输入真实的学生个人信息

## 常见问题

### Q: 如何修改系统提示词？
A: 编辑 `config.py` 中的 `SYSTEM_PROMPT` 变量。

### Q: 如何添加新的知识库？
A: 编辑 `search_tools.py` 中的 `knowledge_base` 字典。

### Q: 如何调整模型参数？
A: 修改 `config.py` 中的 `TEMPERATURE`、`MAX_TOKENS` 等参数。

### Q: 支持哪些学科？
A: 目前预配置了数学、语文、英语、科学等学科，可自由扩展。

## 后续优化方向

- [ ] 接入真实的教学资源数据库
- [ ] 添加多轮对话上下文理解
- [ ] 支持多媒体内容生成
- [ ] 集成作业批改功能
- [ ] 添加学习进度跟踪
- [ ] 提供 Web UI 界面

## 许可证

本项目仅供学习和研究使用。

## 联系方式

如有问题或建议，欢迎反馈。

---

**Powered by AutoGPT + Kimi K2-0905**

