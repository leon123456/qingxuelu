//
//  TodayView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    @State private var showingPomodoro = false
    @State private var selectedTask: LearningTask?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部进度环
                ProgressRingView()
                    .padding()
                
                // 今日任务列表
                if todayTasks.isEmpty {
                    EmptyTodayView()
                } else {
                    TaskListView(tasks: todayTasks, onTaskSelected: { task in
                        selectedTask = task
                    })
                }
                
                Spacer()
            }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .sheet(isPresented: $showingPomodoro) {
            if let task = selectedTask {
                PomodoroView(task: task)
            }
        }
        .onChange(of: selectedTask) { _, task in
            if task != nil {
                showingPomodoro = true
            }
        }
    }
    
    // MARK: - 今日任务
    private var todayTasks: [LearningTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow && task.status != .completed
        }.sorted { task1, task2 in
            // 按优先级和截止时间排序
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            if let due1 = task1.dueDate, let due2 = task2.dueDate {
                return due1 < due2
            }
            return task1.createdAt < task2.createdAt
        }
    }
}

// MARK: - 进度环视图
struct ProgressRingView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("今日KR完成度")
                .font(.headline)
                .fontWeight(.semibold)
            
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: todayKRProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: todayKRProgress)
                
                // 进度文字
                VStack {
                    Text("\(Int(todayKRProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(completedKRsToday)/\(totalKRsToday)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 今日KR进度计算
    private var todayKRProgress: Double {
        guard totalKRsToday > 0 else { return 0.0 }
        return Double(completedKRsToday) / Double(totalKRsToday)
    }
    
    private var completedKRsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.goals.flatMap { $0.keyResults }.filter { kr in
            // 检查KR是否在今日完成
            return kr.isCompleted && kr.createdAt >= today && kr.createdAt < tomorrow
        }.count
    }
    
    private var totalKRsToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.goals.flatMap { $0.keyResults }.filter { kr in
            // 检查KR是否应该在今日完成
            return kr.createdAt >= today && kr.createdAt < tomorrow
        }.count
    }
}

// MARK: - 空状态视图
struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.green.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("今日任务已完成")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("恭喜！今天的学习任务都完成了\n可以休息一下，或者添加新的任务")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 任务列表视图
struct TaskListView: View {
    let tasks: [LearningTask]
    let onTaskSelected: (LearningTask) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCardView(task: task) {
                        onTaskSelected(task)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 任务卡片视图
struct TaskCardView: View {
    let task: LearningTask
    let onTap: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 任务头部
                HStack {
                    Image(systemName: task.category.icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // 优先级标签
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(task.priority.color).opacity(0.2))
                        .foregroundColor(Color(task.priority.color))
                        .cornerRadius(8)
                }
                
                // 任务信息
                HStack {
                    // 预估时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("\(Int(task.estimatedDuration / 60))分钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 截止时间
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(dueDate, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button("开始学习") {
                        onTap()
                    }
                    .buttonStyle(TodayPrimaryButtonStyle())
                    
                    Button("标记完成") {
                        markTaskCompleted()
                    }
                    .buttonStyle(TodaySecondaryButtonStyle())
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func markTaskCompleted() {
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.completedDate = Date()
        dataManager.updateTask(updatedTask)
    }
}

// MARK: - 番茄钟视图
struct PomodoroView: View {
    let task: LearningTask
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: TimeInterval = 25 * 60 // 25分钟
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // 任务信息
                VStack(spacing: 12) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 番茄钟圆环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: 1 - (timeRemaining / (25 * 60)))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    
                    VStack {
                        Text(formatTime(timeRemaining))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(isRunning ? "专注中..." : "准备开始")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 控制按钮
                HStack(spacing: 20) {
                    Button(isRunning ? "暂停" : "开始") {
                        toggleTimer()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("重置") {
                        resetTimer()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("番茄钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                    // 番茄钟完成
                }
            }
        }
        isRunning.toggle()
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 25 * 60
        isRunning = false
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 按钮样式
struct TodayPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct TodaySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 时间格式化器
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

#Preview {
    TodayView()
        .environmentObject(DataManager())
}
