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
    @State private var selectedDate = Date()
    @State private var taskDisplayMode: TaskDisplayMode = .grouped
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 保留顶部日历功能
                TimelineHeaderView(selectedDate: $selectedDate)
                
                // 任务展示区域 - 去掉时间轴
                TaskDisplayView(
                    selectedDate: selectedDate,
                    displayMode: $taskDisplayMode
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

// MARK: - 任务展示模式
enum TaskDisplayMode: String, CaseIterable {
    case grouped = "按目标分组"
    case individual = "逐个展示"
    
    var icon: String {
        switch self {
        case .grouped:
            return "folder.fill"
        case .individual:
            return "list.bullet"
        }
    }
}

// MARK: - 任务展示视图
struct TaskDisplayView: View {
    let selectedDate: Date
    @Binding var displayMode: TaskDisplayMode
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 显示模式切换器
            TaskDisplayModeSelector(selectedMode: $displayMode)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // 任务内容区域
            ScrollView {
                LazyVStack(spacing: 16) {
                    let tasksForDate = getTasksForDate()
                    
                    if tasksForDate.isEmpty {
                        // 空状态
                        EmptyTaskView(selectedDate: selectedDate)
                    } else {
                        switch displayMode {
                        case .grouped:
                            GroupedTaskView(tasks: tasksForDate)
                        case .individual:
                            IndividualTaskView(tasks: tasksForDate)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100) // 为浮动按钮留空间
            }
        }
        .overlay(
            // 右下角浮动添加任务按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddTask = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(.systemBackground))
                            
                            Text("添加任务")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.systemBackground))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: Color(.label).opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
    
    // MARK: - 获取指定日期的任务
    private func getTasksForDate() -> [LearningTask] {
        return dataManager.tasks.filter { task in
            // 检查任务是否在指定日期
            if task.isTimeBlocked, let scheduledTime = task.scheduledStartTime {
                return Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
            } else if let dueDate = task.dueDate {
                return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
            } else if let scheduledTime = task.scheduledStartTime {
                return Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
            }
            return false
        }
    }
}

// MARK: - 任务显示模式选择器
struct TaskDisplayModeSelector: View {
    @Binding var selectedMode: TaskDisplayMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TaskDisplayMode.allCases, id: \.self) { mode in
                Button(action: { selectedMode = mode }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMode == mode ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedMode == mode ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 按目标分组的任务视图
struct GroupedTaskView: View {
    let tasks: [LearningTask]
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        let groupedTasks = Dictionary(grouping: tasks) { task in
            task.goalId
        }
        
        ForEach(groupedTasks.keys.sorted(by: { key1, key2 in
            // 按目标名称排序
            let goal1 = dataManager.goals.first { $0.id == key1 }
            let goal2 = dataManager.goals.first { $0.id == key2 }
            return (goal1?.title ?? "") < (goal2?.title ?? "")
        }), id: \.self) { goalId in
            if let goalTasks = groupedTasks[goalId], !goalTasks.isEmpty {
                TaskGroupCard(
                    goalId: goalId,
                    tasks: goalTasks
                )
            }
        }
    }
}

// MARK: - 逐个展示的任务视图
struct IndividualTaskView: View {
    let tasks: [LearningTask]
    
    var body: some View {
        ForEach(tasks.sorted(by: { task1, task2 in
            // 按优先级和创建时间排序
            if task1.priority != task2.priority {
                return task1.priority.rawValue < task2.priority.rawValue
            }
            return task1.createdAt < task2.createdAt
        })) { task in
            TaskCard(task: task)
        }
    }
}

// MARK: - 任务组卡片
struct TaskGroupCard: View {
    let goalId: UUID?
    let tasks: [LearningTask]
    @EnvironmentObject var dataManager: DataManager
    @State private var isExpanded = true
    
    var goal: LearningGoal? {
        guard let goalId = goalId else { return nil }
        return dataManager.goals.first { $0.id == goalId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 目标标题栏
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 12) {
                    // 目标图标
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: goal?.category.icon ?? "folder.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal?.title ?? "未分类任务")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(tasks.count) 个任务")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 展开/收起按钮
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 任务列表
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(tasks.sorted(by: { $0.priority.rawValue < $1.priority.rawValue })) { task in
                        TaskCard(task: task, showGoalInfo: false)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - 任务卡片
struct TaskCard: View {
    let task: LearningTask
    let showGoalInfo: Bool
    @EnvironmentObject var dataManager: DataManager
    @State private var showingTaskDetail = false
    
    init(task: LearningTask, showGoalInfo: Bool = true) {
        self.task = task
        self.showGoalInfo = showGoalInfo
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 任务图标
            ZStack {
                Circle()
                    .fill(getCategoryColor().opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: task.category.icon)
                    .foregroundColor(getCategoryColor())
                    .font(.system(size: 18, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // 优先级标签
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(getPriorityColor().opacity(0.2))
                        )
                        .foregroundColor(getPriorityColor())
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 目标信息（可选显示）
                if showGoalInfo, let goalId = task.goalId {
                    if let goal = dataManager.goals.first(where: { $0.id == goalId }) {
                        HStack(spacing: 4) {
                            Text("#")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text(goal.title)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 任务时间信息
                if let time = task.scheduledStartTime ?? task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatTaskTime(time))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(task.estimatedDuration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 完成状态圆圈
            Button(action: { toggleTaskCompletion() }) {
                ZStack {
                    Circle()
                        .stroke(task.status == .completed ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.status == .completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onTapGesture {
            showingTaskDetail = true
        }
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
        }
    }
    
    private func getCategoryColor() -> Color {
        switch task.category {
        case .chinese:
            return .red
        case .math:
            return .blue
        case .english:
            return .green
        case .physics:
            return .purple
        case .chemistry:
            return .orange
        case .biology, .science:
            return .mint
        case .history:
            return .brown
        case .geography:
            return .cyan
        case .politics:
            return .pink
        case .other:
            return .indigo
        }
    }
    
    private func getPriorityColor() -> Color {
        switch task.priority {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        if updatedTask.status == .completed {
            updatedTask.completedDate = Date()
        } else {
            updatedTask.completedDate = nil
        }
        dataManager.updateTask(updatedTask)
    }
    
    private func formatTaskTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
}

// MARK: - 空任务视图
struct EmptyTaskView: View {
    let selectedDate: Date
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("今天还没有安排任务")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("点击右下角按钮添加任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingAddTask = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("添加第一个任务")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 40)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(DataManager())
}
