//
//  GoalTemplateView.swift
//  qingxuelu
//
//  Created by Assistant on 2025-09-11.
//

import SwiftUI

struct GoalTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var searchText = ""
    @State private var selectedCategoryIndex = 0
    @State private var selectedTemplate: GoalTemplate? = nil
    
    // 所有分类，包括"全部"
    private let allCategories: [(String, SubjectCategory?)] = [
        ("全部", nil),
        ("语文", .chinese),
        ("数学", .math),
        ("英语", .english),
        ("物理", .physics),
        ("化学", .chemistry),
        ("生物", .biology),
        ("历史", .history),
        ("地理", .geography),
        ("政治", .politics),
        ("其他", .other)
    ]
    
    private var currentCategory: SubjectCategory? {
        allCategories[selectedCategoryIndex].1
    }
    
    private var filteredTemplates: [GoalTemplate] {
        let templates = GoalTemplateManager.shared.templates
        
        var filtered = templates
        
        // 按类别筛选
        if let category = currentCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    private func getTemplatesForCategory(_ category: SubjectCategory?) -> [GoalTemplate] {
        let templates = GoalTemplateManager.shared.templates
        
        var filtered = templates
        
        // 按类别筛选
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // 类别筛选按钮
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(allCategories.enumerated()), id: \.offset) { index, category in
                            CategoryChip(
                                title: category.0,
                                isSelected: selectedCategoryIndex == index,
                                action: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedCategoryIndex = index
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // 使用 TabView 实现左右滑动
                TabView(selection: $selectedCategoryIndex) {
                    ForEach(Array(allCategories.enumerated()), id: \.offset) { index, category in
                        TemplateListView(
                            templates: getTemplatesForCategory(category.1),
                            selectedTemplate: $selectedTemplate
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedCategoryIndex)
            }
            .navigationTitle("目标模板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template) { appliedTemplate in
                applyTemplate(appliedTemplate)
                selectedTemplate = nil  // 这会自动关闭 sheet
            }
        }
    }
    
    private func applyTemplate(_ template: GoalTemplate) {
        // 将模板转换为学习目标
        var goal = LearningGoal(
            title: template.name,
            description: template.description,
            category: template.category,
            priority: template.priority,
            targetDate: Date().addingTimeInterval(TimeInterval(template.duration * 24 * 3600)),
            goalType: template.goalType
        )
        
        // 添加里程碑
        goal.milestones = template.milestones.map { milestoneTemplate in
            Milestone(
                title: milestoneTemplate.title,
                description: milestoneTemplate.description,
                targetDate: Date().addingTimeInterval(TimeInterval(milestoneTemplate.duration * 24 * 3600))
            )
        }
        
        // 添加关键结果
        goal.keyResults = template.keyResults.map { keyResultTemplate in
            KeyResult(
                title: keyResultTemplate.title,
                description: keyResultTemplate.description,
                targetValue: keyResultTemplate.targetValue,
                unit: keyResultTemplate.unit
            )
        }
        
        // 添加建议任务
        for taskTemplate in template.suggestedTasks {
            let priority: Priority = {
                switch taskTemplate.difficulty {
                case .easy: return .low
                case .medium: return .medium
                case .hard: return .high
                }
            }()
            
            let task = LearningTask(
                title: taskTemplate.title,
                description: taskTemplate.description,
                category: template.category,
                priority: priority,
                estimatedDuration: TimeInterval(taskTemplate.estimatedDuration * 60),
                goalId: goal.id
            )
            dataManager.addTask(task)
        }
        
        dataManager.addGoal(goal)
        dismiss()
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索模板...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("清除") {
                    text = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 类别标签
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
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
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 模板卡片
struct TemplateCardView: View {
    let template: GoalTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(template.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        
                        Text(template.goalType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // 标签
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(template.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // 统计信息
                HStack {
                    Label("\(template.milestones.count) 里程碑", systemImage: "flag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(template.keyResults.count) 关键结果", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(template.suggestedTasks.count) 任务", systemImage: "checklist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 模板详情视图
struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let template: GoalTemplate
    let onApply: (GoalTemplate) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 模板基本信息
                    TemplateInfoSection(template: template)
                    
                    // 里程碑
                    if !template.milestones.isEmpty {
                        TemplateMilestonesSection(template: template)
                    }
                    
                    // 关键结果
                    if !template.keyResults.isEmpty {
                        KeyResultsSection(template: template)
                    }
                    
                    // 建议任务
                    if !template.suggestedTasks.isEmpty {
                        SuggestedTasksSection(template: template)
                    }
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用模板") {
                        onApply(template)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 模板信息区域
struct TemplateInfoSection: View {
    let template: GoalTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 标签
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // 基本信息
            VStack(alignment: .leading, spacing: 8) {
                TemplateInfoRow(title: "科目", value: template.category.rawValue, icon: template.category.icon)
                TemplateInfoRow(title: "目标类型", value: template.goalType.rawValue, icon: template.goalType.icon)
                TemplateInfoRow(title: "优先级", value: template.priority.rawValue, icon: "exclamationmark.triangle")
                TemplateInfoRow(title: "预计时长", value: "\(template.duration) 天", icon: "clock")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 模板里程碑区域
struct TemplateMilestonesSection: View {
    let template: GoalTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("里程碑")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(template.milestones) { milestone in
                MilestoneTemplateRow(milestone: milestone)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 关键结果区域
struct KeyResultsSection: View {
    let template: GoalTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键结果")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(template.keyResults) { keyResult in
                KeyResultTemplateRow(keyResult: keyResult)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 建议任务区域
struct SuggestedTasksSection: View {
    let template: GoalTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("建议任务")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(template.suggestedTasks) { task in
                TaskTemplateRow(task: task)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 模板信息行
struct TemplateInfoRow: View {
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

// MARK: - 里程碑模板行
struct MilestoneTemplateRow: View {
    let milestone: MilestoneTemplate
    
    var body: some View {
        HStack {
            Image(systemName: "flag")
                .foregroundColor(Color(.systemOrange))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(milestone.duration)天")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 关键结果模板行
struct KeyResultTemplateRow: View {
    let keyResult: KeyResultTemplate
    
    var body: some View {
        HStack {
            Image(systemName: "target")
                .foregroundColor(Color(.systemGreen))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(keyResult.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(keyResult.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(keyResult.targetValue)) \(keyResult.unit)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 任务模板行
struct TaskTemplateRow: View {
    let task: TaskTemplate
    
    var body: some View {
        HStack {
            Image(systemName: "checklist")
                .foregroundColor(.purple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(task.estimatedDuration)分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(task.difficulty.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(task.difficulty.color).opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空模板视图
struct EmptyTemplatesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有找到匹配的模板")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("尝试调整搜索条件或选择不同的类别")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 模板列表视图
struct TemplateListView: View {
    let templates: [GoalTemplate]
    @Binding var selectedTemplate: GoalTemplate?
    
    var body: some View {
        if templates.isEmpty {
            EmptyTemplatesView()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(templates) { template in
                        TemplateCardView(template: template) {
                            selectedTemplate = template
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    GoalTemplateView()
        .environmentObject(DataManager())
}
