//
//  GoalTemplateView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/10.
//

import SwiftUI

struct GoalTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var templateManager = GoalTemplateManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: SubjectCategory? = nil
    @State private var selectedTemplate: GoalTemplate? = nil
    
    let onTemplateSelected: (GoalTemplate) -> Void
    
    var filteredTemplates: [GoalTemplate] {
        return templateManager.searchTemplates(query: searchText)
            .filter { template in
                selectedCategory == nil || template.category == selectedCategory
            }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // 分类筛选
                CategoryFilterView(selectedCategory: $selectedCategory)
                
                // 模板列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateCardView(template: template) {
                                selectedTemplate = template
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("选择模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template) { selectedTemplate in
                onTemplateSelected(selectedTemplate)
                dismiss()
            }
        }
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索模板...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("清除") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 分类筛选
struct CategoryFilterView: View {
    @Binding var selectedCategory: SubjectCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部选项
                CategoryChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // 各科目选项
                ForEach(SubjectCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 分类芯片
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - 模板卡片
struct TemplateCardView: View {
    let template: GoalTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部信息
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(template.duration)天")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(template.priority.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(priorityColor(template.priority).opacity(0.2))
                            .foregroundColor(priorityColor(template.priority))
                            .cornerRadius(8)
                    }
                }
                
                // 标签
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(template.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // 统计信息
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(template.milestones.count)个里程碑")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(template.keyResults.count)个关键结果")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(template.suggestedTasks.count)个任务")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - 模板详情视图
struct TemplateDetailView: View {
    let template: GoalTemplate
    let onUseTemplate: (GoalTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 模板头部
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: template.icon)
                                .font(.largeTitle)
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
                        
                        // 基本信息
                        HStack(spacing: 20) {
                            InfoItem(title: "科目", value: template.category.rawValue, icon: template.category.icon)
                            InfoItem(title: "类型", value: template.goalType.rawValue, icon: template.goalType.icon)
                            InfoItem(title: "时长", value: "\(template.duration)天", icon: "calendar")
                            InfoItem(title: "优先级", value: template.priority.rawValue, icon: "exclamationmark.triangle")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 里程碑
                    if !template.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("里程碑")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(template.milestones.sorted(by: { $0.order < $1.order })) { milestone in
                                MilestoneTemplateRow(milestone: milestone)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    }
                    
                    // 关键结果
                    if !template.keyResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("关键结果")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(template.keyResults) { keyResult in
                                KeyResultTemplateRow(keyResult: keyResult)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    }
                    
                    // 建议任务
                    if !template.suggestedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("建议任务")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(template.suggestedTasks) { task in
                                TaskTemplateRow(task: task)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    }
                }
                .padding()
            }
            .navigationTitle("模板详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("使用模板") {
                        onUseTemplate(template)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 信息项
struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 里程碑模板行
struct MilestoneTemplateRow: View {
    let milestone: MilestoneTemplate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("第\(milestone.duration)天")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 关键结果模板行
struct KeyResultTemplateRow: View {
    let keyResult: KeyResultTemplate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
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
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 任务模板行
struct TaskTemplateRow: View {
    let task: TaskTemplate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(task.estimatedDuration)分钟")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(task.difficulty.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(difficultyColor(task.difficulty).opacity(0.2))
                    .foregroundColor(difficultyColor(task.difficulty))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func difficultyColor(_ difficulty: TaskDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

#Preview {
    GoalTemplateView { template in
        print("Selected template: \(template.name)")
    }
}
