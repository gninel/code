"use client";

import React from 'react';
import styles from './HomeworkEditor.module.css';

export default function HomeworkEditor() {
    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <div className={styles.title}>
                    <span>📝 AI 作业设计</span>
                </div>
                <div className={styles.stats}>
                    <div className={styles.statItem}>
                        <span>目标覆盖率:</span>
                        <span style={{ color: 'var(--primary)', fontWeight: 600 }}>100%</span>
                    </div>
                    <div className={styles.statItem}>
                        <span>预计用时:</span>
                        <span>15分钟</span>
                    </div>
                </div>
            </div>

            <div className={styles.section}>
                <div className={styles.sectionHeader}>
                    <div className={styles.sectionTitle}>基础巩固 (必做)</div>
                    <span className={`${styles.difficultyBadge} ${styles.basic}`}>难度: ⭐</span>
                </div>

                <div className={styles.questionCard}>
                    <div className={styles.questionHeader}>
                        <span className={styles.questionType}>填空题</span>
                        <span className={styles.targetRef}>🎯 对应目标1</span>
                    </div>
                    <div className={styles.questionContent}>
                        文中四次写到背影，分别是：点题的背影、________的背影、________的背影、________的背影。
                    </div>
                    <div className={styles.actions}>
                        <button className={styles.actionBtn}>查看解析</button>
                        <button className={styles.actionBtn}>换一题</button>
                    </div>
                </div>
            </div>

            <div className={styles.section}>
                <div className={styles.sectionHeader}>
                    <div className={styles.sectionTitle}>能力提升 (选做)</div>
                    <span className={`${styles.difficultyBadge} ${styles.advanced}`}>难度: ⭐⭐</span>
                </div>

                <div className={styles.questionCard}>
                    <div className={styles.questionHeader}>
                        <span className={styles.questionType}>简答题</span>
                        <span className={styles.targetRef}>🎯 对应目标2</span>
                    </div>
                    <div className={styles.questionContent}>
                        作者说“我那时真是聪明过分”，这里的“聪明”是什么意思？表达了作者怎样的情感？
                    </div>
                    <div className={styles.actions}>
                        <button className={styles.actionBtn}>查看解析</button>
                        <button className={styles.actionBtn}>换一题</button>
                    </div>
                </div>
            </div>

            <div className={styles.section}>
                <div className={styles.sectionHeader}>
                    <div className={styles.sectionTitle}>思维拓展 (挑战)</div>
                    <span className={`${styles.difficultyBadge} ${styles.challenge}`}>难度: ⭐⭐⭐</span>
                </div>

                <div className={styles.questionCard}>
                    <div className={styles.questionHeader}>
                        <span className={styles.questionType}>探究题</span>
                        <span className={styles.targetRef}>🎯 对应目标3</span>
                    </div>
                    <div className={styles.questionContent}>
                        结合问答链中的“深层”问题，谈谈你对“父爱如山，母爱如水”的理解，并写一段关于父亲的细节描写（100字左右）。
                    </div>
                    <div className={styles.actions}>
                        <button className={styles.actionBtn}>查看解析</button>
                        <button className={styles.actionBtn}>换一题</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
