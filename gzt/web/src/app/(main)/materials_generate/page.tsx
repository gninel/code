"use client";

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import styles from './page.module.css';

// Icons
const CloseIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
    </svg>
);

const DownloadIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
        <polyline points="7 10 12 15 17 10"></polyline>
        <line x1="12" y1="15" x2="12" y2="3"></line>
    </svg>
);

const FullscreenIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="15 3 21 3 21 9"></polyline>
        <polyline points="9 21 3 21 3 15"></polyline>
        <line x1="21" y1="3" x2="14" y2="10"></line>
        <line x1="3" y1="21" x2="10" y2="14"></line>
    </svg>
);

const FileIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
        <polyline points="14 2 14 8 20 8"></polyline>
        <line x1="16" y1="13" x2="8" y2="13"></line>
        <line x1="16" y1="17" x2="8" y2="17"></line>
        <polyline points="10 9 9 9 8 9"></polyline>
    </svg>
);

const BotAvatar = () => (
    <div className={styles.botAvatar}>
        <span>✨</span>
    </div>
);

function MaterialsGenerateContent() {
    const searchParams = useSearchParams();
    const router = useRouter();
    const initialPrompt = searchParams.get('prompt') || '';

    // Mock States
    const [messages, setMessages] = useState<any[]>([]);
    const [isGenerating, setIsGenerating] = useState(false);

    useEffect(() => {
        if (initialPrompt) {
            setMessages([{ role: 'user', content: initialPrompt }]);
            setIsGenerating(true);

            // Mock System Response
            setTimeout(() => {
                setMessages(prev => [
                    ...prev,
                    { role: 'assistant', content: '我来根据您的要求生成互动完形填空网页，特别关注您提到的6个改进点...' }
                ]);
                setIsGenerating(false);
            }, 1000);
        }
    }, [initialPrompt]);

    const handleClose = () => {
        router.push('/materials');
    };

    return (
        <div className={styles.container}>
            {/* Header */}
            <div className={styles.header}>
                <div className={styles.headerLeft}>
                    <span className={styles.brand}>飞象老师</span>
                    <span className={styles.divider}>|</span>
                    <span className={styles.title}>完形填空-讲评模板</span>
                </div>
                <div className={styles.headerRight}>
                    <button className={styles.closeBtn} onClick={handleClose}>
                        <CloseIcon />
                    </button>
                </div>
            </div>

            {/* Split Content */}
            <div className={styles.content}>
                {/* Left: Chat / Process */}
                <div className={styles.leftPanel}>
                    {messages.map((msg, idx) => (
                        <div key={idx} className={`${styles.message} ${msg.role === 'user' ? styles.userMsg : styles.aiMsg}`}>
                            {msg.role === 'user' ? (
                                <div className={styles.msgBubbleUser}>{msg.content}</div>
                            ) : (
                                <div className={styles.aiContainer}>
                                    <BotAvatar />
                                    <div className={styles.msgContent}>
                                        <div className={styles.statusLabel}>
                                            ⌛ 过程输出
                                        </div>
                                        <div className={styles.msgText}>{msg.content}</div>

                                        {/* Mock Generated File Link in Chat */}
                                        <div className={styles.fileLink}>
                                            <div className={styles.fileIcon}>
                                                <span style={{ color: '#22c55e', fontWeight: 'bold' }}>{'</>'}</span>
                                            </div>
                                            <div className={styles.fileName}>互动完形填空 - 苹果蛋糕的回忆.html</div>
                                            <button className={styles.miniDownloadBtn}>⬇ 下载</button>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </div>
                    ))}

                    {/* Pending State */}
                    <div className={styles.pendingInput}>
                        {isGenerating ? (
                            <div className={styles.loadingStatus}><span>✨</span> 正在回放任务中...</div>
                        ) : (
                            <button className={styles.resultBtn}>直接查看结果</button>
                        )}
                    </div>
                </div>

                {/* Right: Preview */}
                <div className={styles.rightPanel}>
                    <div className={styles.previewHeader}>
                        <h3>文件预览</h3>
                        <div className={styles.previewActions}>
                            <button className={styles.actionLink}><FullscreenIcon /> 全屏浏览</button>
                            <button className={styles.actionLink}><DownloadIcon /> 下载</button>
                        </div>
                    </div>

                    <div className={styles.previewCard}>
                        {/* Mock Header of Card */}
                        <div className={styles.previewCardHeader}>
                            <div className={styles.fileIconSmall}>HTML</div>
                            <span>互动完形填空 - 苹果蛋糕的回忆.html</span>
                        </div>

                        {/* Interactive Content Mock */}
                        <div className={styles.interactiveArea}>
                            <div className={styles.interactiveTitle}>互动完形填空练习</div>
                            <div className={styles.interactiveSubtitle}>苹果蛋糕的回忆 - 点击句子听朗读，选择正确答案填空</div>

                            <div className={styles.legend}>
                                <span className={styles.legendItem} style={{ '--color': '#f97316' } as any}>逻辑线索</span>
                                <span className={styles.legendItem} style={{ '--color': '#14b8a6' } as any}>原词复现</span>
                                <span className={styles.legendItem} style={{ '--color': '#a855f7' } as any}>情感线索</span>
                            </div>

                            <div className={styles.passage}>
                                The New Year party was usually held at my aunt's house and my favorite part was the <span className={styles.highlight}>apple cake</span>.
                            </div>
                        </div>

                        {/* Bottom File List Mock */}
                        <div className={styles.bottomFiles}>
                            <div>生成文件 2/2</div>
                            <div className={styles.fileList}>
                                <div className={styles.fileChip}>📄 互动完形填空... ⬇</div>
                                <div className={styles.fileChip}>📄 互动完形填空... ⬇</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default function MaterialsGeneratePage() {
    return (
        <Suspense fallback={<div style={{ padding: '2rem' }}>Loading...</div>}>
            <MaterialsGenerateContent />
        </Suspense>
    );
}
