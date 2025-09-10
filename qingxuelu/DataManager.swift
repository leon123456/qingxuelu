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
    
    // 兼容性支持（逐步迁移）
    @Published var profiles: [StudentProfile] = []
    @Published var templates: [LearningTemplate] = []
    @Published var students: [Student] = []
    @Published var currentStudent: Student?
    
    private let userDefaults = UserDefaults.standard
    
    // 核心数据键
    private let goalsKey = "goals"
    private let tasksKey = "tasks"
    private let recordsKey = "records"
    private let reflectionsKey = "reflections"
    
    // 兼容性键
    private let profilesKey = "profiles"
    private let templatesKey = "templates"
    private let studentsKey = "students"
    private let currentStudentKey = "currentStudent"
    
    init() {
        loadData()
    }
    
    // MARK: - 数据持久化
    private func saveData() {
        // 保存核心数据
        if let goalsData = try? JSONEncoder().encode(goals) {
            userDefaults.set(goalsData, forKey: goalsKey)
        }
        if let tasksData = try? JSONEncoder().encode(tasks) {
            userDefaults.set(tasksData, forKey: tasksKey)
        }
        if let recordsData = try? JSONEncoder().encode(records) {
            userDefaults.set(recordsData, forKey: recordsKey)
        }
        if let reflectionsData = try? JSONEncoder().encode(reflections) {
            userDefaults.set(reflectionsData, forKey: reflectionsKey)
        }
        
        // 兼容性保存
        if let studentsData = try? JSONEncoder().encode(students) {
            userDefaults.set(studentsData, forKey: studentsKey)
        }
        if let templatesData = try? JSONEncoder().encode(templates) {
            userDefaults.set(templatesData, forKey: templatesKey)
        }
        if let profilesData = try? JSONEncoder().encode(profiles) {
            userDefaults.set(profilesData, forKey: profilesKey)
        }
        if let currentStudentData = try? JSONEncoder().encode(currentStudent) {
            userDefaults.set(currentStudentData, forKey: currentStudentKey)
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
    
    func deleteGoal(_ goal: LearningGoal) {
        goals.removeAll { $0.id == goal.id }
        tasks.removeAll { $0.goalId == goal.id }
        saveData()
    }
    
    func getGoalsForStudent(_ studentId: UUID) -> [LearningGoal] {
        // 第一版暂不使用userId过滤，返回所有目标
        return goals
    }
    
    // MARK: - 任务管理
    func addTask(_ task: LearningTask) {
        tasks.append(task)
        saveData()
    }
    
    func updateTask(_ task: LearningTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveData()
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
        students.removeAll()
        goals.removeAll()
        tasks.removeAll()
        records.removeAll()
        profiles.removeAll()
        templates.removeAll()
        currentStudent = nil
        saveData()
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
}
