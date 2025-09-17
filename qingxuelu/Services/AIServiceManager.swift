//
//  AIServiceManager.swift
//  qingxuelu
//
//  Created by ZL on 2025/9/5.
//

import Foundation
import Combine

// MARK: - AI服务管理器
class AIServiceManager: ObservableObject {
    static let shared = AIServiceManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = AppEnvironment.current.apiKey
    private let baseURL = AppEnvironment.current.baseURL
    
    private init() {}
    
    // MARK: - 生成学习模板
    func generateLearningTemplate(for profile: StudentProfile) async throws -> LearningTemplate {
        isLoading = true
        defer { isLoading = false }
        
        let prompt = buildPrompt(for: profile)
        let response = try await callQwenAPI(prompt: prompt)
        
        return try parseTemplateResponse(response, profile: profile)
    }
    
    // MARK: - 测试AI响应（调试用）
    func testAIResponse(for profile: StudentProfile) async throws -> String {
        let prompt = buildPrompt(for: profile)
        return try await callQwenAPI(prompt: prompt)
    }
    
    // MARK: - 构建AI提示词
    private func buildPrompt(for profile: StudentProfile) -> String {
        let subjectScoresText = profile.subjectScores.map { score in
            "\(score.subject.rawValue): \(score.score)分 (\(score.level.rawValue))"
        }.joined(separator: ", ")
        
        return """
        你是一位专业的教育专家，请为以下学生制定一个科学的学习管理模板：
        
        学生信息：
        - 年级：\(profile.grade.rawValue) (\(profile.grade.description))
        - 学业水平：\(profile.academicLevel.rawValue)
        - 各科成绩：\(subjectScoresText)
        - 学习风格：\(profile.learningStyle.rawValue)
        - 优势：\(profile.strengths.joined(separator: ", "))
        - 薄弱环节：\(profile.weaknesses.joined(separator: ", "))
        - 兴趣爱好：\(profile.interests.joined(separator: ", "))
        - 学习目标：\(profile.goals.joined(separator: ", "))
        
        请生成一个JSON格式的学习管理模板，包含以下内容：
        1. 模板标题和描述
        2. 3-5个学习目标（包含SMART目标和OKR目标）
        3. 每个目标对应的里程碑或关键结果
        4. 10-15个具体的学习任务
        5. 每日学习计划安排
        6. 5-8条学习建议
        
        请确保：
        - 目标要符合学生当前水平，既有挑战性又可实现
        - 任务要具体可执行，时间安排合理
        - 建议要实用且针对性强
        - 考虑学生的学习风格和兴趣爱好
        
        返回格式必须是有效的JSON，不要包含其他文字说明。
        """
    }
    
    // MARK: - 调用Qwen API
    private func callQwenAPI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        let requestBody = OpenAICompatibleRequest(
            model: APIConfig.model,
            messages: [
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: APIConfig.temperature,
            maxTokens: APIConfig.maxTokens,
            topP: APIConfig.topP
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 设置更长的超时时间，因为AI生成模板需要更多时间
        request.timeoutInterval = 120.0 // 2分钟超时
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAICompatibleResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.noContent
        }
        
        return content
    }
    
    // MARK: - 解析AI响应
    private func parseTemplateResponse(_ response: String, profile: StudentProfile) throws -> LearningTemplate {
        // 添加调试信息
        print("=== AI原始响应开始 ===")
        print(response)
        print("=== AI原始响应结束 ===")
        
        // 清理响应文本，提取JSON部分
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("=== 清理后响应开始 ===")
        print(cleanedResponse)
        print("=== 清理后响应结束 ===")
        
        // 尝试修复不完整的JSON
        let fixedResponse = fixIncompleteJSON(cleanedResponse)
        print("=== 修复后响应开始 ===")
        print(fixedResponse)
        print("=== 修复后响应结束 ===")
        
        guard let data = fixedResponse.data(using: .utf8) else {
            print("无法将响应转换为UTF-8数据")
            throw AIServiceError.parseError
        }
        
        // 先尝试解析为字典
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            print("=== JSON对象解析成功 ===")
            print(jsonObject)
            print("=== JSON对象结束 ===")
            
            // 尝试解析为灵活的字典结构
            if let dict = jsonObject as? [String: Any] {
                return try parseFlexibleTemplate(from: dict, profile: profile)
            }
        } catch {
            print("JSON对象解析失败: \(error)")
            print("原始数据: \(String(data: data, encoding: .utf8) ?? "无法转换为字符串")")
        }
        
        // 如果解析失败，创建一个默认模板
        print("创建默认模板...")
        return createDefaultTemplate(for: profile)
    }
    
    // MARK: - 修复不完整的JSON
    private func fixIncompleteJSON(_ jsonString: String) -> String {
        var fixed = jsonString
        
        // 检查是否缺少结束的括号
        let openBraces = fixed.filter { $0 == "{" }.count
        let closeBraces = fixed.filter { $0 == "}" }.count
        let openBrackets = fixed.filter { $0 == "[" }.count
        let closeBrackets = fixed.filter { $0 == "]" }.count
        
        // 添加缺少的结束括号
        for _ in 0..<(openBrackets - closeBrackets) {
            fixed += "]"
        }
        for _ in 0..<(openBraces - closeBraces) {
            fixed += "}"
        }
        
        return fixed
    }
    
    // MARK: - 灵活解析模板
    private func parseFlexibleTemplate(from dict: [String: Any], profile: StudentProfile) throws -> LearningTemplate {
        // 提取标题和描述（支持中英文键名）
        let title = dict["title"] as? String ?? 
                   dict["templateTitle"] as? String ?? 
                   dict["模板标题"] as? String ?? 
                   "\(profile.grade.rawValue)学习计划"
        
        let description = dict["description"] as? String ?? 
                         dict["templateDescription"] as? String ?? 
                         dict["模板描述"] as? String ?? 
                         "为\(profile.grade.rawValue)学生制定的个性化学习计划"
        
        var template = LearningTemplate(
            title: title,
            description: description,
            grade: profile.grade,
            academicLevel: profile.academicLevel,
            templateType: .comprehensive
        )
        
        // 解析目标（支持多种格式）
        if let goalsArray = dict["goals"] as? [[String: Any]] ?? 
                           dict["learningGoals"] as? [[String: Any]] ?? 
                           dict["学习目标"] as? [[String: Any]] {
            template.goals = parseGoals(from: goalsArray)
        }
        
        // 解析任务（支持多种格式）
        if let tasksArray = dict["tasks"] as? [String] ?? 
                           dict["learningTasks"] as? [String] ?? 
                           dict["学习任务"] as? [String] {
            template.tasks = parseTasks(from: tasksArray)
        }
        
        // 添加建议
        let advice = dict["generalAdvice"] as? String ?? 
                    dict["建议"] as? String ?? 
                    "请根据学生情况调整学习计划"
        template.recommendations = [advice]
        
        print("✅ 灵活模板转换成功！")
        print("📊 目标数量: \(template.goals.count)")
        print("📊 任务数量: \(template.tasks.count)")
        print("📊 建议数量: \(template.recommendations.count)")
        
        return template
    }
    
    // MARK: - 解析目标
    private func parseGoals(from goalsArray: [[String: Any]]) -> [TemplateGoal] {
        return goalsArray.enumerated().map { index, goalDict in
            let title = goalDict["title"] as? String ?? 
                       goalDict["goalDescription"] as? String ?? 
                       goalDict["SMART目标"] as? String ?? 
                       "学习目标 \(index + 1)"
            
            let description = goalDict["description"] as? String ?? 
                             goalDict["goalDescription"] as? String ?? 
                             goalDict["OKR目标"] as? String ?? 
                             title
            
            let goalType = goalDict["goalType"] as? String ?? 
                          goalDict["type"] as? String ?? 
                          "smart"
            
            var goal = TemplateGoal(
                title: title,
                description: description,
                category: .chinese, // 默认分类
                priority: .medium,
                targetDate: Date().addingTimeInterval(30 * 24 * 3600), // 30天后
                goalType: GoalType(rawValue: goalType.lowercased()) ?? .smart
            )
            
            // 解析里程碑
            if let milestones = goalDict["milestones"] as? [String] {
                goal.milestones = milestones.map { milestoneTitle in
                    TemplateMilestone(
                        title: milestoneTitle,
                        description: "",
                        targetDate: goal.targetDate,
                        order: 0
                    )
                }
            }
            
            return goal
        }
    }
    
    // MARK: - 解析任务
    private func parseTasks(from tasksArray: [String]) -> [TemplateTask] {
        return tasksArray.enumerated().map { index, taskString in
            TemplateTask(
                title: taskString,
                description: taskString,
                category: .chinese, // 默认分类
                priority: .medium,
                estimatedDuration: 30, // 默认30分钟
                frequency: .daily,
                order: index
            )
        }
    }
    
    // MARK: - 创建默认模板
    private func createDefaultTemplate(for profile: StudentProfile) -> LearningTemplate {
        var template = LearningTemplate(
            title: "\(profile.grade.rawValue)学习计划",
            description: "为\(profile.grade.rawValue)学生制定的个性化学习计划",
            grade: profile.grade,
            academicLevel: profile.academicLevel,
            templateType: .comprehensive
        )
        
        // 添加默认目标
        let defaultGoal = TemplateGoal(
            title: "提升整体学习成绩",
            description: "通过系统学习提升各科成绩",
            category: .chinese,
            priority: .high,
            targetDate: Date().addingTimeInterval(30 * 24 * 3600),
            goalType: .smart
        )
        template.goals = [defaultGoal]
        
        // 添加默认任务
        let defaultTask = TemplateTask(
            title: "每日学习任务",
            description: "完成每日学习计划",
            category: .chinese,
            priority: .medium,
            estimatedDuration: 60,
            frequency: .daily,
            order: 0
        )
        template.tasks = [defaultTask]
        
        // 添加默认建议
        template.recommendations = ["建议每天保持规律的学习时间", "注意劳逸结合", "定期复习巩固"]
        
        return template
    }
}

// MARK: - AI服务错误
enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case apiError
    case noContent
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .apiError:
            return "API调用失败"
        case .noContent:
            return "AI未返回内容"
        case .parseError:
            return "解析AI响应失败"
        }
    }
}

// MARK: - OpenAI兼容API请求模型
struct OpenAICompatibleRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAICompatibleResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - AI响应解析模型
struct TemplateResponse: Codable {
    let title: String
    let description: String
    let goals: [TemplateGoalData]
    let tasks: [TemplateTaskData]
    let schedule: TemplateScheduleData
    let recommendations: [String]
}

struct TemplateGoalData: Codable {
    let title: String
    let description: String
    let category: SubjectCategory
    let priority: Priority
    let targetDate: Date
    let goalType: GoalType
    let milestones: [TemplateMilestoneData]
    let keyResults: [TemplateKeyResultData]
}

struct TemplateMilestoneData: Codable {
    let title: String
    let description: String
    let targetDate: Date
    let order: Int
}

struct TemplateKeyResultData: Codable {
    let title: String
    let description: String
    let targetValue: Double
    let unit: String
    let order: Int
}

struct TemplateTaskData: Codable {
    let title: String
    let description: String
    let category: SubjectCategory
    let priority: Priority
    let estimatedDuration: Int
    let frequency: TaskFrequency
    let order: Int
}

struct TemplateScheduleData: Codable {
    let dailyStudyTime: Int
    let weeklyStudyDays: Int
    let studyTimeSlots: [StudyTimeSlotData]
    let breakTime: Int
}

struct StudyTimeSlotData: Codable {
    let startTime: String
    let endTime: String
    let subject: SubjectCategory?
    let description: String
}
