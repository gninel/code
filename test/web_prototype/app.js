const { createApp, ref, onMounted } = Vue;

createApp({
    setup() {
        const isSidebarCollapsed = ref(false);
        const activeNavId = ref('home');
        const showAiModal = ref(false);
        const currentAiHelper = ref({});

        // --- Navigation Data ---
        const navMenu = ref([
            {
                title: '',
                items: [
                    { id: 'home', label: '个人主页', icon: 'ph-duotone ph-house', expanded: false }
                ]
            },
            {
                title: '教学工作',
                items: [
                    {
                        id: 'prep',
                        label: '备课中心',
                        icon: 'ph-duotone ph-books',
                        expanded: true,
                        children: [
                            { id: 'prep-manage', label: '课程管理' },
                            { id: 'prep-design', label: '教学设计' },
                            { id: 'prep-resource', label: '资源库' }
                        ]
                    },
                    {
                        id: 'homework',
                        label: '作业中心',
                        icon: 'ph-duotone ph-pencil-circle',
                        expanded: false,
                        children: [
                            { id: 'hw-manage', label: '作业管理' },
                            { id: 'hw-analysis', label: '学情分析' }
                        ]
                    },
                    {
                        id: 'class',
                        label: '课堂分析',
                        icon: 'ph-duotone ph-chart-bar',
                        expanded: false
                    }
                ]
            },
            {
                title: '专业发展',
                items: [
                    {
                        id: 'research',
                        label: '研修',
                        icon: 'ph-duotone ph-student',
                        expanded: false
                    },
                    {
                        id: 'credit',
                        label: '我的学分',
                        icon: 'ph-duotone ph-star',
                        expanded: false
                    },
                    {
                        id: 'growth',
                        label: '个人发展',
                        icon: 'ph-duotone ph-trend-up',
                        expanded: false
                    }
                ]
            }
        ]);

        // --- AI Helpers Data ---
        const aiHelpers = ref([
            {
                id: 1,
                title: '教学改进',
                icon: '💡',
                iconBg: 'bg-yellow-100 text-yellow-600',
                features: ['智能诊断教学逻辑', '优化课堂提问', '建议教学策略'],
                badge: '3个建议'
            },
            {
                id: 2,
                title: '科研提升',
                icon: '🔬',
                iconBg: 'bg-purple-100 text-purple-600',
                features: ['识别科研薄弱点', '推荐科研方向', '生成论文大纲'],
                badge: null
            },
            {
                id: 3,
                title: '智能填报',
                icon: '✍️',
                iconBg: 'bg-blue-100 text-blue-600',
                features: ['自动识别申报类别', '自动填充信息', '生成成果描述'],
                badge: '2个待办'
            },
            {
                id: 4,
                title: '教研活动',
                icon: '👥',
                iconBg: 'bg-green-100 text-green-600',
                features: ['生成活动主题', '自动安排议程', '推荐邀请名单'],
                badge: '1个待发'
            },
            {
                id: 5,
                title: '进阶分析',
                icon: '📊',
                iconBg: 'bg-indigo-100 text-indigo-600',
                features: ['同行水平对比', '瓶颈诊断', '发展路径规划'],
                badge: null
            },
            {
                id: 6,
                title: '资源生成',
                icon: '🎨',
                iconBg: 'bg-pink-100 text-pink-600',
                features: ['PPT大纲生成', '智能配图', '习题自动生成'],
                badge: 'NEW'
            }
        ]);

        // --- Recommendations Data ---
        const videoRecs = ref([
            {
                id: 1,
                title: '如何设计高效提问？',
                duration: '05:00',
                img: 'https://images.unsplash.com/photo-1577896335477-28585062912f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
                rating: '4.8',
                tags: ['课堂设计', '提问策略'],
                reason: '基于课堂分析薄弱点推荐'
            },
            {
                id: 2,
                title: '高中数学函数可视化教学',
                duration: '08:24',
                img: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
                rating: '4.9',
                tags: ['信息技术', '可视化'],
                reason: '同行高分评价'
            }
        ]);

        const paperRecs = ref([
            {
                id: 1,
                title: '基于大概念的高中数学单元教学设计研究',
                author: '李明',
                journal: '数学教育学报',
                date: '2024.01',
                abstract: '本文探讨了在新课标背景下，如何以大概念为核心进行单元整体教学设计，提出了"三阶六步"的教学模式...',
                tags: ['单元教学', '核心素养'],
                citations: 12
            },
            {
                id: 2,
                title: '人工智能赋能下的个性化学习路径探索',
                author: '张伟',
                journal: '电化教育研究',
                date: '2023.11',
                abstract: '随着AI技术的发展，个性化学习成为可能。本研究基于学习分析技术，构建了智能化的学习路径推荐系统...',
                tags: ['人工智能', '个性化学习'],
                citations: 45
            }
        ]);

        // --- Methods ---
        const toggleSidebar = () => {
            isSidebarCollapsed.value = !isSidebarCollapsed.value;
            // Resize charts after transition
            setTimeout(() => {
                resizeCharts();
            }, 300);
        };

        const toggleSubmenu = (item) => {
            if (isSidebarCollapsed.value) return; // Don't expand in collapsed mode
            item.expanded = !item.expanded;
        };

        const setActive = (id) => {
            activeNavId.value = id;
        };

        const openAiModal = (helper) => {
            currentAiHelper.value = helper;
            showAiModal.value = true;
        };

        const closeAiModal = () => {
            showAiModal.value = false;
        };

        let teachingChartInstance = null;
        let researchChartInstance = null;

        const initCharts = () => {
            // Teaching Ability Radar
            const teachingChartDom = document.getElementById('teachingChart');
            teachingChartInstance = echarts.init(teachingChartDom);
            const teachingOption = {
                color: ['#6366f1'],
                radar: {
                    indicator: [
                        { name: '教学设计', max: 100 },
                        { name: '学情分析', max: 100 },
                        { name: '课堂掌控', max: 100 },
                        { name: '学生参与', max: 100 },
                        { name: '教学创新', max: 100 }
                    ],
                    splitArea: {
                        areaStyle: {
                            color: ['#f8fafc', '#f1f5f9']
                        }
                    },
                    axisName: {
                        color: '#64748b',
                        fontWeight: 'bold'
                    }
                },
                series: [
                    {
                        type: 'radar',
                        data: [
                            {
                                value: [85, 90, 75, 95, 80],
                                name: '教学能力 (Teaching)',
                                areaStyle: {
                                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                                        { offset: 0, color: 'rgba(99, 102, 241, 0.5)' },
                                        { offset: 1, color: 'rgba(99, 102, 241, 0.1)' }
                                    ])
                                }
                            }
                        ]
                    }
                ]
            };
            teachingChartInstance.setOption(teachingOption);

            // Research Ability Radar
            const researchChartDom = document.getElementById('researchChart');
            researchChartInstance = echarts.init(researchChartDom);
            const researchOption = {
                color: ['#ec4899', '#94a3b8'],
                legend: {
                    data: ['本年度', '上年度'],
                    bottom: 0,
                    icon: 'circle'
                },
                radar: {
                    indicator: [
                        { name: '论文发表', max: 100 },
                        { name: '课题申报', max: 100 },
                        { name: '课例质量', max: 100 },
                        { name: '研究深度', max: 100 },
                        { name: '创新突破', max: 100 }
                    ],
                    splitArea: { show: false },
                    axisName: { color: '#64748b' }
                },
                series: [
                    {
                        type: 'radar',
                        data: [
                            {
                                value: [70, 60, 85, 75, 65],
                                name: '本年度',
                                areaStyle: {
                                    opacity: 0.2
                                }
                            },
                            {
                                value: [60, 50, 75, 70, 60],
                                name: '上年度',
                                lineStyle: { type: 'dashed' }
                            }
                        ]
                    }
                ]
            };
            researchChartInstance.setOption(researchOption);
        };

        const resizeCharts = () => {
            if (teachingChartInstance) teachingChartInstance.resize();
            if (researchChartInstance) researchChartInstance.resize();
        };

        onMounted(() => {
            initCharts();
            window.addEventListener('resize', resizeCharts);
        });

        return {
            isSidebarCollapsed,
            navMenu,
            activeNavId,
            toggleSidebar,
            toggleSubmenu,
            setActive,
            aiHelpers,
            videoRecs,
            paperRecs,
            showAiModal,
            currentAiHelper,
            openAiModal,
            closeAiModal
        };
    }
}).mount('#app');
