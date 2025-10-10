//
//  DataManager.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation
import SwiftUI

// MARK: - 数据管理器
class DataManager: ObservableObject {
    // 核心数据模型
    @Published var goals: [LearningGoal] = []
    @Published var tasks: [LearningTask] = []
    @Published var records: [LearningRecord] = []
    @Published var reflections: [LearningReflection] = []
    @Published var plans: [LearningPlan] = []
    @Published var recycleBin: [DeletedGoal] = []
    @Published var pomodoroSessions: [PomodoroSession] = []
    
    // 兼容性支持（逐步迁移）
    @Published var profiles: [StudentProfile] = []
    @Published var templates: [LearningTemplate] = []
    @Published var students: [Student] = []
    @Published var currentStudent: Student?
    
    // 优化：添加数据更新时间戳，用于缓存机制
    @Published var lastUpdateTime: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    
    // 核心数据键
    private let goalsKey = "goals"
    private let tasksKey = "tasks"
    private let recordsKey = "records"
    private let reflectionsKey = "reflections"
    private let plansKey = "plans"
    private let recycleBinKey = "recycleBin"
    private let pomodoroSessionsKey = "pomodoroSessions"
    
    // 兼容性键
    private let profilesKey = "profiles"
    private let templatesKey = "templates"
    private let studentsKey = "students"
    private let currentStudentKey = "currentStudent"
    
    init() {
        loadData()
        
        // 如果没有当前学生，创建一个默认学生档案
        if currentStudent == nil {
            createDefaultStudent()
        }
        
        // 完全禁用示例数据生成，避免UUID冲突
        // if goals.isEmpty && plans.isEmpty && tasks.isEmpty && records.isEmpty && reflections.isEmpty {
        //     addSampleData()
        // }
    }
    
    // MARK: - 数据持久化
    private func saveData() {
        // 使用后台队列进行数据编码，避免阻塞主线程
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 在后台线程进行JSON编码
            let goalsData = try? JSONEncoder().encode(self.goals)
            let tasksData = try? JSONEncoder().encode(self.tasks)
            let recordsData = try? JSONEncoder().encode(self.records)
            let reflectionsData = try? JSONEncoder().encode(self.reflections)
            let plansData = try? JSONEncoder().encode(self.plans)
            let recycleBinData = try? JSONEncoder().encode(self.recycleBin)
            let pomodoroSessionsData = try? JSONEncoder().encode(self.pomodoroSessions)
            let studentsData = try? JSONEncoder().encode(self.students)
            let templatesData = try? JSONEncoder().encode(self.templates)
            let profilesData = try? JSONEncoder().encode(self.profiles)
            let currentStudentData = try? JSONEncoder().encode(self.currentStudent)
            
            // 回到主线程进行UserDefaults写入
            DispatchQueue.main.async {
                if let goalsData = goalsData {
                    self.userDefaults.set(goalsData, forKey: self.goalsKey)
                }
                if let tasksData = tasksData {
                    self.userDefaults.set(tasksData, forKey: self.tasksKey)
                }
                if let recordsData = recordsData {
                    self.userDefaults.set(recordsData, forKey: self.recordsKey)
                }
                if let reflectionsData = reflectionsData {
                    self.userDefaults.set(reflectionsData, forKey: self.reflectionsKey)
                }
                if let plansData = plansData {
                    self.userDefaults.set(plansData, forKey: self.plansKey)
                }
                if let recycleBinData = recycleBinData {
                    self.userDefaults.set(recycleBinData, forKey: self.recycleBinKey)
                }
                if let pomodoroSessionsData = pomodoroSessionsData {
                    self.userDefaults.set(pomodoroSessionsData, forKey: self.pomodoroSessionsKey)
                }
                if let studentsData = studentsData {
                    self.userDefaults.set(studentsData, forKey: self.studentsKey)
                }
                if let templatesData = templatesData {
                    self.userDefaults.set(templatesData, forKey: self.templatesKey)
                }
                if let profilesData = profilesData {
                    self.userDefaults.set(profilesData, forKey: self.profilesKey)
                }
                if let currentStudentData = currentStudentData {
                    self.userDefaults.set(currentStudentData, forKey: self.currentStudentKey)
                }
            }
        }
    }
    
    private func loadData() {
        // 加载核心数据
        if let goalsData = userDefaults.data(forKey: goalsKey),
           let loadedGoals = try? JSONDecoder().decode([LearningGoal].self, from: goalsData) {
            goals = loadedGoals
        }
        if let tasksData = userDefaults.data(forKey: tasksKey),
           let loadedTasks = try? JSONDecoder().decode([LearningTask].self, from: tasksData) {
            tasks = loadedTasks
        }
        if let recordsData = userDefaults.data(forKey: recordsKey),
           let loadedRecords = try? JSONDecoder().decode([LearningRecord].self, from: recordsData) {
            records = loadedRecords
        }
        if let reflectionsData = userDefaults.data(forKey: reflectionsKey),
           let loadedReflections = try? JSONDecoder().decode([LearningReflection].self, from: reflectionsData) {
            reflections = loadedReflections
        }
        if let plansData = userDefaults.data(forKey: plansKey),
           let loadedPlans = try? JSONDecoder().decode([LearningPlan].self, from: plansData) {
            plans = loadedPlans
            print("=== 加载计划调试信息 ===")
            print("加载的计划数量: \(plans.count)")
            for plan in plans {
                print("计划ID: \(plan.id), 标题: \(plan.title)")
            }
            print("=== 加载计划调试信息结束 ===")
        }
        if let recycleBinData = userDefaults.data(forKey: recycleBinKey),
           let loadedRecycleBin = try? JSONDecoder().decode([DeletedGoal].self, from: recycleBinData) {
            recycleBin = loadedRecycleBin
        }
        if let pomodoroSessionsData = userDefaults.data(forKey: pomodoroSessionsKey),
           let loadedPomodoroSessions = try? JSONDecoder().decode([PomodoroSession].self, from: pomodoroSessionsData) {
            pomodoroSessions = loadedPomodoroSessions
        }
        
        // 兼容性加载
        if let studentsData = userDefaults.data(forKey: studentsKey),
           let loadedStudents = try? JSONDecoder().decode([Student].self, from: studentsData) {
            students = loadedStudents
        }
        if let templatesData = userDefaults.data(forKey: templatesKey),
           let loadedTemplates = try? JSONDecoder().decode([LearningTemplate].self, from: templatesData) {
            templates = loadedTemplates
        }
        if let profilesData = userDefaults.data(forKey: profilesKey),
           let loadedProfiles = try? JSONDecoder().decode([StudentProfile].self, from: profilesData) {
            profiles = loadedProfiles
        }
        if let currentStudentData = userDefaults.data(forKey: currentStudentKey),
           let loadedCurrentStudent = try? JSONDecoder().decode(Student.self, from: currentStudentData) {
            currentStudent = loadedCurrentStudent
        }
    }
    
    // MARK: - 目标管理
    func addGoal(_ goal: LearningGoal) {
        goals.append(goal)
        saveData()
    }
    
    func updateGoal(_ goal: LearningGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveData()
        }
    }
    
    // MARK: - 批量删除辅助方法
    private func deleteTasksBatch(_ tasksToDelete: [LearningTask]) {
        for task in tasksToDelete {
            // 删除任务的学习记录
            records.removeAll { $0.taskId == task.id }
            // 删除任务本身
            tasks.removeAll { $0.id == task.id }
        }
    }
    
    func deleteGoal(_ goal: LearningGoal) {
        // 1. 删除关联的计划（如果存在）
        if let plan = getPlanForGoal(goal.id) {
            deletePlan(plan)
        }
        
        // 2. 批量删除关联的任务和学习记录
        let relatedTasks = getTasksForGoal(goal.id)
        deleteTasksBatch(relatedTasks)
        
        // 3. 将目标移到回收站而不是直接删除
        let deletedGoal = DeletedGoal(goal: goal, deletedReason: "用户手动删除")
        recycleBin.append(deletedGoal)
        
        // 4. 从目标列表中移除
        goals.removeAll { $0.id == goal.id }
        
        print("✅ 已将目标「\(goal.title)」移到回收站")
        saveData()
    }
    
    func getGoalsForStudent(_ studentId: UUID) -> [LearningGoal] {
        // 第一版暂不使用userId过滤，返回所有目标
        return goals
    }
    
    // MARK: - 任务管理
    func addTask(_ task: LearningTask) {
        tasks.append(task)
        lastUpdateTime = Date()
        saveData()
    }
    
    func updateTask(_ task: LearningTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            lastUpdateTime = Date()
            saveData()
        }
    }
    
    // MARK: - 任务完成逻辑
    func completeTask(_ task: LearningTask, actualDuration: TimeInterval, notes: String? = nil, rating: Int? = nil) {
        // 1. 更新任务状态
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.completedDate = Date()
        updatedTask.actualDuration = actualDuration
        updatedTask.updatedAt = Date()
        updateTask(updatedTask)
        
        // 2. 创建学习记录
        let record = LearningRecord(
            taskId: task.id,
            startTime: Date().addingTimeInterval(-actualDuration),
            endTime: Date(),
            notes: notes,
            rating: rating
        )
        addRecord(record)
        
        // 3. 更新相关进度
        updateProgressForTaskCompletion(task)
        
        print("✅ 任务「\(task.title)」已完成，学习时长: \(Int(actualDuration/60))分钟")
    }
    
    // MARK: - 进度更新机制
    private func updateProgressForTaskCompletion(_ task: LearningTask) {
        // 更新目标进度
        if let goalId = task.goalId {
            updateGoalProgress(goalId)
        }
        
        // 更新里程碑进度
        if let planId = task.planId {
            updateMilestoneProgress(planId)
        }
        
        // 更新关键结果进度
        if let goalId = task.goalId {
            updateKeyResultProgress(goalId)
        }
    }
    
    private func updateGoalProgress(_ goalId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }) else { return }
        
        let goalTasks = getTasksForGoal(goalId)
        let completedTasks = goalTasks.filter { $0.status == .completed }
        let progress = goalTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(goalTasks.count)
        
        goals[goalIndex].progress = progress
        goals[goalIndex].updatedAt = Date()
        
        // 检查目标是否完成
        if progress >= 1.0 {
            goals[goalIndex].status = .completed
            goals[goalIndex].actualEndDate = Date()
            print("🎉 目标「\(goals[goalIndex].title)」已完成！")
        }
        
        saveData()
    }
    
    private func updateMilestoneProgress(_ planId: UUID) {
        guard let planIndex = plans.firstIndex(where: { $0.id == planId }) else { return }
        
        for (_, weeklyPlan) in plans[planIndex].weeklyPlans.enumerated() {
            let weekTasks = getTasksForWeek(planId, weekNumber: weeklyPlan.weekNumber)
            let completedWeekTasks = weekTasks.filter { $0.status == .completed }
            
            // 检查周里程碑是否完成
            if !completedWeekTasks.isEmpty && completedWeekTasks.count == weekTasks.count {
                // 里程碑完成逻辑
                checkMilestoneCompletion(planId, weekNumber: weeklyPlan.weekNumber)
            }
        }
    }
    
    private func checkMilestoneCompletion(_ planId: UUID, weekNumber: Int) {
        // 检查并更新相关里程碑
        guard let goalId = plans.first(where: { $0.id == planId })?.id else { return }
        
        if let goalIndex = goals.firstIndex(where: { $0.id == goalId }) {
            // 更新里程碑进度
            for (milestoneIndex, milestone) in goals[goalIndex].milestones.enumerated() {
                if shouldCompleteMilestone(milestone, weekNumber: weekNumber) {
                    goals[goalIndex].milestones[milestoneIndex].isCompleted = true
                    goals[goalIndex].milestones[milestoneIndex].completedDate = Date()
                    print("🏆 里程碑「\(milestone.title)」已完成！")
                }
            }
            saveData()
        }
    }
    
    private func shouldCompleteMilestone(_ milestone: Milestone, weekNumber: Int) -> Bool {
        // 根据里程碑的目标日期和周数判断是否应该完成
        let calendar = Calendar.current
        let milestoneWeek = calendar.component(.weekOfYear, from: milestone.targetDate)
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        
        return currentWeek >= milestoneWeek && !milestone.isCompleted
    }
    
    private func updateKeyResultProgress(_ goalId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }) else { return }
        
        // 根据任务完成情况更新关键结果
        let goalTasks = getTasksForGoal(goalId)
        let completedTasks = goalTasks.filter { $0.status == .completed }
        
        for (krIndex, keyResult) in goals[goalIndex].keyResults.enumerated() {
            // 根据关键结果类型更新进度
            switch keyResult.unit {
            case "分钟", "小时":
                // 时间类关键结果：累计学习时长
                let totalDuration = completedTasks.reduce(0) { $0 + ($1.actualDuration ?? 0) }
                goals[goalIndex].keyResults[krIndex].currentValue = totalDuration / 60 // 转换为分钟
                
            case "题", "个", "篇":
                // 数量类关键结果：完成任务数量
                goals[goalIndex].keyResults[krIndex].currentValue = Double(completedTasks.count)
                
            case "%":
                // 百分比类关键结果：完成率
                let completionRate = goalTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(goalTasks.count) * 100
                goals[goalIndex].keyResults[krIndex].currentValue = completionRate
                
            default:
                // 其他类型：基于任务完成数量
                goals[goalIndex].keyResults[krIndex].currentValue = Double(completedTasks.count)
            }
            
            // 检查关键结果是否完成
            if goals[goalIndex].keyResults[krIndex].currentValue >= keyResult.targetValue {
                goals[goalIndex].keyResults[krIndex].isCompleted = true
                print("🎯 关键结果「\(keyResult.title)」已完成！")
            }
        }
        
        saveData()
    }
    
    // MARK: - 辅助方法
    func getTasksForWeek(_ planId: UUID, weekNumber: Int) -> [LearningTask] {
        // 暂时返回所有关联该计划的任务，后续可以根据周计划ID优化
        return tasks.filter { task in
            task.planId == planId
        }
    }
    
    func deleteTask(_ task: LearningTask) {
        tasks.removeAll { $0.id == task.id }
        records.removeAll { $0.taskId == task.id }
        saveData()
    }
    
    func getTasksForStudent(_ studentId: UUID) -> [LearningTask] {
        // 第一版暂不使用userId过滤，返回所有任务
        return tasks
    }
    
    func getTasksForGoal(_ goalId: UUID) -> [LearningTask] {
        return tasks.filter { $0.goalId == goalId }
    }
    
    func getTasksForPlan(_ planId: UUID) -> [LearningTask] {
        return tasks.filter { $0.planId == planId }
    }
    
    // MARK: - 学习记录管理
    func addRecord(_ record: LearningRecord) {
        records.append(record)
        saveData()
    }
    
    func updateRecord(_ record: LearningRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveData()
        }
    }
    
    func deleteRecord(_ record: LearningRecord) {
        records.removeAll { $0.id == record.id }
        saveData()
    }
    
    func getRecordsForStudent(_ studentId: UUID) -> [LearningRecord] {
        // 第一版暂不使用userId过滤，返回所有记录
        return records
    }
    
    func getRecordsForTask(_ taskId: UUID) -> [LearningRecord] {
        return records.filter { $0.taskId == taskId }
    }
    
    // MARK: - 数据分析
    func getTotalStudyTime(for studentId: UUID, in dateRange: DateInterval? = nil) -> TimeInterval {
        let studentRecords = getRecordsForStudent(studentId)
        let filteredRecords = dateRange != nil ? 
            studentRecords.filter { dateRange!.contains($0.startTime) } : 
            studentRecords
        
        return filteredRecords.reduce(0) { $0 + $1.duration }
    }
    
    func getStudyTimeBySubject(for studentId: UUID, in dateRange: DateInterval? = nil) -> [SubjectCategory: TimeInterval] {
        let studentTasks = getTasksForStudent(studentId)
        let studentRecords = getRecordsForStudent(studentId)
        let filteredRecords = dateRange != nil ? 
            studentRecords.filter { dateRange!.contains($0.startTime) } : 
            studentRecords
        
        var subjectTime: [SubjectCategory: TimeInterval] = [:]
        
        for record in filteredRecords {
            if let task = studentTasks.first(where: { $0.id == record.taskId }) {
                subjectTime[task.category, default: 0] += record.duration
            }
        }
        
        return subjectTime
    }
    
    func getGoalProgress(for goalId: UUID) -> Double {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return 0.0 }
        
        let goalTasks = getTasksForGoal(goalId)
        guard !goalTasks.isEmpty else { return goal.progress }
        
        let completedTasks = goalTasks.filter { $0.status == .completed }
        return Double(completedTasks.count) / Double(goalTasks.count)
    }
    
    func getUpcomingTasks(for studentId: UUID, limit: Int = 5) -> [LearningTask] {
        let studentTasks = getTasksForStudent(studentId)
        let upcomingTasks = studentTasks
            .filter { $0.status == .pending || $0.status == .inProgress }
            .sorted { 
                if let due1 = $0.dueDate, let due2 = $1.dueDate {
                    return due1 < due2
                }
                return $0.createdAt < $1.createdAt
            }
        
        return Array(upcomingTasks.prefix(limit))
    }
    
    func clearAllData() {
        // 清除所有数据
        students.removeAll()
        goals.removeAll()
        tasks.removeAll()
        records.removeAll()
        reflections.removeAll()
        plans.removeAll()
        recycleBin.removeAll()
        pomodoroSessions.removeAll()
        profiles.removeAll()
        templates.removeAll()
        currentStudent = nil
        
        // 保存到持久化存储
        saveData()
        
        print("✅ 已清除所有数据")
    }
    
    // MARK: - 学生档案管理
    func addProfile(_ profile: StudentProfile) {
        profiles.append(profile)
        saveData()
    }
    
    func updateProfile(_ profile: StudentProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveData()
        }
    }
    
    func deleteProfile(_ profile: StudentProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveData()
    }
    
    func getProfileForStudent(_ studentId: UUID) -> StudentProfile? {
        return profiles.first { $0.studentId == studentId }
    }
    
    // MARK: - 学生管理（兼容性）
    func addStudent(_ student: Student) {
        students.append(student)
        if currentStudent == nil {
            currentStudent = student
        }
        saveData()
    }
    
    func updateStudent(_ student: Student) {
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index] = student
            if currentStudent?.id == student.id {
                currentStudent = student
            }
            saveData()
        }
    }
    
    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
        if currentStudent?.id == student.id {
            currentStudent = students.first
        }
        saveData()
    }
    
    func setCurrentStudent(_ student: Student) {
        currentStudent = student
        saveData()
    }
    
    // MARK: - 创建默认学生档案
    private func createDefaultStudent() {
        let defaultStudent = Student(
            name: "默认学习者",
            grade: "高中",
            school: "默认学校"
        )
        
        students.append(defaultStudent)
        currentStudent = defaultStudent
        saveData()
        
        print("✅ 已创建默认学生档案: \(defaultStudent.name)")
    }
    
    // MARK: - 复盘管理
    func addReflection(_ reflection: LearningReflection) {
        reflections.append(reflection)
        saveData()
    }
    
    func updateReflection(_ reflection: LearningReflection) {
        if let index = reflections.firstIndex(where: { $0.id == reflection.id }) {
            reflections[index] = reflection
            saveData()
        }
    }
    
    func deleteReflection(_ reflection: LearningReflection) {
        reflections.removeAll { $0.id == reflection.id }
        saveData()
    }
    
    func getReflectionsForTimeRange(_ timeRange: DateInterval) -> [LearningReflection] {
        return reflections.filter { timeRange.contains($0.createdAt) }
    }
    
    // MARK: - 测试数据
    private func addSampleData() {
        // 添加示例目标
        let sampleGoal = LearningGoal(
            title: "英语口语提升",
            description: "通过日常练习提升英语口语表达能力",
            category: .english,
            priority: .high,
            targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        )
        addGoal(sampleGoal)
        
        // 为这个目标生成计划
        let plan = generatePlanFromGoal(sampleGoal)
        addPlan(plan)
        
        // 添加一些任务
        let task1 = LearningTask(
            title: "每日英语对话练习",
            description: "与AI或朋友进行15分钟英语对话",
            category: .english,
            priority: .high,
            estimatedDuration: 15 * 60 // 15分钟
        )
        addTask(task1)
        
        let task2 = LearningTask(
            title: "英语单词背诵",
            description: "背诵20个新单词",
            category: .english,
            priority: .medium,
            estimatedDuration: 30 * 60 // 30分钟
        )
        addTask(task2)
    }
    
    // MARK: - 学习计划管理
    func addPlan(_ plan: LearningPlan) {
        // 更新目标的planId
        if let goalIndex = goals.firstIndex(where: { $0.id == plan.id }) {
            goals[goalIndex].planId = plan.id
        }
        
        // 如果已存在相同ID的计划，则更新它
        if let existingIndex = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[existingIndex] = plan
        } else {
            plans.append(plan)
        }
        
        print("=== 添加计划调试信息 ===")
        print("计划ID: \(plan.id)")
        print("计划标题: \(plan.title)")
        print("当前计划总数: \(plans.count)")
        print("=== 添加计划调试信息结束 ===")
        saveData()
    }
    
    func updatePlan(_ plan: LearningPlan) {
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
            saveData()
        }
    }
    
    func deletePlan(_ plan: LearningPlan) {
        // 1. 删除计划下的周计划中的周任务
        for _ in plan.weeklyPlans {
            // 周任务存储在 WeeklyPlan.tasks 中，删除时会自动清理
            // 这里主要是为了确保数据一致性
        }
        
        // 2. 批量删除关联的任务和学习记录
        let relatedTasks = getTasksForPlan(plan.id)
        deleteTasksBatch(relatedTasks)
        
        // 3. 删除计划本身
        plans.removeAll { $0.id == plan.id }
        
        // 4. 清除目标的 planId 引用
        if let goalIndex = goals.firstIndex(where: { $0.planId == plan.id }) {
            var updatedGoal = goals[goalIndex]
            updatedGoal.planId = nil
            goals[goalIndex] = updatedGoal
        }
        
        print("✅ 已删除计划「\(plan.title)」及其所有关联数据")
        saveData()
    }
    
    func getPlanForGoal(_ goalId: UUID) -> LearningPlan? {
        print("=== 获取目标计划详细调试信息 ===")
        print("查询的目标ID: \(goalId)")
        let plan = plans.first(where: { $0.id == goalId })
        if let plan = plan {
            print("找到计划 - ID: \(plan.id), 标题: \(plan.title)")
        } else {
            print("未找到计划")
        }
        print("=== 获取目标计划详细调试信息结束 ===")
        return plan
    }
    
    func getActivePlans() -> [LearningPlan] {
        return plans.filter { $0.isActive }
    }
    
    func generatePlanFromGoal(_ goal: LearningGoal) -> LearningPlan {
        let totalWeeks = Int(goal.targetDate.timeIntervalSince(goal.startDate) / (7 * 24 * 3600))
        let plan = LearningPlan(
            id: goal.id,
            title: "\(goal.title) 学习计划",
            description: "基于目标自动生成的 \(totalWeeks) 周学习计划",
            startDate: goal.startDate,
            endDate: goal.targetDate,
            totalWeeks: totalWeeks
        )
        
        // 生成周计划
        var weeklyPlans: [WeeklyPlan] = []
        for week in 1...totalWeeks {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: week - 1, to: goal.startDate) ?? goal.startDate
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            let milestones = generateMilestonesForWeek(week: week, totalWeeks: totalWeeks, goal: goal)
            let taskCount = calculateTaskCountForWeek(week: week, totalWeeks: totalWeeks, goal: goal)
            let estimatedHours = calculateEstimatedHoursForWeek(week: week, totalWeeks: totalWeeks, goal: goal)
            
            let weeklyPlan = WeeklyPlan(
                weekNumber: week,
                startDate: weekStart,
                endDate: weekEnd,
                milestones: milestones,
                taskCount: taskCount,
                estimatedHours: estimatedHours
            )
            weeklyPlans.append(weeklyPlan)
        }
        
        var updatedPlan = plan
        updatedPlan.weeklyPlans = weeklyPlans
        updatedPlan.resources = generateResourcesForGoal(goal)
        
        return updatedPlan
    }
    
    private func generateMilestonesForWeek(week: Int, totalWeeks: Int, goal: LearningGoal) -> [String] {
        // 根据目标类型和里程碑生成周里程碑
        var milestones: [String] = []
        
        if week <= totalWeeks / 3 {
            // 前1/3阶段：基础阶段
            milestones.append("完成基础理论学习")
        } else if week <= totalWeeks * 2 / 3 {
            // 中1/3阶段：练习阶段
            milestones.append("完成专项练习")
        } else {
            // 后1/3阶段：冲刺阶段
            milestones.append("完成综合复习")
        }
        
        return milestones
    }
    
    private func calculateTaskCountForWeek(week: Int, totalWeeks: Int, goal: LearningGoal) -> Int {
        // 根据目标类型计算每周任务数量
        switch goal.category {
        case .math, .physics, .chemistry:
            return 10 + (week * 2) // 理科任务递增
        case .chinese, .english:
            return 8 + week // 文科任务递增
        case .history, .geography, .politics:
            return 6 + (week / 2) // 文科任务递增较慢
        case .biology, .science:
            return 8 + (week * 3 / 2) // 生物和科学任务递增
        case .other:
            return 5 + week // 其他任务递增
        }
    }
    
    private func calculateEstimatedHoursForWeek(week: Int, totalWeeks: Int, goal: LearningGoal) -> Double {
        // 根据目标类型计算每周预估学习时间
        let baseHours: Double
        switch goal.category {
        case .math, .physics, .chemistry:
            baseHours = 15.0
        case .chinese, .english:
            baseHours = 12.0
        case .history, .geography, .politics:
            baseHours = 10.0
        case .biology, .science:
            baseHours = 12.0
        case .other:
            baseHours = 8.0
        }
        
        // 随着周数增加，学习时间逐渐增加
        return baseHours + Double(week) * 0.5
    }
    
    private func generateResourcesForGoal(_ goal: LearningGoal) -> [LearningResource] {
        // 根据目标类型生成相关学习资源
        var resources: [LearningResource] = []
        
        switch goal.category {
        case .math:
            resources.append(LearningResource(title: "数学教材", type: .textbook, description: "主要学习教材"))
            resources.append(LearningResource(title: "数学题库", type: .exercise, description: "练习题集"))
        case .english:
            resources.append(LearningResource(title: "英语单词书", type: .textbook, description: "词汇学习"))
            resources.append(LearningResource(title: "英语听力材料", type: .video, description: "听力练习"))
        case .chinese:
            resources.append(LearningResource(title: "语文教材", type: .textbook, description: "课文学习"))
            resources.append(LearningResource(title: "作文素材", type: .website, description: "写作素材收集"))
        default:
            resources.append(LearningResource(title: "相关教材", type: .textbook, description: "主要学习材料"))
        }
        
        return resources
    }
    
    // MARK: - 模板管理
    func addTemplate(_ template: LearningTemplate) {
        templates.append(template)
        saveData()
    }
    
    func updateTemplate(_ template: LearningTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveData()
        }
    }
    
    func deleteTemplate(_ template: LearningTemplate) {
        templates.removeAll { $0.id == template.id }
        saveData()
    }
    
    func getTemplatesForGrade(_ grade: Grade) -> [LearningTemplate] {
        return templates.filter { $0.grade == grade }
    }
    
    func getTemplatesForAcademicLevel(_ level: AcademicLevel) -> [LearningTemplate] {
        return templates.filter { $0.academicLevel == level }
    }
    
    // MARK: - 回收站管理
    func restoreGoal(_ deletedGoal: DeletedGoal) {
        // 1. 从回收站移除
        recycleBin.removeAll { $0.id == deletedGoal.id }
        
        // 2. 恢复到目标列表
        goals.append(deletedGoal.goal)
        
        print("✅ 已恢复目标「\(deletedGoal.goal.title)」")
        saveData()
    }
    
    func permanentlyDeleteGoal(_ deletedGoal: DeletedGoal) {
        // 从回收站永久删除
        recycleBin.removeAll { $0.id == deletedGoal.id }
        
        print("✅ 已永久删除目标「\(deletedGoal.goal.title)」")
        saveData()
    }
    
    func clearRecycleBin() {
        recycleBin.removeAll()
        print("✅ 已清空回收站")
        saveData()
    }
    
    func getRecycleBinGoals() -> [DeletedGoal] {
        return recycleBin.sorted { $0.deletedAt > $1.deletedAt }
    }
    
    // MARK: - 番茄钟管理
    func startPomodoroSession(for taskId: UUID?, sessionType: PomodoroSessionType = .work) -> PomodoroSession {
        let session = PomodoroSession(taskId: taskId, sessionType: sessionType)
        pomodoroSessions.append(session)
        saveData()
        return session
    }
    
    func updatePomodoroSession(_ session: PomodoroSession) {
        if let index = pomodoroSessions.firstIndex(where: { $0.id == session.id }) {
            pomodoroSessions[index] = session
            saveData()
        }
    }
    
    func completePomodoroSession(_ sessionId: UUID) {
        if let index = pomodoroSessions.firstIndex(where: { $0.id == sessionId }) {
            var session = pomodoroSessions[index]
            session.status = .completed
            session.endTime = Date()
            session.duration = session.endTime!.timeIntervalSince(session.startTime)
            session.updatedAt = Date()
            pomodoroSessions[index] = session
            saveData()
        }
    }
    
    func pausePomodoroSession(_ sessionId: UUID) {
        if let index = pomodoroSessions.firstIndex(where: { $0.id == sessionId }) {
            var session = pomodoroSessions[index]
            session.status = .paused
            session.updatedAt = Date()
            pomodoroSessions[index] = session
            saveData()
        }
    }
    
    func cancelPomodoroSession(_ sessionId: UUID) {
        if let index = pomodoroSessions.firstIndex(where: { $0.id == sessionId }) {
            var session = pomodoroSessions[index]
            session.status = .cancelled
            session.endTime = Date()
            session.duration = session.endTime!.timeIntervalSince(session.startTime)
            session.updatedAt = Date()
            pomodoroSessions[index] = session
            saveData()
        }
    }
    
    func getActivePomodoroSession() -> PomodoroSession? {
        return pomodoroSessions.first { $0.status == .active }
    }
    
    func getPomodoroSessionsForTask(_ taskId: UUID) -> [PomodoroSession] {
        return pomodoroSessions.filter { $0.taskId == taskId }
    }
    
    func getTodayPomodoroSessions() -> [PomodoroSession] {
        let today = Calendar.current.startOfDay(for: Date())
        return pomodoroSessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }
    }
    
}
