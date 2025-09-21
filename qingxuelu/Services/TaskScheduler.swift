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
        
        // 为每周的每一天生成时间槽
        for dayOffset in 0..<7 {
            let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) ?? weekStartDate
            
            // 获取当天的可用时间槽
            let timeSlots = generateTimeSlots(for: currentDate)
            
            // 为当天的任务分配时间
            let dayTasks = assignTasksToTimeSlots(
                tasks: weeklyPlan.tasks,
                timeSlots: timeSlots,
                date: currentDate,
                weeklyPlanId: weeklyPlan.id,
                goalId: goalId,
                planId: planId
            )
            
            scheduledTasks.append(contentsOf: dayTasks)
        }
        
        return scheduledTasks
    }
    
    // MARK: - 生成时间槽
    private func generateTimeSlots(for date: Date) -> [SchedulingTimeSlot] {
        let calendar = Calendar.current
        var timeSlots: [SchedulingTimeSlot] = []
        
        // 定义学习时间段
        let studyPeriods = [
            (start: 8, end: 12),   // 上午学习时间
            (start: 14, end: 18),  // 下午学习时间
            (start: 19, end: 22)   // 晚上学习时间
        ]
        
        for period in studyPeriods {
            let startTime = calendar.date(bySettingHour: period.start, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(bySettingHour: period.end, minute: 0, second: 0, of: date) ?? date
            
            // 将时间段分割为1小时的时间槽
            var currentTime = startTime
            while currentTime < endTime {
                let slotEndTime = calendar.date(byAdding: .hour, value: 1, to: currentTime) ?? currentTime
                
                let timeSlot = SchedulingTimeSlot(
                    startTime: currentTime,
                    endTime: slotEndTime,
                    isAvailable: true,
                    taskId: nil
                )
                
                timeSlots.append(timeSlot)
                currentTime = slotEndTime
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
                
                // 创建学习任务
                let learningTask = LearningTask(
                    title: task.title,
                    description: task.description,
                    category: mapDifficultyToCategory(task.difficulty),
                    priority: mapDifficultyToPriority(task.difficulty),
                    estimatedDuration: task.estimatedDuration * 3600, // 转换为秒（小时*3600）
                    taskType: .planGenerated,
                    goalId: goalId, // 使用传入的目标ID
                    planId: planId, // 使用传入的计划ID
                    weeklyPlanId: weeklyPlanId,
                    scheduledStartTime: slot.startTime,
                    scheduledEndTime: slot.endTime
                )
                
                scheduledTasks.append(learningTask)
                
                // 标记时间槽为已占用
                availableSlots[slotIndex].isAvailable = false
                availableSlots[slotIndex].taskId = learningTask.id
            }
        }
        
        return scheduledTasks
    }
    
    // MARK: - 寻找合适的时间槽
    private func findSuitableTimeSlot(for task: WeeklyTask, in timeSlots: [SchedulingTimeSlot]) -> Int? {
        let requiredDuration = task.estimatedDuration * 60 // 转换为秒
        
        for (index, slot) in timeSlots.enumerated() {
            if slot.isAvailable {
                let slotDuration = slot.endTime.timeIntervalSince(slot.startTime)
                
                // 检查时间槽是否足够长
                if slotDuration >= requiredDuration {
                    return index
                }
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
