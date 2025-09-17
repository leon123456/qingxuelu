//
//  Student.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation

// MARK: - 学生信息模型
struct Student: Identifiable, Codable {
    let id: UUID
    var name: String
    var grade: String
    var school: String
    var avatar: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, grade: String, school: String, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.grade = grade
        self.school = school
        self.avatar = avatar
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 学习目标模型
struct LearningGoal: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID  // 新增：关联用户，第一版暂不使用
    var planId: UUID?  // 关联的学习计划ID
    var title: String
    var description: String
    var category: SubjectCategory
    var priority: Priority
    var status: GoalStatus
    var startDate: Date
    var targetDate: Date
    var actualEndDate: Date?
    var progress: Double // 0.0 - 1.0
    var milestones: [Milestone]
    var keyResults: [KeyResult] // OKR关键结果
    var goalType: GoalType // SMART 或 OKR
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), userId: UUID = UUID(), planId: UUID? = nil, title: String, description: String, category: SubjectCategory, priority: Priority, targetDate: Date, goalType: GoalType = .smart) {
        self.id = id
        self.userId = userId
        self.planId = planId
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.status = .notStarted
        self.startDate = Date()
        self.targetDate = targetDate
        self.progress = 0.0
        self.milestones = []
        self.keyResults = []
        self.goalType = goalType
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 关键结果模型（OKR）
struct KeyResult: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var targetValue: Double
    var currentValue: Double
    var unit: String // 单位，如"分"、"题"、"小时"
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, description: String, targetValue: Double, unit: String) {
        self.id = id
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = 0.0
        self.unit = unit
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    var progress: Double {
        return targetValue > 0 ? min(currentValue / targetValue, 1.0) : 0.0
    }
}

// MARK: - 目标类型枚举
enum GoalType: String, CaseIterable, Codable {
    case smart = "SMART目标"
    case okr = "OKR目标"
    case hybrid = "混合模式"
    
    var description: String {
        switch self {
        case .smart:
            return "具体、可衡量、可实现、相关、有时限的目标"
        case .okr:
            return "有挑战性的目标，通过关键结果衡量"
        case .hybrid:
            return "结合SMART和OKR的优势"
        }
    }
    
    var icon: String {
        switch self {
        case .smart: return "target"
        case .okr: return "chart.line.uptrend.xyaxis"
        case .hybrid: return "star.fill"
        }
    }
}

// MARK: - 里程碑模型
struct Milestone: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var targetDate: Date
    var completedDate: Date?
    var isCompleted: Bool
    var progress: Double
    
    init(id: UUID = UUID(), title: String, description: String, targetDate: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.progress = 0.0
    }
}

// MARK: - 学习任务模型
struct LearningTask: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID  // 新增：关联用户，第一版暂不使用
    var title: String
    var description: String
    var category: SubjectCategory
    var priority: Priority
    var status: TaskStatus
    var estimatedDuration: TimeInterval // 预估学习时间（分钟）
    var actualDuration: TimeInterval? // 实际学习时间
    var dueDate: Date?
    var completedDate: Date?
    var goalId: UUID? // 关联的学习目标
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), userId: UUID = UUID(), title: String, description: String, category: SubjectCategory, priority: Priority, estimatedDuration: TimeInterval, goalId: UUID? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.status = .pending
        self.estimatedDuration = estimatedDuration
        self.goalId = goalId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 学习记录模型
struct LearningRecord: Identifiable, Codable {
    let id: UUID
    var userId: UUID  // 新增：关联用户，第一版暂不使用
    var taskId: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var notes: String?
    var rating: Int? // 学习质量评分 1-5
    var createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID = UUID(), taskId: UUID, startTime: Date, endTime: Date, notes: String? = nil, rating: Int? = nil) {
        self.id = id
        self.userId = userId
        self.taskId = taskId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.notes = notes
        self.rating = rating
        self.createdAt = Date()
    }
}

// MARK: - 枚举定义

enum SubjectCategory: String, CaseIterable, Codable {
    case chinese = "语文"
    case math = "数学"
    case english = "英语"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .chinese: return "book.fill"
        case .math: return "function"
        case .english: return "globe"
        case .physics: return "atom"
        case .chemistry: return "flask.fill"
        case .biology: return "leaf.fill"
        case .history: return "clock.fill"
        case .geography: return "map.fill"
        case .politics: return "building.columns.fill"
        case .other: return "bookmark.fill"
        }
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case urgent = "紧急"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

enum GoalStatus: String, CaseIterable, Codable {
    case notStarted = "未开始"
    case inProgress = "进行中"
    case completed = "已完成"
    case paused = "已暂停"
    case cancelled = "已取消"
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .paused: return "yellow"
        case .cancelled: return "red"
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "待开始"
    case inProgress = "进行中"
    case completed = "已完成"
    case overdue = "已逾期"
    case cancelled = "已取消"
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .overdue: return "red"
        case .cancelled: return "orange"
        }
    }
}

// MARK: - 学习计划
struct LearningPlan: Identifiable, Codable {
    let id: UUID  // 这个ID就是目标的ID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var totalWeeks: Int
    var weeklyPlans: [WeeklyPlan]
    var resources: [LearningResource]
    var isActive: Bool
    var createdAt: Date
    var userId: UUID = UUID() // 默认值，第一版暂不使用
    
    init(id: UUID, title: String, description: String, startDate: Date, endDate: Date, totalWeeks: Int, weeklyPlans: [WeeklyPlan] = [], resources: [LearningResource] = [], isActive: Bool = true, userId: UUID = UUID()) {
        self.id = id  // 使用目标的ID
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.totalWeeks = totalWeeks
        self.weeklyPlans = weeklyPlans
        self.resources = resources
        self.isActive = isActive
        self.createdAt = Date()
        self.userId = userId
    }
}

// MARK: - 周任务
struct WeeklyTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var quantity: String // 具体数量，如"20个单词"、"5道题"
    var duration: String // 预估时长，如"30分钟"、"2小时"
    var difficulty: String // 难度等级，如"简单"、"中等"、"困难"
    var isCompleted: Bool
    var startedDate: Date? // 实际开始时间
    var completedDate: Date? // 实际完成时间
    var actualDuration: TimeInterval? // 实际耗时（秒）
    var completionNotes: String? // 完成备注
    var completionRating: Int? // 完成质量评分 1-5
    var completionProgress: Double? // 完成度 0.0-1.0
    
    init(id: UUID = UUID(), title: String, description: String = "", quantity: String = "", duration: String = "", difficulty: String = "中等", isCompleted: Bool = false, startedDate: Date? = nil, completedDate: Date? = nil, actualDuration: TimeInterval? = nil, completionNotes: String? = nil, completionRating: Int? = nil, completionProgress: Double? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.quantity = quantity
        self.duration = duration
        self.difficulty = difficulty
        self.isCompleted = isCompleted
        self.startedDate = startedDate
        self.completedDate = completedDate
        self.actualDuration = actualDuration
        self.completionNotes = completionNotes
        self.completionRating = completionRating
        self.completionProgress = completionProgress
    }
}

// MARK: - 周计划
struct WeeklyPlan: Identifiable, Codable {
    let id: UUID
    var weekNumber: Int
    var startDate: Date
    var endDate: Date
    var milestones: [String]
    var taskCount: Int
    var estimatedHours: Double
    var completedTasks: Int
    var isCompleted: Bool
    var tasks: [WeeklyTask] // 新增：具体的任务列表
    
    init(id: UUID = UUID(), weekNumber: Int, startDate: Date, endDate: Date, milestones: [String] = [], taskCount: Int = 0, estimatedHours: Double = 0, completedTasks: Int = 0, isCompleted: Bool = false, tasks: [WeeklyTask] = []) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.milestones = milestones
        self.taskCount = taskCount
        self.estimatedHours = estimatedHours
        self.completedTasks = completedTasks
        self.isCompleted = isCompleted
        self.tasks = tasks
    }
    
    var progress: Double {
        guard taskCount > 0 else { return 0 }
        return Double(completedTasks) / Double(taskCount)
    }
}

// MARK: - 学习资源
struct LearningResource: Identifiable, Codable {
    let id: UUID
    var title: String
    var type: ResourceType
    var url: String?
    var description: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, type: ResourceType, url: String? = nil, description: String = "", isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.type = type
        self.url = url
        self.description = description
        self.isCompleted = isCompleted
    }
}

// MARK: - 资源类型
enum ResourceType: String, CaseIterable, Codable {
    case textbook = "教材"
    case video = "视频"
    case exercise = "习题"
    case course = "课程"
    case website = "网站"
    case app = "应用"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .textbook: return "book.fill"
        case .video: return "play.rectangle.fill"
        case .exercise: return "doc.text.fill"
        case .course: return "graduationcap.fill"
        case .website: return "globe"
        case .app: return "app.fill"
        case .other: return "folder.fill"
        }
    }
}
