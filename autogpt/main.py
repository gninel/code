import argparse
import json
import os

from .agent.agent import TeachingAgent
from .config import Config


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="中小学教学 Agent (Kimi)")
    parser.add_argument("question", type=str, help="教学问题，例如：如何给五年级学生讲解分数加减？")
    parser.add_argument("--results", type=int, default=6, help="检索结果数量")
    parser.add_argument("--pretty", action="store_true", help="美化打印 JSON")
    return parser.parse_args()


def main() -> None:
    # 允许使用 .env （如果用户已在外部设置环境变量也可）
    # 避免在仓库写入 .env（可能被忽略），用户可自行创建
    _ = os.environ.get("KIMI_API_KEY")

    cfg = Config()
    agent = TeachingAgent(cfg)
    args = parse_args()
    result = agent.run(args.question, max_results=args.results)
    if args.pretty:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()

"""主程序入口"""
import sys
from agent import EducationAgent


def main():
    """主函数"""
    print("=" * 60)
    print("    中小学教学智能助手 Agent")
    print("    基于 AutoGPT 框架 + Kimi K2-0905 模型")
    print("=" * 60)
    print()
    
    # 初始化 Agent
    agent = EducationAgent()
    
    print("Agent 已就绪！可以开始提问了。")
    print("输入 'quit' 或 'exit' 退出程序")
    print("-" * 60)
    print()
    
    # 交互循环
    while True:
        try:
            # 获取用户输入
            user_input = input("\n[你] > ").strip()
            
            # 检查退出命令
            if user_input.lower() in ['quit', 'exit', '退出']:
                print("\n感谢使用，再见！")
                break
            
            # 空输入检查
            if not user_input:
                continue
            
            # Agent 处理并回复
            print("\n[Agent] > ", end="", flush=True)
            response = agent.chat(user_input)
            print(response)
            
        except KeyboardInterrupt:
            print("\n\n程序被用户中断")
            break
        except Exception as e:
            print(f"\n发生错误: {str(e)}")
            if '--debug' in sys.argv:
                import traceback
                traceback.print_exc()


if __name__ == "__main__":
    main()

