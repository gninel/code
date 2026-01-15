"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { handleStaticNavigation } from '@/utils/navigationHelper';
import MaterialInputHeader from '@/components/Materials/MaterialInputHeader';
import MaterialGallery from '@/components/Materials/MaterialGallery';
import styles from './page.module.css';

export default function MaterialsPage() {
    const router = useRouter();

    const handleGenerate = (prompt: string) => {
        // Navigate to generation page with query param
        handleStaticNavigation(router, `/materials_generate?prompt=${encodeURIComponent(prompt)}`);
    };

    return (
        <div className={styles.container}>
            <div className={styles.headerSection}>
                <div className={styles.brandTitle}>
                    <span className={styles.logoIcon}>✨</span>
                    <span>一句话生成课堂动画素材和互动工具</span>
                </div>
                <MaterialInputHeader onGenerate={handleGenerate} />
            </div>

            <div className={styles.gallerySection}>
                <MaterialGallery />
            </div>
        </div>
    );
}
