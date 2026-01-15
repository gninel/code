"use client";

import React, { useState, useRef, useEffect } from 'react';
import styles from './UnitBasicInfo.module.css';

interface InfoProps {
    info: {
        discipline: string;
        grade: string;
        term: string;
        unit: string;
        lessonName: string;
        version: string;
        objectives: string[];
        supplement: string;
        previousLessons?: string[];
    };
    onChange: (key: string, value: any) => void;
}

export default function UnitBasicInfo({ info, onChange }: InfoProps) {
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);

    // 前序课例选项
    const previousLessonOptions = [
        '一元一次方程-12.08',
        '实数探秘-12.05',
        '多位数乘一位数-12.02'
    ];

    // Handle click outside to close dropdown
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setIsDropdownOpen(false);
            }
        };

        if (isDropdownOpen) {
            document.addEventListener('mousedown', handleClickOutside);
        }

        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [isDropdownOpen]);

    const toggleLesson = (lesson: string) => {
        const currentSelected = info.previousLessons || [];
        const isSelected = currentSelected.includes(lesson);

        let newSelected;
        if (isSelected) {
            newSelected = currentSelected.filter(item => item !== lesson);
        } else {
            newSelected = [...currentSelected, lesson];
        }

        onChange('previousLessons', newSelected);
    };

    return (
        <div className={styles.container}>
            <div className={styles.row}>
                <div className={styles.field}>
                    <label>年级*</label>
                    <select className={styles.input} value={info.grade} onChange={(e) => onChange('grade', e.target.value)}>
                        <option value="五年级">五年级</option>
                        <option value="六年级">六年级</option>
                        <option value="七年级">七年级</option>
                        <option value="八年级">八年级</option>
                        <option value="九年级">九年级</option>
                    </select>
                </div>
                <div className={styles.field}>
                    <label>学期*</label>
                    <div className={styles.radioGroup}>
                        <label><input type="radio" checked={info.term === '上学期'} onChange={() => onChange('term', '上学期')} /> 上学期</label>
                        <label><input type="radio" checked={info.term === '下学期'} onChange={() => onChange('term', '下学期')} /> 下学期</label>
                    </div>
                </div>
            </div>

            <div className={styles.row}>
                <div className={styles.field}>
                    <label>学科*</label>
                    <select className={styles.input} value={info.discipline} onChange={(e) => onChange('discipline', e.target.value)}>
                        <option value="语文">语文</option>
                        <option value="数学">数学</option>
                        <option value="英语">英语</option>
                    </select>
                </div>
                <div className={styles.field}>
                    <label>教材版本*</label>
                    <select className={styles.input} value={info.version} onChange={(e) => onChange('version', e.target.value)}>
                        <option value="统编版">统编版</option>
                        <option value="人教版">人教版</option>
                        <option value="北师大版">北师大版</option>
                    </select>
                </div>
            </div>

            <div className={styles.row}>
                <div className={styles.field} style={{ flex: 1 }}>
                    <label>单元课时*</label>
                    <div style={{ display: 'flex', gap: '0.5rem', flex: 1 }}>
                        <select className={styles.input} value={info.unit} onChange={(e) => onChange('unit', e.target.value)}>
                            <option value="第一单元">第一单元</option>
                            <option value="第二单元">第二单元</option>
                            <option value="第三单元">第三单元</option>
                            <option value="第四单元">第四单元</option>
                            <option value="第五单元">第五单元</option>
                            <option value="第六单元">第六单元</option>
                        </select>
                        <select className={styles.input} value={info.lessonName} onChange={(e) => onChange('lessonName', e.target.value)}>
                            <option value="确定位置">确定位置</option>
                            <option value="小数除法">小数除法</option>
                            <option value="倍数与因数">倍数与因数</option>
                            <option value="分数的意义">分数的意义</option>
                        </select>
                    </div>
                </div>
            </div>

            <div className={styles.row}>
                <div className={styles.field} style={{ alignItems: 'flex-start' }}>
                    <label style={{ marginTop: '0.4rem' }}>教学目标*</label>

                    <div className={styles.objectiveList}>
                        {info.objectives && info.objectives.map((obj, index) => (
                            <div key={index} className={styles.objectiveItem}>
                                <button
                                    className={styles.trashBtn}
                                    onClick={() => {
                                        const newObjs = [...info.objectives];
                                        newObjs.splice(index, 1);
                                        onChange('objectives', newObjs);
                                    }}
                                    title="删除"
                                >
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /></svg>
                                </button>
                                <input
                                    type="text"
                                    className={styles.objectiveInput}
                                    value={obj}
                                    onChange={(e) => {
                                        const newObjs = [...info.objectives];
                                        newObjs[index] = e.target.value;
                                        onChange('objectives', newObjs);
                                    }}
                                    placeholder={`请输入目标 ${index + 1}`}
                                />
                            </div>
                        ))}
                        <div className={styles.addBtnRow}>
                            <button
                                className={styles.addBtn}
                                onClick={() => {
                                    const newObjs = [...(info.objectives || []), ''];
                                    onChange('objectives', newObjs);
                                }}
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
                                添加目标
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <div className={`${styles.row} ${styles.columnRow}`}>
                <div className={styles.field} style={{ flexDirection: 'column', alignItems: 'flex-start' }}>
                    <label style={{ marginBottom: '0.4rem' }}>补充信息</label>
                    <textarea
                        className={`${styles.textarea} ${styles.shortTextarea}`}
                        value={info.supplement}
                        onChange={(e) => onChange('supplement', e.target.value)}
                        placeholder="请输入补充信息..."
                    />
                </div>
            </div>

            {/* 前序课例下拉多选框 */}
            <div className={`${styles.row} ${styles.columnRow}`}>
                <div className={styles.field} style={{ flexDirection: 'column', alignItems: 'flex-start' }}>
                    <div className={styles.dropdownContainer} ref={dropdownRef}>
                        <div
                            className={styles.dropdownTrigger}
                            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                        >
                            <span>前序课例 ({info.previousLessons?.length || 0})</span>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </div>

                        {isDropdownOpen && (
                            <div className={styles.dropdownMenu}>
                                {previousLessonOptions.map((lesson, idx) => (
                                    <div
                                        key={idx}
                                        className={styles.dropdownItem}
                                        onClick={() => toggleLesson(lesson)}
                                    >
                                        <input
                                            type="checkbox"
                                            checked={info.previousLessons?.includes(lesson) || false}
                                            readOnly
                                        />
                                        <span>{lesson}</span>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
