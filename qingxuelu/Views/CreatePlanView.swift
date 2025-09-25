//
//  CreatePlanView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-11.
//

import SwiftUI

struct CreatePlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let goal: LearningGoal
    @State private var planMode: PlanMode = .ai
    @State private var showingManualPlan = false
    @State private var showingAIPlan = false
    @State private var isGenerating = false
    
    enum PlanMode: String, CaseIterable {
        case ai = "AI生成"
        case manual = "手动填写"
        
        var icon: String {
            switch self {
            case .ai: return "brain.head.profile"
            case .manual: return "pencil"
            }
        }
        
        var description: String {
            switch self {
            case .ai: return "AI根据目标自动生成学习计划"
            case .manual: return "手动设置学习计划和里程碑"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 目标信息预览
                GoalPreviewSection(goal: goal)
                
                // 选择计划方式 - 左右排列
                PlanModeSelectionSection(planMode: $planMode)
                
                Spacer()
                
                // 开始制定计划按钮
                VStack(spacing: 16) {
                    Button(action: startCreatingPlan) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: planMode.icon)
                            }
                            
                            Text(isGenerating ? "正在生成..." : "开始制定计划")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("制定学习计划")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingManualPlan) {
            ManualPlanView(goal: goal)
        }
        .sheet(isPresented: $showingAIPlan) {
            AIPlanView(goal: goal, onPlanApplied: {
                showingAIPlan = false
                dismiss() // 关闭整个CreatePlanView
            })
        }
    }
    
    private func startCreatingPlan() {
        if planMode == .ai {
            isGenerating = true
            // 模拟AI生成过程
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isGenerating = false
                showingAIPlan = true
            }
        } else {
            showingManualPlan = true
        }
    }
}

// MARK: - 目标预览区域
struct GoalPreviewSection: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(goal.goalType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text(goal.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(goal.priority.color).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // 关键结果预览
            if !goal.keyResults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("关键结果")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(goal.keyResults.prefix(3)) { keyResult in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(Color(.systemGreen))
                                .frame(width: 16)
                            
                            Text(keyResult.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(keyResult.targetValue)) \(keyResult.unit)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if goal.keyResults.count > 3 {
                        Text("还有 \(goal.keyResults.count - 3) 个关键结果...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - 计划方式选择区域 - 左右排列
struct PlanModeSelectionSection: View {
    @Binding var planMode: CreatePlanView.PlanMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择制定方式")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            // 左右排列的卡片
            HStack(spacing: 12) {
                // AI生成卡片
                PlanModeCardWithDescription(
                    mode: .ai,
                    isSelected: planMode == .ai,
                    onTap: { planMode = .ai }
                )
                
                // 手动填写卡片
                PlanModeCardWithDescription(
                    mode: .manual,
                    isSelected: planMode == .manual,
                    onTap: { planMode = .manual }
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 带说明的计划方式卡片
struct PlanModeCardWithDescription: View {
    let mode: CreatePlanView.PlanMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 顶部：图标和标题
                HStack {
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.blue.opacity(0.1))
                        )
                    
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
                
                // 中间：描述
                Text(mode.description)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 底部：功能特点
                VStack(alignment: .leading, spacing: 6) {
                    if mode == .ai {
                        PlanFeatureRow(icon: "brain.head.profile", text: "AI分析目标的关键结果和里程碑", isSelected: isSelected)
                        PlanFeatureRow(icon: "calendar", text: "自动计算学习时长和进度安排", isSelected: isSelected)
                        PlanFeatureRow(icon: "target", text: "智能分配每周的学习任务", isSelected: isSelected)
                        PlanFeatureRow(icon: "clock", text: "生成每日学习计划", isSelected: isSelected)
                        PlanFeatureRow(icon: "checkmark.circle", text: "一键应用，快速开始学习", isSelected: isSelected)
                    } else {
                        PlanFeatureRow(icon: "pencil", text: "完全自定义学习计划", isSelected: isSelected)
                        PlanFeatureRow(icon: "calendar", text: "手动设置周数和里程碑", isSelected: isSelected)
                        PlanFeatureRow(icon: "target", text: "自定义每周的关键结果", isSelected: isSelected)
                        PlanFeatureRow(icon: "clock", text: "灵活安排学习时间", isSelected: isSelected)
                        PlanFeatureRow(icon: "gear", text: "适合有经验的用户", isSelected: isSelected)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 计划方式卡片（保留原有组件以防其他地方使用）
struct PlanModeCard: View {
    let mode: CreatePlanView.PlanMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - 手动计划页面
struct ManualPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let goal: LearningGoal
    @State private var totalWeeks = 16
    @State private var startDate = Date()
    @State private var weeklyTasks: [String] = []
    @State private var currentWeekTask = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper("学习周数: \(totalWeeks) 周", value: $totalWeeks, in: 4...52)
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                } header: {
                    Text("计划设置")
                }
                
                Section {
                    ForEach(0..<totalWeeks, id: \.self) { week in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("第 \(week + 1) 周")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("本周学习任务...", text: Binding(
                                get: { weeklyTasks.indices.contains(week) ? weeklyTasks[week] : "" },
                                set: { 
                                    if weeklyTasks.indices.contains(week) {
                                        weeklyTasks[week] = $0
                                    } else {
                                        weeklyTasks.append($0)
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("周计划")
                } footer: {
                    Text("为每周设置具体的学习任务和目标")
                }
            }
            .navigationTitle("手动制定计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveManualPlan()
                    }
                }
            }
        }
    }
    
    private func saveManualPlan() {
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: totalWeeks, to: startDate) ?? startDate
        
        var weeklyPlans: [WeeklyPlan] = []
        for week in 0..<totalWeeks {
            let weekStartDate = Calendar.current.date(byAdding: .weekOfYear, value: week, to: startDate) ?? startDate
            let weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
            
            let weeklyPlan = WeeklyPlan(
                weekNumber: week + 1,
                startDate: weekStartDate,
                endDate: weekEndDate,
                milestones: weeklyTasks.indices.contains(week) ? [weeklyTasks[week]] : [],
                taskCount: 5, // 默认每周5个任务
                estimatedHours: 10 // 默认每周10小时
            )
            weeklyPlans.append(weeklyPlan)
        }
        
        let plan = LearningPlan(
            id: goal.id,
            title: "\(goal.title) - 学习计划",
            description: "为 \(goal.title) 制定的手动学习计划",
            startDate: startDate,
            endDate: endDate,
            totalWeeks: totalWeeks,
            weeklyPlans: weeklyPlans
        )
        
        dataManager.addPlan(plan)
        dismiss()
    }
}

// MARK: - AI计划页面
struct AIPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let goal: LearningGoal
    let onPlanApplied: () -> Void
    @State private var generatedPlan: LearningPlan?
    @State private var isGenerating = true
    @State private var errorMessage: String?
    @State private var totalWeeks = 16
    
    var body: some View {
        NavigationView {
            VStack {
                if isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("AI正在分析目标...")
                            .font(.headline)
                        
                        Text("根据关键结果和里程碑生成学习计划")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if let error = errorMessage {
                            Text("生成失败: \(error)")
                                .font(.caption)
                                .foregroundColor(Color(.systemRed))
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let plan = generatedPlan {
                    VStack(spacing: 0) {
                        // 顶部固定操作区域
                        VStack(spacing: 12) {
                            Button("应用此计划") {
                                dataManager.addPlan(plan)
                                
                                // 在后台进行任务调度
                                Task {
                                    do {
                                        let scheduledPlan = try await AIPlanServiceManager.shared.schedulePlanTasks(plan, dataManager: dataManager)
                                        
                                        await MainActor.run {
                                            // 保存调度后的任务
                                            for task in scheduledPlan.scheduledTasks {
                                                dataManager.addTask(task)
                                                print("📅 调度任务已保存: \(task.title) - \(task.scheduledStartTime?.formatted() ?? "未安排时间")")
                                            }
                                            
                                            print("✅ 计划「\(plan.title)」及其 \(scheduledPlan.scheduledTasks.count) 个任务已保存")
                                        }
                                    } catch {
                                        await MainActor.run {
                                            print("❌ 任务调度失败: \(error)")
                                        }
                                    }
                                }
                                
                                onPlanApplied() // 调用回调关闭整个CreatePlanView
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            
                            Button("编辑计划") {
                                // TODO: 实现计划编辑功能
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        
                        // 计划详情内容
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // 计划概览
                                PlanOverviewSection(plan: plan)
                                
                                // 周计划详情
                                WeeklyPlanDetailSection(plan: plan)
                                
                                // 学习资源
                                if !plan.resources.isEmpty {
                                    CreatePlanResourcesSection(resources: plan.resources)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(Color(.systemOrange))
                        
                        Text("计划生成失败")
                            .font(.headline)
                        
                        Text(errorMessage ?? "未知错误")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("重试") {
                            generateAIPlan()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("AI生成计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isGenerating {
                        Button("重新生成") {
                            generateAIPlan()
                        }
                    }
                }
            }
        }
        .onAppear {
            generateAIPlan()
        }
    }
    
    private func generateAIPlan() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                // 移除硬编码的totalWeeks，让AIPlanServiceManager自己计算正确的周数
                let plan = try await AIPlanServiceManager.shared.generateLearningPlan(for: goal, dataManager: dataManager)
                
                await MainActor.run {
                    generatedPlan = plan
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    print("❌ AI计划生成错误: \(error)")
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
}

// MARK: - 计划概览区域
struct PlanOverviewSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("计划概览")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                CreatePlanInfoRow(title: "总时长", value: "\(plan.totalWeeks) 周", icon: "calendar")
                CreatePlanInfoRow(title: "开始时间", value: plan.startDate, formatter: dateFormatter, icon: "clock")
                CreatePlanInfoRow(title: "结束时间", value: plan.endDate, formatter: dateFormatter, icon: "target")
                CreatePlanInfoRow(title: "总任务数", value: "\(plan.weeklyPlans.reduce(0) { $0 + $1.taskCount }) 个", icon: "checklist")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - 周计划预览区域
struct WeeklyPlanPreviewSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("周计划预览")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(plan.weeklyPlans.prefix(4)) { weeklyPlan in
                WeeklyPlanPreviewCard(weeklyPlan: weeklyPlan)
            }
            
            if plan.weeklyPlans.count > 4 {
                Text("还有 \(plan.weeklyPlans.count - 4) 周计划...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - 周计划预览卡片
struct WeeklyPlanPreviewCard: View {
    let weeklyPlan: WeeklyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(weeklyPlan.weekNumber) 周")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(weeklyPlan.taskCount) 个任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !weeklyPlan.milestones.isEmpty {
                Text(weeklyPlan.milestones.first ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(Int(weeklyPlan.estimatedHours))小时", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(weeklyPlan.startDate, formatter: weekDateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - 计划信息行
struct CreatePlanInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    init(title: String, value: String, icon: String) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    init(title: String, value: Date, formatter: DateFormatter, icon: String) {
        self.title = title
        self.value = formatter.string(from: value)
        self.icon = icon
    }
    
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

// MARK: - 日期格式化器
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private let weekDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter
}()

// MARK: - 周计划详情区域
struct WeeklyPlanDetailSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("周计划详情")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(plan.weeklyPlans.prefix(4)) { weeklyPlan in
                WeeklyPlanDetailCard(weeklyPlan: weeklyPlan)
            }
            
            if plan.weeklyPlans.count > 4 {
                Text("还有 \(plan.weeklyPlans.count - 4) 周计划...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - 周计划详情卡片
struct WeeklyPlanDetailCard: View {
    let weeklyPlan: WeeklyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("第 \(weeklyPlan.weekNumber) 周")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(weeklyPlan.taskCount) 个任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(weeklyPlan.estimatedHours)) 小时")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !weeklyPlan.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("里程碑:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(weeklyPlan.milestones.prefix(2), id: \.self) { milestone in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.systemGreen))
                                .font(.caption)
                            Text(milestone)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if weeklyPlan.milestones.count > 2 {
                        Text("还有 \(weeklyPlan.milestones.count - 2) 个里程碑...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 显示具体任务列表
            if !weeklyPlan.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本周任务:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(weeklyPlan.tasks.prefix(3)) { task in
                        WeeklyTaskRow(task: task)
                    }
                    
                    if weeklyPlan.tasks.count > 3 {
                        Text("还有 \(weeklyPlan.tasks.count - 3) 个任务...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 周任务行
struct WeeklyTaskRow: View {
    let task: WeeklyTask
    
    var body: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundColor(.gray)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if !task.quantity.isEmpty {
                    Text(task.quantity)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !task.duration.isEmpty {
                Text(task.duration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 学习资源区域
struct CreatePlanResourcesSection: View {
    let resources: [LearningResource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐学习资源")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(resources.prefix(3)) { resource in
                HStack {
                    Image(systemName: resource.type.icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resource.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if !resource.description.isEmpty {
                            Text(resource.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    if let url = resource.url, !url.isEmpty {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            
            if resources.count > 3 {
                Text("还有 \(resources.count - 3) 个资源...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
}

#Preview {
    CreatePlanView(goal: LearningGoal(
        title: "提升英语成绩",
        description: "在本学期结束时，英语成绩提升至班级前10名",
        category: .english,
        priority: .high,
        targetDate: Date().addingTimeInterval(90 * 24 * 3600),
        goalType: .okr
    ))
    .environmentObject(DataManager())
}
