//
//  StatsView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingReflection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                    
                    // 学习仪表盘
                    LearningDashboard(timeRange: selectedTimeRange)
                    
                    // 目标进度分析
                    GoalsProgressAnalysis(timeRange: selectedTimeRange)
                    
                    // 学习时长统计
                    StudyTimeStats(timeRange: selectedTimeRange)
                    
                    // 复盘记录
                    ReflectionRecords()
                }
                .padding()
            }
            .navigationTitle("复盘")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingReflection = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingReflection) {
            AddReflectionView()
        }
    }
}

// MARK: - 时间范围枚举
enum TimeRange: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case quarter = "本季度"
    case year = "本年"
    
    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: startOfWeek, end: now)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: startOfMonth, end: now)
        case .quarter:
            let quarter = calendar.component(.month, from: now) / 3
            let startOfQuarter = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarter * 3 + 1, day: 1)) ?? now
            return DateInterval(start: startOfQuarter, end: now)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return DateInterval(start: startOfYear, end: now)
        }
    }
}

// MARK: - 时间范围选择器
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("时间范围", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - 学习仪表盘
struct LearningDashboard: View {
    let timeRange: TimeRange
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习仪表盘")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                // 总学习时长
                StatCard(
                    title: "总学习时长",
                    value: formatDuration(totalStudyTime),
                    icon: "clock.fill",
                    color: .blue
                )
                
                // 任务完成率
                StatCard(
                    title: "任务完成率",
                    value: "\(Int(taskCompletionRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // 目标进度
                StatCard(
                    title: "目标进度",
                    value: "\(Int(goalsProgress * 100))%",
                    icon: "target",
                    color: .orange
                )
                
                // 学习天数
                StatCard(
                    title: "学习天数",
                    value: "\(studyDays)",
                    icon: "calendar",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 统计数据计算
    private var totalStudyTime: TimeInterval {
        let interval = timeRange.dateInterval
        return dataManager.records
            .filter { interval.contains($0.startTime) }
            .reduce(0) { $0 + $1.duration }
    }
    
    private var taskCompletionRate: Double {
        let interval = timeRange.dateInterval
        let tasksInRange = dataManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return interval.contains(dueDate)
        }
        
        guard !tasksInRange.isEmpty else { return 0.0 }
        let completedTasks = tasksInRange.filter { $0.status == .completed }
        return Double(completedTasks.count) / Double(tasksInRange.count)
    }
    
    private var goalsProgress: Double {
        let activeGoals = dataManager.goals.filter { $0.status == .inProgress }
        guard !activeGoals.isEmpty else { return 0.0 }
        return activeGoals.reduce(0) { $0 + $1.progress } / Double(activeGoals.count)
    }
    
    private var studyDays: Int {
        let interval = timeRange.dateInterval
        let studyDates = Set(dataManager.records
            .filter { interval.contains($0.startTime) }
            .map { Calendar.current.startOfDay(for: $0.startTime) })
        return studyDates.count
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 目标进度分析
struct GoalsProgressAnalysis: View {
    let timeRange: TimeRange
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目标进度分析")
                .font(.headline)
                .fontWeight(.semibold)
            
            if activeGoals.isEmpty {
                Text("暂无进行中的目标")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(activeGoals) { goal in
                    GoalProgressCard(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var activeGoals: [LearningGoal] {
        dataManager.goals.filter { $0.status == .inProgress }
    }
}

// MARK: - 目标进度卡片
struct GoalProgressCard: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(goal.title)
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习时长统计
struct StudyTimeStats: View {
    let timeRange: TimeRange
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习时长统计")
                .font(.headline)
                .fontWeight(.semibold)
            
            if studyTimeBySubject.isEmpty {
                Text("暂无学习记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(studyTimeBySubject.sorted(by: { $0.value > $1.value }), id: \.key) { subject, time in
                    SubjectTimeRow(subject: subject, time: time, totalTime: totalStudyTime)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var studyTimeBySubject: [SubjectCategory: TimeInterval] {
        let interval = timeRange.dateInterval
        var subjectTime: [SubjectCategory: TimeInterval] = [:]
        
        for record in dataManager.records.filter({ interval.contains($0.startTime) }) {
            if let task = dataManager.tasks.first(where: { $0.id == record.taskId }) {
                subjectTime[task.category, default: 0] += record.duration
            }
        }
        
        return subjectTime
    }
    
    private var totalStudyTime: TimeInterval {
        studyTimeBySubject.values.reduce(0, +)
    }
}

// MARK: - 科目时间行
struct SubjectTimeRow: View {
    let subject: SubjectCategory
    let time: TimeInterval
    let totalTime: TimeInterval
    
    var body: some View {
        HStack {
            Image(systemName: subject.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(subject.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(time))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("\(Int((time / totalTime) * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 复盘记录
struct ReflectionRecords: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("复盘记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !reflections.isEmpty {
                    NavigationLink("查看全部") {
                        AllReflectionsView()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if reflections.isEmpty {
                Text("暂无复盘记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(reflections.prefix(3)) { reflection in
                    ReflectionCard(reflection: reflection)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var reflections: [LearningReflection] {
        dataManager.reflections.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - 复盘卡片
struct ReflectionCard: View {
    let reflection: LearningReflection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(reflection.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(reflection.createdAt, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(reflection.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !reflection.insights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("关键洞察:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(reflection.insights.prefix(2), id: \.self) { insight in
                        Text("• \(insight)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 学习复盘模型
struct LearningReflection: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var insights: [String]
    var createdAt: Date
    
    init(title: String, content: String, insights: [String] = []) {
        self.title = title
        self.content = content
        self.insights = insights
        self.createdAt = Date()
    }
}

// MARK: - 添加复盘视图
struct AddReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var title = ""
    @State private var content = ""
    @State private var insights: [String] = []
    @State private var newInsight = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("复盘标题") {
                    TextField("输入复盘标题", text: $title)
                }
                
                Section("复盘内容") {
                    TextField("记录你的学习心得和反思...", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("关键洞察") {
                    ForEach(insights, id: \.self) { insight in
                        Text(insight)
                    }
                    .onDelete(perform: deleteInsight)
                    
                    HStack {
                        TextField("添加洞察", text: $newInsight)
                        Button("添加") {
                            if !newInsight.isEmpty {
                                insights.append(newInsight)
                                newInsight = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加复盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveReflection()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func deleteInsight(offsets: IndexSet) {
        insights.remove(atOffsets: offsets)
    }
    
    private func saveReflection() {
        let reflection = LearningReflection(
            title: title,
            content: content,
            insights: insights
        )
        dataManager.addReflection(reflection)
        dismiss()
    }
}

// MARK: - 所有复盘视图
struct AllReflectionsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List {
            ForEach(dataManager.reflections.sorted { $0.createdAt > $1.createdAt }) { reflection in
                ReflectionCard(reflection: reflection)
            }
        }
        .navigationTitle("复盘记录")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - 辅助函数
private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)小时\(minutes)分钟"
    } else {
        return "\(minutes)分钟"
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
    StatsView()
        .environmentObject(DataManager())
}
