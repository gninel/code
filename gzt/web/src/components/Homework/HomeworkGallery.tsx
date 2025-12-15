"use client";

import React, { useState } from 'react';
import styles from './HomeworkGallery.module.css';

// Mock Data
const MOCK_HOMEWORK = [
    {
        id: 1,
        title: '小学数学 - 基础几何认知',
        author: '张老师',
        likes: 1205,
        subject: '数学',
        image: 'https://images.unsplash.com/photo-1596495577886-d920f1fb7238?q=80&w=600&auto=format&fit=crop', // Valid Geometry image
        tag: '一年级'
    },
    {
        id: 2,
        title: '初中语文 - 古诗词鉴赏专项',
        author: '李老师',
        likes: 892,
        subject: '语文',
        bg: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
        isCard: true,
        summary: '精选古诗词鉴赏题目，包含详细解析和答题技巧...',
        tag: '七年级'
    },
    {
        id: 3,
        title: '高中英语 - 完形填空高频词汇',
        author: '王老师',
        likes: 2310,
        subject: '英语',
        bg: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
        isCard: true,
        summary: '历年高考真题高频词汇汇总，并通过语境记忆...',
        tag: '高三'
    },
    {
        id: 4,
        title: '趣味科学小实验 - 物理篇',
        author: '科学探究组',
        likes: 1540,
        subject: '其他',
        image: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?q=80&w=600&auto=format&fit=crop',
        tag: '综合实践'
    }
];

const TABS = ['全部', '数学', '语文', '英语', '其他'];

export default function HomeworkGallery() {
    const [activeTab, setActiveTab] = useState('全部');

    const filteredItems = activeTab === '全部'
        ? MOCK_HOMEWORK
        : MOCK_HOMEWORK.filter(m => m.subject === activeTab);

    return (
        <div className={styles.galleryWrapper}>
            <div className={styles.tabBar}>
                <div className={styles.tabs}>
                    {TABS.map(tab => (
                        <div
                            key={tab}
                            className={`${styles.tabItem} ${activeTab === tab ? styles.active : ''}`}
                            onClick={() => setActiveTab(tab)}
                        >
                            {tab}
                            {tab === '数学' && <span className={styles.hotTag}>Hot</span>}
                        </div>
                    ))}
                </div>
                <div className={styles.searchBar}>
                    <input type="text" placeholder="输入知识点搜索资源" className={styles.searchInput} />
                </div>
            </div>

            <div className={styles.grid}>
                {filteredItems.map(item => (
                    <div key={item.id} className={styles.card}>
                        <div
                            className={styles.cardPreview}
                            style={{
                                background: item.bg || `url(${item.image}) center/cover no-repeat`,
                                backgroundColor: '#e2e8f0'
                            }}
                        >
                            {/* Specific content for 'Card' type items like text previews */}
                            {item.isCard && item.summary && (
                                <div className={styles.cardContentPreview}>
                                    <div className={styles.cardTitleOverlay}>{item.title}</div>
                                    <div className={styles.cardText}>{item.summary}</div>
                                </div>
                            )}
                            {item.tag && <div className={styles.imageTag}>{item.tag}</div>}
                        </div>
                        <div className={styles.cardFooter}>
                            <div className={styles.cardTitle}>{item.title}</div>
                            <div className={styles.cardMeta}>
                                <div className={styles.author}>
                                    <div className={styles.avatar}></div>
                                    <span>{item.author}</span>
                                </div>
                                <div className={styles.likes}>
                                    ❤️ {item.likes}
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
