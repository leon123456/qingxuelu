//
//  EnhancedGoalTemplateExamples.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation

// MARK: - 增强目标模板示例
class EnhancedGoalTemplateExamples {
    
    static let shared = EnhancedGoalTemplateExamples()
    
    private init() {}
    
    // MARK: - 英语口语提升模板（增强版）
    func createEnglishSpeakingTemplate() -> EnhancedGoalTemplate {
        return EnhancedGoalTemplate(
            name: "英语口语提升",
            description: "通过AI生成个性化内容，系统化提升英语口语表达能力，从基础发音到流利对话",
            category: .english,
            goalType: .smart,
            priority: .high,
            duration: 120,
            icon: "speaker.wave.2",
            tags: ["口语", "英语", "AI生成", "个性化"],
            learningPath: createEnglishSpeakingLearningPath(),
            contentContext: createEnglishSpeakingContext(),
            aiGeneratedContent: true,
            milestones: createEnglishSpeakingMilestones(),
            keyResults: createEnglishSpeakingKeyResults(),
            suggestedTasks: createEnglishSpeakingTasks(),
            learningResources: createEnglishSpeakingResources(),
            assessmentPoints: createEnglishSpeakingAssessments(),
            difficultyProgression: [.beginner, .intermediate, .advanced]
        )
    }
    
    // MARK: - 数学基础强化模板（增强版）
    func createMathFoundationTemplate() -> EnhancedGoalTemplate {
        return EnhancedGoalTemplate(
            name: "数学基础强化",
            description: "通过AI生成个性化练习题，巩固数学基础概念，提升解题能力",
            category: .math,
            goalType: .smart,
            priority: .high,
            duration: 90,
            icon: "function",
            tags: ["数学", "基础", "AI生成", "练习"],
            learningPath: createMathFoundationLearningPath(),
            contentContext: createMathFoundationContext(),
            aiGeneratedContent: true,
            milestones: createMathFoundationMilestones(),
            keyResults: createMathFoundationKeyResults(),
            suggestedTasks: createMathFoundationTasks(),
            learningResources: createMathFoundationResources(),
            assessmentPoints: createMathFoundationAssessments(),
            difficultyProgression: [.beginner, .intermediate]
        )
    }
    
    // MARK: - 科学实验探索模板（增强版）
    func createScienceExplorationTemplate() -> EnhancedGoalTemplate {
        return EnhancedGoalTemplate(
            name: "科学实验探索",
            description: "通过AI生成实验指导和安全提示，培养科学思维和实验技能",
            category: .science,
            goalType: .okr,
            priority: .medium,
            duration: 60,
            icon: "flask",
            tags: ["科学", "实验", "AI生成", "探索"],
            learningPath: createScienceExplorationLearningPath(),
            contentContext: createScienceExplorationContext(),
            aiGeneratedContent: true,
            milestones: createScienceExplorationMilestones(),
            keyResults: createScienceExplorationKeyResults(),
            suggestedTasks: createScienceExplorationTasks(),
            learningResources: createScienceExplorationResources(),
            assessmentPoints: createScienceExplorationAssessments(),
            difficultyProgression: [.beginner, .intermediate, .advanced]
        )
    }
}

// MARK: - 英语口语学习路径
extension EnhancedGoalTemplateExamples {
    
    private func createEnglishSpeakingLearningPath() -> LearningPathTemplate {
        let steps = [
            LearningStepTemplate(
                title: "基础发音练习",
                description: "掌握英语音标和基础发音规则",
                order: 1,
                estimatedDuration: 30,
                difficulty: .beginner,
                prerequisites: [],
                learningObjectives: ["掌握48个音标", "正确发音基础单词", "区分相似音素"],
                contentTypes: [.vocabulary, .speaking],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "日常词汇积累",
                description: "学习常用口语词汇和表达",
                order: 2,
                estimatedDuration: 45,
                difficulty: .beginner,
                prerequisites: ["基础发音练习"],
                learningObjectives: ["掌握100个常用词汇", "理解词汇用法", "能够造句"],
                contentTypes: [.vocabulary, .conversation],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "简单对话练习",
                description: "进行基础日常对话练习",
                order: 3,
                estimatedDuration: 60,
                difficulty: .intermediate,
                prerequisites: ["日常词汇积累"],
                learningObjectives: ["能够进行简单对话", "掌握基本句型", "提高流利度"],
                contentTypes: [.conversation, .speaking],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "话题讨论",
                description: "围绕特定话题进行深入讨论",
                order: 4,
                estimatedDuration: 90,
                difficulty: .intermediate,
                prerequisites: ["简单对话练习"],
                learningObjectives: ["能够表达观点", "使用复杂句型", "提高表达准确性"],
                contentTypes: [.conversation, .speaking, .vocabulary],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "流利表达",
                description: "达到流利的口语表达水平",
                order: 5,
                estimatedDuration: 120,
                difficulty: .advanced,
                prerequisites: ["话题讨论"],
                learningObjectives: ["流利表达复杂观点", "使用高级词汇", "自然的口语表达"],
                contentTypes: [.speaking, .conversation, .vocabulary],
                aiGeneratedContent: true
            )
        ]
        
        let adaptiveRules = [
            AdaptiveRuleTemplate(
                condition: "发音准确率 < 70%",
                action: "增加发音练习时间",
                parameters: ["extraTime": "15分钟"],
                priority: 1
            ),
            AdaptiveRuleTemplate(
                condition: "词汇掌握率 < 80%",
                action: "生成更多词汇练习",
                parameters: ["extraWords": "20个"],
                priority: 2
            )
        ]
        
        let progressTracking = ProgressTrackingTemplate(
            trackingMethods: [.completion, .time, .score],
            frequency: .daily,
            metrics: [.completionRate, .timeSpent, .improvement],
            alerts: [.behind, .struggling, .excellent]
        )
        
        let checkpoints = [
            MilestoneCheckpointTemplate(
                title: "发音基础检查",
                description: "检查基础发音掌握情况",
                order: 1,
                requiredTasks: ["基础发音练习"],
                assessmentCriteria: [
                    AssessmentCriteria(name: "发音准确性", description: "音标发音准确率", weight: 0.6, maxScore: 100, passingScore: 70),
                    AssessmentCriteria(name: "流利度", description: "发音流利程度", weight: 0.4, maxScore: 100, passingScore: 60)
                ],
                unlockConditions: ["发音准确率 >= 70%"]
            )
        ]
        
        return LearningPathTemplate(
            steps: steps,
            adaptiveAdjustments: adaptiveRules,
            progressTracking: progressTracking,
            milestoneCheckpoints: checkpoints
        )
    }
    
    private func createEnglishSpeakingContext() -> ContentContextTemplate {
        return ContentContextTemplate(
            background: "学生正在学习英语口语，目标是提升日常交流能力",
            context: "家庭环境，家长希望孩子能够自信地用英语进行日常对话",
            targetAudience: "中学生，英语基础一般",
            learningEnvironment: "家庭学习环境，可以使用手机或平板",
            culturalContext: "中国学生，需要了解中西方文化差异",
            practicalApplications: ["日常问候", "购物对话", "学校交流", "家庭对话"]
        )
    }
    
    private func createEnglishSpeakingMilestones() -> [MilestoneTemplate] {
        return [
            MilestoneTemplate(title: "发音基础", description: "掌握基础音标和发音规则", duration: 14, order: 1),
            MilestoneTemplate(title: "词汇积累", description: "掌握100个常用口语词汇", duration: 30, order: 2),
            MilestoneTemplate(title: "简单对话", description: "能够进行基础日常对话", duration: 60, order: 3),
            MilestoneTemplate(title: "话题讨论", description: "能够围绕话题进行讨论", duration: 90, order: 4),
            MilestoneTemplate(title: "流利表达", description: "达到流利的口语表达水平", duration: 120, order: 5)
        ]
    }
    
    private func createEnglishSpeakingKeyResults() -> [KeyResultTemplate] {
        return [
            KeyResultTemplate(title: "词汇掌握", description: "掌握300个口语常用词汇", targetValue: 300, unit: "个"),
            KeyResultTemplate(title: "练习次数", description: "完成30次口语练习", targetValue: 30, unit: "次"),
            KeyResultTemplate(title: "对话能力", description: "完成5次模拟对话", targetValue: 5, unit: "次"),
            KeyResultTemplate(title: "学习时长", description: "累计学习60小时", targetValue: 60, unit: "小时")
        ]
    }
    
    private func createEnglishSpeakingTasks() -> [TaskTemplate] {
        return [
            TaskTemplate(title: "AI生成发音练习", description: "根据个人发音问题生成针对性练习", estimatedDuration: 15, difficulty: .easy, tags: ["AI生成", "发音"]),
            TaskTemplate(title: "AI生成词汇练习", description: "基于学习进度生成个性化词汇练习", estimatedDuration: 20, difficulty: .easy, tags: ["AI生成", "词汇"]),
            TaskTemplate(title: "AI生成对话练习", description: "生成情景对话练习内容", estimatedDuration: 25, difficulty: .medium, tags: ["AI生成", "对话"]),
            TaskTemplate(title: "AI生成话题讨论", description: "生成话题讨论的引导问题", estimatedDuration: 30, difficulty: .medium, tags: ["AI生成", "讨论"]),
            TaskTemplate(title: "AI生成口语评估", description: "生成口语能力评估内容", estimatedDuration: 20, difficulty: .hard, tags: ["AI生成", "评估"])
        ]
    }
    
    private func createEnglishSpeakingResources() -> [LearningResourceTemplate] {
        return [
            LearningResourceTemplate(
                title: "AI生成发音指导",
                description: "基于个人发音问题的个性化指导",
                type: .video,
                difficulty: .beginner,
                estimatedDuration: 10,
                tags: ["AI生成", "发音"],
                aiGenerated: true
            ),
            LearningResourceTemplate(
                title: "AI生成词汇卡片",
                description: "个性化词汇学习卡片",
                type: .app,
                difficulty: .beginner,
                estimatedDuration: 15,
                tags: ["AI生成", "词汇"],
                aiGenerated: true
            ),
            LearningResourceTemplate(
                title: "AI生成对话脚本",
                description: "情景对话练习脚本",
                type: .textbook,
                difficulty: .intermediate,
                estimatedDuration: 20,
                tags: ["AI生成", "对话"],
                aiGenerated: true
            )
        ]
    }
    
    private func createEnglishSpeakingAssessments() -> [AssessmentPointTemplate] {
        return [
            AssessmentPointTemplate(
                title: "发音准确性评估",
                description: "评估音标发音的准确性",
                type: .test,
                order: 1,
                criteria: [
                    AssessmentCriteria(name: "音标准确性", description: "48个音标的发音准确率", weight: 0.7, maxScore: 100, passingScore: 70),
                    AssessmentCriteria(name: "语调", description: "语调的自然程度", weight: 0.3, maxScore: 100, passingScore: 60)
                ],
                passingScore: 70.0,
                feedback: "发音基础良好，继续练习提高流利度"
            ),
            AssessmentPointTemplate(
                title: "口语流利度评估",
                description: "评估口语表达的流利程度",
                type: .presentation,
                order: 2,
                criteria: [
                    AssessmentCriteria(name: "流利度", description: "表达的流畅程度", weight: 0.4, maxScore: 100, passingScore: 70),
                    AssessmentCriteria(name: "准确性", description: "语法和词汇使用的准确性", weight: 0.4, maxScore: 100, passingScore: 70),
                    AssessmentCriteria(name: "自然度", description: "表达的自然程度", weight: 0.2, maxScore: 100, passingScore: 60)
                ],
                passingScore: 70.0,
                feedback: "口语表达流利，继续保持"
            )
        ]
    }
}

// MARK: - 数学基础学习路径
extension EnhancedGoalTemplateExamples {
    
    private func createMathFoundationLearningPath() -> LearningPathTemplate {
        let steps = [
            LearningStepTemplate(
                title: "基础运算",
                description: "掌握四则运算和基础数学概念",
                order: 1,
                estimatedDuration: 30,
                difficulty: .beginner,
                prerequisites: [],
                learningObjectives: ["掌握加减乘除", "理解运算规则", "提高计算速度"],
                contentTypes: [.exercise, .assessment],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "分数和小数",
                description: "学习分数和小数的概念和运算",
                order: 2,
                estimatedDuration: 45,
                difficulty: .beginner,
                prerequisites: ["基础运算"],
                learningObjectives: ["理解分数概念", "掌握分数运算", "分数小数转换"],
                contentTypes: [.exercise, .assessment],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "几何基础",
                description: "学习基础几何图形和性质",
                order: 3,
                estimatedDuration: 60,
                difficulty: .intermediate,
                prerequisites: ["分数和小数"],
                learningObjectives: ["认识几何图形", "掌握图形性质", "计算图形面积"],
                contentTypes: [.exercise, .assessment],
                aiGeneratedContent: true
            )
        ]
        
        let adaptiveRules = [
            AdaptiveRuleTemplate(
                condition: "计算准确率 < 80%",
                action: "增加基础练习",
                parameters: ["extraExercises": "10题"],
                priority: 1
            ),
            AdaptiveRuleTemplate(
                condition: "解题速度 < 标准",
                action: "增加速度练习",
                parameters: ["timeLimit": "5分钟"],
                priority: 2
            )
        ]
        
        let progressTracking = ProgressTrackingTemplate(
            trackingMethods: [.completion, .score, .time],
            frequency: .weekly,
            metrics: [.completionRate, .score, .improvement],
            alerts: [.behind, .struggling, .excellent]
        )
        
        return LearningPathTemplate(
            steps: steps,
            adaptiveAdjustments: adaptiveRules,
            progressTracking: progressTracking,
            milestoneCheckpoints: []
        )
    }
    
    private func createMathFoundationContext() -> ContentContextTemplate {
        return ContentContextTemplate(
            background: "学生需要巩固数学基础，提高解题能力",
            context: "学校数学课程，家长希望孩子能够跟上进度",
            targetAudience: "初中生，数学基础需要加强",
            learningEnvironment: "家庭学习环境，可以使用计算器",
            culturalContext: "中国数学教育体系",
            practicalApplications: ["考试准备", "日常计算", "逻辑思维", "问题解决"]
        )
    }
    
    private func createMathFoundationMilestones() -> [MilestoneTemplate] {
        return [
            MilestoneTemplate(title: "运算基础", description: "掌握四则运算", duration: 14, order: 1),
            MilestoneTemplate(title: "分数小数", description: "掌握分数和小数运算", duration: 30, order: 2),
            MilestoneTemplate(title: "几何入门", description: "掌握基础几何知识", duration: 60, order: 3),
            MilestoneTemplate(title: "综合应用", description: "能够解决综合数学问题", duration: 90, order: 4)
        ]
    }
    
    private func createMathFoundationKeyResults() -> [KeyResultTemplate] {
        return [
            KeyResultTemplate(title: "计算准确率", description: "基础运算准确率达到95%", targetValue: 95, unit: "%"),
            KeyResultTemplate(title: "解题速度", description: "平均解题时间减少50%", targetValue: 50, unit: "%"),
            KeyResultTemplate(title: "练习完成", description: "完成200道练习题", targetValue: 200, unit: "题"),
            KeyResultTemplate(title: "学习时长", description: "累计学习45小时", targetValue: 45, unit: "小时")
        ]
    }
    
    private func createMathFoundationTasks() -> [TaskTemplate] {
        return [
            TaskTemplate(title: "AI生成基础练习", description: "根据个人薄弱环节生成针对性练习", estimatedDuration: 20, difficulty: .easy, tags: ["AI生成", "基础运算"]),
            TaskTemplate(title: "AI生成分数练习", description: "生成分数和小数运算练习", estimatedDuration: 25, difficulty: .medium, tags: ["AI生成", "分数"]),
            TaskTemplate(title: "AI生成几何练习", description: "生成几何图形相关练习", estimatedDuration: 30, difficulty: .medium, tags: ["AI生成", "几何"]),
            TaskTemplate(title: "AI生成综合练习", description: "生成综合性数学问题", estimatedDuration: 35, difficulty: .hard, tags: ["AI生成", "综合"])
        ]
    }
    
    private func createMathFoundationResources() -> [LearningResourceTemplate] {
        return [
            LearningResourceTemplate(
                title: "AI生成计算练习",
                description: "个性化计算能力提升练习",
                type: .app,
                difficulty: .beginner,
                estimatedDuration: 15,
                tags: ["AI生成", "计算"],
                aiGenerated: true
            ),
            LearningResourceTemplate(
                title: "AI生成解题指导",
                description: "个性化解题思路指导",
                type: .textbook,
                difficulty: .intermediate,
                estimatedDuration: 20,
                tags: ["AI生成", "解题"],
                aiGenerated: true
            )
        ]
    }
    
    private func createMathFoundationAssessments() -> [AssessmentPointTemplate] {
        return [
            AssessmentPointTemplate(
                title: "基础运算测试",
                description: "测试四则运算能力",
                type: .test,
                order: 1,
                criteria: [
                    AssessmentCriteria(name: "准确性", description: "计算准确率", weight: 0.6, maxScore: 100, passingScore: 80),
                    AssessmentCriteria(name: "速度", description: "计算速度", weight: 0.4, maxScore: 100, passingScore: 70)
                ],
                passingScore: 75.0,
                feedback: "基础运算能力良好，继续练习提高速度"
            )
        ]
    }
}

// MARK: - 科学实验学习路径
extension EnhancedGoalTemplateExamples {
    
    private func createScienceExplorationLearningPath() -> LearningPathTemplate {
        let steps = [
            LearningStepTemplate(
                title: "实验安全",
                description: "学习实验安全知识和规范",
                order: 1,
                estimatedDuration: 20,
                difficulty: .beginner,
                prerequisites: [],
                learningObjectives: ["了解安全规范", "掌握安全操作", "识别危险因素"],
                contentTypes: [.reading, .assessment],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "基础实验",
                description: "进行基础科学实验",
                order: 2,
                estimatedDuration: 40,
                difficulty: .beginner,
                prerequisites: ["实验安全"],
                learningObjectives: ["掌握实验步骤", "观察实验现象", "记录实验结果"],
                contentTypes: [.exercise, .assessment],
                aiGeneratedContent: true
            ),
            LearningStepTemplate(
                title: "数据分析",
                description: "学习实验数据分析和结论",
                order: 3,
                estimatedDuration: 30,
                difficulty: .intermediate,
                prerequisites: ["基础实验"],
                learningObjectives: ["分析实验数据", "得出结论", "撰写实验报告"],
                contentTypes: [.writing, .assessment],
                aiGeneratedContent: true
            )
        ]
        
        let adaptiveRules = [
            AdaptiveRuleTemplate(
                condition: "安全知识掌握 < 90%",
                action: "增加安全知识学习",
                parameters: ["extraTime": "10分钟"],
                priority: 1
            )
        ]
        
        let progressTracking = ProgressTrackingTemplate(
            trackingMethods: [.completion, .quality],
            frequency: .weekly,
            metrics: [.completionRate, .quality],
            alerts: [.behind, .struggling]
        )
        
        return LearningPathTemplate(
            steps: steps,
            adaptiveAdjustments: adaptiveRules,
            progressTracking: progressTracking,
            milestoneCheckpoints: []
        )
    }
    
    private func createScienceExplorationContext() -> ContentContextTemplate {
        return ContentContextTemplate(
            background: "学生需要培养科学思维和实验技能",
            context: "学校科学课程，家长希望孩子能够安全地进行实验",
            targetAudience: "初中生，对科学实验感兴趣",
            learningEnvironment: "家庭实验室环境，需要成人监督",
            culturalContext: "中国科学教育体系",
            practicalApplications: ["科学探究", "问题解决", "批判思维", "实验技能"]
        )
    }
    
    private func createScienceExplorationMilestones() -> [MilestoneTemplate] {
        return [
            MilestoneTemplate(title: "安全规范", description: "掌握实验安全知识", duration: 7, order: 1),
            MilestoneTemplate(title: "基础实验", description: "完成5个基础实验", duration: 30, order: 2),
            MilestoneTemplate(title: "数据分析", description: "掌握数据分析方法", duration: 45, order: 3),
            MilestoneTemplate(title: "实验报告", description: "能够撰写实验报告", duration: 60, order: 4)
        ]
    }
    
    private func createScienceExplorationKeyResults() -> [KeyResultTemplate] {
        return [
            KeyResultTemplate(title: "安全知识", description: "安全知识测试达到90分", targetValue: 90, unit: "分"),
            KeyResultTemplate(title: "实验完成", description: "完成10个科学实验", targetValue: 10, unit: "个"),
            KeyResultTemplate(title: "报告质量", description: "实验报告平均分达到85分", targetValue: 85, unit: "分"),
            KeyResultTemplate(title: "学习时长", description: "累计学习30小时", targetValue: 30, unit: "小时")
        ]
    }
    
    private func createScienceExplorationTasks() -> [TaskTemplate] {
        return [
            TaskTemplate(title: "AI生成安全指导", description: "生成个性化实验安全指导", estimatedDuration: 15, difficulty: .easy, tags: ["AI生成", "安全"]),
            TaskTemplate(title: "AI生成实验步骤", description: "生成详细实验操作步骤", estimatedDuration: 25, difficulty: .medium, tags: ["AI生成", "实验"]),
            TaskTemplate(title: "AI生成数据分析", description: "生成数据分析指导", estimatedDuration: 20, difficulty: .medium, tags: ["AI生成", "分析"]),
            TaskTemplate(title: "AI生成报告模板", description: "生成实验报告写作模板", estimatedDuration: 30, difficulty: .hard, tags: ["AI生成", "报告"])
        ]
    }
    
    private func createScienceExplorationResources() -> [LearningResourceTemplate] {
        return [
            LearningResourceTemplate(
                title: "AI生成安全手册",
                description: "个性化实验安全手册",
                type: .textbook,
                difficulty: .beginner,
                estimatedDuration: 10,
                tags: ["AI生成", "安全"],
                aiGenerated: true
            ),
            LearningResourceTemplate(
                title: "AI生成实验指导",
                description: "个性化实验操作指导",
                type: .app,
                difficulty: .intermediate,
                estimatedDuration: 20,
                tags: ["AI生成", "实验"],
                aiGenerated: true
            )
        ]
    }
    
    private func createScienceExplorationAssessments() -> [AssessmentPointTemplate] {
        return [
            AssessmentPointTemplate(
                title: "安全知识测试",
                description: "测试实验安全知识掌握情况",
                type: .test,
                order: 1,
                criteria: [
                    AssessmentCriteria(name: "安全知识", description: "安全知识掌握程度", weight: 1.0, maxScore: 100, passingScore: 90)
                ],
                passingScore: 90.0,
                feedback: "安全知识掌握良好，可以开始实验"
            )
        ]
    }
}
