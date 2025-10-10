//
//  AIGoalGenerator.swift
//  qingxuelu
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation
import Combine

// MARK: - AI目标生成服务
class AIGoalGenerator: ObservableObject {
    static let shared = AIGoalGenerator()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = AppEnvironment.current.apiKey
    private let baseURL = AppEnvironment.current.baseURL
    
    private init() {}
    
    // MARK: - 生成目标内容
    func generateGoalContent(
        title: String,
        description: String,
        category: SubjectCategory,
        goalType: GoalType,
        targetDate: Date,
        priority: Priority
    ) async throws -> AIGeneratedGoalContent {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prompt = buildGoalPrompt(
                title: title,
                description: description,
                category: category,
                goalType: goalType,
                targetDate: targetDate,
                priority: priority
            )
            
            let response = try await callQwenAPI(prompt: prompt)
            return try parseGoalResponse(response)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                errorMessage = "请求超时，请检查网络连接并重试"
            case .notConnectedToInternet:
                errorMessage = "无法连接到网络，请检查网络设置"
            default:
                errorMessage = "网络请求失败：\(error.localizedDescription)"
            }
            throw error
        } catch {
            errorMessage = "生成目标内容失败：\(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 构建AI提示词
    private func buildGoalPrompt(
        title: String,
        description: String,
        category: SubjectCategory,
        goalType: GoalType,
        targetDate: Date,
        priority: Priority
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let targetDateString = dateFormatter.string(from: targetDate)
        let currentDateString = dateFormatter.string(from: Date())
        
        return """
        你是一位专业的学习规划师，请根据以下学习目标信息，生成详细的目标内容和执行计划：
        
        目标信息：
        - 目标标题：\(title)
        - 目标描述：\(description)
        - 学科分类：\(category.rawValue)
        - 目标类型：\(goalType.rawValue)
        - 优先级：\(priority.rawValue)
        - 当前日期：\(currentDateString)
        - 目标完成时间：\(targetDateString)
        
        请生成一个JSON格式的详细目标内容，包含以下内容：
        
        1. 优化后的目标描述（更具体、可量化）
        2. 根据目标类型生成相应的内容：
           - 如果是SMART目标或混合目标：生成3-5个里程碑
           - 如果是OKR目标或混合目标：生成3-5个关键结果
        3. 学习建议和注意事项
        4. 预估的学习时长和频率
        
        要求：
        - 里程碑要具体可量化，有明确的时间节点和完成标准
        - 关键结果要有具体的数值目标和衡量标准
        - 内容要符合学生的实际水平和时间安排
        - 建议要实用且针对性强
        - 里程碑的targetDate必须是"yyyy-MM-dd"格式的字符串
        
        返回格式必须是有效的JSON，严格按照以下结构：
        {
          "optimizedDescription": "优化后的目标描述",
          "milestones": [
            {
              "title": "里程碑标题",
              "description": "里程碑描述",
              "targetDate": "2024-02-15"
            }
          ],
          "keyResults": [
            {
              "title": "关键结果标题",
              "description": "关键结果描述",
              "targetValue": 100,
              "unit": "分"
            }
          ],
          "suggestions": ["建议1", "建议2"],
          "estimatedHours": 50,
          "frequency": "每天1小时"
        }
        
        不要包含其他文字说明，只返回JSON。
        """
    }
    
    // MARK: - 调用Qwen API
    private func callQwenAPI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        let request = OpenAICompatibleRequest(
            model: "qwen-plus",
            messages: [
                OpenAIMessage(role: "system", content: "你是一位专业的学习规划师，擅长制定科学的学习目标和计划。"),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            maxTokens: 2000,
            topP: 0.9
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 300.0 // 5分钟超时，与AIPlanServiceManager保持一致
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIServiceError.apiError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError
        }
        
        let apiResponse = try JSONDecoder().decode(OpenAICompatibleResponse.self, from: data)
        
        guard let content = apiResponse.choices.first?.message.content,
              !content.isEmpty else {
            throw AIServiceError.noContent
        }
        
        return content
    }
    
    // MARK: - 解析AI响应
    private func parseGoalResponse(_ response: String) throws -> AIGeneratedGoalContent {
        // 清理响应内容，提取JSON部分
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw AIServiceError.parseError
        }
        
        do {
            let goalResponse = try JSONDecoder().decode(AIGoalResponse.self, from: data)
            return convertToGeneratedContent(goalResponse)
        } catch {
            print("❌ 解析AI响应失败: \(error)")
            print("原始响应: \(response)")
            throw AIServiceError.parseError
        }
    }
    
    // MARK: - 转换为生成内容
    private func convertToGeneratedContent(_ response: AIGoalResponse) -> AIGeneratedGoalContent {
        let milestones = response.milestones.map { milestoneData in
            Milestone(
                title: milestoneData.title,
                description: milestoneData.description,
                targetDate: milestoneData.parsedTargetDate
            )
        }
        
        let keyResults = response.keyResults.map { keyResultData in
            KeyResult(
                title: keyResultData.title,
                description: keyResultData.description,
                targetValue: keyResultData.targetValue,
                unit: keyResultData.unit
            )
        }
        
        return AIGeneratedGoalContent(
            optimizedDescription: response.optimizedDescription,
            milestones: milestones,
            keyResults: keyResults,
            suggestions: response.suggestions,
            estimatedHours: response.estimatedHours,
            frequency: response.frequency
        )
    }
}

// MARK: - AI生成的目标内容
struct AIGeneratedGoalContent {
    let optimizedDescription: String
    let milestones: [Milestone]
    let keyResults: [KeyResult]
    let suggestions: [String]
    let estimatedHours: Int
    let frequency: String
}

// MARK: - AI响应模型
struct AIGoalResponse: Codable {
    let optimizedDescription: String
    let milestones: [AIMilestoneData]
    let keyResults: [AIKeyResultData]
    let suggestions: [String]
    let estimatedHours: Int
    let frequency: String
}

struct AIMilestoneData: Codable {
    let title: String
    let description: String
    let targetDate: String // 改为字符串类型，稍后解析为Date
    
    // 计算属性：将字符串转换为Date
    var parsedTargetDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: targetDate) ?? Date().addingTimeInterval(7 * 24 * 3600) // 默认7天后
    }
}

struct AIKeyResultData: Codable {
    let title: String
    let description: String
    let targetValue: Double
    let unit: String
}

