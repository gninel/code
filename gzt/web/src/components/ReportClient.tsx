"use client";

import React from 'react';
import styles from './ReportClient.module.css';

// Icons
const PlayIcon = () => <svg width="24" height="24" viewBox="0 0 24 24" fill="white"><path d="M8 5v14l11-7z" /></svg>;
const BrainIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z" /><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z" /></svg>
);
const ShareIcon = () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" /><polyline points="16 6 12 2 8 6" /><line x1="12" y1="2" x2="12" y2="15" /></svg>;
const DownloadIcon = () => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
const EditIcon = () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>;
const MessageIcon = () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>;

export default function ReportClient({ id }: { id: string }) {
    return (
        <div className={styles.container}>
            {/* Header */}
            <div className={styles.reportHeader}>
                <div className={styles.headerLeft}>
                    <div className={styles.logoText}>
                        <BrainIcon />
                        <span>睿智教 AI课堂分析报告</span>
                    </div>
                </div>

                <div className={styles.navLinks}>
                    <span className={`${styles.navLink} ${styles.active}`}>首页</span>
                    <span className={styles.navLink}>课堂行为</span>
                    <span className={styles.navLink}>课堂问答</span>
                    <span className={styles.navLink}>AI观课</span>
                    <span className={styles.navLink}>人机共评</span>
                </div>

                <div className={styles.headerActions}>
                    <div className={styles.actionItem}><ShareIcon /> 报告分享</div>
                    <div className={styles.actionItem}><DownloadIcon /> 报告下载</div>
                    <div className={styles.actionItem}>☁ 睿云AI教研室</div>
                </div>
            </div>

            {/* Dashboard Content */}
            <div className={styles.dashboard}>

                {/* Left Column */}
                <div className={styles.leftCol}>
                    {/* Video Player */}
                    <div className={styles.videoCard}>
                        <div className={styles.videoPlaceholder}>
                            <div className={styles.playBtn}>
                                <PlayIcon />
                            </div>
                            <div className={styles.videoControls}>
                                <span>00:00 / 39:57</span>
                                <span>HD •••</span>
                            </div>
                        </div>
                    </div>

                    {/* Document Viewer */}
                    <div style={{ marginTop: '1.5rem' }}>
                        <div className={styles.docCard}>
                            <div className={styles.docTabs}>
                                <div className={`${styles.docTab} ${styles.active}`}>教学设计</div>
                                <div className={styles.docTab}>实录</div>
                                <div style={{ flex: 1 }}></div>
                                <div className={styles.docTab}>↑ 上传</div>
                            </div>
                            <div className={styles.docContent}>
                                <h3>基因突变教学设计</h3>
                                <p><strong>1. 教学目标设计</strong></p>
                                <p>本节课选自高中生物必修2《遗传与进化》第5章第1节的内容...</p>
                                <p><strong>2. 教学内容分析</strong></p>
                                <p>基因突变是生物变异的根本来源，是生物进化的原始材料...</p>
                                <br />
                                <p> (文档预览区域) </p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Right Column */}
                <div className={styles.rightCol}>

                    {/* Top Row: Info & AI Summary */}
                    <div className={styles.topStats}>
                        {/* Class Info */}
                        <div className={styles.infoCard}>
                            <div className={styles.cardTitle}>📘 课堂基本情况</div>
                            <div className={styles.infoGrid}>
                                <div className={styles.infoItem}>
                                    <label>授课教师</label>
                                    <span>小研老师</span>
                                </div>
                                <div className={styles.infoItem}>
                                    <label>授课类型</label>
                                    <span>新授课</span>
                                </div>
                                <div className={styles.infoItem}>
                                    <label>学段</label>
                                    <span>高中</span>
                                </div>
                                <div className={styles.infoItem}>
                                    <label>年级</label>
                                    <span>高一</span>
                                </div>
                                <div className={styles.infoItem}>
                                    <label>学科</label>
                                    <span>生物</span>
                                </div>
                            </div>
                        </div>

                        {/* AI Summary */}
                        <div className={styles.infoCard}>
                            <div className={styles.cardTitle}>💬 小睿寄语 ✨</div>
                            <div className={styles.aiSummary}>
                                <ul>
                                    <li>本堂课教学内容围绕基因突变的定义与类型展开，包括碱基替换、增添和缺失的原因。</li>
                                    <li>详细分析了突变如何影响氨基酸序列、蛋白质功能，并探讨了密码子特性如简并性。</li>
                                    <li>以教师主导讲授为主，学生参与机会有限。</li>
                                    <li>分析性提问占据主导，同时涉及应用性、理解性和创造性提问层次。</li>
                                    <li>教师语速整体适宜且较为稳定。</li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    {/* Bottom Row: Charts */}
                    <div className={styles.chartSection}>
                        <div className={styles.cardHeader}>
                            <div className={styles.cardTitle}>🎓 课堂行为时序图</div>
                        </div>

                        <div className={styles.timelinePlot}>
                            {/* Tracks */}
                            <div className={styles.timelineTracks}>
                                <div className={styles.track}>
                                    <div className={styles.trackLabel}>讲授</div>
                                    <div className={styles.trackBar}>
                                        <div className={styles.segment} style={{ left: '10%', width: '20%' }}></div>
                                        <div className={styles.segment} style={{ left: '40%', width: '15%' }}></div>
                                        <div className={styles.segment} style={{ left: '60%', width: '30%' }}></div>
                                    </div>
                                </div>
                                <div className={styles.track}>
                                    <div className={styles.trackLabel}>板书</div>
                                    <div className={styles.trackBar}>
                                        <div className={styles.segment} style={{ left: '15%', width: '1%', background: '#0ea5e9' }}></div>
                                        <div className={styles.segment} style={{ left: '55%', width: '2%', background: '#0ea5e9' }}></div>
                                    </div>
                                </div>
                                <div className={styles.track}>
                                    <div className={styles.trackLabel}>指导</div>
                                    <div className={styles.trackBar}>
                                        <div className={styles.segment} style={{ left: '30%', width: '2%', background: '#22d3ee' }}></div>
                                        <div className={styles.segment} style={{ left: '80%', width: '2%', background: '#22d3ee' }}></div>
                                    </div>
                                </div>
                                <div className={styles.track}>
                                    <div className={styles.trackLabel}>互动</div>
                                    <div className={styles.trackBar}>
                                        <div className={styles.segment} style={{ left: '35%', width: '5%', background: '#f59e0b' }}></div>
                                        <div className={styles.segment} style={{ left: '70%', width: '3%', background: '#f59e0b' }}></div>
                                    </div>
                                </div>
                            </div>

                            {/* Donut Chart Mock */}
                            <div className={styles.donutChart}>
                                <div className={styles.donutCircle}>
                                    <div className={styles.donutInner}>
                                        <span style={{ fontSize: '0.8rem', color: '#94a3b8' }}>讲授</span>
                                        <span style={{ fontSize: '1.2rem', fontWeight: 'bold', color: '#3b82f6' }}>75.8%</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Floating Sidebar */}
            <div className={styles.floatingBar}>
                <div className={styles.floatBtn} title="笔记"><EditIcon /></div>
                <div className={styles.floatBtn} title="问答"><MessageIcon /></div>
                <div className={styles.floatBtn} title="邀请"><ShareIcon /></div>
            </div>
        </div>
    );
}
