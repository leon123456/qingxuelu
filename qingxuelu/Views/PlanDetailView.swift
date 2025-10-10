//
//  PlanDetailView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct PlanDetailViewNew: View {
    let plan: LearningPlan
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingTaskScheduler = false
    @State private var showingEditPlan = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 计划概览
                    PlanOverviewSection(plan: plan)
                    
                    // 调度状态
                    ScheduleStatusSection(plan: plan, showingTaskScheduler: $showingTaskScheduler)
                    
                    // 周计划列表
                    WeeklyPlansSection(plan: plan)
                    
                    // 学习资源
                    LearningResourcesSection(plan: plan)
                    
                    // 操作按钮
                PlanActionButtonsSection(
                    plan: plan,
                    showingTaskScheduler: $showingTaskScheduler,
                    showingEditPlan: $showingEditPlan
                )
                }
                .padding()
            }
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("编辑") {
                        showingEditPlan = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingTaskScheduler) {
            TaskSchedulerView(plan: plan)
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanView(plan: plan)
        }
    }
}

// MARK: - 计划概览区域
struct PlanOverviewSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("计划概览")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PlanInfoRow(
                    title: "计划描述",
                    value: plan.description,
                    icon: "doc.text"
                )
                
                PlanInfoRow(
                    title: "计划时长",
                    value: "\(plan.totalWeeks) 周",
                    icon: "calendar"
                )
                
                PlanInfoRow(
                    title: "开始日期",
                    value: plan.startDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar.badge.plus"
                )
                
                PlanInfoRow(
                    title: "结束日期",
                    value: plan.endDate.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar.badge.minus"
                )
                
                PlanInfoRow(
                    title: "总任务数",
                    value: "\(getTotalTaskCount()) 个",
                    icon: "list.bullet"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getTotalTaskCount() -> Int {
        return plan.weeklyPlans.reduce(0) { total, weeklyPlan in
            total + weeklyPlan.tasks.count
        }
    }
}

// MARK: - 调度状态区域
struct ScheduleStatusSection: View {
    let plan: LearningPlan
    @Binding var showingTaskScheduler: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("任务调度状态")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                // 状态图标
                ZStack {
                    Circle()
                        .fill(Color(plan.scheduleStatus.color))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: plan.scheduleStatus.icon)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.systemBackground))
                }
                
                // 状态信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.scheduleStatus.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(plan.scheduleStatus.color))
                    
                    Text(getStatusDescription())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 已调度的任务统计
            if plan.scheduleStatus != .notScheduled {
                HStack {
                    Text("已调度任务:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(plan.scheduledTasks.count) 个")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // 安排任务到日历按钮
            Button(action: { showingTaskScheduler = true }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text(getScheduleButtonText())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(getScheduleButtonColor())
                .foregroundColor(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getStatusDescription() -> String {
        switch plan.scheduleStatus {
        case .notScheduled:
            return "任务尚未安排到日历中"
        case .scheduled:
            return "任务已自动安排到日历"
        case .customized:
            return "任务已根据个人偏好安排"
        }
    }
    
    private func getScheduleButtonText() -> String {
        switch plan.scheduleStatus {
        case .notScheduled:
            return "安排任务到日历"
        case .scheduled:
            return "重新安排任务"
        case .customized:
            return "调整任务安排"
        }
    }
    
    private func getScheduleButtonColor() -> Color {
        switch plan.scheduleStatus {
        case .notScheduled:
            return .blue
        case .scheduled:
            return .orange
        case .customized:
            return .green
        }
    }
}

// MARK: - 周计划区域
struct WeeklyPlansSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("周计划详情")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(plan.weeklyPlans) { weeklyPlan in
                WeeklyPlanCard(weeklyPlan: weeklyPlan, allWeeklyPlans: plan.weeklyPlans)
            }
        }
    }
}

// MARK: - 周计划卡片
struct WeeklyPlanCard: View {
    let weeklyPlan: WeeklyPlan
    let allWeeklyPlans: [WeeklyPlan]
    @State private var isPressed = false
    @State private var showingWeekDetail = false
    
    var isCurrentWeek: Bool {
        let now = Date()
        return now >= weeklyPlan.startDate && now <= weeklyPlan.endDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 周计划标题
            HStack {
                Text("第 \(weeklyPlan.weekNumber) 周")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isCurrentWeek {
                        Text("本周")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Text("\(weeklyPlan.tasks.count) 个任务")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // 里程碑
            if !weeklyPlan.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("里程碑:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(weeklyPlan.milestones, id: \.self) { milestone in
                        Text("• \(milestone)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 任务预览
            if !weeklyPlan.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务预览:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(weeklyPlan.tasks.prefix(3)) { task in
                        TaskPreviewRow(task: task)
                    }
                    
                    if weeklyPlan.tasks.count > 3 {
                        Text("... 还有 \(weeklyPlan.tasks.count - 3) 个任务")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 点击提示
            HStack {
                Spacer()
                Text("点击查看详情")
                    .font(.caption)
                    .foregroundColor(.blue)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentWeek ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            WeeklyPlanDetailView(weeklyPlan: weeklyPlan, allWeeklyPlans: allWeeklyPlans)
        }
    }
}

// MARK: - 任务预览行
struct TaskPreviewRow: View {
    let task: WeeklyTask
    
    var body: some View {
        HStack {
            Text("• \(task.title)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(task.estimatedDuration / 60))分钟")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - 学习资源区域
struct LearningResourcesSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                ForEach(plan.resources) { resource in
                    ResourceRow(resource: resource)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 资源行
struct ResourceRow: View {
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
                
                Text(resource.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 操作按钮区域
struct PlanActionButtonsSection: View {
    let plan: LearningPlan
    @Binding var showingTaskScheduler: Bool
    @Binding var showingEditPlan: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 次要操作按钮
            HStack(spacing: 12) {
                Button(action: { showingEditPlan = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("编辑计划")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                if plan.scheduleStatus != .notScheduled {
                    Button(action: { /* 重新调度 */ }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("重新调度")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - 计划信息行
struct PlanInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
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

#Preview {
    PlanDetailView(plan: LearningPlan(
        id: UUID(),
        title: "英语口语提升计划",
        description: "通过日常练习提升英语口语表达能力",
        startDate: Date(),
        endDate: Date().addingTimeInterval(90 * 24 * 3600),
        totalWeeks: 12
    ))
    .environmentObject(DataManager())
}
