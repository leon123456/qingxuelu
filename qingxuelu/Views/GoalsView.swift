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
    @State private var showingTemplateBrowser = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                let goals = filteredGoals()
                
                if goals.isEmpty {
                    EmptyGoalsView()
                } else {
                    List {
                        ForEach(goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
                
                // 浏览模板区域
                BrowseTemplatesSection(showingTemplateBrowser: $showingTemplateBrowser)
            }
            .navigationTitle("学习目标")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
                
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
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .sheet(isPresented: $showingTemplateBrowser) {
            GoalTemplateView { selectedTemplate in
                // 直接创建目标，不需要再进入 AddGoalView
                createGoalFromTemplate(selectedTemplate)
                showingTemplateBrowser = false
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
    
    private func deleteGoals(offsets: IndexSet) {
        let goals = dataManager.goals
        for index in offsets {
            dataManager.deleteGoal(goals[index])
        }
    }
    
    private func createGoalFromTemplate(_ template: GoalTemplate) {
        var goal = LearningGoal(
            title: template.name,
            description: template.description,
            category: template.category,
            priority: template.priority,
            targetDate: Date().addingTimeInterval(TimeInterval(template.duration * 24 * 3600)),
            goalType: template.goalType
        )
        goal.milestones = template.milestones.map { $0.toMilestone() }
        goal.keyResults = template.keyResults.map { $0.toKeyResult() }
        
        dataManager.addGoal(goal)
        
        // 添加建议的任务
        for taskTemplate in template.suggestedTasks {
            let task = taskTemplate.toLearningTask(goalId: goal.id)
            dataManager.addTask(task)
        }
    }
}

// MARK: - 目标行视图
struct GoalRowView: View {
    let goal: LearningGoal
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 目标基本信息
                GoalInfoSection(goal: goal)
                
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
                        .foregroundColor(.green)
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
                    TaskRowView(task: task)
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

// MARK: - 日期格式化器
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

// MARK: - 浏览模板区域
struct BrowseTemplatesSection: View {
    @Binding var showingTemplateBrowser: Bool
    @ObservedObject var templateManager = GoalTemplateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("浏览模板")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("查看全部") {
                    showingTemplateBrowser = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Text("使用预设模板快速创建学习目标")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 模板预览卡片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(templateManager.templates.prefix(3))) { template in
                        TemplatePreviewCard(template: template) {
                            showingTemplateBrowser = true
                        }
                    }
                    
                    // 查看更多卡片
                    Button(action: {
                        showingTemplateBrowser = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("更多")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .frame(width: 80, height: 100)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .top
        )
    }
}

// MARK: - 模板预览卡片
struct TemplatePreviewCard: View {
    let template: GoalTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(template.duration)天")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.2)))
                        .foregroundColor(.blue)
                }
                
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                HStack {
                    Label("\(template.milestones.count)", systemImage: "flag.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(template.keyResults.count)", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 100)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GoalsView()
        .environmentObject(DataManager())
}
