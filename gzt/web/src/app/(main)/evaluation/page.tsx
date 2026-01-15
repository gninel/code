"use client";

import React, { useState } from 'react';
import { handleStaticNavigation } from '@/utils/navigationHelper';
import styles from './page.module.css';

// Icons
const CalendarIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
);
const UserIcon = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
);
const BookIcon = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
);
const SearchIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
);
const LockIcon = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
);
const CompareIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"></path></svg>
); // Using Git compare loosely, or standard columns
const ColumnsIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3h7a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-7m0-18H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h7m0-18v18" /></svg>
);


const MOCK_REPORTS = [
    {
        id: 1,
        title: '一元一次课程',
        teacher: '羊小萌',
        subject: '小学语文',
        date: '2025.12.05 18:00',
        designStatus: '无教学设计',
        mode: '练习型',
        time: '40min',
        teacherActivity: '12%',
        studentActivity: '88%',
        isPublic: true
    },
    {
        id: 2,
        title: '冬天',
        teacher: '羊小萌',
        subject: '小学语文',
        date: '2025.12.04 10:40',
        designStatus: '无教学设计',
        mode: '练习型',
        time: '0min',
        teacherActivity: '0%',
        studentActivity: '100%',
        isPublic: false
    },
    {
        id: 3,
        title: '秋天',
        teacher: '羊小萌',
        subject: '小学语文',
        date: '2025.12.04 10:39',
        designStatus: '无教学设计',
        mode: '练习型',
        time: '0min',
        teacherActivity: '0%',
        studentActivity: '100%',
        isPublic: true
    },
    {
        id: 4,
        title: '雪地里的小画家',
        teacher: '小睿老师',
        subject: '小学语文',
        date: '2025.10.10 22:00',
        designStatus: '无教学设计',
        mode: '讲授型',
        time: '39min',
        teacherActivity: '81%',
        studentActivity: '19%',
        isPublic: false
    },
    {
        id: 5,
        title: '生命真奇妙',
        teacher: '小睿老师',
        subject: '小学心理健康',
        date: '2025.10.09', // Mock date missing time in image example?
        designStatus: '有教学设计',
        isImported: true, // "导入课程"
        mode: '混合型',
        time: '41min',
        teacherActivity: '55%',
        studentActivity: '45%',
        isPublic: true
    }
];

export default function EvaluationPage() {
    return (
        <div className={styles.container}>
            {/* Header */}
            <div className={styles.header}>
                <div className={styles.tabs}>
                    <div className={`${styles.tab} ${styles.activeTab}`}>报告列表</div>
                    {/* Teacher List Removed */}
                </div>
                <button className={styles.compareBtn}>
                    <ColumnsIcon />
                    多课对比
                </button>
            </div>

            {/* Filter Bar */}
            <div className={styles.filters}>
                <div className={styles.filterItem}>
                    <CalendarIcon />
                    <span style={{ marginLeft: '8px' }}>开始日期 → 结束日期</span>
                </div>
                <select className={styles.filterItem} defaultValue="all_status">
                    <option value="all_status">全部状态</option>
                    <option value="draft">草稿</option>
                    <option value="published">已发布</option>
                </select>
                <select className={styles.filterItem} defaultValue="view_status">
                    <option value="view_status">查看状态</option>
                    <option value="viewed">已查看</option>
                    <option value="unviewed">未查看</option>
                </select>

                <div className={styles.searchBox}>
                    {/* Search Teacher Name Removed */}
                    <input
                        type="text"
                        placeholder="🔍 搜索课堂名称"
                        className={styles.filterInput}
                    />
                </div>
                {/* Search School Name Removed per request */}
            </div>

            {/* Grid */}
            <div className={styles.grid}>
                {MOCK_REPORTS.map(report => (
                    <div key={report.id} className={styles.card}>

                        {/* Card Header & Meta */}
                        <div>
                            <div className={styles.cardHeader}>
                                <div className={styles.cardTitle}>{report.title}</div>
                                <div className={styles.menuBtn}>•••</div>
                            </div>

                            <div className={styles.cardMeta}>
                                <div className={styles.metaItem}>
                                    <UserIcon /> {report.teacher}
                                </div>
                                <div className={styles.metaItem}>
                                    <BookIcon /> {report.subject}
                                </div>
                                <div className={styles.metaItem}>
                                    <CalendarIcon /> {report.date}
                                </div>
                                <div className={styles.metaItem}>
                                    {report.designStatus === '有教学设计' ? '✅' : 'ⓧ'} {report.designStatus}
                                </div>
                                {report.isImported && <div className={styles.metaItem}>↪ 导入课程</div>}
                            </div>
                        </div>

                        {/* Stats Box */}
                        <div className={styles.statsBox}>
                            <div className={styles.statsRow}>
                                <span>课堂模式：{report.mode}</span>
                            </div>
                            <div className={styles.statsRow}>
                                <span>授课时间：<span className={styles.statValue}>{report.time}</span></span>
                                <span>教师行为：<span className={styles.statValue}>{report.teacherActivity}</span></span>
                                <span>学生行为：<span className={styles.statValue}>{report.studentActivity}</span></span>
                            </div>
                        </div>

                        {/* Footer */}
                        <div className={styles.cardFooter}>
                            <div className={styles.publicInfo}>
                                <LockIcon /> {report.isPublic ? '公开' : '私有'}
                            </div>
                            <div className={styles.actions}>
                                <button
                                    className={`${styles.actionBtn} ${styles.actionBtnPrimary}`}
                                    onClick={() => handleStaticNavigation(null, `/report_${report.id}`)} // Pass null router as we want new tab logic or direct nav
                                >
                                    查看
                                </button>
                                <button className={styles.actionBtn}>下载</button>
                                <button className={styles.actionBtn}>分享</button>
                            </div>
                        </div>

                    </div>
                ))}
            </div>
        </div>
    );
}
