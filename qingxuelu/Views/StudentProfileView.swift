//
//  StudentProfileView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct StudentProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var aiService = AIServiceManager.shared
    
    @State private var grade: Grade = .grade6
    @State private var academicLevel: AcademicLevel = .average
    @State private var subjectScores: [SubjectScore] = []
    @State private var learningStyle: LearningStyle = .balanced
    @State private var strengths: [String] = []
    @State private var weaknesses: [String] = []
    @State private var interests: [String] = []
    @State private var goals: [String] = []
    
    @State private var newStrength = ""
    @State private var newWeakness = ""
    @State private var newInterest = ""
    @State private var newGoal = ""
    
    @State private var showingAITemplate = false
    @State private var generatedTemplate: LearningTemplate?
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section {
                    Picker("年级", selection: $grade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            HStack {
                                Image(systemName: grade.icon)
                                Text(grade.rawValue)
                            }
                            .tag(grade)
                        }
                    }
                    
                    Picker("学业水平", selection: $academicLevel) {
                        ForEach(AcademicLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    
                    Picker("学习风格", selection: $learningStyle) {
                        ForEach(LearningStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: style.icon)
                                    Text(style.rawValue)
                                }
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(style)
                        }
                    }
                } header: {
                    Text("基本信息")
                }
                
                // 各科成绩
                Section {
                    ForEach(SubjectCategory.allCases, id: \.self) { subject in
                        SubjectScoreRow(
                            subject: subject,
                            score: bindingForSubject(subject)
                        )
                    }
                } header: {
                    Text("各科成绩")
                } footer: {
                    Text("请根据最近一次考试成绩填写")
                }
                
                // 优势
                Section {
                    ForEach(strengths, id: \.self) { strength in
                        Text(strength)
                    }
                    .onDelete(perform: deleteStrengths)
                    
                    HStack {
                        TextField("添加优势", text: $newStrength)
                        Button("添加") {
                            if !newStrength.isEmpty {
                                strengths.append(newStrength)
                                newStrength = ""
                            }
                        }
                        .disabled(newStrength.isEmpty)
                    }
                } header: {
                    Text("学习优势")
                }
                
                // 薄弱环节
                Section {
                    ForEach(weaknesses, id: \.self) { weakness in
                        Text(weakness)
                    }
                    .onDelete(perform: deleteWeaknesses)
                    
                    HStack {
                        TextField("添加薄弱环节", text: $newWeakness)
                        Button("添加") {
                            if !newWeakness.isEmpty {
                                weaknesses.append(newWeakness)
                                newWeakness = ""
                            }
                        }
                        .disabled(newWeakness.isEmpty)
                    }
                } header: {
                    Text("薄弱环节")
                }
                
                // 兴趣爱好
                Section {
                    ForEach(interests, id: \.self) { interest in
                        Text(interest)
                    }
                    .onDelete(perform: deleteInterests)
                    
                    HStack {
                        TextField("添加兴趣爱好", text: $newInterest)
                        Button("添加") {
                            if !newInterest.isEmpty {
                                interests.append(newInterest)
                                newInterest = ""
                            }
                        }
                        .disabled(newInterest.isEmpty)
                    }
                } header: {
                    Text("兴趣爱好")
                }
                
                // 学习目标
                Section {
                    ForEach(goals, id: \.self) { goal in
                        Text(goal)
                    }
                    .onDelete(perform: deleteGoals)
                    
                    HStack {
                        TextField("添加学习目标", text: $newGoal)
                        Button("添加") {
                            if !newGoal.isEmpty {
                                goals.append(newGoal)
                                newGoal = ""
                            }
                        }
                        .disabled(newGoal.isEmpty)
                    }
                } header: {
                    Text("学习目标")
                }
                
                // AI生成模板
                Section {
                    Button(action: generateAITemplate) {
                        HStack {
                            if aiService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                            }
                            
                            Text(aiService.isLoading ? "AI正在生成模板..." : "AI生成学习管理模板")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(aiService.isLoading || !isProfileComplete)
                    
                    if let errorMessage = aiService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(Color(.systemRed))
                            .font(.caption)
                    }
                } header: {
                    Text("AI智能推荐")
                } footer: {
                    Text("基于学生信息，AI将生成个性化的学习管理模板")
                }
            }
            .navigationTitle("学生档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .disabled(!isProfileComplete)
                }
            }
        }
        .sheet(isPresented: $showingAITemplate) {
            if let template = generatedTemplate {
                AITemplateView(template: template) {
                    applyTemplate(template)
                }
            }
        }
    }
    
    // MARK: - 计算属性
    private var isProfileComplete: Bool {
        return !subjectScores.isEmpty && !strengths.isEmpty && !weaknesses.isEmpty
    }
    
    // MARK: - 方法
    private func bindingForSubject(_ subject: SubjectCategory) -> Binding<Int> {
        Binding(
            get: {
                subjectScores.first { $0.subject == subject }?.score ?? 0
            },
            set: { newValue in
                if let index = subjectScores.firstIndex(where: { $0.subject == subject }) {
                    subjectScores[index].score = newValue
                } else {
                    subjectScores.append(SubjectScore(subject: subject, score: newValue))
                }
            }
        )
    }
    
    private func deleteStrengths(offsets: IndexSet) {
        strengths.remove(atOffsets: offsets)
    }
    
    private func deleteWeaknesses(offsets: IndexSet) {
        weaknesses.remove(atOffsets: offsets)
    }
    
    private func deleteInterests(offsets: IndexSet) {
        interests.remove(atOffsets: offsets)
    }
    
    private func deleteGoals(offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
    private func generateAITemplate() {
        guard let currentStudent = dataManager.currentStudent else { return }
        
        let profile = StudentProfile(
            studentId: currentStudent.id,
            grade: grade,
            academicLevel: academicLevel
        )
        
        // 这里需要更新profile的其他属性
        var updatedProfile = profile
        updatedProfile.subjectScores = subjectScores
        updatedProfile.learningStyle = learningStyle
        updatedProfile.strengths = strengths
        updatedProfile.weaknesses = weaknesses
        updatedProfile.interests = interests
        updatedProfile.goals = goals
        
        Task {
            do {
                let template = try await aiService.generateLearningTemplate(for: updatedProfile)
                await MainActor.run {
                    generatedTemplate = template
                    showingAITemplate = true
                }
            } catch {
                await MainActor.run {
                    aiService.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func applyTemplate(_ template: LearningTemplate) {
        // 将AI生成的模板应用到实际的学习目标中
        guard let currentStudent = dataManager.currentStudent else { return }
        
        for templateGoal in template.goals {
            var goal = LearningGoal(
                title: templateGoal.title,
                description: templateGoal.description,
                category: templateGoal.category,
                priority: templateGoal.priority,
                targetDate: templateGoal.targetDate,
                goalType: templateGoal.goalType
            )
            
            // 转换里程碑
            goal.milestones = templateGoal.milestones.map { templateMilestone in
                Milestone(
                    title: templateMilestone.title,
                    description: templateMilestone.description,
                    targetDate: templateMilestone.targetDate
                )
            }
            
            // 转换关键结果
            goal.keyResults = templateGoal.keyResults.map { templateKeyResult in
                KeyResult(
                    title: templateKeyResult.title,
                    description: templateKeyResult.description,
                    targetValue: templateKeyResult.targetValue,
                    unit: templateKeyResult.unit
                )
            }
            
            dataManager.addGoal(goal)
        }
        
        // 创建学习任务
        for templateTask in template.tasks {
            let task = LearningTask(
                title: templateTask.title,
                description: templateTask.description,
                category: templateTask.category,
                priority: templateTask.priority,
                estimatedDuration: TimeInterval(templateTask.estimatedDuration * 60) // 转换为秒
            )
            
            dataManager.addTask(task)
        }
        
        dismiss()
    }
    
    private func saveProfile() {
        // 保存学生档案
        dismiss()
    }
}

// MARK: - 科目成绩行视图
struct SubjectScoreRow: View {
    let subject: SubjectCategory
    @Binding var score: Int
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: subject.icon)
                Text(subject.rawValue)
            }
            
            Spacer()
            
            HStack {
                Text("\(score)分")
                    .foregroundColor(scoreColor)
                    .fontWeight(.medium)
                
                Slider(value: Binding(
                    get: { Double(score) },
                    set: { score = Int($0) }
                ), in: 0...100, step: 1)
                .frame(width: 120)
            }
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - AI模板预览视图
struct AITemplateView: View {
    let template: LearningTemplate
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 模板信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 学习目标
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学习目标")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(template.goals) { goal in
                            GoalCard(goal: goal)
                        }
                    }
                    
                    // 学习任务
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学习任务")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(template.tasks) { task in
                            TaskCard(task: task)
                        }
                    }
                    
                    // 学习建议
                    VStack(alignment: .leading, spacing: 12) {
                        Text("学习建议")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(template.recommendations, id: \.self) { recommendation in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                
                                Text(recommendation)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI学习模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("应用模板") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 目标卡片
struct GoalCard: View {
    let goal: TemplateGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.goalType.icon)
                    .foregroundColor(.blue)
                
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(goal.goalType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(goal.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !goal.milestones.isEmpty {
                Text("里程碑：")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(goal.milestones) { milestone in
                    HStack {
                        Text("•")
                        Text(milestone.title)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            if !goal.keyResults.isEmpty {
                Text("关键结果：")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(goal.keyResults) { keyResult in
                    HStack {
                        Text("•")
                        Text("\(keyResult.title) - \(Int(keyResult.targetValue)) \(keyResult.unit)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 任务卡片
struct TaskCard: View {
    let task: TemplateTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.frequency.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
                
                Text("\(task.estimatedDuration)分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StudentProfileView()
        .environmentObject(DataManager())
}
