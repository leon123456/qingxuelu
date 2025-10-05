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
    @State private var showingTemplates = false
    @State private var showingAIGeneration = false
    @State private var editingMilestone: Milestone?
    @State private var editingKeyResult: KeyResult?
    @State private var aiGeneratedContent: AIGeneratedGoalContent?
    @StateObject private var aiGenerator = AIGoalGenerator.shared
    
    var body: some View {
        NavigationView {
            Form {
                // 模板选择部分
                Section {
                    Button("浏览模板") {
                        showingTemplates = true
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("快速开始")
                } footer: {
                    Text("使用预设模板快速创建学习目标，包含里程碑和关键结果")
                }
                
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
                    
                    DatePicker("目标完成时间", selection: $targetDate, displayedComponents: .date)
                    
                } header: {
                    Text("目标设置")
                } footer: {
                    if !title.isEmpty && !description.isEmpty {
                        Text("填写完基本信息后，可以使用 AI 智能生成详细的目标内容和执行计划")
                    }
                }
                
                // SMART目标的里程碑
                if goalType == .smart || goalType == .hybrid {
                    Section {
                        ForEach(milestones) { milestone in
                            Button(action: {
                                editingMilestone = milestone
                            }) {
                                MilestoneRowView(milestone: milestone)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteMilestones)
                        
                        // AI 智能生成按钮
                        Button(action: {
                            showingAIGeneration = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI 智能生成里程碑")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("根据目标信息自动生成里程碑")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(aiGenerator.isLoading || title.isEmpty || description.isEmpty)
                        
                        // 手动添加里程碑按钮
                        Button("手动添加里程碑") {
                            showingAddMilestone = true
                        }
                    } header: {
                        Text("里程碑")
                    } footer: {
                        if title.isEmpty || description.isEmpty {
                            Text("请先填写目标标题和描述，然后可以使用 AI 智能生成或手动添加里程碑")
                        } else {
                            Text("将大目标分解为小的里程碑，更容易跟踪进度。可以选择 AI 智能生成或手动添加")
                        }
                    }
                }
                
                // OKR目标的关键结果
                if goalType == .okr || goalType == .hybrid {
                    Section {
                        ForEach(keyResults) { keyResult in
                            Button(action: {
                                editingKeyResult = keyResult
                            }) {
                                KeyResultRowView(keyResult: keyResult)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteKeyResults)
                        
                        // AI 智能生成按钮
                        Button(action: {
                            showingAIGeneration = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI 智能生成关键结果")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("根据目标信息自动生成关键结果")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(aiGenerator.isLoading || title.isEmpty || description.isEmpty)
                        
                        // 手动添加关键结果按钮
                        Button("手动添加关键结果") {
                            showingAddKeyResult = true
                        }
                    } header: {
                        Text("关键结果")
                    } footer: {
                        if title.isEmpty || description.isEmpty {
                            Text("请先填写目标标题和描述，然后可以使用 AI 智能生成或手动添加关键结果")
                        } else {
                            Text("设定3-5个可量化的关键结果来衡量目标达成。可以选择 AI 智能生成或手动添加")
                        }
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
        .sheet(isPresented: $showingTemplates) {
            GoalTemplateView()
        }
        .sheet(item: $editingMilestone) { milestone in
            AddMilestoneView(milestone: milestone) { updatedMilestone in
                if let index = milestones.firstIndex(where: { $0.id == updatedMilestone.id }) {
                    milestones[index] = updatedMilestone
                }
                editingMilestone = nil
            }
        }
        .sheet(item: $editingKeyResult) { keyResult in
            AddKeyResultView(keyResult: keyResult) { updatedKeyResult in
                if let index = keyResults.firstIndex(where: { $0.id == updatedKeyResult.id }) {
                    keyResults[index] = updatedKeyResult
                }
                editingKeyResult = nil
            }
        }
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(
                title: title,
                description: description,
                category: category,
                goalType: goalType,
                targetDate: targetDate,
                priority: priority,
                onGenerated: { content in
                    applyAIGeneratedContent(content)
                }
            )
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
    
    // MARK: - AI 生成内容处理
    private func applyAIGeneratedContent(_ content: AIGeneratedGoalContent) {
        // 更新描述
        if !content.optimizedDescription.isEmpty {
            description = content.optimizedDescription
        }
        
        // 添加里程碑
        if !content.milestones.isEmpty {
            milestones.append(contentsOf: content.milestones)
        }
        
        // 添加关键结果
        if !content.keyResults.isEmpty {
            keyResults.append(contentsOf: content.keyResults)
        }
    }
}

// MARK: - 添加/编辑关键结果视图
struct AddKeyResultView: View {
    @Environment(\.dismiss) private var dismiss
    
    let keyResult: KeyResult?
    let onSave: (KeyResult) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue: Double = 100
    @State private var unit = "分"
    @State private var currentValue: Double = 0
    
    // 初始化器
    init(keyResult: KeyResult? = nil, onSave: @escaping (KeyResult) -> Void) {
        self.keyResult = keyResult
        self.onSave = onSave
        self._title = State(initialValue: keyResult?.title ?? "")
        self._description = State(initialValue: keyResult?.description ?? "")
        self._targetValue = State(initialValue: keyResult?.targetValue ?? 100)
        self._unit = State(initialValue: keyResult?.unit ?? "分")
        self._currentValue = State(initialValue: keyResult?.currentValue ?? 0)
    }
    
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
                        
                        if keyResult != nil {
                            HStack {
                                Text("当前值")
                                Spacer()
                                TextField("当前值", value: $currentValue, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                        }
                    }
                } header: {
                    Text("量化指标")
                } footer: {
                    Text("例如：目标值100，单位\"分\"，表示目标达到100分")
                }
            }
            .navigationTitle(keyResult == nil ? "添加关键结果" : "编辑关键结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let keyResultToSave: KeyResult
                        if let existingKeyResult = keyResult {
                            // 编辑模式：手动创建一个新的KeyResult实例
                            var newKeyResult = KeyResult(
                                id: existingKeyResult.id,
                                title: title,
                                description: description,
                                targetValue: targetValue,
                                unit: unit
                            )
                            // 手动更新字段
                            newKeyResult.currentValue = currentValue
                            newKeyResult.isCompleted = existingKeyResult.isCompleted
                            newKeyResult.createdAt = existingKeyResult.createdAt
                            keyResultToSave = newKeyResult
                        } else {
                            // 新建模式：创建新的关键结果
                            keyResultToSave = KeyResult(
                                title: title,
                                description: description,
                                targetValue: targetValue,
                                unit: unit
                            )
                        }
                        onSave(keyResultToSave)
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

// MARK: - 添加/编辑里程碑视图
struct AddMilestoneView: View {
    @Environment(\.dismiss) private var dismiss
    
    let milestone: Milestone?
    let onSave: (Milestone) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var targetDate = Date().addingTimeInterval(7 * 24 * 3600) // 7天后
    
    // 初始化器
    init(milestone: Milestone? = nil, onSave: @escaping (Milestone) -> Void) {
        self.milestone = milestone
        self.onSave = onSave
        self._title = State(initialValue: milestone?.title ?? "")
        self._description = State(initialValue: milestone?.description ?? "")
        self._targetDate = State(initialValue: milestone?.targetDate ?? Date().addingTimeInterval(7 * 24 * 3600))
    }
    
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
            .navigationTitle(milestone == nil ? "添加里程碑" : "编辑里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let milestoneToSave: Milestone
                        if let existingMilestone = milestone {
                            // 编辑模式：创建新Milestone实例并手动更新字段
                            milestoneToSave = Milestone(
                                id: existingMilestone.id,
                                title: title,
                                description: description,
                                targetDate: targetDate
                            )
                        } else {
                            // 新建模式：创建新的里程碑
                            milestoneToSave = Milestone(
                                title: title,
                                description: description,
                                targetDate: targetDate
                            )
                        }
                        onSave(milestoneToSave)
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
    @State private var startDate: Date
    @State private var durationDays: Int
    @State private var status: GoalStatus
    @State private var progress: Double
    @State private var milestones: [Milestone]
    @State private var keyResults: [KeyResult]
    @State private var goalType: GoalType
    @State private var showingAddMilestone = false
    @State private var showingAddKeyResult = false
    @State private var showingTemplates = false
    @State private var showingAIGeneration = false
    @State private var editingMilestone: Milestone?
    @State private var editingKeyResult: KeyResult?
    @State private var aiGeneratedContent: AIGeneratedGoalContent?
    @StateObject private var aiGenerator = AIGoalGenerator.shared
    
    init(goal: LearningGoal) {
        self.goal = goal
        self._title = State(initialValue: goal.title)
        self._description = State(initialValue: goal.description)
        self._category = State(initialValue: goal.category)
        self._priority = State(initialValue: goal.priority)
        self._targetDate = State(initialValue: goal.targetDate)
        
        // 添加开始时间和持续天数的字段
        self._startDate = State(initialValue: goal.startDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: goal.startDate, to: goal.targetDate)
        self._durationDays = State(initialValue: max((components.day ?? 0) + 1, 1))
        
        self._status = State(initialValue: goal.status)
        self._progress = State(initialValue: goal.progress)
        self._milestones = State(initialValue: goal.milestones)
        self._keyResults = State(initialValue: goal.keyResults)
        self._goalType = State(initialValue: goal.goalType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 模板选择部分
                Section {
                    Button("浏览模板") {
                        showingTemplates = true
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("快速开始")
                } footer: {
                    Text("使用预设模板快速创建学习目标，包含里程碑和关键结果")
                }
                
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
                    
                    DatePicker("目标开始时间", selection: $startDate, displayedComponents: .date)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("持续天数")
                            Spacer()
                            Text("\(durationDays)天")
                        }
                        
                        Slider(value: Binding(
                            get: { Double(durationDays) },
                            set: { 
                                durationDays = Int($0)
                                // 自动更新目标完成时间
                                targetDate = Calendar.current.date(byAdding: .day, value: durationDays - 1, to: startDate) ?? startDate
                            }
                        ), in: 1...365, step: 1)
                    }
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
                            Button(action: {
                                editingMilestone = milestone
                            }) {
                                MilestoneRowView(milestone: milestone)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteMilestones)
                        
                        // AI 智能生成按钮
                        Button(action: {
                            showingAIGeneration = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI 智能生成里程碑")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("根据目标信息自动生成里程碑")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(aiGenerator.isLoading || title.isEmpty || description.isEmpty)
                        
                        // 手动添加里程碑按钮
                        Button("手动添加里程碑") {
                            showingAddMilestone = true
                        }
                    } header: {
                        Text("里程碑")
                    } footer: {
                        if title.isEmpty || description.isEmpty {
                            Text("请先填写目标标题和描述，然后可以使用 AI 智能生成或手动添加里程碑")
                        } else {
                            Text("将大目标分解为小的里程碑，更容易跟踪进度。可以选择 AI 智能生成或手动添加")
                        }
                    }
                }
                
                // OKR目标的关键结果
                if goalType == .okr || goalType == .hybrid {
                    Section {
                        ForEach(keyResults) { keyResult in
                            Button(action: {
                                editingKeyResult = keyResult
                            }) {
                                KeyResultRowView(keyResult: keyResult)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteKeyResults)
                        
                        // AI 智能生成按钮
                        Button(action: {
                            showingAIGeneration = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI 智能生成关键结果")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("根据目标信息自动生成关键结果")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(aiGenerator.isLoading || title.isEmpty || description.isEmpty)
                        
                        // 手动添加关键结果按钮
                        Button("手动添加关键结果") {
                            showingAddKeyResult = true
                        }
                    } header: {
                        Text("关键结果")
                    } footer: {
                        if title.isEmpty || description.isEmpty {
                            Text("请先填写目标标题和描述，然后可以使用 AI 智能生成或手动添加关键结果")
                        } else {
                            Text("设定3-5个可量化的关键结果来衡量目标达成。可以选择 AI 智能生成或手动添加")
                        }
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
        .sheet(isPresented: $showingTemplates) {
            GoalTemplateView()
        }
        .sheet(isPresented: $showingAIGeneration) {
            AIGenerationView(
                title: title,
                description: description,
                category: category,
                goalType: goalType,
                targetDate: targetDate,
                priority: priority,
                onGenerated: { content in
                    applyAIGeneratedContent(content)
                }
            )
        }
        .sheet(item: $editingMilestone) { milestone in
            AddMilestoneView(milestone: milestone) { updatedMilestone in
                if let index = milestones.firstIndex(where: { $0.id == updatedMilestone.id }) {
                    milestones[index] = updatedMilestone
                }
                editingMilestone = nil
            }
        }
        .sheet(item: $editingKeyResult) { keyResult in
            AddKeyResultView(keyResult: keyResult) { updatedKeyResult in
                if let index = keyResults.firstIndex(where: { $0.id == updatedKeyResult.id }) {
                    keyResults[index] = updatedKeyResult
                }
                editingKeyResult = nil
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
        updatedGoal.startDate = startDate
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
    
    // MARK: - AI 生成内容处理
    private func applyAIGeneratedContent(_ content: AIGeneratedGoalContent) {
        // 更新描述
        if !content.optimizedDescription.isEmpty {
            description = content.optimizedDescription
        }
        
        // 添加里程碑
        if !content.milestones.isEmpty {
            milestones.append(contentsOf: content.milestones)
        }
        
        // 添加关键结果
        if !content.keyResults.isEmpty {
            keyResults.append(contentsOf: content.keyResults)
        }
    }
}

#Preview {
    AddGoalView()
        .environmentObject(DataManager())
}