"use client";

import React from 'react';
import styles from './QAChainEditor.module.css';

export default function QAChainEditor() {
    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <div className={styles.title}>
                    <span>🔗 问答链设计</span>
                    <span className={styles.chainLogic}>逻辑：层进式</span>
                </div>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button style={{ fontSize: '0.85rem', color: 'var(--primary)' }}>+ 添加主问题</button>
                </div>
            </div>

            <div className={styles.mainQuestionCard}>
                <span className={styles.label}>核心主问题</span>
                <div className={styles.questionText}>
                    作者在文中四次描写背影，为什么只有买橘子的背影写得最详细？这体现了怎样的父爱？
                </div>
            </div>

            <div className={styles.subQuestionsList}>
                <div className={styles.subQuestionItem}>
                    <div className={`${styles.tag} ${styles.what}`}>WHAT (现象)</div>
                    <div className={styles.content}>
                        请找出文中描写父亲买橘子时的动作词，这些动作说明了什么？
                    </div>
                    <div className={styles.toolbar}>
                        <button className={styles.toolBtn}>关联目标1</button>
                        <button className={styles.toolBtn}>生成活动</button>
                    </div>
                </div>

                <div className={styles.subQuestionItem}>
                    <div className={`${styles.tag} ${styles.why}`}>WHY (原因)</div>
                    <div className={styles.content}>
                        父亲身体肥胖，行动不便，为什么还要坚持亲自去买橘子？
                    </div>
                    <div className={styles.toolbar}>
                        <button className={styles.toolBtn}>关联目标3</button>
                        <button className={styles.toolBtn}>生成活动</button>
                    </div>
                </div>

                <div className={styles.subQuestionItem}>
                    <div className={`${styles.tag} ${styles.how}`}>HOW (深层)</div>
                    <div className={styles.content}>
                        这种“笨拙”的努力，与你平时感受到的父爱有什么相似之处？
                    </div>
                    <div className={styles.toolbar}>
                        <button className={styles.toolBtn}>关联目标3</button>
                        <button className={styles.toolBtn}>生成作业</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
