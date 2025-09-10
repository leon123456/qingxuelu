//
//  AddTaskView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var category: SubjectCategory = .chinese
    @State private var priority: Priority = .medium
    @State private var estimatedDuration: Double = 60 // 60分钟
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var selectedGoal: LearningGoal?
    @State private var hasGoal = false
    
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
                } header: {
                    Text("时间预估")
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
            .navigationTitle("添加学习任务")
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
        var task = LearningTask(
            title: title,
            description: description,
            category: category,
            priority: priority,
            estimatedDuration: estimatedDuration * 60, // 转换为秒
            goalId: hasGoal ? selectedGoal?.id : nil
        )
        
        if hasDueDate, let due = dueDate {
            task.dueDate = due
        }
        
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
                    Text("时间管理")
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
                        }
                    }
                }
            }
            .navigationTitle("编辑学习任务")
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
        .onAppear {
            // 设置关联的目标
            if let goalId = task.goalId {
                selectedGoal = dataManager.goals.first { $0.id == goalId }
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
        updatedTask.actualDuration = actualDuration != nil ? actualDuration! * 60 : nil
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.status = status
        updatedTask.goalId = hasGoal ? selectedGoal?.id : nil
        updatedTask.updatedAt = Date()
        
        dataManager.updateTask(updatedTask)
        dismiss()
    }
}

// MARK: - 学习计时器视图
struct StudyTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let task: LearningTask
    @State private var isRunning = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var notes = ""
    @State private var rating: Int = 3
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 计时器显示
                VStack(spacing: 20) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("学习时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 控制按钮
                HStack(spacing: 30) {
                    Button(action: stopTimer) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    .disabled(!isRunning)
                    
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                
                // 学习记录
                VStack(alignment: .leading, spacing: 16) {
                    Text("学习记录")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学习质量评分")
                            .font(.subheadline)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { rating = star }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title2)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("学习笔记")
                            .font(.subheadline)
                        
                        TextField("记录学习心得、难点等", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("学习计时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveStudyRecord()
                    }
                    .disabled(elapsedTime == 0)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            resumeTimer()
        }
    }
    
    private func startTimer() {
        startTime = Date()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func resumeTimer() {
        startTime = Date().addingTimeInterval(-elapsedTime)
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func saveStudyRecord() {
        guard let start = startTime else { return }
        
        let endTime = Date()
        let record = LearningRecord(
            taskId: task.id,
            startTime: start,
            endTime: endTime,
            notes: notes.isEmpty ? nil : notes,
            rating: rating
        )
        
        dataManager.addRecord(record)
        
        // 更新任务的实际学习时间
        var updatedTask = task
        let currentActualDuration = updatedTask.actualDuration ?? 0
        updatedTask.actualDuration = currentActualDuration + elapsedTime
        updatedTask.updatedAt = Date()
        dataManager.updateTask(updatedTask)
        
        dismiss()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(DataManager())
}
