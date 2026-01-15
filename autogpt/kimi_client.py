"""Kimi API 客户端"""
from openai import OpenAI
from config import Config


class KimiClient:
    """Kimi API 客户端封装"""
    
    def __init__(self):
        self.client = OpenAI(
            api_key=Config.KIMI_API_KEY,
            base_url=Config.KIMI_API_BASE
        )
        self.model = Config.KIMI_MODEL
    
    def chat(self, messages, temperature=None, max_tokens=None):
        """
        调用 Kimi API 进行对话
        
        Args:
            messages: 消息列表，格式为 [{"role": "user", "content": "..."}]
            temperature: 温度参数，默认使用配置值
            max_tokens: 最大 token 数，默认使用配置值
        
        Returns:
            API 响应内容
        """
        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=temperature or Config.TEMPERATURE,
            max_tokens=max_tokens or Config.MAX_TOKENS
        )
        return response.choices[0].message.content
    
    def plan(self, question):
        """
        根据问题生成规划
        
        Args:
            question: 用户问题
        
        Returns:
            规划步骤列表
        """
        prompt = f"""作为中小学教学助手，请分析以下问题并制定解决步骤：

问题：{question}

请按照以下格式输出规划步骤（每步一行，用数字编号）：
1. 第一步：...
2. 第二步：...
3. 第三步：...

只输出步骤，不要其他说明。"""
        
        messages = [
            {"role": "system", "content": Config.SYSTEM_PROMPT},
            {"role": "user", "content": prompt}
        ]
        
        result = self.chat(messages)
        # 解析步骤
        steps = []
        for line in result.strip().split('\n'):
            line = line.strip()
            if line and (line[0].isdigit() or line.startswith('-')):
                # 移除编号和符号
                step = line.split('.', 1)[-1].strip()
                step = step.lstrip('-').strip()
                if step:
                    steps.append(step)
        return steps if steps else [result]
    
    def analyze(self, question, context=None):
        """
        分析问题并生成回答
        
        Args:
            question: 用户问题
            context: 检索到的上下文信息
        
        Returns:
            分析结果
        """
        context_text = f"\n相关上下文信息：\n{context}\n" if context else ""
        
        prompt = f"""请基于以下信息回答中小学教学相关问题：

问题：{question}
{context_text}

请提供详细、准确、易懂的回答，确保符合中小学教学要求。"""
        
        messages = [
            {"role": "system", "content": Config.SYSTEM_PROMPT},
            {"role": "user", "content": prompt}
        ]
        
        return self.chat(messages)
