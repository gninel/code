"use client";

import React from 'react';
import styles from './ScenarioActivityEditor.module.css';

export default function ScenarioActivityEditor() {
    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <div className={styles.title}>
                    <span>🎭 情境与活动设计</span>
                </div>
                <button style={{ fontSize: '0.85rem', color: 'var(--primary)' }}>+ 添加活动环节</button>
            </div>

            <div className={styles.timeline}>
                <div className={styles.timelineItem}>
                    <div className={`${styles.timelineDot} ${styles.active}`} />
                    <div className={styles.activityCard}>
                        <div className={styles.activityHeader}>
                            <span className={styles.activityTitle}>环节一：情境导入</span>
                            <span className={styles.activityDuration}>⏱️ 5分钟</span>
                        </div>
                        <div className={styles.activityContent}>
                            <div className={styles.scenarioBox}>
                                <span className={styles.scenarioLabel}>情境创设</span>
                                <div className={styles.scenarioText}>
                                    播放歌曲《父亲》，展示一组不同年代的父亲背影照片（黑白到彩色），引导学生回忆自己印象中父亲的背影。
                                </div>
                            </div>
                            <div className={styles.stepsList}>
                                <div className={styles.step}>
                                    <span className={styles.stepNumber}>1.</span>
                                    <span>教师播放多媒体素材，营造温情氛围。</span>
                                </div>
                                <div className={styles.step}>
                                    <span className={styles.stepNumber}>2.</span>
                                    <span>提问：看到这些照片，你想到了什么？（预热问答）</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className={styles.timelineItem}>
                    <div className={`${styles.timelineDot} ${styles.active}`} />
                    <div className={styles.activityCard}>
                        <div className={styles.activityHeader}>
                            <span className={styles.activityTitle}>环节二：文本细读与探究</span>
                            <span className={styles.activityDuration}>⏱️ 20分钟</span>
                        </div>
                        <div className={styles.activityContent}>
                            <div className={styles.scenarioBox}>
                                <span className={styles.scenarioLabel}>任务驱动</span>
                                <div className={styles.scenarioText}>
                                    假设你是电影导演，要拍摄“买橘子”这一经典片段，你会如何设计特写镜头？请小组合作完成分镜头脚本。
                                </div>
                            </div>
                            <div className={styles.stepsList}>
                                <div className={styles.step}>
                                    <span className={styles.stepNumber}>1.</span>
                                    <span>学生分组（4人一组），圈画文中描写父亲动作的词语（攀、缩、倾）。</span>
                                </div>
                                <div className={styles.step}>
                                    <span className={styles.stepNumber}>2.</span>
                                    <span>小组讨论：为什么要用这些词？如果换成“走过去”、“拿橘子”好不好？</span>
                                </div>
                                <div className={styles.step}>
                                    <span className={styles.stepNumber}>3.</span>
                                    <span>各组代表分享“分镜头脚本”设计思路，教师点评并关联“核心主问题”。</span>
                                </div>
                            </div>
                            <div className={styles.tags}>
                                <span className={styles.tag}>小组合作</span>
                                <span className={styles.tag}>角色扮演</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
