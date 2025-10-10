//
//  ScheduleSettings.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation

// MARK: - 建议类型
enum SuggestionType: String, Codable, CaseIterable {
    case studyMethod = "学习方法"
    case timeManagement = "时间管理"
    case difficultyAdjustment = "难度调整"
    case resourceRecommendation = "资源推荐"
    case practiceStrategy = "练习策略"
    case motivation = "学习动机"
}

// MARK: - 任务调度设置
struct ScheduleSettings: Codable {
    // 时间约束
    var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6] // 默认周一到周五，1=周日，2=周一...7=周六
    var schoolEndTime: DateComponents = DateComponents(hour: 18, minute: 0) // 下午6点
    var latestStudyTime: DateComponents = DateComponents(hour: 22, minute: 0) // 晚上10点
    var dailyStudyHours: Int = 2
    
    // 兼容性属性（保持向后兼容）
    var weekdayLearning: Bool {
        get { !selectedWeekdays.intersection([2, 3, 4, 5, 6]).isEmpty }
        set { 
            if newValue {
                selectedWeekdays.formUnion([2, 3, 4, 5, 6])
            } else {
                selectedWeekdays.subtract([2, 3, 4, 5, 6])
            }
        }
    }
    
    var weekendLearning: Bool {
        get { !selectedWeekdays.intersection([1, 7]).isEmpty }
        set { 
            if newValue {
                selectedWeekdays.formUnion([1, 7])
            } else {
                selectedWeekdays.subtract([1, 7])
            }
        }
    }
    
    // 学习偏好
    var taskDistribution: TaskDistribution = .uniform
    var taskInterval: Int = 15 // 15分钟间隔
    var priorityTaskTime: DateComponents = DateComponents(hour: 19, minute: 0) // 晚上7点
    
    // 高级设置
    var avoidConflictWithMeals: Bool = true
    var preferMorningStudy: Bool = false
    var maxTasksPerDay: Int = 6
    
    init() {
        // 使用默认设置
    }
}

// MARK: - 任务分布类型
enum TaskDistribution: String, CaseIterable, Codable {
    case uniform = "均匀分布"
    case concentrated = "集中学习"
    case scattered = "分散学习"
    
    var description: String {
        switch self {
        case .uniform:
            return "每天安排相似数量的任务"
        case .concentrated:
            return "在特定时间段集中安排任务"
        case .scattered:
            return "将任务分散到一天中的不同时间"
        }
    }
    
    var icon: String {
        switch self {
        case .uniform:
            return "equal.circle"
        case .concentrated:
            return "target"
        case .scattered:
            return "sparkles"
        }
    }
}

// MARK: - 调度状态
enum ScheduleStatus: String, CaseIterable, Codable {
    case notScheduled = "未调度"
    case scheduled = "已调度"
    case customized = "已自定义"
    
    var color: String {
        switch self {
        case .notScheduled:
            return "gray"
        case .scheduled:
            return "blue"
        case .customized:
            return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .notScheduled:
            return "clock"
        case .scheduled:
            return "calendar"
        case .customized:
            return "calendar.badge.checkmark"
        }
    }
}

// MARK: - 调度预览数据
struct SchedulePreview: Codable {
    let totalTasks: Int
    let totalDuration: TimeInterval
    let dailyBreakdown: [DailySchedule]
    let conflicts: [ScheduleConflict]
    let suggestions: [ScheduleSuggestion]
}

struct DailySchedule: Codable, Identifiable {
    let id: UUID
    let date: Date
    let tasks: [ScheduledTaskPreview]
    let totalDuration: TimeInterval
    let isWeekend: Bool
    
    init(id: UUID = UUID(), date: Date, tasks: [ScheduledTaskPreview], totalDuration: TimeInterval, isWeekend: Bool) {
        self.id = id
        self.date = date
        self.tasks = tasks
        self.totalDuration = totalDuration
        self.isWeekend = isWeekend
    }
}

struct ScheduledTaskPreview: Codable, Identifiable {
    let id: UUID
    let title: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let category: SubjectCategory
    let priority: Priority
    
    init(id: UUID = UUID(), title: String, startTime: Date, endTime: Date, duration: TimeInterval, category: SubjectCategory, priority: Priority) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.category = category
        self.priority = priority
    }
}

struct ScheduleConflict: Codable, Identifiable {
    let id: UUID
    let type: ConflictType
    let message: String
    let severity: ConflictSeverity
    let suggestedFix: String?
    
    init(id: UUID = UUID(), type: ConflictType, message: String, severity: ConflictSeverity, suggestedFix: String? = nil) {
        self.id = id
        self.type = type
        self.message = message
        self.severity = severity
        self.suggestedFix = suggestedFix
    }
}

enum ConflictType: String, CaseIterable, Codable {
    case timeOverlap = "时间冲突"
    case tooManyTasks = "任务过多"
    case insufficientTime = "时间不足"
    case weekendViolation = "周末限制"
    case schoolTimeViolation = "上学时间冲突"
}

enum ConflictSeverity: String, CaseIterable, Codable {
    case low = "低"
    case medium = "中"
    case high = "高"
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .medium:
            return "orange"
        case .high:
            return "red"
        }
    }
}

struct ScheduleSuggestion: Codable, Identifiable {
    let id: UUID
    let type: SuggestionType
    let message: String
    let action: String?
    
    init(id: UUID = UUID(), type: SuggestionType, message: String, action: String? = nil) {
        self.id = id
        self.type = type
        self.message = message
        self.action = action
    }
}

// SuggestionType 已在 LearningContentGenerator.swift 中定义，这里移除重复定义
