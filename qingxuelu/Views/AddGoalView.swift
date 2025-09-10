//
//  AddGoalView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var category: SubjectCategory = .chinese
    @State private var priority: Priority = .medium
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 3600) // 30天后
    @State private var milestones: [Milestone] = []
    @State private var keyResults: [KeyResult] = []
    @State private var goalType: GoalType = .smart
    @State private var showingAddMilestone = false
    @State private var showingAddKeyResult = false
    @State private var showingTemplateSelector = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("目标标题", text: $title)
                    TextField("目标描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Button(action: {
                        showingTemplateSelector = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("从模板创建")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("基本信息")
                } footer: {
                    Text("选择预设模板可以快速创建常见的学习目标")
                }
                
                Section {
                    Picker("目标类型", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                VStack(alignment: .leading) {
                                    Text(type.rawValue)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(type)
                        }
                    }
                    
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
                    
                    DatePicker("目标完成时间", selection: $targetDate, displayedComponents: .date)
                } header: {
                    Text("目标设置")
                }
                
                // SMART目标的里程碑
                if goalType == .smart || goalType == .hybrid {
                    Section {
                        ForEach(milestones) { milestone in
                            MilestoneRowView(milestone: milestone)
                        }
                        .onDelete(perform: deleteMilestones)
                        
                        Button("添加里程碑") {
                            showingAddMilestone = true
                        }
                    } header: {
                        Text("里程碑")
                    } footer: {
                        Text("将大目标分解为小的里程碑，更容易跟踪进度")
                    }
                }
                
                // OKR目标的关键结果
                if goalType == .okr || goalType == .hybrid {
                    Section {
                        ForEach(keyResults) { keyResult in
                            KeyResultRowView(keyResult: keyResult)
                        }
                        .onDelete(perform: deleteKeyResults)
                        
                        Button("添加关键结果") {
                            showingAddKeyResult = true
                        }
                    } header: {
                        Text("关键结果")
                    } footer: {
                        Text("设定3-5个可量化的关键结果来衡量目标达成")
                    }
                }
            }
            .navigationTitle("添加学习目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingAddMilestone) {
            AddMilestoneView { milestone in
                milestones.append(milestone)
            }
        }
        .sheet(isPresented: $showingAddKeyResult) {
            AddKeyResultView { keyResult in
                keyResults.append(keyResult)
            }
        }
        .sheet(isPresented: $showingTemplateSelector) {
            GoalTemplateView { template in
                applyTemplate(template)
            }
        }
    }
    
    private func applyTemplate(_ template: GoalTemplate) {
        let goal = template.toLearningGoal()
        
        // 应用模板数据到当前表单
        title = goal.title
        description = goal.description
        category = goal.category
        priority = goal.priority
        targetDate = goal.targetDate
        goalType = goal.goalType
        milestones = goal.milestones
        keyResults = goal.keyResults
        
        // 自动创建建议的任务
        for taskTemplate in template.suggestedTasks {
            let task = taskTemplate.toLearningTask(goalId: goal.id)
            dataManager.addTask(task)
        }
    }
    
    private func saveGoal() {
        var goal = LearningGoal(
            title: title,
            description: description,
            category: category,
            priority: priority,
            targetDate: targetDate,
            goalType: goalType
        )
        goal.milestones = milestones
        goal.keyResults = keyResults
        
        dataManager.addGoal(goal)
        dismiss()
    }
    
    private func deleteMilestones(offsets: IndexSet) {
        milestones.remove(atOffsets: offsets)
    }
    
    private func deleteKeyResults(offsets: IndexSet) {
        keyResults.remove(atOffsets: offsets)
    }
}


// MARK: - 添加关键结果视图
struct AddKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (KeyResult) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue: Double = 100
    @State private var unit = "分"
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("关键结果标题", text: $title)
                    TextField("关键结果描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("目标值")
                            Spacer()
                            TextField("目标值", value: $targetValue, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("单位")
                            Spacer()
                            TextField("单位", text: $unit)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                    }
                } header: {
                    Text("量化指标")
                } footer: {
                    Text("例如：目标值100，单位\"分\"，表示目标达到100分")
                }
            }
            .navigationTitle("添加关键结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let keyResult = KeyResult(
                            title: title,
                            description: description,
                            targetValue: targetValue,
                            unit: unit
                        )
                        onSave(keyResult)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 关键结果行视图
struct KeyResultRowView: View {
    let keyResult: KeyResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(keyResult.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(keyResult.currentValue))/\(Int(keyResult.targetValue)) \(keyResult.unit)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if !keyResult.description.isEmpty {
                Text(keyResult.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: keyResult.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加里程碑视图
struct AddMilestoneView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Milestone) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetDate = Date().addingTimeInterval(7 * 24 * 3600) // 7天后
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("里程碑标题", text: $title)
                    TextField("里程碑描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("目标完成时间", selection: $targetDate, displayedComponents: .date)
                } header: {
                    Text("里程碑信息")
                }
            }
            .navigationTitle("添加里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let milestone = Milestone(
                            title: title,
                            description: description,
                            targetDate: targetDate
                        )
                        onSave(milestone)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 编辑目标视图
struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let goal: LearningGoal
    @State private var title: String
    @State private var description: String
    @State private var category: SubjectCategory
    @State private var priority: Priority
    @State private var targetDate: Date
    @State private var status: GoalStatus
    @State private var progress: Double
    @State private var milestones: [Milestone]
    @State private var keyResults: [KeyResult]
    @State private var goalType: GoalType
    @State private var showingAddMilestone = false
    @State private var showingAddKeyResult = false
    
    init(goal: LearningGoal) {
        self.goal = goal
        self._title = State(initialValue: goal.title)
        self._description = State(initialValue: goal.description)
        self._category = State(initialValue: goal.category)
        self._priority = State(initialValue: goal.priority)
        self._targetDate = State(initialValue: goal.targetDate)
        self._status = State(initialValue: goal.status)
        self._progress = State(initialValue: goal.progress)
        self._milestones = State(initialValue: goal.milestones)
        self._keyResults = State(initialValue: goal.keyResults)
        self._goalType = State(initialValue: goal.goalType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("目标标题", text: $title)
                    TextField("目标描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    Picker("目标类型", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                VStack(alignment: .leading) {
                                    Text(type.rawValue)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(type)
                        }
                    }
                    
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
                        ForEach(GoalStatus.allCases, id: \.self) { status in
                            Text(status.rawValue)
                                .tag(status)
                        }
                    }
                    
                    DatePicker("目标完成时间", selection: $targetDate, displayedComponents: .date)
                } header: {
                    Text("目标设置")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("进度")
                            Spacer()
                            Text("\(Int(progress * 100))%")
                        }
                        
                        Slider(value: $progress, in: 0...1, step: 0.01)
                    }
                } header: {
                    Text("进度管理")
                }
                
                // SMART目标的里程碑
                if goalType == .smart || goalType == .hybrid {
                    Section {
                        ForEach(milestones) { milestone in
                            MilestoneRowView(milestone: milestone)
                        }
                        .onDelete(perform: deleteMilestones)
                        
                        Button("添加里程碑") {
                            showingAddMilestone = true
                        }
                    } header: {
                        Text("里程碑")
                    }
                }
                
                // OKR目标的关键结果
                if goalType == .okr || goalType == .hybrid {
                    Section {
                        ForEach(keyResults) { keyResult in
                            KeyResultRowView(keyResult: keyResult)
                        }
                        .onDelete(perform: deleteKeyResults)
                        
                        Button("添加关键结果") {
                            showingAddKeyResult = true
                        }
                    } header: {
                        Text("关键结果")
                    }
                }
            }
            .navigationTitle("编辑学习目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingAddMilestone) {
            AddMilestoneView { milestone in
                milestones.append(milestone)
            }
        }
        .sheet(isPresented: $showingAddKeyResult) {
            AddKeyResultView { keyResult in
                keyResults.append(keyResult)
            }
        }
    }
    
    private func saveGoal() {
        var updatedGoal = goal
        updatedGoal.title = title
        updatedGoal.description = description
        updatedGoal.category = category
        updatedGoal.priority = priority
        updatedGoal.targetDate = targetDate
        updatedGoal.status = status
        updatedGoal.progress = progress
        updatedGoal.milestones = milestones
        updatedGoal.keyResults = keyResults
        updatedGoal.goalType = goalType
        updatedGoal.updatedAt = Date()
        
        dataManager.updateGoal(updatedGoal)
        dismiss()
    }
    
    private func deleteMilestones(offsets: IndexSet) {
        milestones.remove(atOffsets: offsets)
    }
    
    private func deleteKeyResults(offsets: IndexSet) {
        keyResults.remove(atOffsets: offsets)
    }
}

#Preview {
    AddGoalView()
        .environmentObject(DataManager())
}