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

// MARK: - 增强模板数据结构（使用 EnhancedGoalTemplate.swift 中的定义）

// MARK: - 模板管理器
class GoalTemplateManager: ObservableObject {
    static let shared = GoalTemplateManager()
    @Published var templates: [GoalTemplate] = []
    
    private init() {
        loadTemplatesFromJSON()
    }
    
    // MARK: - 从JSON文件加载模板
    private func loadTemplatesFromJSON() {
        var allTemplates: [GoalTemplate] = []
        
        // 直接加载已知的模板文件
        let templateFiles = [
            // Math templates
            "advanced_math_review",
            "junior_math_grade7",
            "junior_math_grade8", 
            "junior_math_grade9",
            // Chinese templates
            "classical_chinese_learning",
            "classical_literature_reading",
            "tang_song_poetry_learning",
            "writing_skills_improvement",
            "junior_chinese_grade7",
            "junior_chinese_grade8",
            "junior_chinese_grade9",
            // English templates
            "english_speaking_improvement",
            "middle_school_english_improvement",
            "junior_english_grade7",
            "junior_english_grade8",
            "junior_english_grade9",
            // Skills templates
            "python_programming_basics",
            "time_management_skills"
        ]
        
        for templateFile in templateFiles {
            // 尝试从不同目录加载模板文件
            let possiblePaths = [
                templateFile, // 根目录
                "Templates/Math/\(templateFile)",
                "Templates/Chinese/\(templateFile)", 
                "Templates/English/\(templateFile)",
                "Templates/Skills/\(templateFile)",
                "Templates/Science/\(templateFile)"
            ]
            
            var templateLoaded = false
            for path in possiblePaths {
                if let bundlePath = Bundle.main.path(forResource: path, ofType: "json") {
                    if let template = loadTemplateFromFile(bundlePath) {
                        allTemplates.append(template)
                        print("✅ 加载模板: \(template.name) (从 \(path))")
                        templateLoaded = true
                        break
                    }
                }
            }
            
            if !templateLoaded {
                print("❌ 无法找到模板文件: \(templateFile).json")
            }
        }
        
        if allTemplates.isEmpty {
            print("❌ 没有加载到任何模板，使用默认模板")
            loadDefaultTemplates()
        } else {
            templates = allTemplates.sorted { $0.name < $1.name }
            print("✅ 成功从独立JSON文件加载了 \(templates.count) 个目标模板")
        }
    }
    
    // MARK: - 从文件加载单个模板
    private func loadTemplateFromFile(_ filePath: String) -> GoalTemplate? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let templateData = try JSONDecoder().decode(TemplateDataModel.self, from: data)
            return templateData.toGoalTemplate()
        } catch {
            print("❌ 加载模板文件失败: \(filePath), 错误: \(error)")
            return nil
        }
    }
    
    // MARK: - 备用默认模板
    private func loadDefaultTemplates() {
        print("⚠️ 使用默认模板数据")
        templates = [
            GoalTemplate(
                name: "英语口语提升",
                description: "通过日常练习和对话，提升英语口语表达能力",
                category: SubjectCategory.english,
                goalType: GoalType.smart,
                priority: Priority.high,
                duration: 90,
                icon: "speaker.wave.2",
                tags: ["口语", "英语", "日常对话"],
                milestones: [
                    MilestoneTemplate(title: "基础发音练习", description: "掌握基本音标和发音规则", duration: 14, order: 1)
                ],
                keyResults: [
                    KeyResultTemplate(title: "每日练习时长", description: "每天至少练习30分钟", targetValue: 30, unit: "分钟")
                ],
                suggestedTasks: [
                    TaskTemplate(title: "音标练习", description: "练习英语音标发音", estimatedDuration: 15, difficulty: .easy, tags: ["发音", "基础"])
                ]
            )
        ]
    }
    
    // MARK: - 重新加载模板
    func reloadTemplates() {
        loadTemplatesFromJSON()
    }
    
    // MARK: - 添加新模板
    func addTemplate(_ template: GoalTemplate) {
        templates.append(template)
        saveTemplatesToJSON()
    }
    
    // MARK: - 更新模板
    func updateTemplate(_ template: GoalTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplatesToJSON()
        }
    }
    
    // MARK: - 删除模板
    func deleteTemplate(_ template: GoalTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplatesToJSON()
    }
    
    // MARK: - 保存模板到JSON文件
    private func saveTemplatesToJSON() {
        // 注意：在iOS应用中，Bundle.main是只读的，无法直接写入
        // 这里只是示例，实际应用中需要将模板保存到Documents目录或使用其他存储方式
        print("💾 模板已更新，当前模板数量: \(templates.count)")
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

// MARK: - JSON数据模型
struct TemplateData: Codable {
    let templates: [TemplateDataModel]
}

struct TemplateDataModel: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let goalType: String
    let priority: String
    let duration: Int
    let icon: String
    let tags: [String]
    let milestones: [MilestoneDataModel]
    let keyResults: [KeyResultDataModel]
    let suggestedTasks: [TaskDataModel]
    
    func toGoalTemplate() -> GoalTemplate {
        return GoalTemplate(
            name: name,
            description: description,
            category: SubjectCategory(rawValue: category) ?? .other,
            goalType: GoalType(rawValue: goalType) ?? .smart,
            priority: Priority(rawValue: priority) ?? .medium,
            duration: duration,
            icon: icon,
            tags: tags,
            milestones: milestones.map { $0.toMilestoneTemplate() },
            keyResults: keyResults.map { $0.toKeyResultTemplate() },
            suggestedTasks: suggestedTasks.map { $0.toTaskTemplate() }
        )
    }
}

struct MilestoneDataModel: Codable {
    let title: String
    let description: String
    let duration: Int
    let order: Int
    
    func toMilestoneTemplate() -> MilestoneTemplate {
        return MilestoneTemplate(
            title: title,
            description: description,
            duration: duration,
            order: order
        )
    }
}

struct KeyResultDataModel: Codable {
    let title: String
    let description: String
    let targetValue: Double
    let unit: String
    
    func toKeyResultTemplate() -> KeyResultTemplate {
        return KeyResultTemplate(
            title: title,
            description: description,
            targetValue: targetValue,
            unit: unit
        )
    }
}

struct TaskDataModel: Codable {
    let title: String
    let description: String
    let estimatedDuration: Int
    let difficulty: String
    let tags: [String]
    
    func toTaskTemplate() -> TaskTemplate {
        let difficultyLevel: TaskDifficulty
        switch difficulty.lowercased() {
        case "easy", "简单":
            difficultyLevel = .easy
        case "hard", "困难":
            difficultyLevel = .hard
        default:
            difficultyLevel = .medium
        }
        
        return TaskTemplate(
            title: title,
            description: description,
            estimatedDuration: estimatedDuration,
            difficulty: difficultyLevel,
            tags: tags
        )
    }
}

// MARK: - 增强字段的JSON数据模型（使用 EnhancedGoalTemplate.swift 中的定义）
