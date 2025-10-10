//
//  EnhancedGoalTemplate.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation

// MARK: - 增强的学习目标模板
struct EnhancedGoalTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let category: SubjectCategory
    let goalType: GoalType
    let priority: Priority
    let duration: Int // 天数
    let icon: String
    let tags: [String]
    
    // 增强的学习路径
    let learningPath: LearningPathTemplate
    let contentContext: ContentContextTemplate
    let aiGeneratedContent: Bool
    
    // 原有的基础结构
    let milestones: [MilestoneTemplate]
    let keyResults: [KeyResultTemplate]
    let suggestedTasks: [TaskTemplate]
    
    // 新增：学习资源
    let learningResources: [LearningResourceTemplate]
    let assessmentPoints: [AssessmentPointTemplate]
    let difficultyProgression: [DifficultyLevel]
    
    init(id: UUID = UUID(), 
         name: String, 
         description: String, 
         category: SubjectCategory, 
         goalType: GoalType, 
         priority: Priority, 
         duration: Int, 
         icon: String, 
         tags: [String],
         learningPath: LearningPathTemplate,
         contentContext: ContentContextTemplate,
         aiGeneratedContent: Bool = true,
         milestones: [MilestoneTemplate] = [],
         keyResults: [KeyResultTemplate] = [],
         suggestedTasks: [TaskTemplate] = [],
         learningResources: [LearningResourceTemplate] = [],
         assessmentPoints: [AssessmentPointTemplate] = [],
         difficultyProgression: [DifficultyLevel] = [.beginner, .intermediate, .advanced]) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.goalType = goalType
        self.priority = priority
        self.duration = duration
        self.icon = icon
        self.tags = tags
        self.learningPath = learningPath
        self.contentContext = contentContext
        self.aiGeneratedContent = aiGeneratedContent
        self.milestones = milestones
        self.keyResults = keyResults
        self.suggestedTasks = suggestedTasks
        self.learningResources = learningResources
        self.assessmentPoints = assessmentPoints
        self.difficultyProgression = difficultyProgression
    }
    
    // 转换为学习目标
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

// MARK: - 学习路径模板
struct LearningPathTemplate: Codable {
    let steps: [LearningStepTemplate]
    let adaptiveAdjustments: [AdaptiveRuleTemplate]
    let progressTracking: ProgressTrackingTemplate
    let milestoneCheckpoints: [MilestoneCheckpointTemplate]
    
    init(steps: [LearningStepTemplate] = [],
         adaptiveAdjustments: [AdaptiveRuleTemplate] = [],
         progressTracking: ProgressTrackingTemplate = ProgressTrackingTemplate(),
         milestoneCheckpoints: [MilestoneCheckpointTemplate] = []) {
        self.steps = steps
        self.adaptiveAdjustments = adaptiveAdjustments
        self.progressTracking = progressTracking
        self.milestoneCheckpoints = milestoneCheckpoints
    }
}

// MARK: - 学习步骤模板
struct LearningStepTemplate: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let order: Int
    let estimatedDuration: Int // 分钟
    let difficulty: DifficultyLevel
    let prerequisites: [String] // 前置条件
    let learningObjectives: [String] // 学习目标
    let contentTypes: [ContentType] // 内容类型
    let aiGeneratedContent: Bool // 是否使用AI生成内容
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         order: Int,
         estimatedDuration: Int,
         difficulty: DifficultyLevel,
         prerequisites: [String] = [],
         learningObjectives: [String] = [],
         contentTypes: [ContentType] = [],
         aiGeneratedContent: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.order = order
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.prerequisites = prerequisites
        self.learningObjectives = learningObjectives
        self.contentTypes = contentTypes
        self.aiGeneratedContent = aiGeneratedContent
    }
}

// MARK: - 内容上下文模板
struct ContentContextTemplate: Codable {
    let background: String // 学习背景
    let context: String // 具体上下文
    let targetAudience: String // 目标受众
    let learningEnvironment: String // 学习环境
    let culturalContext: String // 文化背景
    let practicalApplications: [String] // 实际应用场景
    
    init(background: String = "",
         context: String = "",
         targetAudience: String = "",
         learningEnvironment: String = "",
         culturalContext: String = "",
         practicalApplications: [String] = []) {
        self.background = background
        self.context = context
        self.targetAudience = targetAudience
        self.learningEnvironment = learningEnvironment
        self.culturalContext = culturalContext
        self.practicalApplications = practicalApplications
    }
}

// MARK: - 学习资源模板
struct LearningResourceTemplate: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: ResourceType
    let url: String?
    let content: String? // 如果是文本内容
    let difficulty: DifficultyLevel
    let estimatedDuration: Int // 分钟
    let tags: [String]
    let aiGenerated: Bool // 是否AI生成
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         type: ResourceType,
         url: String? = nil,
         content: String? = nil,
         difficulty: DifficultyLevel = .beginner,
         estimatedDuration: Int = 30,
         tags: [String] = [],
         aiGenerated: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.url = url
        self.content = content
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.tags = tags
        self.aiGenerated = aiGenerated
    }
}

// MARK: - 评估点模板
struct AssessmentPointTemplate: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: AssessmentType
    let order: Int
    let criteria: [AssessmentCriteria]
    let passingScore: Double
    let feedback: String
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         type: AssessmentType,
         order: Int,
         criteria: [AssessmentCriteria] = [],
         passingScore: Double = 70.0,
         feedback: String = "") {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.order = order
        self.criteria = criteria
        self.passingScore = passingScore
        self.feedback = feedback
    }
}

// MARK: - 自适应规则模板
struct AdaptiveRuleTemplate: Codable {
    let condition: String // 触发条件
    let action: String // 执行动作
    let parameters: [String: String] // 参数
    let priority: Int // 优先级
}

// MARK: - 进度跟踪模板
struct ProgressTrackingTemplate: Codable {
    let trackingMethods: [TrackingMethod]
    let frequency: TrackingFrequency
    let metrics: [ProgressMetric]
    let alerts: [ProgressAlert]
    
    init(trackingMethods: [TrackingMethod] = [.completion, .time],
         frequency: TrackingFrequency = .daily,
         metrics: [ProgressMetric] = [.completionRate, .timeSpent],
         alerts: [ProgressAlert] = []) {
        self.trackingMethods = trackingMethods
        self.frequency = frequency
        self.metrics = metrics
        self.alerts = alerts
    }
}

// MARK: - 里程碑检查点模板
struct MilestoneCheckpointTemplate: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let order: Int
    let requiredTasks: [String] // 必需完成的任务
    let assessmentCriteria: [AssessmentCriteria]
    let unlockConditions: [String] // 解锁条件
    
    init(id: UUID = UUID(),
         title: String,
         description: String,
         order: Int,
         requiredTasks: [String] = [],
         assessmentCriteria: [AssessmentCriteria] = [],
         unlockConditions: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.order = order
        self.requiredTasks = requiredTasks
        self.assessmentCriteria = assessmentCriteria
        self.unlockConditions = unlockConditions
    }
}

// MARK: - 支持枚举

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        case .expert: return "4.circle"
        }
    }
}

enum ContentType: String, CaseIterable, Codable {
    case vocabulary = "词汇"
    case grammar = "语法"
    case conversation = "对话"
    case reading = "阅读"
    case writing = "写作"
    case listening = "听力"
    case speaking = "口语"
    case exercise = "练习"
    case assessment = "评估"
    
    var icon: String {
        switch self {
        case .vocabulary: return "textformat.abc"
        case .grammar: return "doc.text"
        case .conversation: return "bubble.left.and.bubble.right"
        case .reading: return "book"
        case .writing: return "pencil"
        case .listening: return "headphones"
        case .speaking: return "mic"
        case .exercise: return "checkmark.circle"
        case .assessment: return "chart.bar"
        }
    }
}

// ResourceType 已在 Student.swift 中定义，这里移除重复定义

enum AssessmentType: String, CaseIterable, Codable {
    case quiz = "测验"
    case assignment = "作业"
    case project = "项目"
    case presentation = "展示"
    case test = "测试"
    case selfAssessment = "自评"
    case peerReview = "互评"
    
    var icon: String {
        switch self {
        case .quiz: return "questionmark.circle"
        case .assignment: return "doc.text"
        case .project: return "folder"
        case .presentation: return "presentation"
        case .test: return "pencil.and.outline"
        case .selfAssessment: return "person.circle"
        case .peerReview: return "person.2"
        }
    }
}

enum TrackingMethod: String, CaseIterable, Codable {
    case completion = "完成度"
    case time = "时间"
    case score = "分数"
    case frequency = "频率"
    case quality = "质量"
}

enum TrackingFrequency: String, CaseIterable, Codable {
    case daily = "每日"
    case weekly = "每周"
    case monthly = "每月"
    case milestone = "里程碑"
}

enum ProgressMetric: String, CaseIterable, Codable {
    case completionRate = "完成率"
    case timeSpent = "学习时长"
    case score = "得分"
    case streak = "连续天数"
    case improvement = "进步幅度"
    case quality = "质量"
}

enum ProgressAlert: String, CaseIterable, Codable {
    case behind = "进度落后"
    case ahead = "进度超前"
    case struggling = "学习困难"
    case excellent = "表现优秀"
}

// MARK: - 评估标准
struct AssessmentCriteria: Codable {
    let name: String
    let description: String
    let weight: Double // 权重
    let maxScore: Double // 最高分
    let passingScore: Double // 及格分
}
