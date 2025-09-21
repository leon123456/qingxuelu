//
//  GoalsView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddGoal = false
    @State private var selectedStatus: GoalStatus? = nil
    @State private var showingTemplates = false
    @State private var goalToDelete: LearningGoal? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                let goals = filteredGoals()
                
                // 主要内容区域
                if goals.isEmpty {
                    // 空状态 - 使用 Spacer 让内容居中，模板区域固定在底部
                    VStack {
                        Spacer()
                        EmptyGoalsView()
                        Spacer()
                    }
                } else {
                    // 有目标时 - 使用 List 显示目标
                    List {
                        ForEach(goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal) {
                                    goalToDelete = goal
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
                
                // 目标模板区域 - 始终固定在底部
                BrowseTemplatesSection()
            }
            .navigationTitle("学习目标")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("全部") { selectedStatus = nil }
                        ForEach(GoalStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) { selectedStatus = status }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 手动创建目标按钮
                        Button(action: { showingAddGoal = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("手动创建")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // 模板按钮
                        Button(action: { showingTemplates = true }) {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(isPresented: $showingTemplates) {
            GoalTemplateView()
        }
        .alert("删除目标", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let goal = goalToDelete {
                    dataManager.deleteGoal(goal)
                }
            }
        } message: {
            if let goal = goalToDelete {
                Text("确定要删除「\(goal.title)」吗？\n\n删除的目标将移到回收站，您可以在设置中恢复或永久删除。")
            }
        }
    }
    
    private func filteredGoals() -> [LearningGoal] {
        let goals = dataManager.goals
        if let status = selectedStatus {
            return goals.filter { $0.status == status }
        }
        return goals
    }
    
}

// MARK: - 目标行视图
struct GoalRowView: View {
    let goal: LearningGoal
    let onDelete: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
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
                    HStack(spacing: 8) {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(Color(.systemRed))
                                .padding(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(goal.goalType.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                            
                            Text(goal.status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(goal.status.color).opacity(0.2))
                                .cornerRadius(8)
                            
                            Text(goal.priority.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(goal.priority.color).opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // 时间信息
            HStack {
                Text("开始: \(goal.startDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("目标: \(goal.targetDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 空目标视图
struct EmptyGoalsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有学习目标")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("制定明确的学习目标，让学习更有方向")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 空学生视图
struct EmptyStudentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("请先添加学生信息")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("在设置页面添加学生信息后，就可以开始管理学习目标了")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 目标详情视图
struct GoalDetailView: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditGoal = false
    @State private var showingCreatePlan = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 目标基本信息
                GoalInfoSection(goal: goal)
                
                // 制定计划区域
                CreatePlanSection(goal: goal, showingCreatePlan: $showingCreatePlan)
                
                // 进度信息
                ProgressSection(goal: goal)
                
                // 里程碑
                MilestonesSection(goal: goal)
                
                // 相关任务
                RelatedTasksSection(goal: goal)
            }
            .padding()
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") {
                    showingEditGoal = true
                }
            }
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanView(goal: goal)
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalView(goal: goal)
        }
    }
}

// MARK: - 目标信息区域
struct GoalInfoSection: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目标信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "科目", value: goal.category.rawValue, icon: goal.category.icon)
                InfoRow(title: "优先级", value: goal.priority.rawValue, icon: "exclamationmark.triangle")
                InfoRow(title: "状态", value: goal.status.rawValue, icon: "circle.fill")
                InfoRow(title: "开始时间", value: goal.startDate, formatter: dateFormatter, icon: "calendar")
                InfoRow(title: "目标时间", value: goal.targetDate, formatter: dateFormatter, icon: "target")
            }
            
            if !goal.description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(goal.description)
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

// MARK: - 进度区域
struct ProgressSection: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("进度信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // 总体进度
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("总体进度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: goal.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
                
                // 里程碑进度
                if !goal.milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("里程碑进度")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        let completedMilestones = goal.milestones.filter { $0.isCompleted }.count
                        let totalMilestones = goal.milestones.count
                        
                        HStack {
                            Text("\(completedMilestones)/\(totalMilestones) 已完成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(Double(completedMilestones) / Double(totalMilestones) * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        ProgressView(value: Double(completedMilestones) / Double(totalMilestones))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 里程碑区域
struct MilestonesSection: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("里程碑")
                .font(.headline)
                .fontWeight(.semibold)
            
            if goal.milestones.isEmpty {
                Text("暂无里程碑")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(goal.milestones) { milestone in
                    MilestoneRowView(milestone: milestone)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 里程碑行视图
struct MilestoneRowView: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(milestone.isCompleted)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("目标: \(milestone.targetDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let completedDate = milestone.completedDate {
                    Text("完成: \(completedDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(Color(.systemGreen))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 相关任务区域
struct RelatedTasksSection: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关任务")
                .font(.headline)
                .fontWeight(.semibold)
            
            let relatedTasks = dataManager.getTasksForGoal(goal.id)
            
            if relatedTasks.isEmpty {
                Text("暂无相关任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(relatedTasks) { task in
                    SimpleTaskRowView(task: task)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 信息行视图
struct InfoRow: View {
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


// MARK: - 制定计划区域
struct CreatePlanSection: View {
    let goal: LearningGoal
    @Binding var showingCreatePlan: Bool
    @EnvironmentObject var dataManager: DataManager
    
    private var hasExistingPlan: Bool {
        dataManager.getPlanForGoal(goal.id) != nil
    }
    
    private var existingPlan: LearningPlan? {
        dataManager.getPlanForGoal(goal.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: hasExistingPlan ? "calendar.badge.checkmark" : "calendar.badge.plus")
                    .foregroundColor(hasExistingPlan ? .green : .blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习计划")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if hasExistingPlan {
                        Text("已制定计划，点击查看详情")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("为目标制定详细的学习计划")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if hasExistingPlan {
                    NavigationLink(destination: PlanDetailView(plan: existingPlan!)) {
                        Text("查看计划")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                } else {
                    Button("制定计划") {
                        showingCreatePlan = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            if !hasExistingPlan {
                VStack(alignment: .leading, spacing: 8) {
                    Text("制定计划后，系统将：")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        PlanFeatureRow(icon: "calendar", text: "将目标拆解为周计划")
                        PlanFeatureRow(icon: "target", text: "设置每周的关键结果")
                        PlanFeatureRow(icon: "clock", text: "自动生成每日任务")
                        PlanFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "跟踪学习进度")
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 计划功能行
struct PlanFeatureRow: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    init(icon: String, text: String, isSelected: Bool = false) {
        self.icon = icon
        self.text = text
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

// MARK: - 浏览模板部分
struct BrowseTemplatesSection: View {
    @State private var showingTemplates = false
    
    private let previewTemplates = Array(GoalTemplateManager.shared.templates.prefix(3))
    
    var body: some View {
        VStack(spacing: 0) {
            // 简洁的模板区域设计
            Button(action: {
                showingTemplates = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                        // 标题区域
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("目标模板")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("使用预设模板快速创建学习目标")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // 查看全部按钮样式，但实际点击由外层按钮处理
                            HStack(spacing: 2) {
                                Text("查看全部")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.blue.opacity(0.1))
                            )
                        }
                        
                        // 模板卡片区域
                        if !previewTemplates.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(previewTemplates) { template in
                                        TemplatePreviewCard(template: template)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        } else {
                            // 空状态
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                
                                Text("暂无可用模板")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                }
            }
            .buttonStyle(PlainButtonStyle()) // 移除默认按钮样式
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingTemplates) {
            GoalTemplateView()
        }
    }
}

// MARK: - 模板预览卡片
struct TemplatePreviewCard: View {
    let template: GoalTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 顶部图标和标签
            HStack {
                Image(systemName: template.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 18, height: 18)
                
                Spacer()
                
                Text(template.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.15))
                    )
                    .foregroundColor(.blue)
            }
            
            // 标题
            Text(template.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(10)
        .frame(width: 120, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - 日期格式化器
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    GoalsView()
        .environmentObject(DataManager())
}
