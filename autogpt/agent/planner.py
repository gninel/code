from typing import List

from ..config import Config
from ..kimi_client import KimiClient


PLANNER_PROMPT = (
    "你将收到一个与中小学教学相关的问题。请输出一个简明的执行计划，包含3-6个步骤，"
    "覆盖：澄清需求→检索要点→知识点组织→示例与类比→形成答案。"
    "使用有序列表输出，每步一句。"
)


class Planner:
    def __init__(self, client: KimiClient | None = None, config: Config | None = None):
        self.client = client or KimiClient(config)
        self.config = config or Config()

    def make_plan(self, question: str) -> List[str]:
        sys = {"role": "system", "content": self.config.SYSTEM_PROMPT}
        inst = {"role": "user", "content": f"{PLANNER_PROMPT}\n\n问题：{question}"}
        text = self.client.chat([sys, inst], temperature=0.4, max_tokens=600)
        steps: List[str] = []
        for line in text.splitlines():
            line = line.strip().lstrip("- ")
            if not line:
                continue
            # 去掉序号前缀
            for prefix in ["1.", "2.", "3.", "4.", "5.", "6.", "7.", "8."]:
                if line.startswith(prefix):
                    line = line[len(prefix):].strip()
                    break
            steps.append(line)
        return steps[:8]


