[根目录](../../CLAUDE.md) > **autogpt**

# TeachingAgent - 中小学教学智能助手

## 模块职责

基于Kimi AI的智能教学助手，专门用于处理中小学教学相关问题。采用规划-检索-生成的架构模式，能够制定教学方案、回答教学问题、设计教案，并提供诊断学习问题的功能。

## 入口与启动

### 主入口文件
- **main.py**: 命令行主程序入口
- **agent.py**: 简化版Agent接口

### 快速启动
```bash
cd autogpt
pip install -r requirements.txt

# 交互式对话
python main.py

# 命令行直接提问
python -m autogpt.main "如何给五年级学生讲解分数加减？" --pretty

# 使用示例
python example.py
```

### 环境变量配置
```bash
export KIMI_API_KEY=your_kimi_api_key
export KIMI_MODEL=kimi-k2-0905-preview
export KIMI_API_BASE=https://api.moonshot.cn/v1
```

## 对外接口

### 命令行接口
```bash
# 基本用法
python -m autogpt.main "问题内容" [选项]

# 选项参数
--results N     # 检索结果数量 (默认6)
--pretty        # 美化JSON输出格式
```

### 编程接口
```python
from agent import EducationAgent

# 创建Agent实例
agent = EducationAgent()

# 对话接口
response = agent.chat("如何教小学生理解分数的概念？")

# 计划执行
agent.execute_plan(step_num=1)
```

## 关键依赖与配置

### 核心依赖 (requirements.txt)
```python
requests>=2.28.0      # HTTP请求库
python-dotenv>=0.19.0 # 环境变量管理
argparse             # 命令行参数解析
json                 # JSON处理
os                   # 系统操作
```

### 配置管理 (config.py)
```python
class Config:
    KIMI_API_KEY = os.getenv("KIMI_API_KEY", "")
    KIMI_MODEL = os.getenv("KIMI_MODEL", "kimi-k2-0905-preview")
    KIMI_API_BASE = os.getenv("KIMI_API_BASE", "https://api.moonshot.cn/v1")
    MAX_TOKENS = 4000
    TEMPERATURE = 0.7
```

## 系统架构

### 核心组件架构
```
TeachingAgent
├── Planning Module        # 教学规划模块
├── Search Module         # 知识检索模块
├── Generation Module     # 内容生成模块
└── Dialog Management     # 对话管理
```

### Agent模块结构
```
agent/
├── __init__.py          # 模块初始化
├── agent.py             # 基础Agent类
├── planner.py           # 教学规划器
└── answerer.py          # 问题回答器
```

## 数据模型

### 请求响应模型
```json
{
  "question": "用户提出的教学问题",
  "plan": {
    "steps": ["步骤1", "步骤2", "步骤3"],
    "duration": "预计时长",
    "objectives": ["教学目标1", "教学目标2"]
  },
  "search": {
    "results": [
      {
        "title": "搜索结果标题",
        "content": "内容摘要",
        "source": "来源链接"
      }
    ],
    "total_results": 6
  },
  "answer": "AI生成的综合回答",
  "timestamp": "2025-11-08T17:01:32Z"
}
```

### 对话历史模型
```python
class ConversationHistory:
    def __init__(self):
        self.messages = []
        self.context = {}
        self.session_id = str(uuid.uuid4())

    def add_message(self, role: str, content: str):
        self.messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now()
        })
```

## 核心功能模块

### 1. 教学规划器 (planner.py)
```python
def create_lesson_plan(topic: str, grade_level: str, duration: int) -> Dict:
    """
    创建详细的教学计划

    Args:
        topic: 教学主题
        grade_level: 年级水平
        duration: 课时长度(分钟)

    Returns:
        包含教学步骤、目标、材料的完整计划
    """
```

### 2. 问题回答器 (answerer.py)
```python
def answer_teaching_question(question: str, context: Dict = None) -> str:
    """
    回答教学相关问题

    Args:
        question: 教学问题
        context: 上下文信息(可选)

    Returns:
        详细的教学解答
    """
```

### 3. 知识检索 (search_tools.py)
```python
def search_educational_resources(query: str, subject: str = None) -> List[Dict]:
    """
    搜索教学资源

    Args:
        query: 搜索关键词
        subject: 学科限制(可选)

    Returns:
        相关教学资源列表
    """
```

## 测试与质量

### 功能测试覆盖
- 教学问题回答准确性测试
- 教学计划生成完整性测试
- 多轮对话上下文理解测试
- API调用失败降级测试

### 质量保证措施
- 提示词工程优化
- 输出结果格式标准化
- 错误处理和重试机制
- 性能监控和日志记录

### 使用场景验证
- 小学数学概念讲解
- 初中物理实验指导
- 高中化学问题解答
- 教学方案设计
- 学习问题诊断

## 常见问题 (FAQ)

### Q: 如何获取Kimi API密钥？
A:
- 访问 https://platform.moonshot.cn
- 注册账号并创建API密钥
- 配置到环境变量中

### Q: 支持哪些学科？
A:
- 数学、语文、英语、物理、化学、生物等
- 可通过配置扩展新学科
- 支持跨学科综合问题

### Q: 回答准确性如何保证？
A:
- 使用最新Kimi K2模型
- 结合网络检索获取最新信息
- 多轮对话优化理解
- 教育领域专门优化

### Q: 如何定制教学风格？
A:
- 修改config.py中的系统提示词
- 调整模型参数(temperature等)
- 自定义教学模板

## 相关文件清单

### 核心程序文件
- `main.py` - 命令行主程序 (88行)
- `agent.py` - 简化版Agent接口
- `example.py` - 使用示例
- `planner.py` - 教学规划器

### Agent模块
- `agent/__init__.py` - 模块初始化
- `agent/agent.py` - 核心Agent类
- `agent/planner.py` - 教学规划器
- `agent/answerer.py` - 问题回答器

### 工具和配置
- `search_tools.py` - 检索工具
- `tools/search.py` - 搜索功能
- `kimi_client.py` - Kimi API客户端
- `config.py` - 配置管理
- `tools.py` - 通用工具

### 配置文件
- `requirements.txt` - Python依赖
- `README.md` - 详细说明文档

### 目录结构
```
autogpt/
├── agent/                    # Agent核心模块
│   ├── __init__.py          # 模块初始化
│   ├── agent.py             # Agent类
│   ├── planner.py           # 教学规划
│   └── answerer.py          # 问题回答
├── tools/                   # 工具模块
│   └── search.py            # 搜索工具
├── main.py                  # 命令行入口
├── agent.py                 # 简化接口
├── example.py               # 使用示例
├── config.py                # 配置管理
├── kimi_client.py           # API客户端
├── search_tools.py          # 检索工具
├── tools.py                 # 通用工具
├── requirements.txt         # 依赖列表
├── README.md               # 项目说明
└── CLAUDE.md              # 本文档
```

## 使用示例

### 1. 数学概念教学
```bash
python -m autogpt.main "如何给五年级学生讲解分数的概念？" --pretty
```

### 2. 教学方案设计
```bash
python -m autogpt.main "设计一个45分钟的物理课，主题是力的作用效果" --pretty
```

### 3. 学习问题诊断
```bash
python -m autogpt.main "学生在解一元二次方程时总是出错，如何帮助？" --pretty
```

## 性能优化建议

### API调用优化
- 合理设置MAX_TOKENS避免浪费
- 使用缓存机制减少重复调用
- 批量处理相关问题

### 响应速度优化
- 异步处理网络请求
- 预加载常用教学模板
- 本地缓存知识库内容

## 变更记录 (Changelog)

### 2025-11-08 17:01:32 - 初始化文档
- 分析代码结构和功能模块
- 创建完整的技术文档
- 添加使用示例和最佳实践

---

*本模块文档由自适应初始化架构师生成*