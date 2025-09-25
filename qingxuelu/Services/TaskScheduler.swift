//
//  TaskScheduler.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-19.
//

import Foundation

// MARK: - 任务调度服务
class TaskScheduler: ObservableObject {
    static let shared = TaskScheduler()
    
    private init() {}
    
    // MARK: - 将周计划任务分配到具体日期
    func scheduleWeeklyTasks(_ weeklyPlan: WeeklyPlan, for weekStartDate: Date, goalId: UUID? = nil, planId: UUID? = nil) -> [LearningTask] {
        var scheduledTasks: [LearningTask] = []
        let calendar = Calendar.current
        
        print("🔍 任务调度调试 - 周计划ID: \(weeklyPlan.id)")
        print("🔍 任务调度调试 - 周计划任务数量: \(weeklyPlan.tasks.count)")
        print("🔍 任务调度调试 - 周计划任务详情: \(weeklyPlan.tasks.map { "\($0.title): \(Int($0.estimatedDuration / 60))分钟" })")
        
        // 智能拆分任务到一周
        let distributedTasks = distributeTasksAcrossWeek(weeklyPlan.tasks, weekStartDate: weekStartDate)
        
        print("🔍 任务调度调试 - 分配后的任务: \(distributedTasks.map { "第\($0.key)天: \($0.value.count)个任务" })")
        
        // 只为工作日分配任务（周一到周五）
        for dayOffset in 0..<5 {
            let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) ?? weekStartDate
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // 获取当天的任务
            let dayTasks = distributedTasks[dayOffset] ?? []
            
            print("🔍 任务调度调试 - 第\(dayOffset + 1)天任务数量: \(dayTasks.count)")
            
            // 获取当天的可用时间槽
            let timeSlots = generateTimeSlots(for: currentDate, weekday: weekday)
            
            print("🔍 任务调度调试 - 第\(dayOffset + 1)天时间槽数量: \(timeSlots.count)")
            
            // 为当天的任务分配具体时间
            let scheduledDayTasks = assignTasksToTimeSlots(
                tasks: dayTasks,
                timeSlots: timeSlots,
                date: currentDate,
                weeklyPlanId: weeklyPlan.id,
                goalId: goalId,
                planId: planId
            )
            
            print("🔍 任务调度调试 - 第\(dayOffset + 1)天调度任务数量: \(scheduledDayTasks.count)")
            
            scheduledTasks.append(contentsOf: scheduledDayTasks)
        }
        
        return scheduledTasks
    }
    
    // MARK: - 智能拆分任务到一周
    private func distributeTasksAcrossWeek(_ tasks: [WeeklyTask], weekStartDate: Date) -> [Int: [WeeklyTask]] {
        var distributedTasks: [Int: [WeeklyTask]] = [:]
        let calendar = Calendar.current
        
        // 只初始化工作日（周一到周五）的任务数组
        for dayOffset in 0..<5 {
            distributedTasks[dayOffset] = []
        }
        
        // 按任务类型和时长分组
        let taskGroups = groupTasksByType(tasks)
        
        for (taskType, taskGroup) in taskGroups {
            switch taskType {
            case .daily:
                // 每日任务：分配到工作日
                distributeDailyTasks(taskGroup, to: &distributedTasks)
            case .weekly:
                // 周任务：智能分配到2-3天
                distributeWeeklyTasks(taskGroup, to: &distributedTasks)
            case .intensive:
                // 集中任务：分配到周末
                distributeIntensiveTasks(taskGroup, to: &distributedTasks)
            }
        }
        
        return distributedTasks
    }
    
    // MARK: - 任务类型分组
    private func groupTasksByType(_ tasks: [WeeklyTask]) -> [TaskDistributionType: [WeeklyTask]] {
        var groups: [TaskDistributionType: [WeeklyTask]] = [:]
        
        for task in tasks {
            let distributionType = determineTaskDistributionType(task)
            if groups[distributionType] == nil {
                groups[distributionType] = []
            }
            groups[distributionType]?.append(task)
        }
        
        return groups
    }
    
    // MARK: - 确定任务分配类型
    private func determineTaskDistributionType(_ task: WeeklyTask) -> TaskDistributionType {
        let duration = task.estimatedDuration / 3600 // 转换为小时
        
        // 根据任务时长和描述判断类型
        if duration <= 0.5 { // 30分钟
            // 短任务：可能是每日任务
            if task.description.contains("每日") || task.description.contains("每天") {
                return .daily
            }
            return .weekly
        } else if duration <= 2.0 { // 2小时
            // 中等任务：分配到2-3天
            return .weekly
        } else {
            // 长任务：分配到3-5天
            return .intensive
        }
    }
    
    // MARK: - 分配每日任务
    private func distributeDailyTasks(_ tasks: [WeeklyTask], to distributedTasks: inout [Int: [WeeklyTask]]) {
        // 每日任务分配到工作日（周一到周五）
        for dayOffset in 0..<5 {
            for task in tasks {
                // 将任务拆分为更小的子任务
                let subTasks = splitTaskIntoSubTasks(task, days: 5)
                if dayOffset < subTasks.count {
                    distributedTasks[dayOffset]?.append(subTasks[dayOffset])
                }
            }
        }
    }
    
    // MARK: - 分配周任务
    private func distributeWeeklyTasks(_ tasks: [WeeklyTask], to distributedTasks: inout [Int: [WeeklyTask]]) {
        for task in tasks {
            let days = calculateOptimalDays(for: task)
            let subTasks = splitTaskIntoSubTasks(task, days: days)
            
            // 只分配到工作日（周一到周五）
            for (index, subTask) in subTasks.enumerated() {
                if index < 5 { // 只分配到工作日
                    distributedTasks[index]?.append(subTask)
                }
            }
        }
    }
    
    // MARK: - 分配集中任务
    private func distributeIntensiveTasks(_ tasks: [WeeklyTask], to distributedTasks: inout [Int: [WeeklyTask]]) {
        for task in tasks {
            // 集中任务分配到3-5个工作日
            let days = calculateOptimalDays(for: task)
            let subTasks = splitTaskIntoSubTasks(task, days: days)
            
            // 只分配到工作日（周一到周五）
            for (index, subTask) in subTasks.enumerated() {
                if index < 5 { // 确保不超出工作日范围
                    distributedTasks[index]?.append(subTask)
                }
            }
        }
    }
    
    // MARK: - 计算最优天数
    private func calculateOptimalDays(for task: WeeklyTask) -> Int {
        let duration = task.estimatedDuration / 3600 // 转换为小时
        
        if duration <= 0.5 { // 30分钟
            return 1 // 30分钟任务分配到1天
        } else if duration <= 1.0 { // 60分钟
            return 2 // 60分钟任务分配到2天
        } else if duration <= 2.0 { // 2小时
            return 2 // 2小时任务分配到2天
        } else if duration <= 3.0 { // 3小时
            return 3 // 3小时任务分配到3天
        } else if duration <= 4.0 { // 4小时
            return 4 // 4小时任务分配到4天
        } else {
            return 5 // 更长任务分配到5天
        }
    }
    
    // MARK: - 标准化任务时长
    private func standardizeTaskDuration(_ duration: TimeInterval) -> TimeInterval {
        let hours = duration / 3600 // 转换为小时
        
        // 标准化时长：0.25、0.5、0.75、1.0、1.25、1.5小时
        let standardDurations: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
        
        // 找到最接近的标准时长
        var closestDuration = 0.25
        var minDifference = abs(hours - 0.25)
        
        for standardDuration in standardDurations {
            let difference = abs(hours - standardDuration)
            if difference < minDifference {
                minDifference = difference
                closestDuration = standardDuration
            }
        }
        
        return TimeInterval(closestDuration * 3600) // 转换为秒
    }
    
    // MARK: - 拆分任务为子任务
    private func splitTaskIntoSubTasks(_ task: WeeklyTask, days: Int) -> [WeeklyTask] {
        let totalDuration = task.estimatedDuration // 以秒为单位
        let totalMinutes = Int(totalDuration / 60) // 转换为分钟
        
        // 计算每天的基础时长
        let baseMinutesPerDay = totalMinutes / days
        let remainderMinutes = totalMinutes % days
        
        var subTasks: [WeeklyTask] = []
        
        for dayIndex in 0..<days {
            // 计算当天的时长
            var dayMinutes = baseMinutesPerDay
            if dayIndex < remainderMinutes {
                dayMinutes += 1 // 将余数分钟分配给前几天
            }
            
            // 标准化时长
            let standardizedDuration = standardizeTaskDuration(TimeInterval(dayMinutes * 60))
            let standardizedMinutes = Int(standardizedDuration / 60)
            
            let subTask = WeeklyTask(
                id: UUID(),
                title: task.title,
                description: task.description,
                quantity: task.quantity,
                duration: "\(standardizedMinutes)分钟",
                difficulty: task.difficulty,
                isCompleted: false,
                startedDate: nil,
                completedDate: nil,
                actualDuration: nil,
                completionNotes: nil,
                completionRating: nil,
                completionProgress: nil,
                estimatedDuration: standardizedDuration,
                preferredDays: task.preferredDays,
                preferredTimeSlots: task.preferredTimeSlots,
                dependencies: task.dependencies
            )
            
            subTasks.append(subTask)
        }
        
        return subTasks
    }
    
    // MARK: - 生成时间槽
    private func generateTimeSlots(for date: Date, weekday: Int) -> [SchedulingTimeSlot] {
        let calendar = Calendar.current
        var timeSlots: [SchedulingTimeSlot] = []
        
        // 只在工作日安排任务，周末不安排
        let isWeekend = (weekday == 1 || weekday == 7) // 周日=1, 周六=7
        
        if isWeekend {
            // 周末不安排任务，返回空时间槽
            return []
        }
        
        // 工作日：紧凑的时间安排
        let studyPeriods: [(start: Int, end: Int)] = [
            (start: 8, end: 12),   // 上午学习时间
            (start: 14, end: 18),  // 下午学习时间
            (start: 19, end: 22)   // 晚上学习时间
        ]
        
        for period in studyPeriods {
            let startTime = calendar.date(bySettingHour: period.start, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(bySettingHour: period.end, minute: 0, second: 0, of: date) ?? date
            
            // 工作日使用标准化的时间槽：30分钟
            let slotDuration = 30 // 工作日30分钟时间槽
            var currentTime = startTime
            
            while currentTime < endTime {
                let slotEndTime = calendar.date(byAdding: .minute, value: slotDuration, to: currentTime) ?? currentTime
                
                // 确保不超过时间段结束时间
                let actualEndTime = min(slotEndTime, endTime)
                
                let timeSlot = SchedulingTimeSlot(
                    startTime: currentTime,
                    endTime: actualEndTime,
                    isAvailable: true,
                    taskId: nil
                )
                
                timeSlots.append(timeSlot)
                currentTime = actualEndTime
            }
        }
        
        return timeSlots
    }
    
    // MARK: - 将任务分配到时间槽
    private func assignTasksToTimeSlots(
        tasks: [WeeklyTask],
        timeSlots: [SchedulingTimeSlot],
        date: Date,
        weeklyPlanId: UUID,
        goalId: UUID? = nil,
        planId: UUID? = nil
    ) -> [LearningTask] {
        var scheduledTasks: [LearningTask] = []
        var availableSlots = timeSlots
        
        // 按优先级和难度排序任务
        let sortedTasks = tasks.sorted { task1, task2 in
            // 先按难度排序（简单任务优先）
            if task1.difficulty != task2.difficulty {
                return task1.difficulty.rawValue < task2.difficulty.rawValue
            }
            // 再按预估时长排序（短任务优先）
            return task1.estimatedDuration < task2.estimatedDuration
        }
        
        for task in sortedTasks {
            // 寻找合适的时间槽
            if let slotIndex = findSuitableTimeSlot(for: task, in: availableSlots) {
                let slot = availableSlots[slotIndex]
                
                // 计算需要占用的时间槽数量
                let requiredDuration = task.estimatedDuration
                let slotDuration = slot.endTime.timeIntervalSince(slot.startTime)
                let slotsNeeded = Int(ceil(requiredDuration / slotDuration))
                
                // 创建学习任务
                let learningTask = LearningTask(
                    title: task.title,
                    description: task.description,
                    category: mapDifficultyToCategory(task.difficulty),
                    priority: mapDifficultyToPriority(task.difficulty),
                    estimatedDuration: task.estimatedDuration, // 已经是秒，不需要再转换
                    taskType: .planGenerated,
                    goalId: goalId, // 使用传入的目标ID
                    planId: planId, // 使用传入的计划ID
                    weeklyPlanId: weeklyPlanId,
                    scheduledStartTime: slot.startTime,
                    scheduledEndTime: slot.endTime
                )
                
                scheduledTasks.append(learningTask)
                
                // 标记连续的时间槽为已占用
                for i in 0..<min(slotsNeeded, availableSlots.count - slotIndex) {
                    let currentIndex = slotIndex + i
                    if currentIndex < availableSlots.count {
                        availableSlots[currentIndex].isAvailable = false
                        availableSlots[currentIndex].taskId = learningTask.id
                    }
                }
            }
        }
        
        return scheduledTasks
    }
    
    // MARK: - 寻找合适的时间槽
    private func findSuitableTimeSlot(for task: WeeklyTask, in timeSlots: [SchedulingTimeSlot]) -> Int? {
        let requiredDuration = task.estimatedDuration // 已经是秒，不需要再转换
        
        for (index, slot) in timeSlots.enumerated() {
            if slot.isAvailable {
                let slotDuration = slot.endTime.timeIntervalSince(slot.startTime)
                
                // 检查时间槽是否足够长
                if slotDuration >= requiredDuration {
                    return index
                }
                
                // 如果单个时间槽不够，尝试找连续的多个时间槽
                if slotDuration < requiredDuration {
                    if let consecutiveSlots = findConsecutiveSlots(startingFrom: index, requiredDuration: requiredDuration, in: timeSlots) {
                        return consecutiveSlots
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - 寻找连续的时间槽
    private func findConsecutiveSlots(startingFrom startIndex: Int, requiredDuration: TimeInterval, in timeSlots: [SchedulingTimeSlot]) -> Int? {
        var totalDuration: TimeInterval = 0
        var consecutiveCount = 0
        
        for i in startIndex..<timeSlots.count {
            let slot = timeSlots[i]
            
            // 检查时间槽是否可用且连续
            if !slot.isAvailable {
                break
            }
            
            // 检查时间槽是否连续（前一个时间槽的结束时间等于当前时间槽的开始时间）
            if i > startIndex {
                let previousSlot = timeSlots[i - 1]
                if previousSlot.endTime != slot.startTime {
                    break
                }
            }
            
            let slotDuration = slot.endTime.timeIntervalSince(slot.startTime)
            totalDuration += slotDuration
            consecutiveCount += 1
            
            // 如果总时长足够，返回起始索引
            if totalDuration >= requiredDuration {
                return startIndex
            }
        }
        
        return nil
    }
    
    // MARK: - 辅助方法
    private func mapDifficultyToCategory(_ difficulty: TaskDifficulty) -> SubjectCategory {
        // 这里可以根据实际需求映射
        return .other
    }
    
    private func mapDifficultyToPriority(_ difficulty: TaskDifficulty) -> Priority {
        switch difficulty {
        case .easy:
            return .low
        case .medium:
            return .medium
        case .hard:
            return .high
        }
    }
}

// MARK: - 时间槽模型（用于任务调度）
struct SchedulingTimeSlot: Codable {
    var startTime: Date
    var endTime: Date
    var isAvailable: Bool
    var taskId: UUID?
}

// MARK: - 任务分配类型枚举
enum TaskDistributionType: String, CaseIterable, Codable {
    case daily = "daily"           // 每日任务
    case weekly = "weekly"         // 周任务
    case intensive = "intensive"   // 集中任务
    
    var displayName: String {
        switch self {
        case .daily: return "每日任务"
        case .weekly: return "周任务"
        case .intensive: return "集中任务"
        }
    }
}

// MARK: - 星期枚举
enum Weekday: Int, CaseIterable, Codable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var displayName: String {
        switch self {
        case .monday: return "周一"
        case .tuesday: return "周二"
        case .wednesday: return "周三"
        case .thursday: return "周四"
        case .friday: return "周五"
        case .saturday: return "周六"
        case .sunday: return "周日"
        }
    }
}
