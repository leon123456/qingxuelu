//
//  PomodoroView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct PomodoroView: View {
    @StateObject private var pomodoroTimer = PomodoroTimer()
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let task: LearningTask?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 番茄钟圆形进度条
                PomodoroProgressView(
                    progress: pomodoroTimer.getProgress(),
                    timeRemaining: pomodoroTimer.timeRemaining,
                    sessionType: pomodoroTimer.currentSessionType,
                    isRunning: pomodoroTimer.isRunning,
                    isPaused: pomodoroTimer.isPaused
                )
                
                // 会话信息
                PomodoroSessionInfo(
                    session: pomodoroTimer.currentSession,
                    completedSessions: pomodoroTimer.completedWorkSessions,
                    task: task
                )
                
                // 控制按钮
                PomodoroControlButtons(
                    timer: pomodoroTimer,
                    task: task,
                    dataManager: dataManager
                )
                
                // 下一个会话建议
                PomodoroNextSessionSuggestion(timer: pomodoroTimer)
                
                Spacer()
            }
            .padding()
            .navigationTitle("番茄钟")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        showingSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            PomodoroSettingsView(timer: pomodoroTimer)
        }
        .onAppear {
            // 如果有任务，自动开始工作会话
            if let task = task {
                pomodoroTimer.startSession(for: task.id, sessionType: .work, taskEstimatedDuration: task.estimatedDuration)
            }
        }
        .onDisappear {
            // 页面消失时保存当前会话
            if let session = pomodoroTimer.currentSession {
                dataManager.updatePomodoroSession(session)
            }
        }
    }
}

// MARK: - 番茄钟进度视图
struct PomodoroProgressView: View {
    let progress: Double
    let timeRemaining: TimeInterval
    let sessionType: PomodoroSessionType
    let isRunning: Bool
    let isPaused: Bool
    
    var body: some View {
        ZStack {
            // 背景圆圈
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                .frame(width: 200, height: 200)
            
            // 进度圆圈
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    sessionType.color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // 中心内容
            VStack(spacing: 8) {
                // 时间显示
                Text(formatTime(timeRemaining))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(sessionType.color)
                
                // 会话类型
                HStack(spacing: 4) {
                    Image(systemName: sessionType.icon)
                        .font(.title2)
                        .foregroundColor(sessionType.color)
                    
                    Text(sessionType.rawValue)
                        .font(.headline)
                        .foregroundColor(sessionType.color)
                }
                
                // 状态指示器
                if isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("进行中")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if isPaused {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("已暂停")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 会话信息视图
struct PomodoroSessionInfo: View {
    let session: PomodoroSession?
    let completedSessions: Int
    let task: LearningTask?
    
    var body: some View {
        VStack(spacing: 12) {
            if let session = session {
                HStack {
                    Text("开始时间:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(session.startTime, formatter: timeFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("计划时长:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(session.plannedDuration))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Text("今日完成:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(completedSessions)个番茄时间")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // 时长建议说明
            if let task = task {
                HStack {
                    Text("时长建议:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(getDurationSuggestion(for: task.estimatedDuration))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        return "\(minutes)分钟"
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func getDurationSuggestion(for taskEstimatedDuration: TimeInterval?) -> String {
        guard let taskDuration = taskEstimatedDuration else {
            return "使用标准番茄钟时长（25分钟）"
        }
        
        let taskDurationMinutes = taskDuration / 60
        
        if taskDurationMinutes <= 5 {
            return "短任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 15 {
            return "中等任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 30 {
            return "较长任务：使用任务时长（\(Int(taskDurationMinutes))分钟）"
        } else if taskDurationMinutes <= 60 {
            return "长任务：使用标准番茄钟时长（25分钟）"
        } else {
            return "超长任务：使用标准番茄钟时长（25分钟），建议分段完成"
        }
    }
}

// MARK: - 控制按钮视图
struct PomodoroControlButtons: View {
    @ObservedObject var timer: PomodoroTimer
    let task: LearningTask?
    let dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 20) {
            if timer.isRunning {
                // 暂停按钮
                Button(action: { timer.pauseSession() }) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("暂停")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else if timer.isPaused {
                // 继续按钮
                Button(action: { timer.resumeSession() }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("继续")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                // 开始按钮
                Button(action: { 
                    let sessionType = timer.getNextSessionType()
                    timer.startSession(for: task?.id, sessionType: sessionType, taskEstimatedDuration: task?.estimatedDuration)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            // 停止按钮
            Button(action: { 
                timer.stopSession()
                if let session = timer.currentSession {
                    dataManager.updatePomodoroSession(session)
                }
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("停止")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - 下一个会话建议视图
struct PomodoroNextSessionSuggestion: View {
    @ObservedObject var timer: PomodoroTimer
    
    var body: some View {
        VStack(spacing: 8) {
            Text("建议下一个会话")
                .font(.headline)
                .foregroundColor(.secondary)
            
            let nextType = timer.getNextSessionType()
            HStack(spacing: 8) {
                Image(systemName: nextType.icon)
                    .foregroundColor(nextType.color)
                
                Text(nextType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(nextType.color)
                
                Text("(\(Int(timer.getDuration(for: nextType) / 60))分钟)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(nextType.color.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func getDuration(for sessionType: PomodoroSessionType) -> TimeInterval {
        switch sessionType {
        case .work:
            return timer.workDuration
        case .shortBreak:
            return timer.shortBreakDuration
        case .longBreak:
            return timer.longBreakDuration
        }
    }
}

// MARK: - 番茄钟设置视图
struct PomodoroSettingsView: View {
    @ObservedObject var timer: PomodoroTimer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("工作时间") {
                    HStack {
                        Text("番茄时间")
                        Spacer()
                        Text("\(Int(timer.workDuration / 60))分钟")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { timer.workDuration / 60 },
                            set: { timer.updateWorkDuration($0 * 60) }
                        ),
                        in: 5...60,
                        step: 5
                    )
                }
                
                Section("休息时间") {
                    HStack {
                        Text("短休息")
                        Spacer()
                        Text("\(Int(timer.shortBreakDuration / 60))分钟")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { timer.shortBreakDuration / 60 },
                            set: { timer.updateShortBreakDuration($0 * 60) }
                        ),
                        in: 1...15,
                        step: 1
                    )
                    
                    HStack {
                        Text("长休息")
                        Spacer()
                        Text("\(Int(timer.longBreakDuration / 60))分钟")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { timer.longBreakDuration / 60 },
                            set: { timer.updateLongBreakDuration($0 * 60) }
                        ),
                        in: 10...30,
                        step: 5
                    )
                }
                
                Section("循环设置") {
                    HStack {
                        Text("长休息间隔")
                        Spacer()
                        Text("每\(timer.sessionsUntilLongBreak)个番茄时间")
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper(
                        "长休息间隔",
                        value: Binding(
                            get: { timer.sessionsUntilLongBreak },
                            set: { timer.updateSessionsUntilLongBreak($0) }
                        ),
                        in: 2...8
                    )
                }
            }
            .navigationTitle("番茄钟设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PomodoroView(task: nil)
        .environmentObject(DataManager())
}
