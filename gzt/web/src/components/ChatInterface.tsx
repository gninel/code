"use client";

import React, { useState } from 'react';
import styles from './ChatInterface.module.css';

// Icons
const BrainIcon = () => (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z" />
        <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z" />
    </svg>
);

const AttachmentIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48" />
    </svg>
);

const ImageIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect width="18" height="18" x="3" y="3" rx="2" ry="2" />
        <circle cx="9" cy="9" r="2" />
        <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" />
    </svg>
);

const MicIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
        <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
        <line x1="12" x2="12" y1="19" y2="22" />
    </svg>
);

const ArrowUpIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m5 12 7-7 7 7" />
        <path d="M12 19V5" />
    </svg>
);

const SparklesIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
    </svg>
);

import GenerationResult from './GenerationResult';

export default function ChatInterface() {
    const [inputValue, setInputValue] = useState('');
    const [activeTab, setActiveTab] = useState('chain');
    const [hasResult, setHasResult] = useState(false);

    if (hasResult) {
        return <GenerationResult />;
    }

    return (
        <div className={styles.container}>
            <div className={styles.welcomeSection}>
                <div className={styles.logo}>
                    <BrainIcon />
                </div>
                <h1 className={styles.title}>Hi, 我是您的思辨教学助手</h1>
                <p className={styles.subtitle}>
                    输入教学主题，一键生成<span className={styles.highlight}>启发式问答链</span>，培养学生高阶思维。
                </p>
            </div>

            <div className={styles.inputCard}>
                <div className={styles.tabs}>
                    <div
                        className={`${styles.tab} ${activeTab === 'chain' ? styles.active : ''}`}
                        onClick={() => setActiveTab('chain')}
                    >
                        <SparklesIcon />
                        问答链生成
                    </div>
                    <div
                        className={`${styles.tab} ${activeTab === 'outline' ? styles.active : ''}`}
                        onClick={() => setActiveTab('outline')}
                    >
                        📄 教案大纲
                    </div>
                    <div
                        className={`${styles.tab} ${activeTab === 'target' ? styles.active : ''}`}
                        onClick={() => setActiveTab('target')}
                    >
                        🎯 教学目标
                    </div>
                </div>

                <div className={styles.inputArea}>
                    <textarea
                        className={styles.textarea}
                        placeholder="请输入课程名称（如《背影》）或核心知识点。&#10;示例：请为初二学生生成关于《背影》的层进式问答链，引导学生思考父爱表达的含蓄与深沉，包含追问逻辑。"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyDown={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey && inputValue.trim()) {
                                e.preventDefault();
                                setHasResult(true);
                            }
                        }}
                    />
                </div>

                <div className={styles.actions}>
                    <div className={styles.tools}>
                        <button className={styles.toolBtn} title="上传文件">
                            <AttachmentIcon />
                        </button>
                        <button className={styles.toolBtn} title="上传图片">
                            <ImageIcon />
                        </button>
                    </div>

                    <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                        <button className={styles.toolBtn} title="语音输入">
                            <MicIcon />
                        </button>
                        <button
                            className={`${styles.submitBtn} ${inputValue.trim() ? styles.active : ''}`}
                            disabled={!inputValue.trim()}
                            onClick={() => setHasResult(true)}
                        >
                            <ArrowUpIcon />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
