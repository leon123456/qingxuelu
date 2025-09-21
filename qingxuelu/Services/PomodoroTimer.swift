//
//  PomodoroTimer.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 番茄钟计时器服务
class PomodoroTimer: ObservableObject {
    @Published var currentSession: PomodoroSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    
    // 番茄钟配置
    @Published var workDuration: TimeInterval = 25 * 60 // 25分钟
    @Published var shortBreakDuration: TimeInterval = 5 * 60 // 5分钟
    @Published var longBreakDuration: TimeInterval = 15 * 60 // 15分钟
    @Published var sessionsUntilLongBreak = 4 // 每4个番茄时间后长休息
    
    @Published var completedWorkSessions = 0
    @Published var currentSessionType: PomodoroSessionType = .work
    
    init() {
        loadSettings()
    }
    
    // MARK: - 计时器控制
    func startSession(for taskId: UUID? = nil, sessionType: PomodoroSessionType = .work, taskEstimatedDuration: TimeInterval? = nil) {
        stopTimer()
        
        let duration = getSmartDuration(for: sessionType, taskEstimatedDuration: taskEstimatedDuration)
        currentSession = PomodoroSession(
            taskId: taskId,
            sessionType: sessionType,
            plannedDuration: duration
        )
        
        timeRemaining = duration
        currentSessionType = sessionType
        isRunning = true
        isPaused = false
        startTime = Date()
        pausedTime = 0
        
        startTimer()
    }
    
    func pauseSession() {
        guard isRunning else { return }
        
        isPaused = true
        isRunning = false
        stopTimer()
        
        if let session = currentSession {
            // 更新会话状态为暂停
            var updatedSession = session
            updatedSession.status = .paused
            updatedSession.updatedAt = Date()
            currentSession = updatedSession
        }
    }
    
    func resumeSession() {
        guard isPaused else { return }
        
        isPaused = false
        isRunning = true
        startTime = Date()
        
        if let session = currentSession {
            // 更新会话状态为活跃
            var updatedSession = session
            updatedSession.status = .active
            updatedSession.updatedAt = Date()
            currentSession = updatedSession
        }
        
        startTimer()
    }
    
    func stopSession() {
        stopTimer()
        
        if let session = currentSession {
            var updatedSession = session
            updatedSession.status = .cancelled
            updatedSession.endTime = Date()
            updatedSession.duration = updatedSession.endTime!.timeIntervalSince(updatedSession.startTime)
            updatedSession.updatedAt = Date()
            currentSession = updatedSession
        }
        
        resetTimer()
    }
    
    func completeSession() {
        stopTimer()
        
        if let session = currentSession {
            var updatedSession = session
            updatedSession.status = .completed
            updatedSession.endTime = Date()
            updatedSession.duration = updatedSession.endTime!.timeIntervalSince(updatedSession.startTime)
            updatedSession.updatedAt = Date()
            currentSession = updatedSession
            
            // 更新会话计数
            if session.sessionType == .work {
                completedWorkSessions += 1
            }
        }
        
        resetTimer()
    }
    
    // MARK: - 私有方法
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime) + pausedTime
        let remaining = (currentSession?.plannedDuration ?? 0) - elapsed
        
        if remaining <= 0 {
            // 时间到了
            completeSession()
        } else {
            timeRemaining = remaining
        }
    }
    
    private func resetTimer() {
        isRunning = false
        isPaused = false
        timeRemaining = 0
        startTime = nil
        pausedTime = 0
    }
    
    func getDuration(for sessionType: PomodoroSessionType) -> TimeInterval {
        switch sessionType {
        case .work:
            return workDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }
    
    // MARK: - 智能时长计算
    func getSmartDuration(for sessionType: PomodoroSessionType, taskEstimatedDuration: TimeInterval? = nil) -> TimeInterval {
        switch sessionType {
        case .work:
            return getSmartWorkDuration(taskEstimatedDuration: taskEstimatedDuration)
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }
    
    private func getSmartWorkDuration(taskEstimatedDuration: TimeInterval? = nil) -> TimeInterval {
        guard let taskDuration = taskEstimatedDuration else {
            // 没有任务时长信息，使用默认番茄钟时长
            return workDuration
        }
        
        // 将任务时长转换为分钟
        let taskDurationMinutes = taskDuration / 60
        
        // 智能调整规则：
        // 1. 如果任务时长 <= 5分钟，使用任务时长
        // 2. 如果任务时长 <= 15分钟，使用任务时长
        // 3. 如果任务时长 <= 30分钟，使用任务时长
        // 4. 如果任务时长 > 30分钟，使用标准番茄钟时长（25分钟）
        // 5. 如果任务时长 > 60分钟，建议分段，使用标准番茄钟时长
        
        if taskDurationMinutes <= 5 {
            // 短任务：使用任务时长
            return taskDuration
        } else if taskDurationMinutes <= 15 {
            // 中等任务：使用任务时长
            return taskDuration
        } else if taskDurationMinutes <= 30 {
            // 较长任务：使用任务时长
            return taskDuration
        } else if taskDurationMinutes <= 60 {
            // 长任务：使用标准番茄钟时长
            return workDuration
        } else {
            // 超长任务：使用标准番茄钟时长，建议分段
            return workDuration
        }
    }
    
    // MARK: - 获取时长建议说明
    func getDurationSuggestion(for taskEstimatedDuration: TimeInterval?) -> String {
        guard let taskDuration = taskEstimatedDuration else {
            return "使用标准番茄钟时长（\(Int(workDuration / 60))分钟）"
        }
        
        let taskDurationMinutes = taskDuration / 60
        
        if taskDurationMinutes <= 5 {
            return "短任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 15 {
            return "中等任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 30 {
            return "较长任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 60 {
            return "长任务：使用标准番茄钟时长（\(Int(workDuration / 60))分钟）"
        } else {
            return "超长任务：使用标准番茄钟时长（\(Int(workDuration / 60))分钟），建议分段完成"
        }
    }
    
    // MARK: - 设置管理
    func updateWorkDuration(_ duration: TimeInterval) {
        workDuration = duration
        saveSettings()
    }
    
    func updateShortBreakDuration(_ duration: TimeInterval) {
        shortBreakDuration = duration
        saveSettings()
    }
    
    func updateLongBreakDuration(_ duration: TimeInterval) {
        longBreakDuration = duration
        saveSettings()
    }
    
    func updateSessionsUntilLongBreak(_ count: Int) {
        sessionsUntilLongBreak = count
        saveSettings()
    }
    
    // MARK: - 建议下一个会话类型
    func getNextSessionType() -> PomodoroSessionType {
        if completedWorkSessions > 0 && completedWorkSessions % sessionsUntilLongBreak == 0 {
            return .longBreak
        } else if currentSessionType == .work {
            return .shortBreak
        } else {
            return .work
        }
    }
    
    // MARK: - 格式化时间
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // MARK: - 进度计算
    func getProgress() -> Double {
        guard let session = currentSession else { return 0 }
        let elapsed = session.plannedDuration - timeRemaining
        return elapsed / session.plannedDuration
    }
    
    // MARK: - 设置持久化
    private func saveSettings() {
        let settings = [
            "workDuration": workDuration,
            "shortBreakDuration": shortBreakDuration,
            "longBreakDuration": longBreakDuration,
            "sessionsUntilLongBreak": sessionsUntilLongBreak,
            "completedWorkSessions": completedWorkSessions
        ] as [String: Any]
        
        UserDefaults.standard.set(settings, forKey: "PomodoroSettings")
    }
    
    private func loadSettings() {
        let settings = UserDefaults.standard.dictionary(forKey: "PomodoroSettings") ?? [:]
        
        if let duration = settings["workDuration"] as? TimeInterval {
            workDuration = duration
        }
        if let duration = settings["shortBreakDuration"] as? TimeInterval {
            shortBreakDuration = duration
        }
        if let duration = settings["longBreakDuration"] as? TimeInterval {
            longBreakDuration = duration
        }
        if let count = settings["sessionsUntilLongBreak"] as? Int {
            sessionsUntilLongBreak = count
        }
        if let count = settings["completedWorkSessions"] as? Int {
            completedWorkSessions = count
        }
    }
    
    deinit {
        stopTimer()
    }
}
