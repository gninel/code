#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
豆包大模型简单测试脚本
"""

import json
from doubao_client import DoubaoClient, DoubaoConfig

def test_simple_chat():
    """测试简单对话"""
    config = DoubaoConfig(
        api_key="405fe7f2-f603-4c4c-b04b-bdea5d441319",
        endpoint_id="ep-20251112223504-j8pvh",
        max_tokens=100,  # 减少token数量
        timeout=30      # 减少超时时间
    )

    client = DoubaoClient(config)

    print("🔧 测试豆包大模型连接...")

    try:
        messages = [
            {"role": "user", "content": "请简单介绍一下你自己。"}
        ]

        response = client.chat_completion(messages)

        if "choices" in response and len(response["choices"]) > 0:
            content = response["choices"][0]["message"]["content"]
            print("✅ 连接成功！")
            print(f"🤖 豆包回复: {content}")

            # 显示使用统计
            usage = response.get("usage", {})
            if usage:
                print(f"📊 Token使用: {usage}")

            return True
        else:
            print("❌ 响应格式错误")
            print(f"响应: {json.dumps(response, ensure_ascii=False, indent=2)}")
            return False

    except Exception as e:
        print(f"❌ 连接失败: {e}")
        return False

def test_teaching_question():
    """测试教学问题"""
    config = DoubaoConfig(
        api_key="405fe7f2-f603-4c4c-b04b-bdea5d441319",
        endpoint_id="ep-20251112223504-j8pvh",
        max_tokens=200,
        timeout=45
    )

    client = DoubaoClient(config)

    print("\n📚 测试教学问题回答...")

    try:
        question = "如何给初中生讲解牛顿第二定律？"
        answer = client.answer_question(question)

        print(f"❓ 问题: {question}")
        print(f"💬 回答: {answer[:200]}...")

        return True

    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False

def main():
    print("🚀 豆包大模型功能测试")
    print("=" * 40)

    # 测试基本连接
    if test_simple_chat():
        print("\n" + "✅ 基本连接测试通过")

        # 测试教学功能
        if test_teaching_question():
            print("\n✅ 教学功能测试通过")
        else:
            print("\n⚠️ 教学功能测试失败")
    else:
        print("\n❌ 基本连接测试失败")
        print("请检查：")
        print("1. API密钥是否正确")
        print("2. Endpoint ID是否正确")
        print("3. 网络连接是否正常")
        print("4. 服务是否可用")

if __name__ == "__main__":
    main()