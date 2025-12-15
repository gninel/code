"use client";

import React, { useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import styles from './Sidebar.module.css';

// Icons
const BrainIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z" />
        <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z" />
    </svg>
);

const BookIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
);

const PenIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z" />
    </svg>
);

const ChartIcon = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 3v18h18" />
        <path d="m19 9-5 5-4-4-3 3" />
    </svg>
);

// Removed ChevronDownIcon as it is no longer used

const MagicIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m5 8 6 6" />
        <path d="m4 14 6-6 2-3" />
        <path d="M2 12h10" />
        <path d="M10 2v10" />
        <path d="m20 20-6-6" />
        <path d="m14 20 6-6-2-3" />
        <path d="M22 12h-10" />
        <path d="M14 22v-10" />
    </svg>
); // Just a placeholder magic icon, or reuse sparkles

export default function Sidebar() {
    const pathname = usePathname();
    const useRouterHook = useRouter();
    // Removed isAiPrepExpanded state

    const handleNavigation = (path: string) => {
        useRouterHook.push(path);
    };

    const isActive = (path: string) => {
        if (path === '/' && pathname === '/') return true;
        if (path !== '/' && pathname.startsWith(path)) return true;
        return false;
    };

    return (
        <aside className={styles.sidebar}>
            <div className={styles.logo} onClick={() => handleNavigation('/design')} style={{ cursor: 'pointer' }}>
                <BrainIcon />
                <span>睿智教</span>
            </div>

            <div className={styles.navSection}>
                {/* Level 1: AI 备课 (Group Header - Non-clickable) */}
                <div className={styles.navGroup}>
                    <div className={styles.navGroupHeader}> {/* No onClick, always expanded */}
                        <div className={styles.navGroupHeaderContent}>
                            <BookIcon />
                            <span>AI 备课</span>
                        </div>
                        {/* No arrow icon needed as it's always expanded and not toggleable */}
                    </div>

                    {/* Always visible submenu */}
                    <div className={styles.subMenu}>
                        {/* Level 2: 教学设计 */}
                        <div
                            className={`${styles.subNavItem} ${isActive('/design') ? styles.active : ''}`}
                            onClick={() => handleNavigation('/design')}
                        >
                            <span>教学设计</span>
                        </div>
                        {/* Level 2: 素材创生 */}
                        <div
                            className={`${styles.subNavItem} ${isActive('/materials') ? styles.active : ''}`}
                            onClick={() => handleNavigation('/materials')}
                        >
                            <span>素材创生</span>
                        </div>
                    </div>
                </div>

                {/* Level 1: 作业设计 */}
                <div
                    className={`${styles.navItem} ${isActive('/homework') ? styles.active : ''}`}
                    onClick={() => handleNavigation('/homework')}
                >
                    <PenIcon />
                    <span>作业设计</span>
                </div>

                {/* Level 1: AI 评课 */}
                <div
                    className={`${styles.navItem} ${isActive('/evaluation') ? styles.active : ''}`}
                    onClick={() => handleNavigation('/evaluation')}
                >
                    <ChartIcon />
                    <span>AI 评课</span>
                </div>
            </div>

            <div className={`${styles.navSection} ${styles.historySection}`}>
                <div className={styles.navTitle}>历史任务</div>
                <div className={styles.historyItem}>
                    <span>📄 《背影》层进式问答链设计</span>
                </div>
                <div className={styles.historyItem}>
                    <span>📄 勾股定理逆向思维引导</span>
                </div>
                <div className={styles.historyItem}>
                    <span>📄 AI伦理辩论赛辩题生成</span>
                </div>
            </div>

            <div className={styles.userProfile}>
                <div className={styles.avatar}>尚</div>
                <div className={styles.userInfo}>
                    <span className={styles.userName}>张老师</span>
                    <span className={styles.userRole}>高级教师</span>
                </div>
            </div>
        </aside>
    );
}
