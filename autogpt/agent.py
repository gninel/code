"""核心 Agent 类"""
from typing import List, Dict, Optional
from kimi_client import KimiClient
from tools import SearchTool, AnalysisTool, EducationKnowledgeBase
from config import Config


class EducationAgent:
    """中小学教学助手 Agent"""
    
    def __init__(self):
        self.llm = KimiClient()
        self.search_tool = SearchTool()
        self.analysis_tool = AnalysisTool()
        self.knowledge_base = EducationKnowledgeBase()
        self.conversation_history = []
    
    def plan(self, question: str) -> List[str]:
        """
        规划解决步骤
        
        Args:
            question: 用户问题
        
        Returns:
            规划步骤列表
        """
        print(f"\n📋 正在规划问题：{question}")
        steps = self.llm.plan(question)
        print(f"✅ 规划完成，共 {len(steps)} 个步骤：")
        for i, step in enumerate(steps, 1):
            print(f"  {i}. {step}")
        return steps
    
    def retrieve(self, question: str, step: str) -> Optional[str]:
        """
        检索相关信息
        
        Args:
            question: 原始问题
            step: 当前步骤
        
        Returns:
            检索到的信息
        """
        print(f"\n🔍 正在检索：{step}")
        
        # 1. 先搜索知识库
        kb_result = self.knowledge_base.search(question)
        if kb_result:
            print(f"  ✓ 从知识库找到相关信息")
            return kb_result
        
        # 2. 网络搜索
        search_results = self.search_tool.search(question)
        if search_results:
            print(f"  ✓ 找到 {len(search_results)} 条搜索结果")
            # 合并搜索结果
            snippets = [r.get("snippet", "") for r in search_results]
            return "\n".join(snippets)
        
        print(f"  ⚠ 未找到相关信息")
        return None
    
    def analyze(self, question: str, context: Optional[str] = None) -> str:
        """
        分析并生成回答
        
        Args:
            question: 用户问题
            context: 检索到的上下文
        
        Returns:
            分析结果
        """
        print(f"\n🧠 正在分析问题...")
        answer = self.llm.analyze(question, context)
        print(f"✅ 分析完成")
        return answer
    
    def execute_step(self, question: str, step: str, iteration: int) -> Dict:
        """
        执行单个步骤
        
        Args:
            question: 原始问题
            step: 当前步骤
            iteration: 迭代次数
        
        Returns:
            步骤执行结果
        """
        print(f"\n{'='*50}")
        print(f"步骤 {iteration}: {step}")
        print(f"{'='*50}")
        
        # 检索信息
        context = self.retrieve(question, step)
        
        # 分析问题
        if "检索" in step or "搜索" in step or "查找" in step:
            # 如果是检索步骤，先检索再分析
            analysis = self.analyze(question, context)
        else:
            # 其他步骤直接分析
            analysis = self.analyze(f"{question}\n\n当前步骤：{step}", context)
        
        return {
            "step": step,
            "context": context,
            "analysis": analysis,
            "iteration": iteration
        }
    
    def run(self, question: str) -> Dict:
        """
        运行 Agent 处理问题
        
        Args:
            question: 用户问题
        
        Returns:
            完整的结果
        """
        print(f"\n{'='*60}")
        print(f"🎓 中小学教学助手 Agent")
        print(f"{'='*60}")
        print(f"问题：{question}\n")
        
        # 1. 规划
        steps = self.plan(question)
        
        if not steps:
            return {
                "question": question,
                "error": "规划失败"
            }
        
        # 2. 执行步骤
        results = []
        for i, step in enumerate(steps, 1):
            if i > Config.MAX_ITERATIONS:
                print(f"\n⚠️ 达到最大迭代次数限制")
                break
            
            result = self.execute_step(question, step, i)
            results.append(result)
            
            # 如果已经得到足够信息，可以提前结束
            if result.get("analysis"):
                # 可以添加提前终止逻辑
                pass
        
        # 3. 综合所有结果生成最终回答
        print(f"\n{'='*60}")
        print(f"📝 生成最终回答...")
        print(f"{'='*60}")
        
        # 汇总所有分析结果
        all_context = "\n\n".join([
            f"步骤 {r['iteration']}: {r['step']}\n分析：{r['analysis']}"
            for r in results if r.get("analysis")
        ])
        
        final_answer = self.analyze(question, all_context)
        
        return {
            "question": question,
            "steps": steps,
            "results": results,
            "final_answer": final_answer
        }
    
    def chat(self, question: str) -> str:
        """
        简单对话接口（直接回答，不进行复杂规划）
        
        Args:
            question: 用户问题
        
        Returns:
            回答
        """
        # 先尝试从知识库检索
        context = self.knowledge_base.search(question)
        
        # 如果知识库没有，进行网络搜索
        if not context:
            search_results = self.search_tool.search(question)
            if search_results:
                context = "\n".join([r.get("snippet", "") for r in search_results])
        
        # 使用 LLM 生成回答
        answer = self.llm.analyze(question, context)
        return answer
