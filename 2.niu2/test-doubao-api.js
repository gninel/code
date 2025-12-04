// 测试豆包大模型API连接
const DOUBAO_API_CONFIG = {
  baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
  endpointId: 'ep-20251112223504-j8pvh',
  apiKey: '405fe7f2-f603-4c4c-b04b-bdea5d441319'
};

async function testDoubaoAPI() {
  console.log('开始测试豆包API连接...');
  console.log('API配置:', {
    baseUrl: DOUBAO_API_CONFIG.baseUrl,
    endpointId: DOUBAO_API_CONFIG.endpointId,
    apiKey: DOUBAO_API_CONFIG.apiKey.substring(0, 10) + '...'
  });

  try {
    // 测试简单的API调用
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
            content: '你好，请回复一个简单的问候'
          }
        ],
        max_tokens: 50,
        temperature: 0.7
      })
    });

    console.log('响应状态:', response.status, response.statusText);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('API错误响应:', errorText);
      return false;
    }

    const data = await response.json();
    console.log('API响应成功:', JSON.stringify(data, null, 2));

    if (data.choices && data.choices.length > 0) {
      const reply = data.choices[0].message.content;
      console.log('模型回复:', reply);
      return true;
    } else {
      console.error('API返回格式错误:', data);
      return false;
    }

  } catch (error) {
    console.error('API调用异常:', error);
    return false;
  }
}

// 运行测试
testDoubaoAPI().then(success => {
  if (success) {
    console.log('✅ 豆包API连接测试成功！');
  } else {
    console.log('❌ 豆包API连接测试失败！');
  }
});