"""规划模块：制定执行计划"""
import json
from typing import List, Dict, Any
from kimi_client import KimiClient
from config import Config

class Planner:
    """规划器：根据问题制定执行计划"""
    
    def __init__(self, client: KimiClient):
        self.client = client
    
    def create_plan(self, question: str) -> List[Dict[str, Any]]:
        """
        创建执行计划
        
        Args:
            question: 用户问题
        
        Returns:
            计划步骤列表
        """
        prompt = f"""作为一个中小学教学助手，我需要回答以下问题：

问题：{question}

请帮我制定一个详细的执行计划，包括以下步骤：
1. 问题理解与分析
2. 相关知识检索
3. 信息整理与分析
4. 形成答案
5. 答案验证与优化

请以JSON格式返回计划，格式如下：
[
  {{"step": 1, "action": "动作描述", "description": "详细说明"}},
  ...
]"""
        
        response = self.client.generate_response(prompt, Config.SYSTEM_PROMPT)
        
        # 解析计划
        try:
            # 尝试提取JSON
            if "```json" in response:
                json_str = response.split("```json")[1].split("```")[0].strip()
            elif "```" in response:
                json_str = response.split("```")[1].split("```")[0].strip()
            else:
                json_str = response
            
            plan = json.loads(json_str)
            if isinstance(plan, list):
                return plan
            else:
                return [plan]
        except Exception as e:
            # 如果解析失败，返回默认计划
            return [
                {"step": 1, "action": "分析问题", "description": "理解问题的核心内容和类型"},
                {"step": 2, "action": "检索知识", "description": "查找相关的教学知识点和方法"},
                {"step": 3, "action": "整理信息", "description": "组织和分析检索到的信息"},
                {"step": 4, "action": "生成答案", "description": "基于分析结果生成完整答案"},
                {"step": 5, "action": "验证优化", "description": "检查答案的准确性和完整性"}
            ]
    
    def refine_plan(self, plan: List[Dict], current_step: int, step_result: str) -> List[Dict]:
        """
        根据执行结果优化计划
        
        Args:
            plan: 当前计划
            current_step: 当前步骤
            step_result: 当前步骤的执行结果
        
        Returns:
            优化后的计划
        """
        prompt = f"""当前执行计划：
{json.dumps(plan, ensure_ascii=False, indent=2)}

已完成的步骤：{current_step}
步骤执行结果：{step_result}

请根据执行结果，判断是否需要调整后续计划。
如果需要调整，请返回优化后的计划（JSON格式）。
如果不需要调整，请返回原计划。"""
        
        response = self.client.generate_response(prompt, Config.SYSTEM_PROMPT)
        
        try:
            if "```json" in response:
                json_str = response.split("```json")[1].split("```")[0].strip()
            elif "```" in response:
                json_str = response.split("```")[1].split("```")[0].strip()
            else:
                json_str = response
            
            refined_plan = json.loads(json_str)
            if isinstance(refined_plan, list):
                return refined_plan
        except:
            pass
        
        return plan

