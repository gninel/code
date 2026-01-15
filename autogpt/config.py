"""应用配置管理"""
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    # Kimi / Moonshot API
    KIMI_API_KEY: str = os.getenv("KIMI_API_KEY", "sk-HIE0liQkkzzAvKVsf0hv0LQDFN9T0ddm30eWCLJG1O4RU1vt")
    KIMI_MODEL: str = os.getenv("KIMI_MODEL", "kimi-k2-0905-preview")
    KIMI_API_BASE: str = os.getenv("KIMI_API_BASE", "https://api.moonshot.cn/v1")

    # 生成参数
    TEMPERATURE: float = float(os.getenv("TEMPERATURE", "0.7"))
    MAX_TOKENS: int = int(os.getenv("MAX_TOKENS", "2000"))
    MAX_ITERATIONS: int = int(os.getenv("MAX_ITERATIONS", "8"))

    # 领域设定
    EDUCATION_DOMAIN: str = "中小学教学"
    SYSTEM_PROMPT: str = (
        "你是一个专业的中小学教学助手，擅长：\n"
        "1. 分析教学问题并提出解决方案\n"
        "2. 设计教学计划和课程\n"
        "3. 解答学科知识点问题\n"
        "4. 提供教学方法和策略建议\n"
        "5. 分析学生的学习问题并提供指导\n\n"
        "请始终以教育专业的角度回答问题，确保内容准确、易懂且符合中小学教学要求。"
    )

"""配置文件管理"""
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """应用配置"""
    KIMI_API_KEY = os.getenv("KIMI_API_KEY", "sk-HIE0liQkkzzAvKVsf0hv0LQDFN9T0ddm30eWCLJG1O4RU1vt")
    KIMI_MODEL = os.getenv("KIMI_MODEL", "kimi-k2-0905-preview")
    KIMI_API_BASE = os.getenv("KIMI_API_BASE", "https://api.moonshot.cn/v1")
    
    # Agent 配置
    MAX_ITERATIONS = 10  # 最大迭代次数
    TEMPERATURE = 0.7  # 模型温度
    MAX_TOKENS = 2000  # 最大 token 数
    
    # 教学领域特定配置
    EDUCATION_DOMAIN = "中小学教学"
    SYSTEM_PROMPT = """你是一个专业的中小学教学助手，擅长：
1. 分析教学问题并提出解决方案
2. 设计教学计划和课程
3. 解答学科知识点问题
4. 提供教学方法和策略建议
5. 分析学生的学习问题并提供指导

请始终以教育专业的角度回答问题，确保内容准确、易懂且符合中小学教学要求。"""

