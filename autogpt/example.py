"""使用示例"""
from agent import EducationAgent


def example_usage():
    """示例用法"""
    print("创建 EducationAgent 实例...")
    agent = EducationAgent()
    
    print("\n" + "="*60)
    print("示例 1: 回答知识问题")
    print("="*60)
    question = "如何教小学生理解分数的概念？"
    print(f"\n问题：{question}")
    response = agent.chat(question)
    print(f"\n回答：{response}")
    
    print("\n" + "="*60)
    print("示例 2: 制定教学计划")
    print("="*60)
    plan_request = "帮我制定一个关于函数性质的教学方案，适合高二学生"
    print(f"\n请求：{plan_request}")
    response = agent.chat(plan_request)
    print(f"\n方案：{response}")
    
    print("\n" + "="*60)
    print("示例 3: 分析学习问题")
    print("="*60)
    problem = "我的学生是八年级，数学成绩一直上不去，特别是在解方程方面总是出错"
    print(f"\n问题：{problem}")
    response = agent.chat(problem)
    print(f"\n分析：{response}")
    
    print("\n" + "="*60)
    print("示例 4: 设计教案")
    print("="*60)
    lesson_request = "设计一个关于古诗鉴赏的教案，适合六年级学生，时长45分钟"
    print(f"\n请求：{lesson_request}")
    response = agent.chat(lesson_request)
    print(f"\n教案：{response}")
    
    print("\n" + "="*60)
    print("演示完成！")
    print("="*60)


if __name__ == "__main__":
    try:
        example_usage()
    except Exception as e:
        print(f"发生错误: {e}")
        import traceback
        traceback.print_exc()

