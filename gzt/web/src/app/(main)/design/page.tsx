"use client";

import React, { useState, useEffect, useRef } from 'react';
import UnitBasicInfo from '@/components/TeachingDesign/UnitBasicInfo';
import DesignModule from '@/components/TeachingDesign/DesignModule';
import styles from './page.module.css';

// Icons
const DownloadIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
        <polyline points="7 10 12 15 17 10" />
        <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
);

const SparklesIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
    </svg>
);

const SendIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="22" y1="2" x2="11" y2="13" />
        <polygon points="22 2 15 22 11 13 2 9 22 2" />
    </svg>
);

const QA_CHAIN_DEFAULT_CONTENT = `核心问题：如何准确确定物体的位置？（兼顾确定位置的三要素、观测点变化与生活应用）
一、吸引环节：激活经验，发现矛盾（对应目标3，铺垫目标1）
1、生活情境提问：“周末全家去动物园，妈妈说‘熊猫馆在大门的东边’，你能直接找到吗？为什么？”
二、探索环节：自主建构，理解核心（对应目标1、2）
2、操作提问：“以动物园大门为观测点，熊猫馆在大门的东北方向 —— 如果用量角器测量，从正北方向向东转 30°，这种方向可以怎么描述？（引导说出 “北偏东 30°”）”
3、补充提问：“知道了熊猫馆在大门的北偏东30°方向，就能确定位置了吗？如果熊猫馆距离大门 100米，而鸟馆在大门北偏东 30°方向 50 米处，它们的位置一样吗？”
4、小组合作：“要唯一确定一个物体的位置，必须包含哪三个关键信息？缺少其中一个会有什么问题？”
5、情境转换：“从大门出发，走到熊猫馆后，现在以熊猫馆为观测点，大门在熊猫馆的什么方向？和之前‘熊猫馆在大门的北偏东 30°’相比，方向有什么变化？”
三、解释环节：梳理方法，规范表达（对应目标 1、2）
6、归纳提问：“请用自己的话总结：怎样才能准确描述物体的位置？（引导学生说出 “先确定观测点→再看方向（北偏东 / 西、南偏东 / 西 + 角度）→最后说距离”）”
7、原理追问：“为什么确定位置必须以‘观测点’为基准？如果观测点不明确，会出现什么情况？”
四、深化环节：迁移应用，拓展思维（对应目标 1、2、3）
8、生活应用：“你家在学校的什么位置？请用‘方向 + 角度 + 距离’的方式描述，再反过来描述学校在你家的位置。”
9、创新设计：“如果让你设计一个‘校园寻宝图’，在图上标注 3 个宝藏地点，用方向、角度和距离描述每个宝藏相对于起点的位置，让同桌根据你的描述寻找宝藏。”
10、反思提问：“通过本节课的学习，你学会了什么？在确定位置时，你最容易出错的地方是什么？生活中还有哪些地方会用到‘方向 + 角度 + 距离’确定位置？”`;

const ACTIVITY_DESIGN_DEFAULT_CONTENT = `一、游戏情境：创设寻宝任务：
"学校少先队要举办校园定向活动，需要设计藏宝图，用最准确的线索帮助同伴寻宝"

二、校园寻宝设计活动流程（10分钟）
1.设计任务（4分钟）
每组在校园平面图上标注2个"宝藏点"
制作寻宝线索卡，要求：
	每个点用"方向+角度+距离"描述
	可在1个宝藏点设置一个干扰项（如缺少距离信息）
2.寻宝挑战（4分钟）
交换线索卡，根据描述寻找对方宝藏
记录寻宝过程中的困惑点
3.反思改进（2分钟）
分析干扰项导致的寻宝失败案例
优化线索卡，补充完整三要素

三、活动设计亮点说明：
1.情境闭环：
课堂引入（家校位置）→游戏应用（寻宝图）形成认知闭环
2.错误分析机制
故意设置的干扰项促使学生自主发现三要素必要性，寻宝失败案例成为最佳教学资源
3．核心素养落实：
空间观念：通过实地场景与平面图的多次转换强化
应用意识：解决真实的位置描述问题
创新意识：自主设计寻宝线索`;

export default function TeachingDesignPage() {
    const [unitInfo, setUnitInfo] = useState({
        discipline: '数学',
        grade: '五年级',
        term: '下学期',
        unit: '第六单元',
        lessonName: '确定位置',
        version: '北师大版',
        objectives: [
            '通过具体活动，初步理解北偏东（西）、南偏东（西）的含义，会用方向、角度和距离描述物体的位置，并能在观测点变化中，重新确定位置。',
            '经历用方向和距离确定物体的位置的方法的探索过程，进一步培养观察能力，识图能力和有条理的进行表达的能力，发展空间观念。',
            '进一步体验数学与生活的密切联系，增强用数学的眼光观察生活、解决问题的意识和能力。'
        ] as string[],
        supplement: '',
        previousLessons: [] as string[],
    });

    const [modules, setModules] = useState({
        qaChain: '',
        qaObjectives: [] as string[],
        scenario: '',
        activityObjectives: [] as string[], // Store selected questions for activity
    });

    const [qaQuestions, setQaQuestions] = useState<string[]>([]);

    // Function to extract questions from QA content
    const extractQuestions = (content: string) => {
        const regex = /(\d+、[^：]+：“[^”]+”)/g;
        const matches = content.match(regex);
        // Also try standard dot notation if '、' isn't used globally, but default content uses '、'
        return matches || [];
    };

    const updateModule = (key: keyof typeof modules, value: any) => {
        setModules(prev => ({ ...prev, [key]: value }));

        // If QA chain is updated, extract questions for the next module
        if (key === 'qaChain') {
            const questions = extractQuestions(value);
            setQaQuestions(questions);
        }
    };

    // Content for the free-edit document on the right
    const [documentContent, setDocumentContent] = useState('');
    const [isGeneratingDesign, setIsGeneratingDesign] = useState(false);
    const [aiCommand, setAiCommand] = useState('');
    const [isAiProcessing, setIsAiProcessing] = useState(false);

    // Track if user has manually edited the document to prevent auto-overwrites
    const [isDocumentEdited, setIsDocumentEdited] = useState(false);

    // Initial generation logic - only triggers when unit/lesson changes from initial values
    useEffect(() => {
        if (unitInfo.unit && unitInfo.lessonName) {
            let generatedObjectives: string[] = [];
            if (unitInfo.lessonName === "确定位置") {
                generatedObjectives = [
                    '通过具体活动，初步理解北偏东（西）、南偏东（西）的含义，会用方向、角度和距离描述物体的位置，并能在观测点变化中，重新确定位置。',
                    '经历用方向和距离确定物体的位置的方法的探索过程，进一步培养观察能力，识图能力和有条理的进行表达的能力，发展空间观念。',
                    '进一步体验数学与生活的密切联系，增强用数学的眼光观察生活、解决问题的意识和能力。'
                ];
            } else if (unitInfo.lessonName === "背影") {
                generatedObjectives = [
                    "掌握《背影》中的关键词语，理解其深刻含义。",
                    "学习通过细节描写刻画人物的方法。",
                    "体会作者对父亲深沉的爱，培养孝敬父母的感情。"
                ];
            } else if (unitInfo.lessonName === "白杨礼赞") {
                generatedObjectives = [
                    "理解白杨树的象征意义。",
                    "学习欲扬先抑的写作手法。",
                    "感受中华民族质朴、坚韧、力求上进的精神。"
                ];
            } else if (unitInfo.lessonName === "荷塘月色") {
                generatedObjectives = [
                    "欣赏荷塘月色的美景，领悟情景交融的写作手法。",
                    "品味语言，学习作者运用语言的技巧。",
                    "体会作者在朦胧的月色下所流露出的淡淡的喜悦和淡淡的哀愁。"
                ];
            } else {
                generatedObjectives = [
                    "知识与能力：掌握本课重点生字词。",
                    "过程与方法：通过朗读感知文章内容。",
                    "情感态度与价值观：激发学生学习兴趣。"
                ];
            }

            // Always update objective when lesson changes for demo purposes
            setUnitInfo(prev => ({ ...prev, objectives: generatedObjectives }));
        }
    }, [unitInfo.unit, unitInfo.lessonName]); // Removed objectiveContent dep

    // Construct the document content whenever left-side inputs change, 
    // BUT only if the user hasn't started manually editing the right side heavily 
    // OR if they explicitly ask to regenerate.
    // simpler approach: The right side is a View. We update it when left side changes 
    // UNLESS we want to support independent editing.
    // User asked for "all editable".
    // Strategy: We keep `documentContent` synced until user edits it? 
    // OR easier: The right side IS the source of truth for the FINAL doc.
    // Let's make a `useEffect` that constructs the text, but only sets it if !isDocumentEdited.
    useEffect(() => {
        if (!isDocumentEdited) {
            const doc = `【基本信息】
年级：${unitInfo.grade}
学期：${unitInfo.term}
学科：${unitInfo.discipline}
教材：${unitInfo.version}
单元：${unitInfo.unit}
课时：${unitInfo.lessonName}

【课时目标】
${unitInfo.objectives?.map((obj, i) => `${i + 1}. ${obj}`).join('\n') || '(暂无)'}

${unitInfo.supplement ? `【补充信息】\n${unitInfo.supplement}\n` : ''}${unitInfo.previousLessons && unitInfo.previousLessons.length > 0 ? `【前序课例】\n${unitInfo.previousLessons.map((lesson, i) => `${i + 1}. ${lesson}`).join('\n')}\n` : ''}
【问题链设计】
${modules.qaChain || '(暂无)'}

【活动设计】
${modules.scenario || '(暂无)'}`;
            setDocumentContent(doc);
        }
    }, [unitInfo, modules, isDocumentEdited]);


    const handleGenerateDesign = () => {
        setIsGeneratingDesign(true);
        // Reset edited state so we can overwrite with fresh data if needed, 
        // OR just simulate an AI generation that updates the right side.
        setTimeout(() => {
            setIsGeneratingDesign(false);
            // Here we could forcefully update the documentContent if we wanted
            // For now, just alert.
            setIsDocumentEdited(false); // Snap back to sync mode or force update
            alert('教学设计已生成！右侧内容已更新。');
        }, 1500);
    };

    const handleSaveQAChain = () => {
        alert('问题链已保存！');
    };

    const handleSaveScenario = () => {
        alert('情境已保存！');
    };

    const handleDownloadWord = () => {
        alert('开始下载Word文档...');
    };

    const handleAiCommandSubmit = () => {
        if (!aiCommand.trim()) return;
        setIsAiProcessing(true);
        setTimeout(() => {
            setIsAiProcessing(false);
            const refinement = `\n\n[AI优化]: 根据指令"${aiCommand}"，已优化...`;
            setDocumentContent(prev => prev + refinement);
            setAiCommand('');
            // Mark as edited so we don't overwrite this new content with auto-sync
            setIsDocumentEdited(true);
            alert(`已根据"${aiCommand}"优化教学设计内容`);
        }, 1500);
    };

    return (
        <div className={styles.container}>
            {/* Left Column: Design Tools */}
            <div className={styles.leftColumn}>
                <div className={styles.scrollableContent}>
                    <UnitBasicInfo
                        info={unitInfo}
                        onChange={(key: string, value: any) => setUnitInfo(prev => ({ ...prev, [key]: value }))}
                    />

                    <DesignModule
                        title="问题链设计"
                        value={modules.qaChain}
                        onChange={(val: string) => updateModule('qaChain', val)}
                        availableObjectives={unitInfo.objectives}
                        selectedObjectives={modules.qaObjectives}
                        onObjectiveChange={(selected) => updateModule('qaObjectives', selected)}
                        defaultContent={QA_CHAIN_DEFAULT_CONTENT}
                        placeholder="点击'问AI'生成问题链设计..."
                        saveButtonLabel="保存问题链"
                        onSave={handleSaveQAChain}
                    />

                    <DesignModule
                        title="活动设计"
                        value={modules.scenario}
                        onChange={(val: string) => updateModule('scenario', val)}
                        availableObjectives={qaQuestions} // Pass extracted questions here
                        selectedObjectives={modules.activityObjectives}
                        onObjectiveChange={(selected) => updateModule('activityObjectives', selected)}
                        dropdownLabel="关联问题"
                        defaultContent={ACTIVITY_DESIGN_DEFAULT_CONTENT}
                        placeholder="点击'问AI'生成活动设计..."
                        saveButtonLabel="保存活动"
                        onSave={handleSaveScenario}
                    />

                    <div className={styles.generateSection}>
                        <button
                            className={styles.generateBtn}
                            onClick={handleGenerateDesign}
                            disabled={isGeneratingDesign}
                        >
                            <SparklesIcon />
                            <span>{isGeneratingDesign ? '生成中...' : '生成教学设计'}</span>
                        </button>
                    </div>
                </div>
            </div>

            {/* Right Column: Preview / Document */}
            <div className={styles.rightColumn}>
                <div className={styles.header}>
                    <h2>教学设计内容</h2>
                    <button className={styles.downloadBtn} onClick={handleDownloadWord} title="下载Word文档">
                        <DownloadIcon />
                        <span>下载Word</span>
                    </button>
                </div>

                {/* Unified Editable Document Area */}
                <div className={styles.previewContent}>
                    <textarea
                        className={styles.fullDocumentEditor}
                        value={documentContent}
                        onChange={(e) => {
                            setDocumentContent(e.target.value);
                            setIsDocumentEdited(true);
                        }}
                        placeholder="教学设计内容为空..."
                    />

                    {/* Space for floating bar */}
                    <div style={{ height: '80px' }}></div>
                </div>

                {/* Floating Input Bar within Right Column */}
                <div className={styles.floatingBar}>
                    <div className={styles.floatingInputWrapper}>
                        <div className={styles.aiIcon}>
                            <SparklesIcon />
                        </div>
                        <input
                            type="text"
                            className={styles.floatingInput}
                            placeholder="输入指令，AI帮您优化教学设计..."
                            value={aiCommand}
                            onChange={(e) => setAiCommand(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && handleAiCommandSubmit()}
                            disabled={isAiProcessing}
                        />
                        <button
                            className={styles.sendBtn}
                            onClick={handleAiCommandSubmit}
                            disabled={!aiCommand.trim() || isAiProcessing}
                        >
                            <SendIcon />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
