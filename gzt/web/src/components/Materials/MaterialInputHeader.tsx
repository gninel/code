"use client";

import React, { useState } from 'react';
import styles from './MaterialInputHeader.module.css';

// Simple Icons
const MicIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
        <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
        <line x1="12" y1="19" x2="12" y2="23" />
        <line x1="8" y1="23" x2="16" y2="23" />
    </svg>
);

const UploadIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
        <polyline points="17 8 12 3 7 8" />
        <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
);

const ImageIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
        <circle cx="8.5" cy="8.5" r="1.5" />
        <polyline points="21 15 16 10 5 21" />
    </svg>
);

const ChevronDownIcon = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m6 9 6 6 6-6" />
    </svg>
);

const ArrowUpIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="12" y1="19" x2="12" y2="5" />
        <polyline points="5 12 12 5 19 12" />
    </svg>
);

interface Props {
    onGenerate: (prompt: string) => void;
}

export default function MaterialInputHeader({ onGenerate }: Props) {
    const [prompt, setPrompt] = useState('');

    // Mock Dropdown States for Teaching Design
    const [teachingDesign, setTeachingDesign] = useState('《背影》教学设计');

    const handleSubmit = () => {
        if (prompt.trim()) {
            onGenerate(prompt);
        }
    };

    return (
        <div className={styles.inputWrapper}>
            {/* Tag label removed per request */}
            <textarea
                className={styles.inputArea}
                placeholder="生成一个牛顿第一定律的初中物理在线演示实验"
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSubmit();
                    }
                }}
            />

            <div className={styles.actionRow}>
                <div className={styles.leftActions}>
                    <div className={styles.dropdownGroup}>
                        <div className={styles.dropdownTrigger}>
                            <span className={styles.tagIcon}>📚</span>
                            <span>{teachingDesign}</span>
                            <ChevronDownIcon />
                        </div>
                    </div>

                    <div className={styles.iconGroup}>
                        <button className={styles.iconBtn} title="上传文件">
                            <UploadIcon />
                        </button>
                        <button className={styles.iconBtn} title="上传图片">
                            <ImageIcon />
                        </button>
                    </div>
                </div>

                <div className={styles.rightActions}>
                    <button className={styles.iconBtn} title="语音输入">
                        <MicIcon />
                    </button>
                    <button
                        className={styles.sendBtn}
                        onClick={handleSubmit}
                        disabled={!prompt.trim()}
                    >
                        <ArrowUpIcon />
                    </button>
                </div>
            </div>
        </div>
    );
}
