//
//  PlanView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

// MARK: - 日期格式化器
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM月dd日"
    return formatter
}()

private let weekDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年MM月dd日"
    return formatter
}()

struct PlanView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedGoal: LearningGoal?
    @State private var showingAddPlan = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if dataManager.goals.isEmpty {
                    EmptyPlanView()
                } else {
                    // 目标选择器
                    GoalSelector(selectedGoal: $selectedGoal)
                    
                    // 计划内容
                    if let goal = selectedGoal {
                        PlanContentView(goal: goal)
                    } else {
                        PlanOverviewView()
                    }
                }
            }
            .navigationTitle("计划")
        }
        .sheet(isPresented: $showingAddPlan) {
            AddGoalView()
        }
    }
}

// MARK: - 空状态视图
struct EmptyPlanView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有学习计划")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("先设定学习目标，然后系统会自动生成学习计划")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 目标选择器
struct GoalSelector: View {
    @Binding var selectedGoal: LearningGoal?
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dataManager.goals) { goal in
                    GoalChip(
                        title: goal.title,
                        isSelected: selectedGoal?.id == goal.id,
                        color: Color(goal.status.color)
                    ) {
                        selectedGoal = goal
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 目标芯片
struct GoalChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                        .opacity(isPressed ? 0.8 : 1.0)
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - 计划内容视图
struct PlanContentView: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    
    var planForGoal: LearningPlan? {
        dataManager.getPlanForGoal(goal.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = planForGoal {
                    // 显示计划
                    NavigationLink(destination: PlanDetailView(plan: plan)) {
                        PlanCardView(plan: plan, action: {}, onDelete: {
                            deletePlan(plan)
                        })
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // 没有计划，显示生成计划按钮
                    GeneratePlanView(goal: goal)
                }
            }
            .padding()
        }
    }
    
    private func deletePlan(_ plan: LearningPlan) {
        dataManager.deletePlan(plan)
        // 同时清除目标的planId
        if let goalIndex = dataManager.goals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = dataManager.goals[goalIndex]
            updatedGoal.planId = nil
            dataManager.updateGoal(updatedGoal)
        }
    }
}

// MARK: - 生成计划视图
struct GeneratePlanView: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingAIPlan = false
    @State private var generatedPlan: LearningPlan?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("为「\(goal.title)」生成AI学习计划")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("AI会根据你的目标、关键结果和里程碑智能生成 \(Int(goal.targetDate.timeIntervalSince(goal.startDate) / (7 * 24 * 3600))) 周的详细学习计划")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let error = errorMessage {
                Text("生成失败: \(error)")
                    .font(.caption)
                    .foregroundColor(Color(.systemRed))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: generateAIPlan) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isGenerating ? "AI生成中..." : "AI生成学习计划")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .sheet(isPresented: $showingAIPlan) {
            if let plan = generatedPlan {
                AIPlanPreviewView(plan: plan, goal: goal) {
                    // 应用计划
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
                    
                    showingAIPlan = false
                }
            }
        }
    }
    
    private func generateAIPlan() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                // 移除错误的周数计算，让AIPlanServiceManager自己计算正确的周数
                let plan = try await AIPlanServiceManager.shared.generateLearningPlan(for: goal, dataManager: dataManager)
                
                await MainActor.run {
                    generatedPlan = plan
                    isGenerating = false
                    showingAIPlan = true
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

// MARK: - AI计划预览视图
struct AIPlanPreviewView: View {
    let plan: LearningPlan
    let goal: LearningGoal
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部固定操作区域
                VStack(spacing: 12) {
                    Button("应用此计划") {
                        onApply()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // 计划详情内容
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 计划概览
                        VStack(alignment: .leading, spacing: 12) {
                            Text("计划概览")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PlanViewInfoRow(title: "总时长", value: "\(plan.totalWeeks) 周", icon: "calendar")
                                PlanViewInfoRow(title: "开始时间", value: plan.startDate, formatter: dateFormatter, icon: "clock")
                                PlanViewInfoRow(title: "结束时间", value: plan.endDate, formatter: dateFormatter, icon: "target")
                                PlanViewInfoRow(title: "总任务数", value: "\(plan.weeklyPlans.reduce(0) { $0 + $1.taskCount }) 个", icon: "checklist")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // 周计划预览
                        VStack(alignment: .leading, spacing: 12) {
                            Text("周计划预览")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(plan.weeklyPlans.prefix(3))) { week in
                                PlanViewWeeklyPreviewCard(week: week)
                            }
                            
                            if plan.weeklyPlans.count > 3 {
                                Text("... 还有 \(plan.weeklyPlans.count - 3) 周计划")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // 学习资源
                        if !plan.resources.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("学习资源")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(Array(plan.resources.prefix(3))) { resource in
                                    ResourcePreviewRow(resource: resource)
                                }
                                
                                if plan.resources.count > 3 {
                                    Text("... 还有 \(plan.resources.count - 3) 个资源")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 16)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI生成的学习计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 计划信息行
struct PlanViewInfoRow: View {
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

// MARK: - 周计划预览卡片
struct PlanViewWeeklyPreviewCard: View {
    let week: WeeklyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(week.weekNumber) 周")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(weekDateFormatter.string(from: week.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !week.milestones.isEmpty {
                Text(week.milestones.first ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("\(week.taskCount) 个任务")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(week.estimatedHours) 小时")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - 资源预览行
struct ResourcePreviewRow: View {
    let resource: LearningResource
    
    var body: some View {
        HStack {
            Image(systemName: resource.type.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(resource.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 计划卡片视图
struct PlanCardView: View {
    let plan: LearningPlan
    let action: () -> Void
    let onDelete: (() -> Void)?
    @State private var showingDeleteAlert = false
    
    var currentWeek: WeeklyPlan? {
        let now = Date()
        return plan.weeklyPlans.first { week in
            now >= week.startDate && now <= week.endDate
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 计划标题和状态
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(plan.totalWeeks)周")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        
                        if onDelete != nil {
                            Button(action: { showingDeleteAlert = true }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(Color(.systemRed))
                                    .padding(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Text(plan.isActive ? "进行中" : "已完成")
                        .font(.caption)
                        .foregroundColor(plan.isActive ? .green : .gray)
                }
            }
            
            // 当前周信息
            if let currentWeek = currentWeek {
                CurrentWeekView(week: currentWeek)
            }
            
            // 资源预览
            if !plan.resources.isEmpty {
                ResourcesPreviewView(resources: Array(plan.resources.prefix(3)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .alert("删除计划", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("确定要删除「\(plan.title)」吗？此操作无法撤销。")
        }
    }
}

// MARK: - 当前周视图
struct CurrentWeekView: View {
    let week: WeeklyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(week.weekNumber) 周")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(week.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: week.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Label("\(week.taskCount) 任务", systemImage: "checklist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(Int(week.estimatedHours))h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 资源预览视图
struct ResourcesPreviewView: View {
    let resources: [LearningResource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学习资源")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                ForEach(resources) { resource in
                    ResourceChipView(resource: resource)
                }
                
                if resources.count >= 3 {
                    Text("+更多")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 资源芯片视图
struct ResourceChipView: View {
    let resource: LearningResource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: resource.type.icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(resource.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 计划概览视图
struct PlanOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var activePlans: [LearningPlan] {
        dataManager.getActivePlans()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if activePlans.isEmpty {
                    Text("选择目标查看计划")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 显示所有活跃计划的概览
                    ForEach(activePlans) { plan in
                        PlanOverviewCard(plan: plan)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 计划概览卡片
struct PlanOverviewCard: View {
    let plan: LearningPlan
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationLink(destination: PlanDetailView(plan: plan)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(plan.totalWeeks) 周计划 • \(plan.weeklyPlans.count) 个里程碑")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(Color(.systemRed))
                                .padding(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("进行中")
                            .font(.caption)
                            .foregroundColor(Color(.systemGreen))
                    }
                }
                
                HStack {
                    Text("\(plan.resources.count) 个资源")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("删除计划", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deletePlan(plan)
            }
        } message: {
            Text("确定要删除「\(plan.title)」吗？此操作无法撤销。")
        }
    }
    
    private func deletePlan(_ plan: LearningPlan) {
        dataManager.deletePlan(plan)
        // 同时清除目标的planId
        if let goalIndex = dataManager.goals.firstIndex(where: { $0.planId == plan.id }) {
            var updatedGoal = dataManager.goals[goalIndex]
            updatedGoal.planId = nil
            dataManager.updateGoal(updatedGoal)
        }
    }
}

// MARK: - 计划详情视图
struct PlanDetailView: View {
    let plan: LearningPlan
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 计划基本信息
                PlanInfoSection(plan: plan)
                
                // 周计划时间线
                WeeklyTimelineView(plan: plan)
                
                // 学习资源
                ResourcesSection(plan: plan)
            }
            .padding()
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - 计划信息区域
struct PlanInfoSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("计划信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                PlanViewInfoRow(title: "总时长", value: "\(plan.totalWeeks) 周", icon: "calendar")
                PlanViewInfoRow(title: "开始时间", value: plan.startDate, formatter: dateFormatter, icon: "play.circle")
                PlanViewInfoRow(title: "结束时间", value: plan.endDate, formatter: dateFormatter, icon: "stop.circle")
                PlanViewInfoRow(title: "状态", value: plan.isActive ? "进行中" : "已完成", icon: "circle.fill")
            }
            
            if !plan.description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(plan.description)
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

// MARK: - 周计划时间线
struct WeeklyTimelineView: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习时间线")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(plan.weeklyPlans) { week in
                    WeeklyTimelineCard(week: week, allWeeklyPlans: plan.weeklyPlans)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 周时间线卡片
struct WeeklyTimelineCard: View {
    let week: WeeklyPlan
    let allWeeklyPlans: [WeeklyPlan]
    @State private var isPressed = false
    @State private var showingWeekDetail = false
    
    var isCurrentWeek: Bool {
        let now = Date()
        return now >= week.startDate && now <= week.endDate
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 周数标识
            VStack {
                Text("\(week.weekNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentWeek ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(isCurrentWeek ? Color.blue : Color.blue.opacity(0.2))
                    .cornerRadius(20)
                
                if isCurrentWeek {
                    Text("本周")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            // 周信息
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(week.startDate, formatter: weekDateFormatter)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(week.endDate, formatter: weekDateFormatter)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if !week.milestones.isEmpty {
                    Text(week.milestones.first ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Label("\(week.taskCount) 任务", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(Int(week.estimatedHours))h", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if week.taskCount > 0 {
                    ProgressView(value: week.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 0.5)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentWeek ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // 添加点击反馈
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                // 导航到周计划详情页
                showingWeekDetail = true
            }
        }
        .sheet(isPresented: $showingWeekDetail) {
            WeeklyPlanDetailView(weeklyPlan: week, allWeeklyPlans: allWeeklyPlans)
        }
    }
}

// MARK: - 资源区域
struct ResourcesSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习资源")
                .font(.headline)
                .fontWeight(.semibold)
            
            if plan.resources.isEmpty {
                Text("暂无学习资源")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(plan.resources) { resource in
                        ResourceCardView(resource: resource)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 资源卡片视图
struct ResourceCardView: View {
    let resource: LearningResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: resource.type.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if resource.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(.systemGreen))
                }
            }
            
            Text(resource.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text(resource.type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !resource.description.isEmpty {
                Text(resource.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 周计划详情视图
struct WeeklyPlanDetailView: View {
    let weeklyPlan: WeeklyPlan
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var isEditing = false
    @State private var editedPlan: WeeklyPlan
    @State private var currentWeekIndex: Int
    @State private var allWeeklyPlans: [WeeklyPlan]
    
    init(weeklyPlan: WeeklyPlan, allWeeklyPlans: [WeeklyPlan]) {
        self.weeklyPlan = weeklyPlan
        self._editedPlan = State(initialValue: weeklyPlan)
        
        // 找到当前周的索引
        let currentIndex = allWeeklyPlans.firstIndex(where: { $0.id == weeklyPlan.id }) ?? 0
        
        self._allWeeklyPlans = State(initialValue: allWeeklyPlans)
        self._currentWeekIndex = State(initialValue: currentIndex)
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentWeekIndex) {
                ForEach(Array(allWeeklyPlans.enumerated()), id: \.element.id) { index, weekPlan in
                    ScrollView {
                        VStack(spacing: 20) {
                            // 周计划基本信息
                            WeeklyPlanInfoSection(plan: weekPlan)
                            
                            // 本周任务列表
                            WeeklyTasksSection(plan: Binding(
                                get: { weekPlan },
                                set: { _ in }
                            ), isEditing: $isEditing, onTaskChange: updateTaskCounts)
                            
                            // 本周里程碑
                            WeeklyMilestonesSection(plan: Binding(
                                get: { weekPlan },
                                set: { _ in }
                            ), isEditing: $isEditing)
                        }
                        .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .onChange(of: currentWeekIndex) { _, newIndex in
                if newIndex < allWeeklyPlans.count {
                    editedPlan = allWeeklyPlans[newIndex]
                }
            }
            .navigationTitle("第\(allWeeklyPlans.isEmpty ? weeklyPlan.weekNumber : allWeeklyPlans[currentWeekIndex].weekNumber)周")
            .overlay(
                // 添加滑动提示
                VStack {
                    Spacer()
                    if allWeeklyPlans.count > 1 {
                        HStack {
                            Spacer()
                            Text("左右滑动查看更多周")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "编辑") {
                        if isEditing {
                            // 保存编辑
                            saveChanges()
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // 更新任务计数和完成状态
        updateTaskCounts()
        
        // 找到包含当前周计划的LearningPlan
        if let planIndex = dataManager.plans.firstIndex(where: { plan in
            plan.weeklyPlans.contains { $0.id == editedPlan.id }
        }) {
            // 找到周计划在LearningPlan中的索引
            if let weekIndex = dataManager.plans[planIndex].weeklyPlans.firstIndex(where: { 
                $0.id == editedPlan.id 
            }) {
                // 更新周计划
                dataManager.plans[planIndex].weeklyPlans[weekIndex] = editedPlan
                
                // 更新整个LearningPlan到DataManager
                dataManager.updatePlan(dataManager.plans[planIndex])
                
                print("✅ 周计划编辑已保存: 第\(editedPlan.weekNumber)周")
            }
        }
    }
    
    private func updateTaskCounts() {
        // 更新任务总数
        editedPlan.taskCount = editedPlan.tasks.count
        
        // 更新已完成任务数
        editedPlan.completedTasks = editedPlan.tasks.filter { $0.isCompleted }.count
        
        // 更新完成状态
        editedPlan.isCompleted = editedPlan.completedTasks == editedPlan.taskCount && editedPlan.taskCount > 0
    }
}

// MARK: - 周计划信息区域
struct WeeklyPlanInfoSection: View {
    let plan: WeeklyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周概览")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("时间范围")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(plan.startDate, formatter: dateFormatter) - \(plan.endDate, formatter: dateFormatter)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("任务数量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(plan.taskCount) 个")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("预计时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(plan.estimatedHours)) 小时")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // 进度条
            if plan.taskCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("完成进度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(plan.completedTasks)/\(plan.taskCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: plan.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 周任务区域
struct WeeklyTasksSection: View {
    @Binding var plan: WeeklyPlan
    @Binding var isEditing: Bool
    let onTaskChange: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本周任务")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isEditing {
                    Button(action: addNewTask) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if plan.tasks.isEmpty {
                Text("暂无任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(plan.tasks.indices, id: \.self) { index in
                        WeeklyTaskDetailRow(
                            task: $plan.tasks[index],
                            isEditing: $isEditing,
                            onDelete: isEditing ? { deleteTask(at: index) } : nil,
                            onTaskChange: onTaskChange
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func addNewTask() {
        let newTask = WeeklyTask(
            title: "新任务",
            description: "",
            quantity: "",
            duration: "",
            difficulty: .medium
        )
        plan.tasks.append(newTask)
        // 更新任务计数
        plan.taskCount = plan.tasks.count
        onTaskChange?()
    }
    
    private func deleteTask(at index: Int) {
        guard index < plan.tasks.count else { return }
        plan.tasks.remove(at: index)
        // 更新任务计数
        plan.taskCount = plan.tasks.count
        // 重新计算完成的任务数
        plan.completedTasks = plan.tasks.filter { $0.isCompleted }.count
        onTaskChange?()
    }
}

// MARK: - 周任务行
struct WeeklyTaskDetailRow: View {
    @Binding var task: WeeklyTask
    @Binding var isEditing: Bool
    let onDelete: (() -> Void)?
    let onTaskChange: (() -> Void)?
    @State private var showingCompletionSheet = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: toggleTaskCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.title3)
                }
                // 移除 .disabled(!isEditing) 限制，允许直接点击完成
                
                VStack(alignment: .leading, spacing: 2) {
                    if isEditing {
                        TextField("任务标题", text: $task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .onChange(of: task.title) {
                                onTaskChange?()
                            }
                    } else {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(task.isCompleted)
                    }
                    
                    if !task.quantity.isEmpty {
                        Text(task.quantity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !task.duration.isEmpty {
                        Text(task.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 显示实际耗时
                    if let actualDuration = task.actualDuration {
                        Text("实际耗时: \(formatDuration(actualDuration))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isEditing, let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(Color(.systemRed))
                            .font(.caption)
                    }
                }
            }
            
            // 显示完成信息
            if task.isCompleted {
                TaskCompletionInfoView(task: task)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingCompletionSheet) {
            TaskCompletionSheet(task: $task) {
                onTaskChange?()
                showingCompletionSheet = false
            }
        }
    }
    
    private func toggleTaskCompletion() {
        if !task.isCompleted {
            // 如果任务未完成，显示完成信息输入界面
            showingCompletionSheet = true
        } else {
            // 如果任务已完成，直接取消完成
            task.isCompleted = false
            task.completedDate = nil
            task.actualDuration = nil
            task.completionNotes = nil
            task.completionRating = nil
            task.completionProgress = nil
            onTaskChange?()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - 任务完成信息视图
struct TaskCompletionInfoView: View {
    let task: WeeklyTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("已完成")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
                
                if let completedDate = task.completedDate {
                    Text(completedDate, formatter: dateFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let notes = task.completionNotes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
            }
            
            if let rating = task.completionRating {
                HStack {
                    Text("完成质量:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 任务完成输入界面
struct TaskCompletionSheet: View {
    @Binding var task: WeeklyTask
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var completionNotes = ""
    @State private var completionRating = 5
    @State private var completionProgress = 1.0
    @State private var actualDurationMinutes = 30
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 任务信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("完成任务")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 时间记录
                    VStack(alignment: .leading, spacing: 12) {
                        Text("时间记录")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("开始时间:")
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)
                                
                                DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("完成时间:")
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)
                                
                                DatePicker("", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("实际耗时:")
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)
                                
                                TextField("分钟", value: $actualDurationMinutes, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                
                                Text("分钟")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 完成度
                    VStack(alignment: .leading, spacing: 12) {
                        Text("完成度")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("完成进度:")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(completionProgress * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: $completionProgress, in: 0...1, step: 0.1)
                                .accentColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 完成质量
                    VStack(alignment: .leading, spacing: 12) {
                        Text("完成质量")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("质量评分:")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(completionRating)分")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        completionRating = star
                                    }) {
                                        Image(systemName: star <= completionRating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.title2)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 完成备注
                    VStack(alignment: .leading, spacing: 12) {
                        Text("完成备注")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("记录完成情况、心得体会等...", text: $completionNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("任务完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        completeTask()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func completeTask() {
        // 更新任务完成信息
        task.isCompleted = true
        task.startedDate = startTime
        task.completedDate = endTime
        task.actualDuration = TimeInterval(actualDurationMinutes * 60)
        task.completionNotes = completionNotes.isEmpty ? nil : completionNotes
        task.completionRating = completionRating
        task.completionProgress = completionProgress
        
        onComplete()
    }
}

// MARK: - 周里程碑区域
struct WeeklyMilestonesSection: View {
    @Binding var plan: WeeklyPlan
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本周里程碑")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isEditing {
                    Button(action: addNewMilestone) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if plan.milestones.isEmpty {
                Text("暂无里程碑")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(plan.milestones.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.systemGreen))
                                .font(.caption)
                            
                            if isEditing {
                                TextField("里程碑", text: $plan.milestones[index])
                                    .font(.subheadline)
                            } else {
                                Text(plan.milestones[index])
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            if isEditing {
                                Button(action: { deleteMilestone(at: index) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color(.systemRed))
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func addNewMilestone() {
        plan.milestones.append("新里程碑")
    }
    
    private func deleteMilestone(at index: Int) {
        guard index < plan.milestones.count else { return }
        plan.milestones.remove(at: index)
    }
}


#Preview {
    PlanView()
        .environmentObject(DataManager())
}
