from typing import Dict, Any

from ..config import Config
from ..tools.search import web_search
from .planner import Planner
from .answerer import Answerer


class TeachingAgent:
    """面向中小学教学问题的规划-检索-生成一体 Agent。"""

    def __init__(self, config: Config | None = None):
        self.config = config or Config()
        self.planner = Planner(config=self.config)
        self.answerer = Answerer(config=self.config)

    def run(self, question: str, max_results: int = 6) -> Dict[str, Any]:
        plan_steps = self.planner.make_plan(question)
        # 以问题为主检索，也可将每个步骤关键词化进一步扩展，这里实现简版
        hits = web_search(question, max_results=max_results)
        answer = self.answerer.synthesize(question, plan_steps, hits)
        return {
            "question": question,
            "plan": plan_steps,
            "search": hits,
            "answer": answer,
        }


