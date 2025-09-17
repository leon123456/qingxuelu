//
//  AIPlanningView.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import SwiftUI

struct AIPlanningView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIServiceManager.shared
    
    @State private var currentStep: PlanningStep = .studentInfo
    @State private var studentInfo = StudentInfoForm()
    @State private var generatedTemplate: LearningTemplate?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingValidationAlert = false
    
    enum PlanningStep: CaseIterable {
        case studentInfo
        case aiGeneration
        case goalConfirmation
        case planPreview
        
        var title: String {
            switch self {
            case .studentInfo: return "学生信息"
            case .aiGeneration: return "AI分析"
            case .goalConfirmation: return "目标确认"
            case .planPreview: return "计划预览"
            }
        }
        
        var description: String {
            switch self {
            case .studentInfo: return "请填写学生的基本信息"
            case .aiGeneration: return "AI正在分析并生成学习计划"
            case .goalConfirmation: return "请确认AI推荐的学习目标"
            case .planPreview: return "查看完整的学习计划"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度指示器
                ProgressIndicator(currentStep: currentStep)
                
                // 主要内容区域
                ScrollView {
                    VStack(spacing: 24) {
                        // 步骤标题
                        VStack(spacing: 8) {
                            Text(currentStep.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(currentStep.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // 步骤内容
                        Group {
                            switch currentStep {
                            case .studentInfo:
                                StudentInfoStep(studentInfo: $studentInfo)
                            case .aiGeneration:
                                AIGenerationStep(isLoading: isLoading, errorMessage: errorMessage)
                            case .goalConfirmation:
                                GoalConfirmationStep(template: generatedTemplate)
                            case .planPreview:
                                PlanPreviewStep(template: generatedTemplate)
                            }
                        }
                        .animation(.easeInOut, value: currentStep)
                    }
                    .padding()
                }
                
                // 底部按钮
                BottomActionButtons(
                    currentStep: currentStep,
                    isLoading: isLoading,
                    onNext: handleNextStep,
                    onPrevious: handlePreviousStep,
                    onComplete: handleComplete
                )
            }
            .navigationTitle("AI智能规划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("请填写学生姓名", isPresented: $showingValidationAlert) {
                Button("确定") { }
            } message: {
                Text("学生姓名是必填项，请填写后再继续")
            }
        }
    }
    
    // MARK: - 步骤处理
    private func handleNextStep() {
        switch currentStep {
        case .studentInfo:
            if validateStudentInfo() {
                currentStep = .aiGeneration
                generateAIPlan()
            } else {
                showingValidationAlert = true
            }
        case .aiGeneration:
            if generatedTemplate != nil {
                currentStep = .goalConfirmation
            }
        case .goalConfirmation:
            currentStep = .planPreview
        case .planPreview:
            break
        }
    }
    
    private func handlePreviousStep() {
        switch currentStep {
        case .studentInfo:
            dismiss()
        case .aiGeneration:
            currentStep = .studentInfo
        case .goalConfirmation:
            currentStep = .aiGeneration
        case .planPreview:
            currentStep = .goalConfirmation
        }
    }
    
    private func handleComplete() {
        // 应用AI生成的计划
        if let template = generatedTemplate {
            applyTemplate(template)
        }
        dismiss()
    }
    
    // MARK: - AI生成
    private func generateAIPlan() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = createStudentProfile()
                
                // 先测试AI原始响应
                let rawResponse = try await aiService.testAIResponse(for: profile)
                print("🔍 AI原始响应:")
                print(rawResponse)
                print("🔍 响应结束")
                
                // 然后尝试解析
                let template = try await aiService.generateLearningTemplate(for: profile)
                
                await MainActor.run {
                    generatedTemplate = template
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ AI生成错误: \(error)")
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func createStudentProfile() -> StudentProfile {
        let subjectScores = studentInfo.subjects.map { subject in
            SubjectScore(subject: subject.category, score: subject.score)
        }
        
        return StudentProfile(
            studentId: UUID(),
            grade: studentInfo.grade,
            academicLevel: studentInfo.academicLevel
        )
    }
    
    private func validateStudentInfo() -> Bool {
        // 只需要姓名不为空即可进入下一步
        return !studentInfo.name.isEmpty
    }
    
    private func applyTemplate(_ template: LearningTemplate) {
        // 应用模板中的目标
        for templateGoal in template.goals {
            var learningGoal = LearningGoal(
                title: templateGoal.title,
                description: templateGoal.description,
                category: templateGoal.category,
                priority: templateGoal.priority,
                targetDate: templateGoal.targetDate,
                goalType: templateGoal.goalType
            )
            
            // 添加里程碑
            for templateMilestone in templateGoal.milestones {
                let milestone = Milestone(
                    title: templateMilestone.title,
                    description: templateMilestone.description,
                    targetDate: templateMilestone.targetDate
                )
                learningGoal.milestones.append(milestone)
            }
            
            // 添加关键结果
            for templateKeyResult in templateGoal.keyResults {
                let keyResult = KeyResult(
                    title: templateKeyResult.title,
                    description: templateKeyResult.description,
                    targetValue: templateKeyResult.targetValue,
                    unit: templateKeyResult.unit
                )
                learningGoal.keyResults.append(keyResult)
            }
            
            dataManager.addGoal(learningGoal)
        }
        
        // 应用模板中的任务
        for templateTask in template.tasks {
            let learningTask = LearningTask(
                title: templateTask.title,
                description: templateTask.description,
                category: templateTask.category,
                priority: templateTask.priority,
                estimatedDuration: TimeInterval(templateTask.estimatedDuration * 60) // 转换为秒
            )
            dataManager.addTask(learningTask)
        }
        
        print("✅ 模板应用成功！")
        print("📊 已添加 \(template.goals.count) 个目标")
        print("📊 已添加 \(template.tasks.count) 个任务")
    }
}

// MARK: - 进度指示器
struct ProgressIndicator: View {
    let currentStep: AIPlanningView.PlanningStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(AIPlanningView.PlanningStep.allCases.enumerated()), id: \.offset) { index, step in
                Circle()
                    .fill(step == currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if index < AIPlanningView.PlanningStep.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
}

// MARK: - 学生信息表单
struct StudentInfoForm {
    var name: String = ""
    var age: Int = 8
    var grade: Grade = .grade1
    var academicLevel: AcademicLevel = .average
    var subjects: [SubjectInfo] = []
    var learningStyle: LearningStyle = .visual
    var strengths: [String] = []
    var weaknesses: [String] = []
    var interests: [String] = []
}

struct SubjectInfo: Identifiable {
    let id = UUID()
    var category: SubjectCategory
    var score: Int
}

// MARK: - 步骤视图组件
struct StudentInfoStep: View {
    @Binding var studentInfo: StudentInfoForm
    @State private var showingAddSubject = false
    @State private var showingValidationAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 基本信息
            VStack(spacing: 16) {
                TextField("学生姓名", text: $studentInfo.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("年龄")
                    Spacer()
                    Stepper("\(studentInfo.age)岁", value: $studentInfo.age, in: 6...18)
                }
                
                Picker("年级", selection: $studentInfo.grade) {
                    ForEach(Grade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("学业水平", selection: $studentInfo.academicLevel) {
                    ForEach(AcademicLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 科目成绩
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("各科成绩")
                        .font(.headline)
                    Spacer()
                    Button("添加科目") {
                        showingAddSubject = true
                    }
                    .font(.caption)
                }
                
                ForEach(studentInfo.subjects) { subject in
                    HStack {
                        Text(subject.category.rawValue)
                        Spacer()
                        Text("\(subject.score)分")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if studentInfo.subjects.isEmpty {
                    Text("请至少添加一门科目的成绩，这样AI能更好地为您生成学习计划")
                        .font(.caption)
                        .foregroundColor(Color(.systemOrange))
                        .padding(.top, 4)
                }
            }
            
            // 学习风格
            VStack(alignment: .leading, spacing: 12) {
                Text("学习风格")
                    .font(.headline)
                
                Picker("学习风格", selection: $studentInfo.learningStyle) {
                    ForEach(LearningStyle.allCases, id: \.self) { style in
                        VStack(alignment: .leading) {
                            Text(style.rawValue)
                            Text(style.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(style)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
            }
            
            // 个性化标签
            VStack(alignment: .leading, spacing: 12) {
                Text("个性化标签")
                    .font(.headline)
                
                TextField("优势 (可选)", text: Binding(
                    get: { studentInfo.strengths.joined(separator: ", ") },
                    set: { studentInfo.strengths = $0.split(separator: ",").map(String.init).filter { !$0.isEmpty } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("薄弱环节 (可选)", text: Binding(
                    get: { studentInfo.weaknesses.joined(separator: ", ") },
                    set: { studentInfo.weaknesses = $0.split(separator: ",").map(String.init).filter { !$0.isEmpty } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("兴趣爱好 (可选)", text: Binding(
                    get: { studentInfo.interests.joined(separator: ", ") },
                    set: { studentInfo.interests = $0.split(separator: ",").map(String.init).filter { !$0.isEmpty } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .sheet(isPresented: $showingAddSubject) {
            AddSubjectView(subjects: $studentInfo.subjects)
        }
        .alert("请填写学生姓名", isPresented: $showingValidationAlert) {
            Button("确定") { }
        } message: {
            Text("学生姓名是必填项，请填写后再继续")
        }
    }
}

struct AIGenerationStep: View {
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("AI正在分析学生信息...")
                        .font(.headline)
                    
                    Text("请稍候，我们正在为您生成个性化的学习计划")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Color(.systemRed))
                    
                    Text("生成失败")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(.systemGreen))
                    
                    Text("AI分析完成")
                        .font(.headline)
                    
                    Text("已为您生成个性化的学习计划")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct GoalConfirmationStep: View {
    let template: LearningTemplate?
    
    var body: some View {
        VStack(spacing: 20) {
            if let template = template {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI推荐的学习目标")
                        .font(.headline)
                    
                    ForEach(template.goals) { goal in
                        GoalConfirmationCard(goal: goal)
                    }
                }
            } else {
                Text("暂无目标数据")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PlanPreviewStep: View {
    let template: LearningTemplate?
    
    var body: some View {
        VStack(spacing: 20) {
            if let template = template {
                VStack(alignment: .leading, spacing: 16) {
                    Text("完整学习计划")
                        .font(.headline)
                    
                    PlanPreviewCard(template: template)
                }
            } else {
                Text("暂无计划数据")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 底部操作按钮
struct BottomActionButtons: View {
    let currentStep: AIPlanningView.PlanningStep
    let isLoading: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep != .studentInfo {
                Button("上一步") {
                    onPrevious()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            Button(action: {
                if currentStep == .planPreview {
                    onComplete()
                } else {
                    onNext()
                }
            }) {
                Text(currentStep == .planPreview ? "完成" : "下一步")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
}

// MARK: - 辅助视图
struct AddSubjectView: View {
    @Binding var subjects: [SubjectInfo]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SubjectCategory = .chinese
    @State private var score: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("科目", selection: $selectedCategory) {
                    ForEach(SubjectCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                
                TextField("分数", text: $score)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("添加科目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if let scoreInt = Int(score), scoreInt >= 0, scoreInt <= 100 {
                            subjects.append(SubjectInfo(category: selectedCategory, score: scoreInt))
                            dismiss()
                        }
                    }
                    .disabled(score.isEmpty || Int(score) == nil)
                }
            }
        }
    }
}

struct GoalConfirmationCard: View {
    let goal: TemplateGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(goal.goalType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(goal.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !goal.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("里程碑:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(Array(goal.milestones.enumerated()), id: \.offset) { index, milestone in
                        Text("• \(milestone)")
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

struct PlanPreviewCard: View {
    let template: LearningTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(template.title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("学习目标: \(template.goals.count)个")
                    .font(.caption)
                
                Text("学习任务: \(template.tasks.count)个")
                    .font(.caption)
                
                Text("总体建议:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("请查看AI生成的详细建议")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    AIPlanningView()
        .environmentObject(DataManager())
}
