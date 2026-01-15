from typing import List, Dict
from duckduckgo_search import DDGS


def web_search(query: str, max_results: int = 5, region: str = "cn-zh") -> List[Dict[str, str]]:
    """使用 DuckDuckGo 进行网页检索，返回标题、URL、摘要。"""
    results: List[Dict[str, str]] = []
    with DDGS() as ddgs:
        for r in ddgs.text(query, region=region, max_results=max_results):
            results.append({
                "title": r.get("title", ""),
                "url": r.get("href", ""),
                "snippet": r.get("body", ""),
            })
    return results


