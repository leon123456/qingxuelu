//
//  TimelineTaskView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-18.
//

import SwiftUI

// MARK: - 时间轴任务视图（借鉴Structured设计）
struct TimelineTaskView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 时间轴头部
            TimelineHeaderView(selectedDate: $selectedDate)
            
            // 时间轴内容 - 可滑动的整页切换
            TabView(selection: $selectedDate) {
                ForEach(generateDateRange(), id: \.self) { date in
                    TimelineContentView(date: date)
                        .tag(date)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: selectedDate) { _, newDate in
                // 添加触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            .id(selectedDate) // 强制重新渲染，确保日期范围更新
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
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
                                .foregroundColor(.white)
                            
                            Text("添加任务")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        )
    }
    
    // MARK: - 生成日期范围
    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        // 生成前后各30天的日期范围，以当前选中日期为中心
        for i in -30...30 {
            if let date = calendar.date(byAdding: .day, value: i, to: selectedDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - 检查选中日期是否有任务
    private var hasTasksForSelectedDate: Bool {
        let hasTasks = dataManager.tasks.contains { task in
            // 检查任务是否在指定日期
            if task.isTimeBlocked, let scheduledTime = task.scheduledStartTime {
                let isSameDay = Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
                if isSameDay {
                    print("🔍 找到时间安排任务: \(task.title) - \(scheduledTime.formatted())")
                }
                return isSameDay
            } else if let dueDate = task.dueDate {
                let isSameDay = Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
                if isSameDay {
                    print("🔍 找到截止日期任务: \(task.title) - \(dueDate.formatted())")
                }
                return isSameDay
            } else if let scheduledTime = task.scheduledStartTime {
                // 新增：显示没有具体时间安排的任务（显示在创建时间）
                let isSameDay = Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
                if isSameDay {
                    print("🔍 找到今日创建任务: \(task.title) - \(scheduledTime.formatted())")
                }
                return isSameDay
            }
            return false
        }
        
        print("📊 选中日期 \(selectedDate.formatted(date: .abbreviated, time: .omitted)) 是否有任务: \(hasTasks)")
        print("📊 DataManager中总任务数: \(dataManager.tasks.count)")
        
        return hasTasks
    }
    
    // MARK: - 时间槽生成
    private var timeSlots: [TimeSlot] {
        var slots: [TimeSlot] = []
        
        let calendar = Calendar.current
        
        // 扩展时间范围：00:00-23:00，包含所有可能的时间
        let startHour = 0
        let endHour = 23
        
        for hour in startHour...endHour {
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            let endTime = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            
            let tasks = getTasksForTimeSlot(startTime: startTime, endTime: endTime)
            
            slots.append(TimeSlot(
                hour: hour,
                startTime: startTime,
                endTime: endTime,
                tasks: tasks
            ))
        }
        
        return slots
    }
    
    // MARK: - 只包含有任务的时间槽
    private var timeSlotsWithTasks: [TimeSlot] {
        return timeSlots.filter { !$0.tasks.isEmpty }
    }
    
    // MARK: - 获取时间槽内的任务
    private func getTasksForTimeSlot(startTime: Date, endTime: Date) -> [LearningTask] {
        let filteredTasks = dataManager.tasks.filter { task in
            // 检查任务是否在指定日期
            let taskTime: Date
            if task.isTimeBlocked, let scheduledTime = task.scheduledStartTime {
                // 有时间安排的任务
                taskTime = scheduledTime
            } else if let dueDate = task.dueDate {
                // 有截止日期的任务
                taskTime = dueDate
            } else if let scheduledTime = task.scheduledStartTime {
                // 没有具体时间安排的任务，使用创建时间
                taskTime = scheduledTime
            } else {
                // 没有时间信息的任务，使用创建时间
                taskTime = task.createdAt
            }
            
            let isSameDay = Calendar.current.isDate(taskTime, inSameDayAs: selectedDate)
            if !isSameDay { return false }
            
            // 检查任务时间是否在时间槽内
            let taskHour = Calendar.current.component(.hour, from: taskTime)
            let startHour = Calendar.current.component(.hour, from: startTime)
            let endHour = Calendar.current.component(.hour, from: endTime)
            
            let isInTimeSlot = taskHour >= startHour && taskHour < endHour
            
            
            return isInTimeSlot
        }
        
        
        return filteredTasks
    }
    
    
    // MARK: - 日期导航方法（参考iOS日历应用）
    private func navigateToPreviousDay() {
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 平滑动画效果
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func navigateToNextDay() {
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 平滑动画效果
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// MARK: - 时间槽数据模型
struct TimeSlot: Identifiable {
    let id = UUID()
    let hour: Int
    let startTime: Date
    let endTime: Date
    let tasks: [LearningTask]
}

// MARK: - 时间槽行视图
struct TimeSlotRow: View {
    let timeSlot: TimeSlot
    let selectedDate: Date
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTask = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧时间轴
            VStack(spacing: 0) {
                // 时间标记
                Text(formatTime(timeSlot.startTime))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                // 时间轴虚线
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 80)
                    .padding(.top, 4)
            }
            
            // 任务内容区域
            VStack(alignment: .leading, spacing: 12) {
                if timeSlot.tasks.isEmpty {
                    // 空时间槽 - 不显示任何按钮，保持空白
                    Spacer()
                        .frame(height: 20)
                } else {
                    // 有任务的时间槽
                    ForEach(timeSlot.tasks) { task in
                        TaskTimelineCard(task: task)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 空时间槽视图
struct EmptyTimeSlotView: View {
    let hour: Int
    @State private var showingAddTask = false
    
    var body: some View {
        Button(action: { showingAddTask = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue.opacity(0.6))
                    .font(.title3)
                
                Text("添加任务")
                    .font(.subheadline)
                    .foregroundColor(.blue.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

// MARK: - 任务时间线卡片
struct TaskTimelineCard: View {
    let task: LearningTask
    @EnvironmentObject var dataManager: DataManager
    @State private var showingTaskDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 任务图标 - 更精致的圆形背景
            ZStack {
                Circle()
                    .fill(getCategoryColor().opacity(0.2))
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
                
                // 目标标注
                if let goalId = task.goalId {
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
                
                // 任务时间和时长
                let taskTime = task.isTimeBlocked ? task.scheduledStartTime : task.dueDate
                if let time = taskTime {
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
            
            // 完成状态圆圈 - 更精致的设计
            Button(action: { toggleTaskCompletion() }) {
                ZStack {
                    Circle()
                        .stroke(task.status == .completed ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if task.status == .completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
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
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
        case .biology:
            return .mint
        case .history:
            return .brown
        case .geography:
            return .cyan
        case .politics:
            return .pink
        case .other:
            return .gray
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
    
    // MARK: - 格式化任务时间
    private func formatTaskTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    // MARK: - 格式化任务时长
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

#Preview {
    TimelineTaskView()
        .environmentObject(DataManager())
}

// MARK: - 空时间线视图
struct EmptyTimelineView: View {
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 08:00 时间节点 - 完整的一行
            HStack(alignment: .center, spacing: 16) {
                // 左侧时间标记
                Text("08:00")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                // 时间轴虚线
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // 右侧内容
                HStack(spacing: 12) {
                    // 粉色闹钟图标
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "alarm")
                            .foregroundColor(.pink)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("08:00")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("早晨活力")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            
            // 中间区域 - 空状态提示文案
            HStack(alignment: .top, spacing: 16) {
                // 左侧空白区域
                Spacer()
                    .frame(width: 50)
                
                // 时间轴虚线
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 80)
                
                // 右侧内容 - 空状态提示
                VStack(spacing: 8) {
                    Text("今天还没有安排任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 20)
            
            // 22:00 时间节点 - 完整的一行
            HStack(alignment: .center, spacing: 16) {
                // 左侧时间标记
                Text("22:00")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                // 时间轴虚线
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // 右侧内容
                HStack(spacing: 12) {
                    // 蓝色月亮图标
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "moon.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("22:00")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("放松心情")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

// MARK: - 时间线内容视图
struct TimelineContentView: View {
    let date: Date
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 检查是否有任务
                if hasTasksForDate {
                    // 只显示有任务的时间槽
                    ForEach(timeSlotsWithTasks, id: \.hour) { timeSlot in
                        TimeSlotRow(timeSlot: timeSlot, selectedDate: date)
                    }
                    
                } else {
                    // 空状态：显示08:00和22:00节点 + 中间添加任务按钮
                    EmptyTimelineView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20) // 增加顶部距离
        }
    }
    
    // MARK: - 检查指定日期是否有任务
    private var hasTasksForDate: Bool {
        let hasTasks = dataManager.tasks.contains { task in
            // 检查任务是否在指定日期
            if task.isTimeBlocked, let scheduledTime = task.scheduledStartTime {
                let isSameDay = Calendar.current.isDate(scheduledTime, inSameDayAs: date)
                return isSameDay
            } else if let dueDate = task.dueDate {
                let isSameDay = Calendar.current.isDate(dueDate, inSameDayAs: date)
                return isSameDay
            } else if let scheduledTime = task.scheduledStartTime {
                // 没有具体时间安排的任务，使用创建时间
                let isSameDay = Calendar.current.isDate(scheduledTime, inSameDayAs: date)
                return isSameDay
            } else {
                // 没有时间信息的任务，使用创建时间
                let isSameDay = Calendar.current.isDate(task.createdAt, inSameDayAs: date)
                return isSameDay
            }
        }
        
        return hasTasks
    }
    
    // MARK: - 时间槽生成
    private var timeSlots: [TimeSlot] {
        var slots: [TimeSlot] = []
        
        let calendar = Calendar.current
        
        // 扩展时间范围：00:00-23:00，包含所有可能的时间
        let startHour = 0
        let endHour = 23
        
        for hour in startHour...endHour {
            let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: date) ?? date
            
            let tasks = getTasksForTimeSlot(startTime: startTime, endTime: endTime)
            
            slots.append(TimeSlot(
                hour: hour,
                startTime: startTime,
                endTime: endTime,
                tasks: tasks
            ))
        }
        
        return slots
    }
    
    // MARK: - 只包含有任务的时间槽
    private var timeSlotsWithTasks: [TimeSlot] {
        return timeSlots.filter { !$0.tasks.isEmpty }
    }
    
    // MARK: - 获取时间槽内的任务
    private func getTasksForTimeSlot(startTime: Date, endTime: Date) -> [LearningTask] {
        let filteredTasks = dataManager.tasks.filter { task in
            // 检查任务是否在指定日期
            let taskTime: Date
            if task.isTimeBlocked, let scheduledTime = task.scheduledStartTime {
                // 有时间安排的任务
                taskTime = scheduledTime
            } else if let dueDate = task.dueDate {
                // 有截止日期的任务
                taskTime = dueDate
            } else if let scheduledTime = task.scheduledStartTime {
                // 没有具体时间安排的任务，使用创建时间
                taskTime = scheduledTime
            } else {
                // 没有时间信息的任务，使用创建时间
                taskTime = task.createdAt
            }
            
            let isSameDay = Calendar.current.isDate(taskTime, inSameDayAs: date)
            if !isSameDay { return false }
            
            // 检查任务时间是否在时间槽内
            let taskHour = Calendar.current.component(.hour, from: taskTime)
            let startHour = Calendar.current.component(.hour, from: startTime)
            let endHour = Calendar.current.component(.hour, from: endTime)
            
            let isInTimeSlot = taskHour >= startHour && taskHour < endHour
            
            return isInTimeSlot
        }
        
        return filteredTasks
    }
}
