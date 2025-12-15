"use client";

import React, { useState } from 'react';
import styles from './page.module.css';
import HomeworkGallery from '@/components/Homework/HomeworkGallery';

// Icons
const ArrowUpIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="12" y1="19" x2="12" y2="5" />
        <polyline points="5 12 12 5 19 12" />
    </svg>
);

const ChevronDownIcon = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m6 9 6 6 6-6" />
    </svg>
);

export default function HomeworkPage() {
    const [activeTab, setActiveTab] = useState<'design' | 'analysis'>('design');
    const [inputValue, setInputValue] = useState('');

    // Mock Dropdown States
    const [gradeSubject, setGradeSubject] = useState('小学数学');
    const [textbook, setTextbook] = useState('人教版');
    const [chapter, setChapter] = useState('第一单元 认识图形');
    const [lesson, setLesson] = useState('第一课时 认识平面图形');

    const handleGenerate = () => {
        if (!inputValue.trim()) return;
        console.log("Generating homework for:", inputValue);
        // Add generation logic here
    };

    return (
        <div className={styles.container}>
            {/* Background Decorations */}
            <div className={styles.bgDecoration1}></div>
            <div className={styles.bgDecoration2}></div>

            <div className={styles.mainContent}>

                <div className={styles.tabSwitch}>
                    <button
                        className={`${styles.tabBtn} ${activeTab === 'design' ? styles.activeTab : ''}`}
                        onClick={() => setActiveTab('design')}
                    >
                        ⚡ 作业设计
                    </button>
                    <button
                        className={`${styles.tabBtn} ${activeTab === 'analysis' ? styles.activeTab : ''}`}
                        onClick={() => setActiveTab('analysis')}
                    >
                        📊 作业分析
                    </button>
                </div>

                <div className={styles.inputCard}>
                    {/* Header with label removed per request */}

                    <textarea
                        className={styles.mainInput}
                        placeholder="输入学情特点要求"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyDown={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey) {
                                e.preventDefault();
                                handleGenerate();
                            }
                        }}
                    />

                    <div className={styles.cardActions}>
                        <div className={styles.dropdownGroup}>
                            <div className={styles.dropdownTrigger}>
                                <span className={styles.tagIcon}>🎓</span>
                                <span>{gradeSubject}</span>
                                <ChevronDownIcon />
                            </div>
                            <div className={styles.dropdownTrigger}>
                                <span className={styles.tagIcon}>📚</span>
                                <span>{textbook}</span>
                                <ChevronDownIcon />
                            </div>
                            <div className={styles.dropdownTrigger}>
                                <span className={styles.tagIcon}>📖</span>
                                <span>{chapter}</span>
                                <ChevronDownIcon />
                            </div>
                            <div className={styles.dropdownTrigger}>
                                <span className={styles.tagIcon}>📑</span>
                                <span>{lesson}</span>
                                <ChevronDownIcon />
                            </div>
                        </div>

                        <button
                            className={styles.generateBtn}
                            onClick={handleGenerate}
                            disabled={!inputValue.trim()}
                        >
                            <ArrowUpIcon />
                        </button>
                    </div>
                </div>

                <HomeworkGallery />
            </div>
        </div>
    );
}
