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
    @State private var selectedStatus: TaskStatus? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if let currentStudent = dataManager.currentStudent {
                    let tasks = filteredTasks(for: currentStudent.id)
                    
                    if tasks.isEmpty {
                        EmptyTasksView()
                    } else {
                        List {
                            ForEach(tasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    SimpleTaskRowView(task: task)
                                }
                            }
                            .onDelete(perform: deleteTasks)
                        }
                    }
                } else {
                    EmptyStudentView()
                }
            }
            .navigationTitle("学习任务")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("全部") { selectedStatus = nil }
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) { selectedStatus = status }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
    
    private func filteredTasks(for studentId: UUID) -> [LearningTask] {
        let tasks = dataManager.getTasksForStudent(studentId)
        if let status = selectedStatus {
            return tasks.filter { $0.status == status }
        }
        return tasks
    }
    
    private func deleteTasks(offsets: IndexSet) {
        guard let currentStudent = dataManager.currentStudent else { return }
        let tasks = dataManager.getTasksForStudent(currentStudent.id)
        for index in offsets {
            dataManager.deleteTask(tasks[index])
        }
    }
}

// MARK: - 空任务视图
struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有学习任务")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("创建学习任务，让学习更有计划")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 任务详情视图
struct TaskDetailView: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditTask = false
    @State private var showingTimer = false
    
    var body: some View {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") {
                    showingEditTask = true
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task)
        }
        .sheet(isPresented: $showingTimer) {
            PomodoroView(task: task)
        }
    }
}

// MARK: - 任务信息区域
struct TaskInfoSection: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("任务信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                // 任务名称
                InfoRow(title: "任务名称", value: task.title, icon: "doc.text")
                
                InfoRow(title: "科目", value: task.category.rawValue, icon: task.category.icon)
                InfoRow(title: "优先级", value: task.priority.rawValue, icon: "exclamationmark.triangle")
                InfoRow(title: "状态", value: task.status.rawValue, icon: "circle.fill")
                InfoRow(title: "预估时间", value: formatDuration(task.estimatedDuration), icon: "clock")
                
                // 显示关联的目标信息
                if let goalId = task.goalId {
                    if let goal = dataManager.goals.first(where: { $0.id == goalId }) {
                        InfoRow(title: "关联目标", value: goal.title, icon: "target")
                    }
                }
                
                // 显示关联的计划信息
                if let planId = task.planId {
                    if let plan = dataManager.plans.first(where: { $0.id == planId }) {
                        InfoRow(title: "关联计划", value: plan.title, icon: "calendar")
                    }
                }
                
                if let actualDuration = task.actualDuration {
                    InfoRow(title: "实际时间", value: formatDuration(actualDuration), icon: "clock.fill")
                }
                
                if let dueDate = task.dueDate {
                    InfoRow(title: "截止时间", value: dueDate, formatter: dateTimeFormatter, icon: "calendar")
                }
                
                if let completedDate = task.completedDate {
                    InfoRow(title: "完成时间", value: completedDate, formatter: dateTimeFormatter, icon: "checkmark.circle")
                }
            }
            
            if !task.description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习记录区域
struct LearningRecordsSection: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习记录")
                .font(.headline)
                .fontWeight(.semibold)
            
            let records = dataManager.getRecordsForTask(task.id)
            
            if records.isEmpty {
                Text("暂无学习记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(records) { record in
                    LearningRecordRowView(record: record)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习记录行视图
struct LearningRecordRowView: View {
    let record: LearningRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.startTime, formatter: dateTimeFormatter)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatDuration(record.duration))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if let rating = record.rating {
                HStack {
                    Text("学习质量:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 操作按钮区域
struct ActionButtonsSection: View {
    let task: LearningTask
    @Binding var showingTimer: Bool
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCompletionAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 任务完成状态显示
            if task.status == .completed {
                TaskCompletionStatusView(task: task)
            } else {
                // 未完成任务的操作按钮
                if task.status != .completed {
                    Button(action: { showingTimer = true }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("开始学习")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                HStack(spacing: 12) {
                    if task.status == .pending {
                        Button(action: { markTaskAsInProgress() }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("开始")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    if task.status == .inProgress {
                        Button(action: { showingCompletionAlert = true }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("完成")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .alert("完成任务", isPresented: $showingCompletionAlert) {
            Button("取消", role: .cancel) { }
            Button("完成", role: .destructive) {
                markTaskAsCompleted()
            }
        } message: {
            Text("确定要标记「\(task.title)」为已完成吗？")
        }
    }
    
    private func markTaskAsInProgress() {
        var updatedTask = task
        updatedTask.status = .inProgress
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
    }
    
    private func markTaskAsCompleted() {
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.completedDate = Date()
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
    }
}

// MARK: - 任务完成状态视图
struct TaskCompletionStatusView: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    @State private var showingReopenAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 完成状态图标和文字
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务已完成")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    if let completedDate = task.completedDate {
                        Text("完成时间: \(completedDate, formatter: dateTimeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 重新打开按钮
            Button(action: { showingReopenAlert = true }) {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("重新打开")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .alert("重新打开任务", isPresented: $showingReopenAlert) {
            Button("取消", role: .cancel) { }
            Button("重新打开", role: .destructive) {
                reopenTask()
            }
        } message: {
            Text("确定要重新打开「\(task.title)」吗？任务状态将变为进行中。")
        }
    }
    
    private func reopenTask() {
        var updatedTask = task
        updatedTask.status = .inProgress
        updatedTask.completedDate = nil
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
    }
}

// MARK: - 辅助函数
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)小时\(minutes)分钟"
    } else {
        return "\(minutes)分钟"
    }
}


private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    TasksView()
        .environmentObject(DataManager())
}
