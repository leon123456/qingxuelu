//
//  StudentProfile.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation

// MARK: - 学生档案模型
struct StudentProfile: Identifiable, Codable {
    let id = UUID()
    var studentId: UUID
    var grade: Grade
    var academicLevel: AcademicLevel
    var subjectScores: [SubjectScore]
    var learningStyle: LearningStyle
    var strengths: [String]
    var weaknesses: [String]
    var interests: [String]
    var goals: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(studentId: UUID, grade: Grade, academicLevel: AcademicLevel) {
        self.studentId = studentId
        self.grade = grade
        self.academicLevel = academicLevel
        self.subjectScores = []
        self.learningStyle = .balanced
        self.strengths = []
        self.weaknesses = []
        self.interests = []
        self.goals = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 年级枚举
enum Grade: String, CaseIterable, Codable {
    case grade1 = "一年级"
    case grade2 = "二年级"
    case grade3 = "三年级"
    case grade4 = "四年级"
    case grade5 = "五年级"
    case grade6 = "六年级"
    case grade7 = "七年级"
    case grade8 = "八年级"
    case grade9 = "九年级"
    case grade10 = "高一"
    case grade11 = "高二"
    case grade12 = "高三"
    
    var description: String {
        switch self {
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            return "小学"
        case .grade7, .grade8, .grade9:
            return "初中"
        case .grade10, .grade11, .grade12:
            return "高中"
        }
    }
    
    var icon: String {
        switch self {
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            return "graduationcap.fill"
        case .grade7, .grade8, .grade9:
            return "book.fill"
        case .grade10, .grade11, .grade12:
            return "studentdesk"
        }
    }
}

// MARK: - 学业水平枚举
enum AcademicLevel: String, CaseIterable, Codable {
    case excellent = "优秀"
    case good = "良好"
    case average = "中等"
    case belowAverage = "待提高"
    
    var description: String {
        switch self {
        case .excellent:
            return "成绩优秀，学习能力强"
        case .good:
            return "成绩良好，有提升空间"
        case .average:
            return "成绩中等，需要加强"
        case .belowAverage:
            return "成绩待提高，需要重点关注"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .average: return "orange"
        case .belowAverage: return "red"
        }
    }
}

// MARK: - 科目成绩模型
struct SubjectScore: Identifiable, Codable {
    let id = UUID()
    var subject: SubjectCategory
    var score: Int // 0-100
    var level: ScoreLevel
    var comment: String
    
    init(subject: SubjectCategory, score: Int, comment: String = "") {
        self.subject = subject
        self.score = score
        self.level = ScoreLevel.fromScore(score)
        self.comment = comment
    }
}

// MARK: - 成绩等级枚举
enum ScoreLevel: String, CaseIterable, Codable {
    case excellent = "优秀"
    case good = "良好"
    case average = "中等"
    case poor = "待提高"
    
    static func fromScore(_ score: Int) -> ScoreLevel {
        switch score {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 60..<80: return .average
        default: return .poor
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .average: return "orange"
        case .poor: return "red"
        }
    }
}

// MARK: - 学习风格枚举
enum LearningStyle: String, CaseIterable, Codable {
    case visual = "视觉型"
    case auditory = "听觉型"
    case kinesthetic = "动觉型"
    case balanced = "综合型"
    
    var description: String {
        switch self {
        case .visual:
            return "喜欢通过图表、图像、文字等视觉方式学习"
        case .auditory:
            return "喜欢通过听讲、讨论等听觉方式学习"
        case .kinesthetic:
            return "喜欢通过动手实践、体验等方式学习"
        case .balanced:
            return "能够适应多种学习方式"
        }
    }
    
    var icon: String {
        switch self {
        case .visual: return "eye.fill"
        case .auditory: return "ear.fill"
        case .kinesthetic: return "hand.raised.fill"
        case .balanced: return "star.fill"
        }
    }
}

// MARK: - AI生成的学习模板
struct LearningTemplate: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var grade: Grade
    var academicLevel: AcademicLevel
    var templateType: TemplateType
    var goals: [TemplateGoal]
    var tasks: [TemplateTask]
    var schedule: TemplateSchedule
    var recommendations: [String]
    var createdAt: Date
    
    init(title: String, description: String, grade: Grade, academicLevel: AcademicLevel, templateType: TemplateType) {
        self.title = title
        self.description = description
        self.grade = grade
        self.academicLevel = academicLevel
        self.templateType = templateType
        self.goals = []
        self.tasks = []
        self.schedule = TemplateSchedule()
        self.recommendations = []
        self.createdAt = Date()
    }
}

// MARK: - 模板类型枚举
enum TemplateType: String, CaseIterable, Codable {
    case comprehensive = "综合提升"
    case subjectFocus = "单科突破"
    case examPrep = "考试准备"
    case habitBuilding = "习惯养成"
    case skillDevelopment = "能力发展"
    
    var description: String {
        switch self {
        case .comprehensive:
            return "全面提升各科成绩"
        case .subjectFocus:
            return "重点突破薄弱科目"
        case .examPrep:
            return "针对性考试准备"
        case .habitBuilding:
            return "培养良好学习习惯"
        case .skillDevelopment:
            return "发展学习能力"
        }
    }
    
    var icon: String {
        switch self {
        case .comprehensive: return "chart.line.uptrend.xyaxis"
        case .subjectFocus: return "target"
        case .examPrep: return "doc.text.fill"
        case .habitBuilding: return "clock.fill"
        case .skillDevelopment: return "brain.head.profile"
        }
    }
}

// MARK: - 模板目标
struct TemplateGoal: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: SubjectCategory
    var priority: Priority
    var targetDate: Date
    var goalType: GoalType
    var milestones: [TemplateMilestone]
    var keyResults: [TemplateKeyResult]
    
    init(title: String, description: String, category: SubjectCategory, priority: Priority, targetDate: Date, goalType: GoalType) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.targetDate = targetDate
        self.goalType = goalType
        self.milestones = []
        self.keyResults = []
    }
}

// MARK: - 模板里程碑
struct TemplateMilestone: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var order: Int
    
    init(title: String, description: String, targetDate: Date, order: Int) {
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.order = order
    }
}

// MARK: - 模板关键结果
struct TemplateKeyResult: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var targetValue: Double
    var unit: String
    var order: Int
    
    init(title: String, description: String, targetValue: Double, unit: String, order: Int) {
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.unit = unit
        self.order = order
    }
}

// MARK: - 模板任务
struct TemplateTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: SubjectCategory
    var priority: Priority
    var estimatedDuration: Int // 分钟
    var frequency: TaskFrequency
    var order: Int
    
    init(title: String, description: String, category: SubjectCategory, priority: Priority, estimatedDuration: Int, frequency: TaskFrequency, order: Int) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.frequency = frequency
        self.order = order
    }
}

// MARK: - 任务频率枚举
enum TaskFrequency: String, CaseIterable, Codable {
    case daily = "每日"
    case weekly = "每周"
    case monthly = "每月"
    case once = "一次性"
    
    var description: String {
        switch self {
        case .daily: return "每天执行"
        case .weekly: return "每周执行"
        case .monthly: return "每月执行"
        case .once: return "只执行一次"
        }
    }
}

// MARK: - 模板学习计划
struct TemplateSchedule: Codable {
    var dailyStudyTime: Int // 每日学习时间（分钟）
    var weeklyStudyDays: Int // 每周学习天数
    var studyTimeSlots: [StudyTimeSlot] // 学习时间段
    var breakTime: Int // 休息时间（分钟）
    
    init() {
        self.dailyStudyTime = 120 // 默认2小时
        self.weeklyStudyDays = 5 // 默认5天
        self.studyTimeSlots = []
        self.breakTime = 15 // 默认15分钟休息
    }
}

// MARK: - 学习时间段
struct StudyTimeSlot: Identifiable, Codable {
    let id = UUID()
    var startTime: String // "19:00"
    var endTime: String // "20:00"
    var subject: SubjectCategory?
    var description: String
    
    init(startTime: String, endTime: String, subject: SubjectCategory? = nil, description: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.subject = subject
        self.description = description
    }
}
