#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
基于豆包大模型的教学智能助手
"""

import argparse
import json
from typing import Dict, Any, List, Optional
from doubao_client import DoubaoClient, DoubaoConfig
import sys

class DoubaoTeachingAgent:
    """基于豆包大模型的教学智能助手"""

    def __init__(self, api_key: str, endpoint_id: str):
        config = DoubaoConfig(
            api_key=api_key,
            endpoint_id=endpoint_id,
            model=endpoint_id
        )
        self.client = DoubaoClient(config)

    def generate_teaching_plan(self, topic: str, grade_level: str = "初中", duration: int = 45) -> Dict[str, Any]:
        """
        生成教学计划

        Args:
            topic: 教学主题
            grade_level: 年级水平
            duration: 课时长度(分钟)

        Returns:
            教学计划
        """
        prompt = f"""
请为{grade_level}学生设计一个关于"{topic}"的{duration}分钟教学计划。

要求按以下格式输出JSON：

{{
    "topic": "{topic}",
    "grade_level": "{grade_level}",
    "duration": {duration},
    "objectives": [
        "教学目标1",
        "教学目标2",
        "教学目标3"
    ],
    "key_points": [
        "重点1",
        "重点2",
        "难点1"
    ],
    "materials": [
        "教学材料1",
        "教学材料2"
    ],
    "steps": [
        {{
            "phase": "导入",
            "duration": 5,
            "activities": ["活动描述"],
            "purpose": "目的说明"
        }},
        {{
            "phase": "新授课",
            "duration": 25,
            "activities": ["活动描述"],
            "purpose": "目的说明"
        }},
        {{
            "phase": "练习",
            "duration": 10,
            "activities": ["活动描述"],
            "purpose": "目的说明"
        }},
        {{
            "phase": "总结",
            "duration": 5,
            "activities": ["活动描述"],
            "purpose": "目的说明"
        }}
    ],
    "assessment": "评价方式",
    "homework": "作业安排"
}}

请确保输出有效的JSON格式。
"""

        try:
            messages = [
                {"role": "system", "content": "你是一个专业的教学设计专家，擅长制定符合学生认知规律的教学计划。"},
                {"role": "user", "content": prompt}
            ]

            response = self.client.chat_completion(messages, temperature=0.3)
            content = response["choices"][0]["message"]["content"]

            # 尝试解析JSON
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                # 如果解析失败，返回原始内容
                return {
                    "topic": topic,
                    "grade_level": grade_level,
                    "duration": duration,
                    "raw_content": content,
                    "error": "JSON解析失败"
                }
        except Exception as e:
            return {
                "error": f"生成教学计划失败: {str(e)}",
                "topic": topic,
                "grade_level": grade_level,
                "duration": duration
            }

    def answer_teaching_question(self, question: str, context: str = "", subject: str = "通用") -> Dict[str, Any]:
        """
        回答教学问题

        Args:
            question: 问题
            context: 上下文
            subject: 学科

        Returns:
            答案结果
        """
        context_part = f"背景信息：{context}\n\n" if context else ""

        prompt = f"""
{context_part}请回答以下{subject}教学问题：

问题：{question}

要求：
1. 答案要准确、专业
2. 语言要通俗易懂，适合教师理解
3. 提供具体的教学建议或解决方案
4. 可以包含相关的教学案例或方法
5. 如果涉及具体学科知识，要确保科学性

请给出详细的回答。
"""

        try:
            messages = [
                {"role": "system", "content": f"你是一个经验丰富的{subject}教学专家，善于解决各种教学问题。"},
                {"role": "user", "content": prompt}
            ]

            response = self.client.chat_completion(messages, temperature=0.5)
            answer = response["choices"][0]["message"]["content"]

            return {
                "question": question,
                "subject": subject,
                "context": context,
                "answer": answer,
                "usage": response.get("usage", {})
            }
        except Exception as e:
            return {
                "error": f"回答问题失败: {str(e)}",
                "question": question,
                "subject": subject
            }

    def generate_experiment_guide(self, experiment_name: str, subject: str = "物理") -> Dict[str, Any]:
        """
        生成实验指导

        Args:
            experiment_name: 实验名称
            subject: 学科

        Returns:
            实验指导
        """
        prompt = f"""
请为{subject}实验"{experiment_name}"生成详细的实验指导方案。

请按以下格式输出JSON：

{{
    "experiment_name": "{experiment_name}",
    "subject": "{subject}",
    "objectives": [
        "实验目标1",
        "实验目标2"
    ],
    "principles": "实验原理说明",
    "materials": [
        "器材1（数量）",
        "器材2（数量）"
    ],
    "safety_precautions": [
        "安全注意事项1",
        "安全注意事项2"
    ],
    "steps": [
        {{
            "step": 1,
            "action": "具体操作步骤",
            "notes": "注意事项"
        }}
    ],
    "data_recording": "数据记录方法和表格设计",
    "analysis": "数据分析方法",
    "conclusions": "预期结论和讨论要点",
    "extensions": "拓展思考或变式实验"
}}

请确保输出有效的JSON格式。
"""

        try:
            messages = [
                {"role": "system", "content": f"你是一个专业的{subject}实验教师，精通实验设计和操作指导。"},
                {"role": "user", "content": prompt}
            ]

            response = self.client.chat_completion(messages, temperature=0.4)
            content = response["choices"][0]["message"]["content"]

            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return {
                    "experiment_name": experiment_name,
                    "subject": subject,
                    "raw_content": content,
                    "error": "JSON解析失败"
                }
        except Exception as e:
            return {
                "error": f"生成实验指导失败: {str(e)}",
                "experiment_name": experiment_name,
                "subject": subject
            }

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="豆包大模型教学智能助手")
    parser.add_argument("question", nargs="?", help="教学问题或主题")
    parser.add_argument("--type", choices=["answer", "plan", "experiment"],
                       default="answer", help="生成类型")
    parser.add_argument("--grade", default="初中", help="年级水平")
    parser.add_argument("--subject", default="通用", help="学科")
    parser.add_argument("--duration", type=int, default=45, help="课时长度(分钟)")
    parser.add_argument("--context", default="", help="背景信息")
    parser.add_argument("--api-key", default="405fe7f2-f603-4c4c-b04b-bdea5d441319",
                       help="豆包API密钥")
    parser.add_argument("--endpoint", default="ep-20251112223504-j8pvh",
                       help="豆包端点ID")
    parser.add_argument("--pretty", action="store_true", help="美化输出")
    parser.add_argument("--test", action="store_true", help="测试连接")

    args = parser.parse_args()

    # 创建教学助手
    agent = DoubaoTeachingAgent(args.api_key, args.endpoint)

    # 测试连接
    if args.test:
        print("🔧 测试豆包大模型连接...")
        if agent.client.test_connection():
            print("✅ 连接成功！")
            return
        else:
            print("❌ 连接失败！")
            return

    # 如果没有提供问题，进入交互模式
    if not args.question:
        print("🎓 豆包大模型教学智能助手")
        print("=" * 40)
        print("输入 'quit' 或 'exit' 退出")
        print("输入 'help' 查看使用帮助")
        print()

        while True:
            try:
                question = input("请输入教学问题: ").strip()
                if question.lower() in ['quit', 'exit', 'q']:
                    break
                if not question:
                    continue
                if question.lower() == 'help':
                    print_help()
                    continue

                result = agent.answer_teaching_question(question)
                print_result(result, args.pretty)

            except KeyboardInterrupt:
                print("\n👋 再见！")
                break
            except Exception as e:
                print(f"❌ 错误: {e}")

        return

    # 处理命令行问题
    try:
        if args.type == "answer":
            result = agent.answer_teaching_question(
                args.question, args.context, args.subject
            )
        elif args.type == "plan":
            result = agent.generate_teaching_plan(
                args.question, args.grade, args.duration
            )
        elif args.type == "experiment":
            result = agent.generate_experiment_guide(
                args.question, args.subject
            )

        print_result(result, args.pretty)

    except Exception as e:
        print(f"❌ 处理失败: {e}")

def print_help():
    """打印帮助信息"""
    help_text = """
使用示例：
1. 回答问题: python doubao_agent.py "如何讲解牛顿第二定律？"
2. 生成教学计划: python doubao_agent.py "力的作用" --type plan --grade 高中
3. 生成实验指导: python doubao_agent.py "单摆实验" --type experiment --subject 物理
4. 测试连接: python doubao_agent.py --test

命令行选项：
--type: answer(默认), plan, experiment
--grade: 小学、初中、高中(默认初中)
--subject: 学科名称
--duration: 课时长度(默认45分钟)
--context: 背景信息
--pretty: 美化JSON输出
"""
    print(help_text)

def print_result(result: Dict[str, Any], pretty: bool = False):
    """打印结果"""
    if pretty:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("🎯 结果:")
        print("-" * 40)

        if "error" in result:
            print(f"❌ {result['error']}")
            return

        if "answer" in result:
            print(f"问题: {result.get('question', '')}")
            print(f"学科: {result.get('subject', '')}")
            print(f"回答:\n{result['answer']}")

        elif "topic" in result:
            print(f"主题: {result.get('topic', '')}")
            print(f"年级: {result.get('grade_level', '')}")
            print(f"时长: {result.get('duration', '')}分钟")
            if "objectives" in result:
                print(f"目标: {', '.join(result['objectives'])}")
            if "steps" in result:
                print("教学步骤:")
                for step in result['steps']:
                    print(f"  {step.get('phase', '')} ({step.get('duration', '')}分钟)")

        elif "experiment_name" in result:
            print(f"实验: {result.get('experiment_name', '')}")
            print(f"学科: {result.get('subject', '')}")
            if "objectives" in result:
                print(f"目标: {', '.join(result['objectives'])}")
            if "materials" in result:
                print(f"器材: {', '.join(result['materials'])}")

if __name__ == "__main__":
    main()