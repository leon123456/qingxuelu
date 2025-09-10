//
//  PlanView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedGoal: LearningGoal?
    @State private var showingAddPlan = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dataManager.goals.isEmpty {
                    EmptyPlanView()
                } else {
                    // 目标选择器
                    GoalSelector(selectedGoal: $selectedGoal)
                    
                    // 计划内容
                    if let goal = selectedGoal {
                        PlanDetailView(goal: goal)
                    } else {
                        PlanOverviewView()
                    }
                }
            }
            .navigationTitle("计划")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlan = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
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
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("还没有学习计划")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("先设定学习目标，然后制定详细的执行计划\n让学习更有条理和效率")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 目标选择器
struct GoalSelector: View {
    @Binding var selectedGoal: LearningGoal?
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部计划选项
                GoalChip(
                    title: "全部计划",
                    isSelected: selectedGoal == nil,
                    color: .gray
                ) {
                    selectedGoal = nil
                }
                
                // 各个目标选项
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
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 计划概览视图
struct PlanOverviewView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周计划概览
                WeeklyPlanOverview()
                
                // 里程碑概览
                MilestonesOverview()
                
                // 任务分布
                TaskDistributionView()
            }
            .padding()
        }
    }
}

// MARK: - 周计划概览
struct WeeklyPlanOverview: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本周计划")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    DayPlanCard(day: day)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var weekDays: [String] {
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    }
}

// MARK: - 日期计划卡片
struct DayPlanCard: View {
    let day: String
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(tasksCount)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("任务")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var tasksCount: Int {
        // 计算该日期的任务数量
        return dataManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: dueDate)
            let dayIndex = weekday == 1 ? 6 : weekday - 2 // 转换为周一到周日的索引
            
            let weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
            return weekDays[dayIndex] == day
        }.count
    }
}

// MARK: - 里程碑概览
struct MilestonesOverview: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("里程碑进度")
                .font(.headline)
                .fontWeight(.semibold)
            
            if upcomingMilestones.isEmpty {
                Text("暂无即将到来的里程碑")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(upcomingMilestones.prefix(3)) { milestone in
                    MilestoneCard(milestone: milestone)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var upcomingMilestones: [Milestone] {
        let allMilestones = dataManager.goals.flatMap { $0.milestones }
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: now)!
        
        return allMilestones.filter { milestone in
            !milestone.isCompleted && milestone.targetDate >= now && milestone.targetDate <= nextWeek
        }.sorted { $0.targetDate < $1.targetDate }
    }
}

// MARK: - 里程碑卡片
struct MilestoneCard: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(.vertical, 8)
    }
}

// MARK: - 任务分布视图
struct TaskDistributionView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("任务分布")
                .font(.headline)
                .fontWeight(.semibold)
            
            if taskDistribution.isEmpty {
                Text("暂无任务数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(taskDistribution, id: \.category) { item in
                    TaskDistributionRow(category: item.category, count: item.count, total: totalTasks)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var taskDistribution: [(category: SubjectCategory, count: Int)] {
        let distribution = Dictionary(grouping: dataManager.tasks, by: { $0.category })
        return distribution.map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    private var totalTasks: Int {
        dataManager.tasks.count
    }
}

// MARK: - 任务分布行
struct TaskDistributionRow: View {
    let category: SubjectCategory
    let count: Int
    let total: Int
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("/ \(total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 计划详情视图
struct PlanDetailView: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 目标信息
                GoalInfoCard(goal: goal)
                
                // 里程碑时间线
                MilestoneTimelineView(goal: goal)
                
                // 相关任务
                RelatedTasksView(goal: goal)
                
                // 学习资源
                LearningResourcesView(goal: goal)
            }
            .padding()
        }
    }
}

// MARK: - 目标信息卡片
struct GoalInfoCard: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(goal.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(goal.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 进度信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // 时间信息
            HStack {
                VStack(alignment: .leading) {
                    Text("开始时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.startDate, formatter: dateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("目标时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.targetDate, formatter: dateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 里程碑时间线
struct MilestoneTimelineView: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("里程碑时间线")
                .font(.headline)
                .fontWeight(.semibold)
            
            if goal.milestones.isEmpty {
                Text("暂无里程碑")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(goal.milestones.sorted { $0.targetDate < $1.targetDate }) { milestone in
                    MilestoneTimelineItem(milestone: milestone)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 里程碑时间线项
struct MilestoneTimelineItem: View {
    let milestone: Milestone
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线点
            VStack {
                Circle()
                    .fill(milestone.isCompleted ? Color.green : Color.blue)
                    .frame(width: 12, height: 12)
                
                if milestone != milestone { // 不是最后一个
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            // 里程碑内容
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(milestone.isCompleted)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("目标: \(milestone.targetDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
    }
}

// MARK: - 相关任务视图
struct RelatedTasksView: View {
    let goal: LearningGoal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("相关任务")
                .font(.headline)
                .fontWeight(.semibold)
            
            let relatedTasks = dataManager.tasks.filter { $0.goalId == goal.id }
            
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 学习资源视图
struct LearningResourcesView: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习资源")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("学习资源功能即将推出")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 任务行视图
struct TaskRowView: View {
    let task: LearningTask
    
    var body: some View {
        HStack {
            Image(systemName: task.category.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let dueDate = task.dueDate {
                    Text("截止: \(dueDate, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(task.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(task.status.color).opacity(0.2))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 日期格式化器
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

#Preview {
    PlanView()
        .environmentObject(DataManager())
}
