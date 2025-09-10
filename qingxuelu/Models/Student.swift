//
//  Student.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation

// MARK: - 学生信息模型
struct Student: Identifiable, Codable {
    let id = UUID()
    var name: String
    var grade: String
    var school: String
    var avatar: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, grade: String, school: String, avatar: String? = nil) {
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
    let id = UUID()
    var userId: UUID = UUID()  // 新增：关联用户，第一版暂不使用
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
    
    init(title: String, description: String, category: SubjectCategory, priority: Priority, targetDate: Date, goalType: GoalType = .smart) {
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
    let id = UUID()
    var title: String
    var description: String
    var targetValue: Double
    var currentValue: Double
    var unit: String // 单位，如"分"、"题"、"小时"
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String, description: String, targetValue: Double, unit: String) {
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
    let id = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var completedDate: Date?
    var isCompleted: Bool
    var progress: Double
    
    init(title: String, description: String, targetDate: Date) {
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.progress = 0.0
    }
}

// MARK: - 学习任务模型
struct LearningTask: Identifiable, Codable, Hashable {
    let id = UUID()
    var userId: UUID = UUID()  // 新增：关联用户，第一版暂不使用
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
    
    init(title: String, description: String, category: SubjectCategory, priority: Priority, estimatedDuration: TimeInterval, goalId: UUID? = nil) {
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
    let id = UUID()
    var userId: UUID = UUID()  // 新增：关联用户，第一版暂不使用
    var taskId: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var notes: String?
    var rating: Int? // 学习质量评分 1-5
    var createdAt: Date
    
    init(taskId: UUID, startTime: Date, endTime: Date, notes: String? = nil, rating: Int? = nil) {
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
