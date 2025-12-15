"use client";

import React, { useState } from 'react';
import styles from './GenerationResult.module.css';
import TeachingGoalEditor from './TeachingGoalEditor';
import QAChainEditor from './QAChainEditor';
import HomeworkEditor from './HomeworkEditor';
import ScenarioActivityEditor from './ScenarioActivityEditor';

export default function GenerationResult() {
    const [activeTab, setActiveTab] = useState('goal'); // goal, chain, activity, homework

    return (
        <div className={styles.container}>
            <div className={styles.leftPanel}>
                <div className={styles.chatHistory}>
                    <div className={`${styles.message} ${styles.userMessage}`}>
                        请为初二学生生成关于《背影》的层进式问答链，引导学生思考父爱表达的含蓄与深沉。
                    </div>
                    <div className={`${styles.message} ${styles.aiMessage}`}>
                        好的，已为您生成《背影》的教学设计方案。
                        <br /><br />
                        <strong>设计思路：</strong><br />
                        1. 目标先行：确立情感体验与写作手法分析的双重目标。<br />
                        2. 问答链：采用“现象-原因-深层”的逻辑递进。
                    </div>
                </div>
                <div className={styles.inputArea}>
                    <textarea
                        className={styles.miniInput}
                        placeholder="继续对话，调整生成结果..."
                        rows={2}
                    />
                </div>
            </div>

            <div className={styles.rightPanel}>
                <div className={styles.tabs}>
                    <div
                        className={`${styles.tab} ${activeTab === 'goal' ? styles.active : ''}`}
                        onClick={() => setActiveTab('goal')}
                    >
                        🎯 教学目标
                    </div>
                    <div
                        className={`${styles.tab} ${activeTab === 'chain' ? styles.active : ''}`}
                        onClick={() => setActiveTab('chain')}
                    >
                        🔗 问答链
                    </div>
                    <div
                        className={`${styles.tab} ${activeTab === 'activity' ? styles.active : ''}`}
                        onClick={() => setActiveTab('activity')}
                    >
                        🎭 情境与活动
                    </div>
                    <div
                        className={`${styles.tab} ${activeTab === 'homework' ? styles.active : ''}`}
                        onClick={() => setActiveTab('homework')}
                    >
                        📝 AI作业
                    </div>
                </div>

                <div className={styles.contentArea}>
                    {activeTab === 'goal' && <TeachingGoalEditor />}
                    {activeTab === 'chain' && <QAChainEditor />}
                    {activeTab === 'activity' && <ScenarioActivityEditor />}
                    {activeTab === 'homework' && <HomeworkEditor />}
                </div>
            </div>
        </div>
    );
}
