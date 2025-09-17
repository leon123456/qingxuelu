//
//  GoalTemplate.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/10.
//

import Foundation

// MARK: - 学习目标模板
struct GoalTemplate: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let category: SubjectCategory
    let goalType: GoalType
    let priority: Priority
    let duration: Int // 天数
    let icon: String
    let tags: [String]
    let milestones: [MilestoneTemplate]
    let keyResults: [KeyResultTemplate]
    let suggestedTasks: [TaskTemplate]
    
    // 将模板转换为学习目标
    func toLearningGoal() -> LearningGoal {
        let targetDate = Date().addingTimeInterval(TimeInterval(duration * 24 * 3600))
        
        var goal = LearningGoal(
            title: name,
            description: description,
            category: category,
            priority: priority,
            targetDate: targetDate,
            goalType: goalType
        )
        
        // 转换里程碑
        goal.milestones = milestones.map { $0.toMilestone() }
        
        // 转换关键结果
        goal.keyResults = keyResults.map { $0.toKeyResult() }
        
        return goal
    }
}

// MARK: - 里程碑模板
struct MilestoneTemplate: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let duration: Int // 相对于目标开始的天数
    let order: Int
    
    func toMilestone() -> Milestone {
        let targetDate = Date().addingTimeInterval(TimeInterval(duration * 24 * 3600))
        return Milestone(
            title: title,
            description: description,
            targetDate: targetDate
        )
    }
}

// MARK: - 关键结果模板
struct KeyResultTemplate: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let targetValue: Double
    let unit: String
    
    func toKeyResult() -> KeyResult {
        return KeyResult(
            title: title,
            description: description,
            targetValue: targetValue,
            unit: unit
        )
    }
}

// MARK: - 任务模板
struct TaskTemplate: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let estimatedDuration: Int // 分钟
    let difficulty: TaskDifficulty
    let tags: [String]
    
    func toLearningTask(goalId: UUID) -> LearningTask {
        return LearningTask(
            title: title,
            description: description,
            category: .other, // 默认分类，用户可以在创建后修改
            priority: .medium, // 默认优先级，用户可以在创建后修改
            estimatedDuration: TimeInterval(estimatedDuration * 60), // 转换为秒
            goalId: goalId
        )
    }
}

// MARK: - 任务难度
enum TaskDifficulty: String, CaseIterable, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

// MARK: - 模板管理器
class GoalTemplateManager: ObservableObject {
    static let shared = GoalTemplateManager()
    @Published var templates: [GoalTemplate] = []
    
    private init() {
        loadDefaultTemplates()
    }
    
    private func loadDefaultTemplates() {
        templates = [
            // 语言学习模板
            GoalTemplate(
                name: "英语口语提升",
                description: "通过日常练习和对话，提升英语口语表达能力",
                category: .english,
                goalType: .smart,
                priority: .high,
                duration: 90,
                icon: "speaker.wave.2",
                tags: ["口语", "英语", "日常对话"],
                milestones: [
                    MilestoneTemplate(title: "基础发音练习", description: "掌握基本音标和发音规则", duration: 14, order: 1),
                    MilestoneTemplate(title: "日常对话练习", description: "能够进行基本的日常对话", duration: 30, order: 2),
                    MilestoneTemplate(title: "话题讨论", description: "能够就常见话题进行深入讨论", duration: 60, order: 3),
                    MilestoneTemplate(title: "流利表达", description: "能够流利地表达复杂观点", duration: 90, order: 4)
                ],
                keyResults: [
                    KeyResultTemplate(title: "每日练习时长", description: "每天至少练习30分钟", targetValue: 30, unit: "分钟"),
                    KeyResultTemplate(title: "对话次数", description: "每周进行至少3次英语对话", targetValue: 3, unit: "次"),
                    KeyResultTemplate(title: "词汇量增长", description: "掌握500个新词汇", targetValue: 500, unit: "个")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "音标练习", description: "练习英语音标发音", estimatedDuration: 15, difficulty: .easy, tags: ["发音", "基础"]),
                    TaskTemplate(title: "跟读练习", description: "跟着录音进行跟读练习", estimatedDuration: 20, difficulty: .medium, tags: ["跟读", "听力"]),
                    TaskTemplate(title: "话题讨论", description: "就指定话题进行英语讨论", estimatedDuration: 30, difficulty: .hard, tags: ["讨论", "表达"])
                ]
            ),
            
            // 编程学习模板
            GoalTemplate(
                name: "Python编程入门",
                description: "从零开始学习Python编程，掌握基础语法和常用库",
                category: .other,
                goalType: .smart,
                priority: .high,
                duration: 60,
                icon: "laptopcomputer",
                tags: ["编程", "Python", "入门"],
                milestones: [
                    MilestoneTemplate(title: "基础语法", description: "掌握Python基本语法和数据类型", duration: 14, order: 1),
                    MilestoneTemplate(title: "控制结构", description: "学会使用条件语句和循环", duration: 21, order: 2),
                    MilestoneTemplate(title: "函数和模块", description: "理解函数定义和模块使用", duration: 35, order: 3),
                    MilestoneTemplate(title: "项目实战", description: "完成一个完整的Python项目", duration: 60, order: 4)
                ],
                keyResults: [
                    KeyResultTemplate(title: "代码练习", description: "完成100道编程练习题", targetValue: 100, unit: "题"),
                    KeyResultTemplate(title: "项目数量", description: "完成3个实际项目", targetValue: 3, unit: "个"),
                    KeyResultTemplate(title: "学习时长", description: "累计学习60小时", targetValue: 60, unit: "小时")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "语法学习", description: "学习Python基础语法", estimatedDuration: 60, difficulty: .easy, tags: ["语法", "基础"]),
                    TaskTemplate(title: "编程练习", description: "完成编程练习题", estimatedDuration: 45, difficulty: .medium, tags: ["练习", "实战"]),
                    TaskTemplate(title: "项目开发", description: "开发一个完整的项目", estimatedDuration: 120, difficulty: .hard, tags: ["项目", "综合"])
                ]
            ),
            
            // 数学学习模板
            GoalTemplate(
                name: "高等数学复习",
                description: "系统复习高等数学知识，准备考试",
                category: .math,
                goalType: .okr,
                priority: .medium,
                duration: 30,
                icon: "function",
                tags: ["数学", "复习", "考试"],
                milestones: [
                    MilestoneTemplate(title: "微积分基础", description: "复习微积分基本概念", duration: 7, order: 1),
                    MilestoneTemplate(title: "积分计算", description: "掌握各种积分计算方法", duration: 14, order: 2),
                    MilestoneTemplate(title: "级数理论", description: "学习级数收敛性判断", duration: 21, order: 3),
                    MilestoneTemplate(title: "综合练习", description: "进行综合题型练习", duration: 30, order: 4)
                ],
                keyResults: [
                    KeyResultTemplate(title: "章节完成", description: "完成8个主要章节", targetValue: 8, unit: "章"),
                    KeyResultTemplate(title: "练习题", description: "完成200道练习题", targetValue: 200, unit: "题"),
                    KeyResultTemplate(title: "模拟考试", description: "完成5次模拟考试", targetValue: 5, unit: "次")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "概念复习", description: "复习数学概念和定理", estimatedDuration: 30, difficulty: .easy, tags: ["概念", "理论"]),
                    TaskTemplate(title: "计算练习", description: "进行数学计算练习", estimatedDuration: 45, difficulty: .medium, tags: ["计算", "练习"]),
                    TaskTemplate(title: "综合题", description: "解决综合性数学问题", estimatedDuration: 60, difficulty: .hard, tags: ["综合", "应用"])
                ]
            ),
            
            // 阅读学习模板
            GoalTemplate(
                name: "经典文学阅读",
                description: "阅读经典文学作品，提升文学素养",
                category: .chinese,
                goalType: .hybrid,
                priority: .medium,
                duration: 45,
                icon: "book",
                tags: ["阅读", "文学", "经典"],
                milestones: [
                    MilestoneTemplate(title: "选书规划", description: "选择并规划阅读书目", duration: 3, order: 1),
                    MilestoneTemplate(title: "第一本书", description: "完成第一本经典作品阅读", duration: 15, order: 2),
                    MilestoneTemplate(title: "第二本书", description: "完成第二本经典作品阅读", duration: 30, order: 3),
                    MilestoneTemplate(title: "读书笔记", description: "整理读书笔记和感悟", duration: 45, order: 4)
                ],
                keyResults: [
                    KeyResultTemplate(title: "阅读数量", description: "完成3本经典作品", targetValue: 3, unit: "本"),
                    KeyResultTemplate(title: "读书笔记", description: "写10篇读书笔记", targetValue: 10, unit: "篇"),
                    KeyResultTemplate(title: "阅读时长", description: "累计阅读30小时", targetValue: 30, unit: "小时")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "选书阅读", description: "阅读指定章节", estimatedDuration: 60, difficulty: .easy, tags: ["阅读", "理解"]),
                    TaskTemplate(title: "读书笔记", description: "写读书笔记和感悟", estimatedDuration: 30, difficulty: .medium, tags: ["笔记", "思考"]),
                    TaskTemplate(title: "作品分析", description: "分析作品主题和技巧", estimatedDuration: 45, difficulty: .hard, tags: ["分析", "文学"])
                ]
            ),
            
            // 技能提升模板
            GoalTemplate(
                name: "时间管理技能",
                description: "学习并实践时间管理技巧，提高工作效率",
                category: .other,
                goalType: .smart,
                priority: .high,
                duration: 21,
                icon: "clock",
                tags: ["时间管理", "效率", "技能"],
                milestones: [
                    MilestoneTemplate(title: "理论学习", description: "学习时间管理基本理论", duration: 3, order: 1),
                    MilestoneTemplate(title: "工具实践", description: "使用时间管理工具", duration: 7, order: 2),
                    MilestoneTemplate(title: "习惯养成", description: "养成良好时间管理习惯", duration: 14, order: 3),
                    MilestoneTemplate(title: "效果评估", description: "评估时间管理效果", duration: 21, order: 4)
                ],
                keyResults: [
                    KeyResultTemplate(title: "任务完成率", description: "每日任务完成率达到90%", targetValue: 90, unit: "%"),
                    KeyResultTemplate(title: "效率提升", description: "工作效率提升30%", targetValue: 30, unit: "%"),
                    KeyResultTemplate(title: "工具使用", description: "熟练使用3种时间管理工具", targetValue: 3, unit: "种")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "理论学习", description: "学习时间管理理论", estimatedDuration: 30, difficulty: .easy, tags: ["理论", "学习"]),
                    TaskTemplate(title: "工具使用", description: "使用时间管理工具", estimatedDuration: 20, difficulty: .medium, tags: ["工具", "实践"]),
                    TaskTemplate(title: "习惯培养", description: "培养时间管理习惯", estimatedDuration: 15, difficulty: .hard, tags: ["习惯", "坚持"])
                ]
            ),
            
            // 初中英语成绩提升模板
            GoalTemplate(
                name: "提升初中英语成绩",
                description: "在本学期结束时，英语成绩提升至班级前 10 名，期末考试 ≥ 90 分，并养成稳定的学习习惯。",
                category: .english,
                goalType: .okr,
                priority: .high,
                duration: 90, // 一个学期约90天
                icon: "graduationcap.fill",
                tags: ["英语", "成绩提升", "初中", "OKR"],
                milestones: [
                    MilestoneTemplate(title: "词汇积累", description: "掌握并熟练运用 800 个核心单词，每周新增 ≥50 单词", duration: 30, order: 1),
                    MilestoneTemplate(title: "阅读理解", description: "完成 12 篇英语阅读理解练习，阅读正确率 ≥80%", duration: 45, order: 2),
                    MilestoneTemplate(title: "写作能力", description: "完成 15 篇英语作文，至少 5 篇作文得分 ≥85/100", duration: 60, order: 3),
                    MilestoneTemplate(title: "听力与口语", description: "每周 30 分钟听力训练，参与 5 次口语对话练习", duration: 75, order: 4),
                    MilestoneTemplate(title: "考试模拟", description: "完成 6 套英语模拟试卷，错题订正率 ≥90%", duration: 90, order: 5)
                ],
                keyResults: [
                    KeyResultTemplate(title: "词汇掌握", description: "掌握并熟练运用 800 个核心单词", targetValue: 800, unit: "个"),
                    KeyResultTemplate(title: "阅读理解", description: "完成 12 篇英语阅读理解练习", targetValue: 12, unit: "篇"),
                    KeyResultTemplate(title: "阅读正确率", description: "阅读正确率 ≥80%", targetValue: 80, unit: "%"),
                    KeyResultTemplate(title: "作文完成", description: "完成 15 篇英语作文", targetValue: 15, unit: "篇"),
                    KeyResultTemplate(title: "高分作文", description: "至少 5 篇作文得分 ≥85/100", targetValue: 5, unit: "篇"),
                    KeyResultTemplate(title: "听力训练", description: "每周 30 分钟听力训练", targetValue: 6, unit: "小时"),
                    KeyResultTemplate(title: "口语练习", description: "参与 5 次口语对话练习", targetValue: 5, unit: "次"),
                    KeyResultTemplate(title: "模拟考试", description: "完成 6 套英语模拟试卷", targetValue: 6, unit: "套"),
                    KeyResultTemplate(title: "错题订正", description: "错题订正率 ≥90%", targetValue: 90, unit: "%")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "单词背诵", description: "背诵20个新单词", estimatedDuration: 30, difficulty: .easy, tags: ["词汇", "背诵"]),
                    TaskTemplate(title: "阅读理解", description: "完成一篇英语阅读理解", estimatedDuration: 25, difficulty: .medium, tags: ["阅读", "理解"]),
                    TaskTemplate(title: "英语作文", description: "写一篇英语作文", estimatedDuration: 45, difficulty: .medium, tags: ["写作", "作文"]),
                    TaskTemplate(title: "听力练习", description: "进行30分钟听力训练", estimatedDuration: 30, difficulty: .easy, tags: ["听力", "练习"]),
                    TaskTemplate(title: "口语对话", description: "参与英语口语对话练习", estimatedDuration: 20, difficulty: .hard, tags: ["口语", "对话"]),
                    TaskTemplate(title: "模拟考试", description: "完成一套英语模拟试卷", estimatedDuration: 90, difficulty: .hard, tags: ["考试", "模拟"]),
                    TaskTemplate(title: "错题订正", description: "订正错题并总结", estimatedDuration: 20, difficulty: .medium, tags: ["订正", "总结"])
                ]
            )
        ]
    }
    
    // 根据分类获取模板
    func getTemplates(for category: SubjectCategory) -> [GoalTemplate] {
        return templates.filter { $0.category == category }
    }
    
    // 根据标签搜索模板
    func searchTemplates(query: String) -> [GoalTemplate] {
        if query.isEmpty {
            return templates
        }
        
        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.description.localizedCaseInsensitiveContains(query) ||
            template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
