"use client";

import React, { useState } from 'react';
import styles from './DesignModule.module.css';

interface DesignModuleProps {
    title: string;
    subTitle?: string;
    value: string;
    onChange: (value: string) => void;
    placeholder?: string;
    saveButtonLabel?: string;
    onSave?: () => void;
    // New props for Multi-Select Objectives
    availableObjectives?: string[];
    selectedObjectives?: string[];
    onObjectiveChange?: (selected: string[]) => void;
    dropdownLabel?: string; // Custom label for the dropdown
    defaultContent?: string; // Content to use for mock generation
}

// Icons
const SparklesIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
    </svg>
);

export default function DesignModule({
    title, subTitle, value, onChange, placeholder,
    saveButtonLabel, onSave,
    availableObjectives, selectedObjectives, onObjectiveChange,
    dropdownLabel = "关联课时目标",
    defaultContent
}: DesignModuleProps) {
    const [isGenerating, setIsGenerating] = useState(false);
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const dropdownRef = React.useRef<HTMLDivElement>(null);

    // Handle click outside to close dropdown
    React.useEffect(() => {
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

    const handleAskAI = () => {
        setIsGenerating(true);
        // Mock AI generation
        setTimeout(() => {
            let promptContext = "";
            if (selectedObjectives && selectedObjectives.length > 0) {
                promptContext = `基于选定的${dropdownLabel.replace('关联', '')}：\n${selectedObjectives.map(o => `- ${o}`).join('\n')}\n\n`;
            }

            let mockContent = "";
            if (defaultContent) {
                mockContent = defaultContent;
                if (promptContext) {
                    mockContent = `${promptContext}\n${defaultContent}`;
                }
            } else {
                mockContent = `[AI生成的${title}内容]\n${promptContext}1. 这是一个示例生成点。\n2. 基于大概念的深度理解。\n3. 具体落实到教学环节中。\n\n(您可以继续编辑此内容)`;
            }

            onChange(value ? `${value}\n\n${mockContent}` : mockContent);
            setIsGenerating(false);
        }, 1500);
    };

    const toggleObjective = (objective: string) => {
        if (!onObjectiveChange) return;

        const currentSelected = selectedObjectives || [];
        const isSelected = currentSelected.includes(objective);

        let newSelected;
        if (isSelected) {
            newSelected = currentSelected.filter(item => item !== objective);
        } else {
            newSelected = [...currentSelected, objective];
        }

        onObjectiveChange(newSelected);
    };

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <span className={styles.title}>{title}</span>
                {/* Header Dropdown for Objectives */}
                {availableObjectives && availableObjectives.length > 0 && (
                    <div className={styles.dropdownContainer} ref={dropdownRef}>
                        <div
                            className={styles.dropdownTrigger}
                            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                        >
                            <span>{dropdownLabel} ({selectedObjectives?.length || 0})</span>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </div>

                        {isDropdownOpen && (
                            <div className={styles.dropdownMenu}>
                                {availableObjectives.map((obj, idx) => (
                                    <div
                                        key={idx}
                                        className={styles.dropdownItem}
                                        onClick={() => toggleObjective(obj)}
                                    >
                                        <input
                                            type="checkbox"
                                            checked={selectedObjectives?.includes(obj) || false}
                                            readOnly
                                        />
                                        <span>{obj}</span>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}
            </div>

            <div className={styles.content}>
                <textarea
                    className={styles.textarea}
                    value={value}
                    onChange={(e) => onChange(e.target.value)}
                    placeholder={placeholder}
                />

                <button
                    className={styles.aiBtn}
                    onClick={handleAskAI}
                    disabled={isGenerating}
                >
                    <SparklesIcon />
                    {isGenerating ? '生成中...' : '问 AI'}
                </button>
            </div>

            {onSave && (
                <button className={styles.saveIconBtn} onClick={onSave} title="保存">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" />
                        <polyline points="17 21 17 13 7 13 7 21" />
                        <polyline points="7 3 7 8 15 8" />
                    </svg>
                </button>
            )}
        </div>
    );
}
