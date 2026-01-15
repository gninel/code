"""检索和分析工具"""
import json
from typing import List, Dict
from kimi_client import KimiClient


class SearchTools:
    """检索工具集合"""
    
    def __init__(self):
        self.kimi = KimiClient()
        # 教学知识库（示例，实际应该连接真实数据源）
        self.knowledge_base = {
            "数学": [
                "小学数学基础：加减乘除、分数、小数、几何图形",
                "初中数学：代数方程、函数、几何证明、统计概率",
                "高中数学：微积分、立体几何、数列、三角函数"
            ],
            "语文": [
                "拼音、识字、词汇、语法基础",
                "阅读理解、写作技巧、古诗词鉴赏",
                "文言文翻译、现代文分析、文学常识"
            ],
            "英语": [
                "字母、音标、基础词汇",
                "语法、句型、时态",
                "听力、口语、阅读、写作技巧"
            ],
            "科学": [
                "物理现象、化学实验、生物知识",
                "实验观察、科学探究方法"
            ]
        }
    
    def search_knowledge(self, keywords: List[str], subject: str = None) -> str:
        """
        在知识库中搜索相关内容
        
        Args:
            keywords: 关键词列表
            subject: 学科类别
            
        Returns:
            搜索到的相关知识
        """
        results = []
        
        # 如果指定了学科，只搜索该学科
        if subject and subject in self.knowledge_base:
            for keyword in keywords:
                for item in self.knowledge_base[subject]:
                    if keyword in item:
                        results.append(item)
        else:
            # 全局搜索
            for keyword in keywords:
                for subject_items in self.knowledge_base.values():
                    for item in subject_items:
                        if keyword in item:
                            results.append(item)
        
        # 去重
        results = list(set(results))
        
        if not results:
            return "未找到相关知识内容"
        
        return "\n".join(results)
    
    def web_search(self, query: str) -> str:
        """
        网络搜索（模拟，实际应接入真实搜索 API）
        
        Args:
            query: 搜索查询
            
        Returns:
            搜索结果摘要
        """
        # 这里使用 Kimi 来生成搜索结果摘要
        prompt = f"""基于你的教学知识，为以下问题提供权威准确的信息：

问题：{query}

请提供详细、准确的教学相关答案。"""
        
        messages = [
            {"role": "system", "content": "你是一个教育知识库助手，能够提供权威的教学信息。"},
            {"role": "user", "content": prompt}
        ]
        
        return self.kimi.chat(messages, max_tokens=1000)
    
    def analyze_learning_problem(self, student_profile: Dict, problem: str) -> Dict:
        """
        分析学生学习问题
        
        Args:
            student_profile: 学生档案
            problem: 问题描述
            
        Returns:
            分析结果和建议
        """
        prompt = f"""请分析以下学生的学习问题并提供针对性的解决方案：

学生信息：
- 年级：{student_profile.get('grade', '未知')}
- 学科：{student_profile.get('subject', '未知')}
- 当前水平：{student_profile.get('level', '未知')}

问题描述：{problem}

请提供：
1. 问题分析
2. 可能原因
3. 解决方案
4. 学习建议"""
        
        messages = [
            {"role": "system", "content": "你是一个经验丰富的教学诊断专家。"},
            {"role": "user", "content": prompt}
        ]
        
        response = self.kimi.chat(messages)
        
        return {
            "problem": problem,
            "analysis": response,
            "recommendations": self._extract_recommendations(response)
        }
    
    def design_lesson_plan(self, topic: str, grade: str, duration: int = 45) -> Dict:
        """
        设计课程教案
        
        Args:
            topic: 课程主题
            grade: 年级
            duration: 课程时长（分钟）
            
        Returns:
            教案内容
        """
        prompt = f"""请设计一个针对中小学教学的详细教案：

课程主题：{topic}
年级：{grade}
时长：{duration} 分钟

请包含以下部分：
1. 教学目标
2. 教学重点和难点
3. 教学过程
4. 课堂活动
5. 作业布置
6. 教学反思"""
        
        messages = [
            {"role": "system", "content": "你是一个教案设计专家，擅长设计实用有效的教学方案。"},
            {"role": "user", "content": prompt}
        ]
        
        response = self.kimi.chat(messages)
        
        return {
            "topic": topic,
            "grade": grade,
            "duration": duration,
            "plan": response
        }
    
    def _extract_recommendations(self, analysis: str) -> List[str]:
        """从分析结果中提取建议"""
        # 简单实现，实际可以使用更复杂的 NLP 方法
        recommendations = []
        lines = analysis.split('\n')
        
        for line in lines:
            if any(keyword in line for keyword in ['建议', '应该', '可以', '试试']):
                recommendations.append(line.strip())
        
        return recommendations if recommendations else ["请按照上面的分析进行学习"]

