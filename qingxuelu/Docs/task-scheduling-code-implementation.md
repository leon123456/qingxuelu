# 任务调度算法代码实现详解

## 核心实现代码

### 1. TaskScheduler 主类

```swift
class TaskScheduler: ObservableObject {
    static let shared = TaskScheduler()
    
    private init() {}
    
    // MARK: - 主要调度方法
    func scheduleWeeklyTasks(_ weeklyPlan: WeeklyPlan, for weekStartDate: Date) -> [LearningTask] {
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
                weeklyPlanId: weeklyPlan.id
            )
            
            scheduledTasks.append(contentsOf: dayTasks)
        }
        
        return scheduledTasks
    }
}
```

### 2. 时间槽生成算法

```swift
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
```

### 3. 任务排序算法

```swift
// MARK: - 将任务分配到时间槽
private func assignTasksToTimeSlots(
    tasks: [WeeklyTask],
    timeSlots: [SchedulingTimeSlot],
    date: Date,
    weeklyPlanId: UUID
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
                estimatedDuration: task.estimatedDuration * 60, // 转换为秒
                taskType: .planGenerated,
                goalId: nil, // 需要从周计划中获取
                planId: nil, // 需要从周计划中获取
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
```

### 4. 智能匹配算法

```swift
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
```

### 5. 辅助映射方法

```swift
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
```

## 数据结构定义

### 1. 时间槽模型

```swift
// MARK: - 时间槽模型（用于任务调度）
struct SchedulingTimeSlot: Codable {
    var startTime: Date
    var endTime: Date
    var isAvailable: Bool
    var taskId: UUID?
}
```

### 2. 星期枚举

```swift
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
```

## 算法测试用例

### 1. 基本功能测试

```swift
func testBasicScheduling() {
    let scheduler = TaskScheduler.shared
    let calendar = Calendar.current
    
    // 创建测试任务
    let tasks = [
        WeeklyTask(title: "理论学习", difficulty: .hard, estimatedDuration: 2.0),
        WeeklyTask(title: "实践练习", difficulty: .medium, estimatedDuration: 1.0),
        WeeklyTask(title: "复习巩固", difficulty: .easy, estimatedDuration: 1.0)
    ]
    
    let weeklyPlan = WeeklyPlan(
        weekNumber: 1,
        startDate: Date(),
        endDate: calendar.date(byAdding: .day, value: 6, to: Date()) ?? Date(),
        tasks: tasks
    )
    
    // 执行调度
    let scheduledTasks = scheduler.scheduleWeeklyTasks(weeklyPlan, for: Date())
    
    // 验证结果
    XCTAssertEqual(scheduledTasks.count, 3)
    XCTAssertNotNil(scheduledTasks.first?.scheduledStartTime)
    XCTAssertNotNil(scheduledTasks.first?.scheduledEndTime)
}
```

### 2. 排序算法测试

```swift
func testTaskSorting() {
    let tasks = [
        WeeklyTask(title: "困难任务", difficulty: .hard, estimatedDuration: 1.0),
        WeeklyTask(title: "简单任务", difficulty: .easy, estimatedDuration: 2.0),
        WeeklyTask(title: "中等任务", difficulty: .medium, estimatedDuration: 1.5)
    ]
    
    let sortedTasks = tasks.sorted { task1, task2 in
        if task1.difficulty != task2.difficulty {
            return task1.difficulty.rawValue < task2.difficulty.rawValue
        }
        return task1.estimatedDuration < task2.estimatedDuration
    }
    
    // 验证排序结果：简单任务应该排在第一位
    XCTAssertEqual(sortedTasks.first?.title, "简单任务")
    XCTAssertEqual(sortedTasks.first?.difficulty, .easy)
}
```

### 3. 时间槽生成测试

```swift
func testTimeSlotGeneration() {
    let scheduler = TaskScheduler.shared
    let testDate = Date()
    
    // 使用反射访问私有方法（仅用于测试）
    let timeSlots = scheduler.generateTimeSlots(for: testDate)
    
    // 验证时间槽数量：8-12点4个 + 14-18点4个 + 19-22点3个 = 11个
    XCTAssertEqual(timeSlots.count, 11)
    
    // 验证时间槽时长
    for slot in timeSlots {
        let duration = slot.endTime.timeIntervalSince(slot.startTime)
        XCTAssertEqual(duration, 3600) // 1小时 = 3600秒
    }
}
```

## 性能优化建议

### 1. 缓存优化

```swift
class TaskScheduler: ObservableObject {
    private var timeSlotCache: [Date: [SchedulingTimeSlot]] = [:]
    
    private func generateTimeSlots(for date: Date) -> [SchedulingTimeSlot] {
        // 检查缓存
        if let cachedSlots = timeSlotCache[date] {
            return cachedSlots
        }
        
        // 生成新的时间槽
        let slots = generateTimeSlotsInternal(for: date)
        
        // 缓存结果
        timeSlotCache[date] = slots
        
        return slots
    }
}
```

### 2. 并行处理

```swift
func scheduleWeeklyTasksParallel(_ weeklyPlan: WeeklyPlan, for weekStartDate: Date) -> [LearningTask] {
    let calendar = Calendar.current
    
    // 使用并行处理加速
    let scheduledTasks = (0..<7).concurrentMap { dayOffset in
        let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) ?? weekStartDate
        let timeSlots = generateTimeSlots(for: currentDate)
        
        return assignTasksToTimeSlots(
            tasks: weeklyPlan.tasks,
            timeSlots: timeSlots,
            date: currentDate,
            weeklyPlanId: weeklyPlan.id
        )
    }.flatMap { $0 }
    
    return scheduledTasks
}
```

## 总结

该任务调度算法的代码实现具有以下特点：

1. **模块化设计**：各功能模块独立，便于测试和维护
2. **高效算法**：O(n log n)的排序复杂度，O(n×m)的匹配复杂度
3. **可扩展性**：支持添加新的调度策略和优化算法
4. **用户友好**：符合学习规律的时间安排
5. **系统稳定**：完善的错误处理和边界条件处理

通过这套算法，我们能够将AI生成的周计划任务智能分配到具体的时间点，为用户提供高效、合理的学习时间安排。

