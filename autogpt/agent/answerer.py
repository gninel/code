from typing import List, Dict

from ..config import Config
from ..kimi_client import KimiClient


SYNTHESIS_PROMPT = (
    "你将根据‘问题’、‘计划步骤’与‘检索要点’撰写答案。要求：\n"
    "- 面向中小学读者，表述清晰、分点、有例子；\n"
    "- 优先引用检索到的可靠知识点（如百科、教材术语），并用自己的话解释；\n"
    "- 若存在地区/版本差异，提示可能差异；\n"
    "- 最后附上参考链接列表（如有）。"
)


class Answerer:
    def __init__(self, client: KimiClient | None = None, config: Config | None = None):
        self.client = client or KimiClient(config)
        self.config = config or Config()

    def synthesize(self, question: str, plan_steps: List[str], search_hits: List[Dict[str, str]]) -> str:
        sys = {"role": "system", "content": self.config.SYSTEM_PROMPT}

        search_bullets = "\n".join(
            [f"- {hit.get('title','')} — {hit.get('snippet','')[:200]}... ({hit.get('url','')})" for hit in search_hits]
        ) or "(无检索结果)"

        plan_bullets = "\n".join([f"- {s}" for s in plan_steps]) or "- 制定基础回答结构"

        user = {"role": "user", "content": (
            f"{SYNTHESIS_PROMPT}\n\n问题：{question}\n\n计划步骤：\n{plan_bullets}\n\n检索要点：\n{search_bullets}"
        )}

        return self.client.chat([sys, user], temperature=self.config.TEMPERATURE, max_tokens=self.config.MAX_TOKENS)


