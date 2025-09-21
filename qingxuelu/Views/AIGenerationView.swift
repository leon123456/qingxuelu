//
//  AIGenerationView.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import SwiftUI

// MARK: - AI 生成界面
struct AIGenerationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiGenerator = AIGoalGenerator.shared
    
    let title: String
    let description: String
    let category: SubjectCategory
    let goalType: GoalType
    let targetDate: Date
    let priority: Priority
    let onGenerated: (AIGeneratedGoalContent) -> Void
    
    @State private var generatedContent: AIGeneratedGoalContent?
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if aiGenerator.isLoading {
                    LoadingView()
                } else if let content = generatedContent {
                    GeneratedContentView(
                        content: content,
                        onApply: {
                            onGenerated(content)
                            dismiss()
                        },
                        onRegenerate: {
                            generateContent()
                        }
                    )
                } else {
                    InitialView(onGenerate: generateContent)
                }
            }
            .navigationTitle("AI 智能生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if generatedContent == nil && !aiGenerator.isLoading {
                generateContent()
            }
        }
    }
    
    private func generateContent() {
        Task {
            do {
                let content = try await aiGenerator.generateGoalContent(
                    title: title,
                    description: description,
                    category: category,
                    goalType: goalType,
                    targetDate: targetDate,
                    priority: priority
                )
                
                await MainActor.run {
                    generatedContent = content
                }
            } catch {
                await MainActor.run {
                    // 错误处理已在 AIGoalGenerator 中处理
                    print("AI生成失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 初始界面
struct InitialView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // AI 图标
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("AI 智能生成")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("正在分析您的目标信息，将为您生成详细的里程碑和关键结果")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // 生成按钮
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("开始生成")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - 加载界面
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 动画图标
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("AI 正在思考中...")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("正在为您生成个性化的目标内容和执行计划")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 生成结果界面
struct GeneratedContentView: View {
    let content: AIGeneratedGoalContent
    let onApply: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 优化后的描述
                if !content.optimizedDescription.isEmpty {
                    ContentSection(
                        title: "优化后的目标描述",
                        icon: "doc.text",
                        content: {
                            Text(content.optimizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    )
                }
                
                // 里程碑
                if !content.milestones.isEmpty {
                    ContentSection(
                        title: "生成的里程碑",
                        icon: "flag",
                        content: {
                            ForEach(content.milestones) { milestone in
                                MilestonePreviewCard(milestone: milestone)
                            }
                        }
                    )
                }
                
                // 关键结果
                if !content.keyResults.isEmpty {
                    ContentSection(
                        title: "生成的关键结果",
                        icon: "target",
                        content: {
                            ForEach(content.keyResults) { keyResult in
                                KeyResultPreviewCard(keyResult: keyResult)
                            }
                        }
                    )
                }
                
                // 学习建议
                if !content.suggestions.isEmpty {
                    ContentSection(
                        title: "学习建议",
                        icon: "lightbulb",
                        content: {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(content.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(suggestion)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    )
                }
                
                // 学习时长和频率
                ContentSection(
                    title: "学习计划",
                    icon: "clock",
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("预估总时长：")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(content.estimatedHours) 小时")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("学习频率：")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(content.frequency)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                )
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                // 应用按钮
                Button(action: onApply) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("应用生成内容")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 重新生成按钮
                Button(action: onRegenerate) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新生成")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
        }
    }
}

// MARK: - 内容区域
struct ContentSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - 里程碑预览卡片
struct MilestonePreviewCard: View {
    let milestone: Milestone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(milestone.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !milestone.description.isEmpty {
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Text(milestone.targetDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.1))
        )
    }
}

// MARK: - 关键结果预览卡片
struct KeyResultPreviewCard: View {
    let keyResult: KeyResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(keyResult.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !keyResult.description.isEmpty {
                Text(keyResult.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundColor(.green)
                
                Text("目标：\(Int(keyResult.targetValue)) \(keyResult.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.green.opacity(0.1))
        )
    }
}

#Preview {
    AIGenerationView(
        title: "提升数学成绩",
        description: "提高数学成绩到90分",
        category: .math,
        goalType: .smart,
        targetDate: Date().addingTimeInterval(30 * 24 * 3600),
        priority: .medium,
        onGenerated: { _ in }
    )
}
