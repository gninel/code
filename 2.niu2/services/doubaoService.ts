import { SimulationState } from "../types";

// 豆包大模型API配置
const DOUBAO_API_CONFIG = {
  baseUrl: import.meta.env.DEV ? '/api/ark' : 'https://ark.cn-beijing.volces.com/api/v3',
  endpointId: 'ep-20251112223504-j8pvh', // 从提供的endpoint ID
  apiKey: process.env.DOUBAO_API_KEY || '405fe7f2-f603-4c4c-b04b-bdea5d441319'
};

interface DoubaoMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

interface DoubaoResponse {
  choices: Array<{
    message: {
      content: string;
      role: string;
    };
    finish_reason: string;
  }>;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export const getPhysicsExplanationFromDoubao = async (
  question: string,
  simState: SimulationState,
  chatHistory: { role: string; parts: { text: string }[] }[]
): Promise<string> => {
  try {
    console.log('🚀 开始调用豆包API');
    console.log('📋 API配置:', {
      baseUrl: DOUBAO_API_CONFIG.baseUrl,
      endpointId: DOUBAO_API_CONFIG.endpointId,
      apiKey: DOUBAO_API_CONFIG.apiKey ? '已配置' : '未配置'
    });

    // 构建系统提示词
    const systemPrompt = `
你是一位热情且知识渊博的物理助教，正在为一个基于 Web 的牛顿第二定律 (F=ma) 在线仿真实验提供指导。

当前实验状态数据:
- 施加的外力 (Force): ${simState.force.toFixed(1)} N
- 物体质量 (Mass): ${simState.mass.toFixed(1)} kg
- 加速度 (Acceleration): ${simState.acceleration.toFixed(2)} m/s²
- 当前速度 (Velocity): ${simState.velocity.toFixed(2)} m/s
- 位移 (Distance): ${simState.position.toFixed(2)} m
- 经过时间 (Time): ${simState.time.toFixed(1)} s

你的目标是帮助用户理解力、质量和加速度之间的关系。
如果用户问"发生了什么？"，请根据当前的数值进行解释。
解释要简洁（100字以内），但要有见地。使用适合学生理解的简单中文。
重点强调改变质量或力如何影响加速度。请务必使用中文回答。
`;

    // 构建消息历史
    const messages: DoubaoMessage[] = [
      {
        role: 'system',
        content: systemPrompt
      }
    ];

    // 添加历史对话
    chatHistory.forEach(msg => {
      if (msg.role === 'user') {
        messages.push({
          role: 'user',
          content: msg.parts[0]?.text || ''
        });
      } else if (msg.role === 'model') {
        messages.push({
          role: 'assistant',
          content: msg.parts[0]?.text || ''
        });
      }
    });

    // 添加当前问题
    messages.push({
      role: 'user',
      content: question
    });

    // 调用豆包API
    console.log('📤 发送API请求:', {
      url: `${DOUBAO_API_CONFIG.baseUrl}/chat/completions`,
      model: DOUBAO_API_CONFIG.endpointId,
      messagesCount: messages.length
    });

    const requestBody = {
      model: DOUBAO_API_CONFIG.endpointId,
      messages: messages,
      max_tokens: 500,
      temperature: 0.7,
      top_p: 0.9,
      stream: false
    };

    console.log('📝 请求体:', JSON.stringify(requestBody, null, 2));

    const response = await fetch(`${DOUBAO_API_CONFIG.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DOUBAO_API_CONFIG.apiKey}`,
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    console.log('📥 API响应状态:', response.status, response.statusText);

    if (!response.ok) {
      const errorData = await response.text();
      console.error('❌ 豆包API错误:', errorData);
      console.error('❌ 响应头:', Object.fromEntries(response.headers.entries()));
      throw new Error(`API请求失败: ${response.status} ${response.statusText}`);
    }

    const data: DoubaoResponse = await response.json();
    console.log('✅ API响应成功:', JSON.stringify(data, null, 2));

    if (data.choices && data.choices.length > 0) {
      const assistantReply = data.choices[0].message.content;
      console.log('💬 模型回复:', assistantReply);
      return assistantReply.trim();
    } else {
      console.error('❌ API返回格式错误:', data);
      throw new Error('API返回格式错误');
    }

  } catch (error) {
    console.error("豆包API调用错误:", error);

    // 提供友好的错误信息
    if (error instanceof Error) {
      if (error.message.includes('401')) {
        return "API密钥验证失败，请检查豆包API密钥配置。";
      } else if (error.message.includes('429')) {
        return "API调用频率过高，请稍后再试。";
      } else if (error.message.includes('500')) {
        return "豆包服务暂时不可用，请稍后重试。";
      }
    }

    return "连接物理概念引擎时出现问题。请检查网络连接或稍后重试。";
  }
};

// 豆包API健康检查
export const checkDoubaoApiHealth = async (): Promise<boolean> => {
  try {
    const response = await fetch(`${DOUBAO_API_CONFIG.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DOUBAO_API_CONFIG.apiKey}`,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        model: DOUBAO_API_CONFIG.endpointId,
        messages: [
          {
            role: 'user',
            content: 'Hello'
          }
        ],
        max_tokens: 10
      })
    });

    return response.ok;
  } catch (error) {
    console.error('豆包API健康检查失败:', error);
    return false;
  }
};