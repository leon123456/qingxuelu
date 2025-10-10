//
//  TaskSchedulerView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct TaskSchedulerView: View {
    let plan: LearningPlan
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var scheduleSettings = ScheduleSettings()
    @State private var isGeneratingTasks = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 计划信息
                    TaskSchedulerPlanInfoSection(plan: plan)
                    
                    // 日期选择
                    WeekdaySelectionSection(settings: $scheduleSettings)
                    
                    // 时间范围设置
                    TimeRangeSection(settings: $scheduleSettings)
                    
                    // 生成任务按钮
                    GenerateTasksButton(
                        isGenerating: $isGeneratingTasks,
                        action: generateTasks
                    )
                }
                .padding()
            }
            .navigationTitle("安排任务到日历")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateTasks() {
        // 使用DispatchQueue来避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            self.isGeneratingTasks = true
        }
        
        Task {
            do {
                // 先删除该计划已存在的任务
                await MainActor.run {
                    let existingTasks = dataManager.tasks.filter { $0.planId == plan.id }
                    for task in existingTasks {
                        dataManager.deleteTask(task)
                    }
                }
                
                // 使用TaskScheduler生成任务
                var allTasks: [LearningTask] = []
                let calendar = Calendar.current
                
                for (weekIndex, weeklyPlan) in plan.weeklyPlans.enumerated() {
                    let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: plan.startDate) ?? plan.startDate
                    let weekTasks = TaskScheduler.shared.scheduleWeeklyTasks(
                        weeklyPlan,
                        for: weekStartDate,
                        goalId: plan.id,
                        planId: plan.id,
                        settings: scheduleSettings
                    )
                    allTasks.append(contentsOf: weekTasks)
                }
                
                await MainActor.run {
                    // 添加生成的任务到DataManager
                    for task in allTasks {
                        dataManager.addTask(task)
                    }
                    
                    // 更新计划的调度状态
                    var updatedPlan = plan
                    updatedPlan.scheduleStatus = .scheduled
                    dataManager.updatePlan(updatedPlan)
                }
                
                // 在下一个运行循环中更新UI状态和关闭视图
                await MainActor.run {
                    self.isGeneratingTasks = false
                    self.dismiss()
                }
                
            } catch {
                await MainActor.run {
                    self.isGeneratingTasks = false
                    print("❌ 生成任务失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 计划信息区域
struct TaskSchedulerPlanInfoSection: View {
    let plan: LearningPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("计划信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("计划名称:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(plan.title)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("计划周期:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(plan.totalWeeks) 周")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("每周计划:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(plan.weeklyPlans.count) 个")
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 日期选择区域
struct WeekdaySelectionSection: View {
    @Binding var settings: ScheduleSettings
    
    private let weekdays = [
        ("周一", 2),
        ("周二", 3),
        ("周三", 4),
        ("周四", 5),
        ("周五", 6),
        ("周六", 7),
        ("周日", 1)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择学习日期")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("选择一周中哪些天可以安排学习任务")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(weekdays, id: \.1) { weekday, dayNumber in
                    WeekdayToggle(
                        title: weekday,
                        isSelected: isWeekdaySelected(dayNumber),
                        action: { toggleWeekday(dayNumber) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func isWeekdaySelected(_ dayNumber: Int) -> Bool {
        return settings.selectedWeekdays.contains(dayNumber)
    }
    
    private func toggleWeekday(_ dayNumber: Int) {
        if settings.selectedWeekdays.contains(dayNumber) {
            settings.selectedWeekdays.remove(dayNumber)
        } else {
            settings.selectedWeekdays.insert(dayNumber)
        }
    }
}

// MARK: - 日期切换按钮
struct WeekdayToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 时间范围设置区域
struct TimeRangeSection: View {
    @Binding var settings: ScheduleSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置学习时间")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("设置每天可以安排学习任务的时间范围")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                // 开始时间
                TimePickerRow(
                    title: "最早开始时间",
                    time: $settings.schoolEndTime,
                    description: "设置每天最早可以开始学习的时间"
                )
                
                // 结束时间
                TimePickerRow(
                    title: "最晚结束时间",
                    time: $settings.latestStudyTime,
                    description: "设置每天最晚可以结束学习的时间"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 时间选择行
struct TimePickerRow: View {
    let title: String
    @Binding var time: DateComponents
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(String(format: "%02d", time.hour ?? 0)):\(String(format: "%02d", time.minute ?? 0))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // 时间调整按钮
                HStack(spacing: 12) {
                    Button(action: { adjustTime(-1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { adjustTime(1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func adjustTime(_ hours: Int) {
        let currentHour = time.hour ?? 0
        let newHour = max(0, min(23, currentHour + hours))
        time.hour = newHour
    }
}

// MARK: - 生成任务按钮
struct GenerateTasksButton: View {
    @Binding var isGenerating: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(Color(.systemBackground))
                } else {
                    Image(systemName: "calendar.badge.plus")
                }
                
                Text(isGenerating ? "正在生成任务..." : "生成任务到日历")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(12)
        }
        .disabled(isGenerating)
    }
}

#Preview {
    TaskSchedulerView(plan: LearningPlan(
        id: UUID(),
        title: "测试计划",
        description: "这是一个测试计划",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date(),
        totalWeeks: 4
    ))
    .environmentObject(DataManager())
}
