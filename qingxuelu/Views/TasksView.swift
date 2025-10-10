//
//  TasksView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    @State private var selectedTask: LearningTask?
    @State private var showingTaskDetail = false
    @State private var showingTimer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 任务列表
                List {
                    ForEach(dataManager.tasks) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(task.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Text(task.status.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(for: task.status))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedTask = task
                            showingTaskDetail = true
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("任务")
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
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task)
            }
        }
        .sheet(isPresented: $showingTimer) {
            PomodoroView(task: selectedTask)
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = offsets.map { dataManager.tasks[$0] }
        for task in tasksToDelete {
            dataManager.deleteTask(task)
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .orange
        }
    }
}

// MARK: - 任务详情视图
struct TaskDetailView: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    @State private var showingTaskCompletion = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 任务基本信息
                    TaskInfoSection(task: task)
                    
                    // 学习记录
                    LearningRecordsSection(task: task)
                    
                    // 操作按钮
                    ActionButtonsSection(task: task, showingTimer: $showingTimer)
                }
                .padding()
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTimer) {
            PomodoroView(task: task)
        }
        .sheet(isPresented: $showingTaskCompletion) {
            TaskCompletionView(task: task)
        }
    }
    
    private func markTaskAsInProgress() {
        var updatedTask = task
        updatedTask.status = .inProgress
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
    }
}

// MARK: - 任务信息区域
struct TaskInfoSection: View {
    let task: LearningTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("任务信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TaskInfoRow(
                    title: "任务描述",
                    value: task.description,
                    icon: "doc.text"
                )
                
                TaskInfoRow(
                    title: "任务类型",
                    value: task.category.rawValue,
                    icon: task.category.icon
                )
                
                TaskInfoRow(
                    title: "优先级",
                    value: task.priority.rawValue,
                    icon: "exclamationmark.triangle"
                )
                
                TaskInfoRow(
                    title: "预估时长",
                    value: "\(Int(task.estimatedDuration / 60)) 分钟",
                    icon: "clock"
                )
                
                if let dueDate = task.dueDate {
                    TaskInfoRow(
                        title: "截止时间",
                        value: dueDate.formatted(date: .abbreviated, time: .shortened),
                        icon: "calendar.badge.exclamationmark"
                    )
                }
                
                if let scheduledTime = task.scheduledStartTime {
                    TaskInfoRow(
                        title: "安排时间",
                        value: scheduledTime.formatted(date: .omitted, time: .shortened),
                        icon: "calendar.badge.clock"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 任务信息行
struct TaskInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 学习记录区域
struct LearningRecordsSection: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习记录")
                .font(.headline)
                .fontWeight(.semibold)
            
            let taskRecords = dataManager.records.filter { $0.taskId == task.id }
            
            if taskRecords.isEmpty {
                Text("暂无学习记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(taskRecords) { record in
                    LearningRecordRow(record: record)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习记录行
struct LearningRecordRow: View {
    let record: LearningRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.endTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(record.duration / 60)) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let rating = record.rating {
                HStack {
                    Text("质量评分:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - 操作按钮区域
struct ActionButtonsSection: View {
    let task: LearningTask
    @Binding var showingTimer: Bool
    @EnvironmentObject var dataManager: DataManager
    @State private var showingTaskCompletion = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 启动任务钟按钮
            Button(action: { showingTimer = true }) {
                HStack {
                    Image(systemName: "timer")
                    Text("启动任务钟")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
            }
            
            // 手动操作按钮
            HStack(spacing: 12) {
                if task.status == .pending {
                    Button(action: { markTaskAsInProgress() }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("手动开始")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                
                if task.status == .inProgress {
                    Button(action: { showingTaskCompletion = true }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("完成任务")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTaskCompletion) {
            TaskCompletionView(task: task)
        }
    }
    
    private func markTaskAsInProgress() {
        var updatedTask = task
        updatedTask.status = .inProgress
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
    }
}

// MARK: - 任务状态指示器
struct TaskStatusIndicator: View {
    let task: LearningTask
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: statusIcon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemBackground))
            }
            
            // 状态文字
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                
                Text(statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .orange
        }
    }
    
    private var statusIcon: String {
        switch task.status {
        case .pending:
            return "clock"
        case .inProgress:
            return "play.fill"
        case .completed:
            return "checkmark"
        case .overdue:
            return "exclamationmark.triangle"
        case .cancelled:
            return "xmark"
        }
    }
    
    private var statusText: String {
        switch task.status {
        case .pending:
            return "待开始"
        case .inProgress:
            return "进行中"
        case .completed:
            return "已完成"
        case .overdue:
            return "已逾期"
        case .cancelled:
            return "已取消"
        }
    }
    
    private var statusDescription: String {
        switch task.status {
        case .pending:
            return "任务等待开始"
        case .inProgress:
            return "任务正在进行中，完成后点击完成任务"
        case .completed:
            return "任务已完成"
        case .overdue:
            return "任务已超过截止时间"
        case .cancelled:
            return "任务已被取消"
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(DataManager())
}
