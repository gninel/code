"use client";

import React, { useState } from 'react';
import styles from './MaterialGallery.module.css';

// Mock Data
const MOCK_MATERIALS = [
    {
        id: 1,
        title: '生成荷塘月色 - 沉浸式体验',
        author: '伍月',
        likes: 5348,
        subject: '语文',
        image: 'https://images.unsplash.com/photo-1528722828814-77b9b83aafb2?q=80&w=600&auto=format&fit=crop', // Beautiful lotus pond with moonlight
        tag: '荷塘月色'
    },
    {
        id: 2,
        title: '互动完形填空练习 - 苹果蛋糕的回忆',
        author: '海淀老师勇闯AI圈',
        likes: 4779,
        subject: '英语',
        bg: 'linear-gradient(135deg, #10b981 0%, #059669 100%)', // Match reference Green card
        isCard: true,
        summary: 'The New Year party was usually held at my aunt\'s house...'
    },
    {
        id: 3,
        title: '几何动点轨迹探索',
        author: '数学王老师',
        likes: 3220,
        subject: '数学',
        image: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=600&auto=format&fit=crop', // Math/Graph image
    },
    {
        id: 4,
        title: '李白诗词云生成',
        author: '语文组长',
        likes: 2100,
        subject: '语文',
        bg: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
        isCard: true,
        summary: '君不见黄河之水天上来，奔流到海不复回...'
    }
];

const TABS = ['全部', '数学', '语文', '英语', '其他'];

export default function MaterialGallery() {
    const [activeTab, setActiveTab] = useState('全部');

    const filteredMaterials = activeTab === '全部'
        ? MOCK_MATERIALS
        : MOCK_MATERIALS.filter(m => m.subject === activeTab);

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
                {filteredMaterials.map(item => (
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
