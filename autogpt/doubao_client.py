#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
豆包大模型API客户端
基于火山引擎豆包大模型服务
"""

import os
import json
import requests
import time
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class DoubaoConfig:
    """豆包大模型配置"""
    api_key: str = "405fe7f2-f603-4c4c-b04b-bdea5d441319"
    endpoint_id: str = "ep-20251112223504-j8pvh"
    base_url: str = "https://ark.cn-beijing.volces.com/api/v3"
    model: str = "ep-20251112223504-j8pvh"  # 使用endpoint ID作为模型名
    max_tokens: int = 4000
    temperature: float = 0.7
    timeout: int = 60
    max_retries: int = 3

class DoubaoClient:
    """豆包大模型客户端"""

    def __init__(self, config: Optional[DoubaoConfig] = None):
        self.config = config or DoubaoConfig()
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {self.config.api_key}",
            "Content-Type": "application/json"
        })

    def chat_completion(self,
                       messages: List[Dict[str, str]],
                       temperature: Optional[float] = None,
                       max_tokens: Optional[int] = None,
                       **kwargs) -> Dict[str, Any]:
        """
        调用豆包大模型对话接口

        Args:
            messages: 对话消息列表，格式：[{"role": "user", "content": "..."}]
            temperature: 温度参数，控制随机性
            max_tokens: 最大生成token数
            **kwargs: 其他参数

        Returns:
            API响应结果
        """
        url = f"{self.config.base_url}/chat/completions"

        payload = {
            "model": self.config.model,
            "messages": messages,
            "temperature": temperature or self.config.temperature,
            "max_tokens": max_tokens or self.config.max_tokens,
            **kwargs
        }

        for attempt in range(self.config.max_retries):
            try:
                logger.info(f"发送请求到豆包大模型 (尝试 {attempt + 1}/{self.config.max_retries}): {url}")
                response = self.session.post(url, json=payload, timeout=self.config.timeout)
                response.raise_for_status()

                result = response.json()
                logger.info(f"豆包大模型响应成功，tokens: {result.get('usage', {})}")
                return result

            except requests.exceptions.Timeout as e:
                logger.warning(f"请求超时 (尝试 {attempt + 1}): {e}")
                if attempt < self.config.max_retries - 1:
                    time.sleep(2 ** attempt)  # 指数退避
                else:
                    raise
            except requests.exceptions.RequestException as e:
                logger.error(f"豆包大模型API请求失败: {e}")
                if attempt < self.config.max_retries - 1:
                    time.sleep(1)
                else:
                    raise
            except json.JSONDecodeError as e:
                logger.error(f"豆包大模型响应解析失败: {e}")
                raise

    def generate_teaching_content(self, topic: str, grade_level: str = "初中") -> str:
        """
        生成教学内容

        Args:
            topic: 教学主题
            grade_level: 年级水平

        Returns:
            生成的教学内容
        """
        prompt = f"""
请为{grade_level}学生生成关于"{topic}"的详细教学内容。

要求：
1. 内容要符合{grade_level}学生的认知水平
2. 语言生动有趣，易于理解
3. 包含重要的概念解释
4. 提供具体的例子或实验
5. 结构清晰，条理分明
6. 字数控制在800-1200字

请直接输出教学内容，不需要额外的说明。
"""

        messages = [
            {"role": "system", "content": "你是一个专业的中学教师，擅长用生动有趣的方式讲解知识。"},
            {"role": "user", "content": prompt}
        ]

        try:
            response = self.chat_completion(messages, temperature=0.6)
            return response["choices"][0]["message"]["content"]
        except Exception as e:
            logger.error(f"生成教学内容失败: {e}")
            raise

    def answer_question(self, question: str, context: str = "") -> str:
        """
        回答学生问题

        Args:
            question: 学生问题
            context: 背景上下文

        Returns:
            问题答案
        """
        context_part = f"背景信息：{context}\n\n" if context else ""

        prompt = f"""
{context_part}请回答以下学生问题：

问题：{question}

要求：
1. 答案要准确、专业
2. 语言要通俗易懂，适合中学生理解
3. 可以提供相关的例子或类比
4. 如果问题涉及计算，请给出详细的解题步骤
5. 鼓励学生思考，提出启发性问题

请直接给出答案。
"""

        messages = [
            {"role": "system", "content": "你是一个耐心、专业的中学教师，善于解答学生的各种问题。"},
            {"role": "user", "content": prompt}
        ]

        try:
            response = self.chat_completion(messages, temperature=0.5)
            return response["choices"][0]["message"]["content"]
        except Exception as e:
            logger.error(f"回答问题失败: {e}")
            raise

    def generate_experiment_description(self, experiment_name: str, subject: str = "物理") -> str:
        """
        生成实验描述

        Args:
            experiment_name: 实验名称
            subject: 学科（物理、化学等）

        Returns:
            实验描述
        """
        prompt = f"""
请为{subject}实验"{experiment_name}"生成详细的实验说明。

要求：
1. 实验目的和原理
2. 所需器材和设备
3. 实验步骤（详细、清晰）
4. 注意事项和安全提醒
5. 数据记录和分析方法
6. 实验结论和拓展思考

语言要简洁明了，步骤要具有可操作性。
"""

        messages = [
            {"role": "system", "content": "你是一个经验丰富的{subject}实验教师，擅长编写实验指导书。"},
            {"role": "user", "content": prompt}
        ]

        try:
            response = self.chat_completion(messages, temperature=0.4)
            return response["choices"][0]["message"]["content"]
        except Exception as e:
            logger.error(f"生成实验描述失败: {e}")
            raise

    def test_connection(self) -> bool:
        """
        测试API连接

        Returns:
            连接是否成功
        """
        try:
            messages = [
                {"role": "user", "content": "请简单介绍一下你自己。"}
            ]
            response = self.chat_completion(messages, max_tokens=100)
            return "choices" in response and len(response["choices"]) > 0
        except Exception as e:
            logger.error(f"连接测试失败: {e}")
            return False

def main():
    """测试函数"""
    client = DoubaoClient()

    print("🔧 测试豆包大模型连接...")
    if client.test_connection():
        print("✅ 豆包大模型连接成功！")

        # 测试教学内容生成
        print("\n📚 测试教学内容生成...")
        content = client.generate_teaching_content("牛顿第二定律", "高中")
        print("生成的内容：")
        print(content)

    else:
        print("❌ 豆包大模型连接失败！")

if __name__ == "__main__":
    main()