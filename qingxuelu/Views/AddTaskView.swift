//
//  AddTaskView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

// MARK: - 自定义圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var category: SubjectCategory = .chinese
    @State private var priority: Priority = .medium
    @State private var estimatedDuration: Double = 60 // 60分钟
    @State private var selectedGoal: LearningGoal?
    
    // 任务开始时间（只选择时间，日期固定为今天）
    @State private var startTime: Date = Date()
    
    // 时间选择相关状态
    @State private var selectedTimeSlot: String = "06:00"
    @State private var selectedDuration: String = "1小时"
    
    // 预设时间选项
    private let timeSlots = ["06:00", "06:15", "06:30", "06:45", "07:00", "07:15", "07:30", "07:45", "08:00", "08:15", "08:30", "08:45", "09:00", "09:15", "09:30", "09:45", "10:00", "10:15", "10:30", "10:45", "11:00", "11:15", "11:30", "11:45", "12:00", "12:15", "12:30", "12:45", "13:00", "13:15", "13:30", "13:45", "14:00", "14:15", "14:30", "14:45", "15:00", "15:15", "15:30", "15:45", "16:00", "16:15", "16:30", "16:45", "17:00", "17:15", "17:30", "17:45", "18:00", "18:15", "18:30", "18:45", "19:00", "19:15", "19:30", "19:45", "20:00", "20:15", "20:30", "20:45", "21:00", "21:15", "21:30", "21:45", "22:00"]
    
    // 预设持续时间选项
    private let durationOptions = ["15分钟", "30分钟", "45分钟", "1小时", "1.5小时", "2小时", "2.5小时", "3小时"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部红色区域 - 任务名称和描述
                VStack(spacing: 16) {
                    // 任务名称输入
                    TextField("新任务", text: $title)
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .background(Color.clear)
                    
                    // 任务描述输入
                    TextField("任务描述（可选）", text: $description, axis: .vertical)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2...4)
                        .background(Color.clear)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                
                // 主要内容区域
                ScrollView {
                    VStack(spacing: 24) {
                        // 日期选择
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text("2025年9月21日 Sunday")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Button("今天") {
                                    // 设置为今天
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal, 20)
                        
                        // 时间选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("时间")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(timeSlots, id: \.self) { timeSlot in
                                        Button(action: {
                                            selectedTimeSlot = timeSlot
                                        }) {
                                            Text(timeSlot)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedTimeSlot == timeSlot ? .blue : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedTimeSlot == timeSlot ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedTimeSlot == timeSlot ? 2 : 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 持续时间选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("持续时间")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(durationOptions, id: \.self) { duration in
                                        Button(action: {
                                            selectedDuration = duration
                                            updateEstimatedDuration(from: duration)
                                        }) {
                                            Text(duration)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedDuration == duration ? .purple : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedDuration == duration ? Color.purple : Color.gray.opacity(0.3), lineWidth: selectedDuration == duration ? 2 : 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 优先级选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("优先级")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                ForEach(Priority.allCases, id: \.self) { priorityOption in
                                    Button(action: {
                                        priority = priorityOption
                                    }) {
                                        Text(priorityOption.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(priority == priorityOption ? .blue : .primary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(priority == priorityOption ? Color.blue : Color.gray.opacity(0.3), lineWidth: priority == priorityOption ? 2 : 1)
                                            )
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 关联目标选择
                        if let currentStudent = dataManager.currentStudent {
                            let allGoals = dataManager.getGoalsForStudent(currentStudent.id)
                            
                            if !allGoals.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("关联目标")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 8) {
                                        Button(action: {
                                            selectedGoal = nil
                                        }) {
                                            HStack {
                                                Text("不关联目标")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                if selectedGoal == nil {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        }
                                        
                                        ForEach(allGoals) { goal in
                                            Button(action: {
                                                selectedGoal = goal
                                            }) {
                                                HStack {
                                                    Text(goal.title)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    if selectedGoal?.id == goal.id {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // 底部间距
                        Spacer(minLength: 100)
                    }
                }
                
                // 底部继续按钮
                VStack {
                    Button(action: {
                        saveTask()
                    }) {
                        Text("继续")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                // 初始化智能时间默认值
                selectedTimeSlot = getCurrentRoundedTimeSlot()
            }
        }
    }
    
    // 根据选择的持续时间更新预估时长
    private func updateEstimatedDuration(from duration: String) {
        switch duration {
        case "15分钟":
            estimatedDuration = 15
        case "30分钟":
            estimatedDuration = 30
        case "45分钟":
            estimatedDuration = 45
        case "1小时":
            estimatedDuration = 60
        case "1.5小时":
            estimatedDuration = 90
        case "2小时":
            estimatedDuration = 120
        case "2.5小时":
            estimatedDuration = 150
        case "3小时":
            estimatedDuration = 180
        default:
            estimatedDuration = 60
        }
    }
    
    // MARK: - 计算当前时间并向上取整到最近的15分钟
    private func getCurrentRoundedTimeSlot() -> String {
        let calendar = Calendar.current
        let now = Date()
        let currentMinute = calendar.component(.minute, from: now)
        let currentHour = calendar.component(.hour, from: now)
        
        // 向上取整到最近的15分钟
        // 逻辑：0-14分钟 → 15分钟，15-29分钟 → 30分钟，30-44分钟 → 45分钟，45-59分钟 → 下一小时
        let roundedMinute: Int
        let finalHour: Int
        
        if currentMinute < 15 {
            roundedMinute = 15
            finalHour = currentHour
        } else if currentMinute < 30 {
            roundedMinute = 30
            finalHour = currentHour
        } else if currentMinute < 45 {
            roundedMinute = 45
            finalHour = currentHour
        } else {
            roundedMinute = 0
            finalHour = (currentHour + 1) % 24
        }
        
        return String(format: "%02d:%02d", finalHour, roundedMinute)
    }
    
    private func saveTask() {
        // 计算任务的开始和结束时间
        let calendar = Calendar.current
        let today = Date()
        
        // 解析选择的时间段
        let timeComponents = selectedTimeSlot.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return
        }
        
        // 将选择的时间应用到今天的日期
        let taskStartTime = calendar.date(bySettingHour: hour,
                                        minute: minute,
                                        second: 0,
                                        of: today) ?? today
        
        let taskEndTime = calendar.date(byAdding: .minute, value: Int(estimatedDuration), to: taskStartTime) ?? taskStartTime
        
        let task = LearningTask(
            title: title,
            description: description,
            category: category,
            priority: priority,
            estimatedDuration: estimatedDuration * 60, // 转换为秒
            goalId: selectedGoal?.id,
            scheduledStartTime: taskStartTime,
            scheduledEndTime: taskEndTime
        )
        
        dataManager.addTask(task)
        dismiss()
    }
}

// MARK: - 编辑任务视图
struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let task: LearningTask
    @State private var title: String
    @State private var description: String
    @State private var category: SubjectCategory
    @State private var priority: Priority
    @State private var estimatedDuration: Double
    @State private var actualDuration: Double?
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var status: TaskStatus
    @State private var selectedGoal: LearningGoal?
    @State private var hasGoal: Bool
    
    // 新增：时间安排状态
    @State private var scheduledStartTime: Date?
    @State private var scheduledEndTime: Date?
    @State private var hasScheduledTime: Bool
    
    init(task: LearningTask) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._category = State(initialValue: task.category)
        self._priority = State(initialValue: task.priority)
        self._estimatedDuration = State(initialValue: task.estimatedDuration / 60) // 转换为分钟
        self._actualDuration = State(initialValue: task.actualDuration != nil ? task.actualDuration! / 60 : nil)
        self._dueDate = State(initialValue: task.dueDate)
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._status = State(initialValue: task.status)
        self._hasGoal = State(initialValue: task.goalId != nil)
        self._scheduledStartTime = State(initialValue: task.scheduledStartTime)
        self._scheduledEndTime = State(initialValue: task.scheduledEndTime)
        self._hasScheduledTime = State(initialValue: task.isTimeBlocked)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("任务标题", text: $title)
                    TextField("任务描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    Picker("科目", selection: $category) {
                        ForEach(SubjectCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .tag(priority)
                        }
                    }
                    
                    Picker("状态", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.rawValue)
                                .tag(status)
                        }
                    }
                } header: {
                    Text("任务设置")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("预估学习时间")
                            Spacer()
                            Text("\(Int(estimatedDuration))分钟")
                        }
                        
                        Slider(value: $estimatedDuration, in: 15...300, step: 15)
                    }
                    
                    if let actual = actualDuration {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("实际学习时间")
                                Spacer()
                                Text("\(Int(actual))分钟")
                            }
                            
                            Slider(value: Binding(
                                get: { actual },
                                set: { actualDuration = $0 }
                            ), in: 0...600, step: 15)
                        }
                    }
                } header: {
                    Text("时间设置")
                }
                
                Section {
                    Toggle("设置截止时间", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("截止时间", selection: Binding(
                            get: { dueDate ?? Date().addingTimeInterval(24 * 3600) },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("截止时间")
                }
                
                // 新增：时间安排部分
                Section {
                    Toggle("安排具体时间", isOn: $hasScheduledTime)
                    
                    if hasScheduledTime {
                        DatePicker("开始时间", selection: Binding(
                            get: { scheduledStartTime ?? Date() },
                            set: { 
                                scheduledStartTime = $0
                                // 自动设置结束时间
                                scheduledEndTime = Calendar.current.date(byAdding: .minute, value: Int(estimatedDuration), to: $0)
                            }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker("结束时间", selection: Binding(
                            get: { scheduledEndTime ?? Date().addingTimeInterval(estimatedDuration * 60) },
                            set: { scheduledEndTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("时间安排")
                } footer: {
                    if hasScheduledTime {
                        Text("安排具体时间可以帮助你更好地管理学习计划，类似Structured的时间线管理")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let currentStudent = dataManager.currentStudent {
                    let goals = dataManager.getGoalsForStudent(currentStudent.id)
                        .filter { $0.status == .inProgress || $0.status == .notStarted }
                    
                    if !goals.isEmpty {
                        Section {
                            Toggle("关联学习目标", isOn: $hasGoal)
                            
                            if hasGoal {
                                Picker("选择目标", selection: $selectedGoal) {
                                    Text("请选择目标").tag(nil as LearningGoal?)
                                    ForEach(goals) { goal in
                                        Text(goal.title)
                                            .tag(goal as LearningGoal?)
                                    }
                                }
                            }
                        } header: {
                            Text("关联目标")
                        } footer: {
                            Text("将任务关联到学习目标，便于跟踪进度")
                        }
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.category = category
        updatedTask.priority = priority
        updatedTask.estimatedDuration = estimatedDuration * 60 // 转换为秒
        updatedTask.status = status
        updatedTask.goalId = hasGoal ? selectedGoal?.id : nil
        updatedTask.scheduledStartTime = hasScheduledTime ? scheduledStartTime : nil
        updatedTask.scheduledEndTime = hasScheduledTime ? scheduledEndTime : nil
        updatedTask.isTimeBlocked = hasScheduledTime
        
        if hasDueDate, let due = dueDate {
            updatedTask.dueDate = due
        } else {
            updatedTask.dueDate = nil
        }
        
        if let actual = actualDuration {
            updatedTask.actualDuration = actual * 60 // 转换为秒
        }
        
        dataManager.updateTask(updatedTask)
        dismiss()
    }
}

#Preview {
    AddTaskView()
        .environmentObject(DataManager())
}