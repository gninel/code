import { GoogleGenAI } from "@google/genai";
import { SimulationState } from "../types";

// Initialize the Gemini API client
// Note: In a real production app, you should proxy this through a backend to hide the key.
const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

export const getPhysicsExplanation = async (
  question: string,
  simState: SimulationState,
  chatHistory: { role: string; parts: { text: string }[] }[]
): Promise<string> => {
  try {
    const systemContext = `
      你是一位热情且知识渊博的物理助教，正在为一个基于 Web 的牛顿第二定律 (F=ma) 在线仿真实验提供指导。
      
      当前实验状态数据:
      - 施加的外力 (Force): ${simState.force.toFixed(1)} N
      - 物体质量 (Mass): ${simState.mass.toFixed(1)} kg
      - 加速度 (Acceleration): ${simState.acceleration.toFixed(2)} m/s²
      - 当前速度 (Velocity): ${simState.velocity.toFixed(2)} m/s
      - 位移 (Distance): ${simState.position.toFixed(2)} m
      - 经过时间 (Time): ${simState.time.toFixed(1)} s

      你的目标是帮助用户理解力、质量和加速度之间的关系。
      如果用户问“发生了什么？”，请根据当前的数值进行解释。
      解释要简洁（100字以内），但要有见地。使用适合学生理解的简单中文。
      重点强调改变质量或力如何影响加速度。请务必使用中文回答。
    `;

    const chat = ai.chats.create({
      model: 'gemini-2.5-flash',
      config: {
        systemInstruction: systemContext,
      },
      history: chatHistory.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: msg.parts
      }))
    });

    const result = await chat.sendMessage({ message: question });
    return result.text || "我正在思考其中的物理原理...";
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "连接物理概念引擎时出现问题 (API Error)。请检查网络连接。";
  }
};