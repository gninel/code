"use client";

import React, { useState } from 'react';
import styles from './TeachingGoalEditor.module.css';

interface Goal {
    id: string;
    type: 'knowledge' | 'ability' | 'value';
    content: string;
}

export default function TeachingGoalEditor() {
    const [goals, setGoals] = useState<Goal[]>([
        { id: '1', type: 'knowledge', content: '学生能够准确复述《背影》中四次背影的描写及其情感内涵。' },
        { id: '2', type: 'ability', content: '通过比较阅读与细节分析，提升对散文“形散神不散”特点的鉴赏能力。' },
        { id: '3', type: 'value', content: '体会父爱的深沉与含蓄，反思自己与亲人的相处模式，培养感恩意识。' },
    ]);

    const handleContentChange = (id: string, newContent: string) => {
        setGoals(goals.map(g => g.id === id ? { ...g, content: newContent } : g));
    };

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <div className={styles.title}>
                    <span>🎯 教学目标设计</span>
                </div>
                <div className={styles.actions}>
                    <button className={styles.actionBtn}>重置</button>
                    <button className={`${styles.actionBtn} ${styles.primaryBtn}`}>确认锁定</button>
                </div>
            </div>

            <div className={styles.section}>
                <div className={styles.sectionTitle}>核心素养目标 (AI 推荐)</div>

                {goals.map((goal) => (
                    <div key={goal.id} className={styles.goalCard}>
                        <div className={styles.goalType}>
                            {goal.type === 'knowledge' ? '知识与技能' :
                                goal.type === 'ability' ? '过程与方法' : '情感态度价值观'}
                        </div>
                        <div
                            className={styles.goalContent}
                            contentEditable
                            suppressContentEditableWarning
                            onBlur={(e) => handleContentChange(goal.id, e.currentTarget.textContent || '')}
                        >
                            {goal.content}
                        </div>
                        <div className={styles.toolbar}>
                            <button className={styles.toolBtn}>✨ 润色</button>
                            <button className={styles.toolBtn}>🔄 换一换</button>
                        </div>
                    </div>
                ))}
            </div>

            <div className={styles.section}>
                <div className={styles.sectionTitle}>校本化调整</div>
                <div className={`${styles.goalCard} ${styles.addCard}`} style={{ borderStyle: 'dashed', textAlign: 'center', cursor: 'pointer' }}>
                    <span style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>+ 添加自定义目标</span>
                </div>
            </div>
        </div>
    );
}
